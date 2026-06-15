import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/tickets_repository.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import 'create_ticket_screen.dart';
import 'login_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with WidgetsBindingObserver {
  final _auth = AuthRepository();
  List<Ticket> _tickets = [];
  bool _loading = true;
  bool _hasUnsynced = false;
  bool _isSyncing = false;
  bool _loadingInProgress = false;
  String _userName = '';
  String _userId = '';
  String _token = '';

  Timer? _syncTimer;
  static const int _maxSyncAttempts = 10;

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

  // Reinicia polling quando o app volta ao foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token.isNotEmpty) {
      _loadTickets();
    }
  }

  // Inicia polling — idempotente: ignora se já está rodando
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
    _userName = await _auth.getSavedUserName() ?? 'Usuário';
    _userId = await _auth.getSavedUserId() ?? '';
    await _loadTickets();
  }

  // Carrega tickets e auto-inicia polling se houver pendentes sem timer ativo
  Future<void> _loadTickets() async {
    if (!mounted || _loadingInProgress) return;
    _loadingInProgress = true;
    if (_tickets.isEmpty) setState(() => _loading = true);
    try {
      final repo = TicketsRepository(token: _token);
      await repo.syncPending();
      final tickets = await repo.syncAndList();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _hasUnsynced = tickets.any((t) => !t.isSynced);
        _loading = false;
      });
      if (_hasUnsynced && _syncTimer == null) _startSyncPolling();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(token: _token, userId: _userId),
      ),
    );
    // _loadTickets já vai disparar o polling automaticamente se houver pendentes
    if (created == true) _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Chamados'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _UserHeader(name: _userName),
          if (_isSyncing) const _SyncingBanner(),
          if (!_isSyncing && _hasUnsynced) _OfflineBanner(onRetry: _loadTickets),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              color: cs.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tickets.isEmpty
                      ? _EmptyState(onAdd: _openCreate)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _tickets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => TicketCard(ticket: _tickets[i]),
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
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String name;
  const _UserHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withAlpha(40),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $name!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Acompanhe seus chamados abaixo',
                style: TextStyle(
                  color: Colors.white.withAlpha(190),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.amber.shade800),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum chamado ainda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão abaixo para abrir\nseu primeiro chamado técnico.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Abrir chamado'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
