import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/tickets_repository.dart';
import '../models/ticket.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ticket_card.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

enum _Filter { all, open, inProgress, done }

extension _FilterX on _Filter {
  String get label => switch (this) {
        _Filter.all => 'Todos',
        _Filter.open => 'Abertos',
        _Filter.inProgress => 'Em andamento',
        _Filter.done => 'Concluídos',
      };

  bool matches(Ticket t) => switch (this) {
        _Filter.all => true,
        _Filter.open => t.status == TicketStatus.pending,
        _Filter.inProgress =>
          t.status == TicketStatus.accepted ||
              t.status == TicketStatus.inProgress,
        _Filter.done =>
          t.status == TicketStatus.completed ||
              t.status == TicketStatus.cancelled,
      };
}

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with WidgetsBindingObserver {
  final _auth = AuthRepository();
  List<Ticket> _allTickets = [];
  _Filter _filter = _Filter.all;
  bool _loading = true;
  bool _hasUnsynced = false;
  bool _isSyncing = false;
  bool _loadingInProgress = false;
  String _userId = '';
  String _token = '';

  Timer? _syncTimer;
  static const int _maxSyncAttempts = 10;

  List<Ticket> get _filtered =>
      _allTickets.where((t) => _filter.matches(t)).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token.isNotEmpty) {
      _loadTickets();
    }
  }

  void _startSyncPolling() {
    if (_syncTimer != null) return;
    int attempts = 0;
    if (mounted) setState(() => _isSyncing = true);
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      await _loadTickets();
      if (!_hasUnsynced || attempts >= _maxSyncAttempts) {
        timer.cancel();
        _syncTimer = null;
        if (mounted) setState(() => _isSyncing = false);
      }
    });
  }

  Future<void> _init() async {
    _token = await _auth.getToken() ?? '';
    _userId = await _auth.getSavedUserId() ?? '';
    await _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (!mounted || _loadingInProgress) return;
    _loadingInProgress = true;
    if (_allTickets.isEmpty) setState(() => _loading = true);
    try {
      final repo = TicketsRepository(token: _token);
      await repo.syncPending();
      final all = await repo.syncAndList();
      if (!mounted) return;
      setState(() {
        _allTickets = all;
        _hasUnsynced = all.any((t) => !t.isSynced);
        _loading = false;
      });
      if (_hasUnsynced && _syncTimer == null) _startSyncPolling();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(token: _token, userId: _userId),
      ),
    );
    if (created == true) _loadTickets();
  }

  Future<void> _openDetail(Ticket ticket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticket: ticket, token: _token),
      ),
    );
    if (changed == true) _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Chamados'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isSyncing) const _SyncingBanner(),
          if (!_isSyncing && _hasUnsynced)
            _OfflineBanner(onRetry: _loadTickets),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              color: cs.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _EmptyState(
                          filter: _filter,
                          onAdd: _openCreate,
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => TicketCard(
                            ticket: filtered[i],
                            onTap: () => _openDetail(filtered[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo chamado'),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

// ── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final ValueChanged<_Filter> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        children: _Filter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primary
                    : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Banners ──────────────────────────────────────────────────────────────────

class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Aguardando confirmação do servidor...',
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alguns chamados ainda não foram sincronizados.',
              style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Tentar agora'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  final VoidCallback onAdd;
  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isAll = filter == _Filter.all;
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                isAll
                    ? 'Nenhum chamado ainda'
                    : 'Nenhum chamado em "${filter.label}"',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isAll)
                Text(
                  'Toque no botão abaixo para abrir\nseu primeiro chamado técnico.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              if (isAll) ...[
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Abrir chamado'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
