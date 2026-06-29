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

enum _Filter { active, done }

extension _FilterX on _Filter {
  String get label => switch (this) {
        _Filter.active => 'Em andamento',
        _Filter.done => 'Concluídos',
      };

  bool matches(Ticket t) => switch (this) {
        _Filter.active =>
          t.status == TicketStatus.accepted || t.status == TicketStatus.inProgress,
        _Filter.done => t.status == TicketStatus.completed,
      };
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with WidgetsBindingObserver {
  final _auth = AuthRepository();
  String _token = '';
  List<Ticket> _all = [];
  _Filter _filter = _Filter.active;
  bool _loading = true;

  RealtimeRepository? _realtime;
  StreamSubscription<RealtimeEvent>? _subscription;

  List<Ticket> get _filtered => _all.where((t) => _filter.matches(t)).toList();

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token.isNotEmpty) {
      _load();
    }
  }

  Future<void> _init() async {
    _token = await _auth.getToken() ?? '';
    await _load();
    _realtime = RealtimeRepository(token: _token);
    _subscription = _realtime!.connect().listen((event) {
      if (event.event == 'ticket.status_changed') _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final repo = TicketsRepository(token: _token);
      final tickets = await repo.listMine();
      if (!mounted) return;
      setState(() {
        _all = tickets;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(Ticket ticket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket, token: _token)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus serviços'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(selected: _filter, onSelected: (f) => setState(() => _filter = f)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: cs.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? _EmptyState(filter: _filter)
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

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
  final _Filter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.engineering_outlined, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Nenhum chamado em "${filter.label}"',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Aceite chamados na aba "Pendentes"\npara vê-los aqui.',
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
