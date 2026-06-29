import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/repositories/tickets_repository.dart';
import '../models/ticket.dart';
import '../widgets/status_chip.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final String token;

  const TicketDetailScreen({super.key, required this.ticket, required this.token});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Ticket _ticket;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _accept() async {
    setState(() => _working = true);
    try {
      await TicketsRepository(token: widget.token).accept(_ticket.id);
      if (!mounted) return;
      _showSnack('Chamado aceito! Acompanhe em "Meus serviços".');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        _showSnack(e.toString());
      }
    }
  }

  void _decline() {
    // Recusa é apenas local: o chamado continua na fila para outros parceiros.
    Navigator.pop(context, false);
  }

  Future<void> _startWork() async {
    setState(() => _working = true);
    try {
      await TicketsRepository(token: widget.token).startWork(_ticket.id);
      if (!mounted) return;
      _showSnack('Atendimento iniciado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        _showSnack(e.toString());
      }
    }
  }

  Future<void> _complete() async {
    setState(() => _working = true);
    try {
      await TicketsRepository(token: widget.token).complete(_ticket.id);
      if (!mounted) return;
      _showSnack('Chamado concluído!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        _showSnack(e.toString());
      }
    }
  }

  Widget _buildActions() {
    switch (_ticket.status) {
      case TicketStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _working ? null : _decline,
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                label: const Text('Recusar', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _working ? null : _accept,
                icon: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Aceitar'),
              ),
            ),
          ],
        );
      case TicketStatus.accepted:
        return ElevatedButton.icon(
          onPressed: _working ? null : _startWork,
          icon: _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.engineering_rounded),
          label: const Text('Iniciar atendimento'),
        );
      case TicketStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: _working ? null : _complete,
          icon: _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.task_alt_rounded),
          label: const Text('Concluir atendimento'),
        );
      case TicketStatus.completed:
      case TicketStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final createdAt = fmt.format(_ticket.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do chamado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: StatusChip(status: _ticket.status)),
            const SizedBox(height: 20),
            Text(
              _ticket.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.build_outlined, label: 'Especialidade', value: _ticket.specialty),
                    if (_ticket.addressText != null && _ticket.addressText!.isNotEmpty)
                      _DetailRow(icon: Icons.location_on_outlined, label: 'Endereço', value: _ticket.addressText!),
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Aberto em', value: createdAt),
                  ],
                ),
              ),
            ),
            if (_ticket.description != null && _ticket.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Descrição',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(_ticket.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
            const SizedBox(height: 32),
            _buildActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
