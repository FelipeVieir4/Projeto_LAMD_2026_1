import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/realtime_repository.dart';
import '../data/repositories/tickets_repository.dart';
import '../models/ticket.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> with WidgetsBindingObserver {
  final _auth = AuthRepository();
  String _token = '';
  List<Ticket> _tickets = [];
  bool _loading = true;
  bool _connected = false;
  String? _specialtyFilter;

  RealtimeRepository? _realtime;
  StreamSubscription<RealtimeEvent>? _subscription;
  Timer? _safetyNetTimer;

  List<String> get _specialties =>
      _tickets.map((t) => t.specialty).toSet().toList()..sort();

  List<Ticket> get _filtered => _specialtyFilter == null
      ? _tickets
      : _tickets.where((t) => t.specialty == _specialtyFilter).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _realtime?.dispose();
    _safetyNetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token.isNotEmpty) {
      _loadPending();
    }
  }

  Future<void> _init() async {
    _token = await _auth.getToken() ?? '';
    await _loadPending();
    _connectRealtime();
    // Rede de segurança: caso o WebSocket caia, garante atualização periódica.
    _safetyNetTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadPending());
  }

  void _connectRealtime() {
    _realtime = RealtimeRepository(token: _token);
    _subscription = _realtime!.connect().listen((event) {
      if (event.event == 'ticket.created') {
        _loadPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Novo chamado recebido!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (event.event == 'ticket.status_changed') {
        // Outro parceiro pode ter aceitado um chamado da fila — atualiza a lista.
        _loadPending();
      }
      if (mounted) setState(() => _connected = true);
    });
  }

  Future<void> _loadPending() async {
    if (!mounted) return;
    try {
      final repo = TicketsRepository(token: _token);
      final tickets = await repo.listPending();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
        if (_specialtyFilter != null &&
            !tickets.any((t) => t.specialty == _specialtyFilter)) {
          _specialtyFilter = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(Ticket ticket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticket: ticket, token: _token),
      ),
    );
    if (changed == true) _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final specialties = _specialties;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamados pendentes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: _connected ? 'Conectado em tempo real' : 'Conectando...',
              child: Icon(
                _connected ? Icons.bolt_rounded : Icons.bolt_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
        bottom: specialties.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _SpecialtyFilterBar(
                  specialties: specialties,
                  selected: _specialtyFilter,
                  onSelected: (s) => setState(() => _specialtyFilter = s),
                ),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPending,
        color: cs.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? _EmptyState(filtered: _specialtyFilter != null)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => TicketCard(
                      ticket: filtered[i],
                      onTap: () => _openDetail(filtered[i]),
                    ),
                  ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _SpecialtyFilterBar extends StatelessWidget {
  final List<String> specialties;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SpecialtyFilterBar({
    required this.specialties,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...specialties];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        children: options.map((s) {
          final isSelected = s == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s ?? 'Todas'),
              selected: isSelected,
              onSelected: (_) => onSelected(s),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                filtered ? 'Nenhum chamado nessa especialidade' : 'Nenhum chamado pendente',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                filtered
                    ? 'Tente outra especialidade ou\nselecione "Todas".'
                    : 'Você será avisado automaticamente\nquando um novo chamado chegar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
