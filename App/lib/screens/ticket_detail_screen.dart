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
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  bool get _cancellable =>
      _ticket.status == TicketStatus.pending || _ticket.status == TicketStatus.accepted;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar chamado'),
        content: const Text('Tem certeza que deseja cancelar este chamado? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await TicketsRepository(token: widget.token).cancelTicket(_ticket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado cancelado.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final createdAt = fmt.format(_ticket.createdAt.toLocal());
    final updatedAt = fmt.format(_ticket.updatedAt.toLocal());

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
                    _DetailRow(
                      icon: Icons.build_outlined,
                      label: 'Especialidade',
                      value: _ticket.specialty,
                    ),
                    if (_ticket.addressText != null && _ticket.addressText!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Endereço',
                        value: _ticket.addressText!,
                      ),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Aberto em',
                      value: createdAt,
                    ),
                    _DetailRow(
                      icon: Icons.update_outlined,
                      label: 'Atualizado',
                      value: updatedAt,
                    ),
                    if (_ticket.partnerId != null)
                      const _DetailRow(
                        icon: Icons.engineering_rounded,
                        label: 'Parceiro',
                        value: 'Designado',
                      ),
                  ],
                ),
              ),
            ),
            if (_ticket.description != null && _ticket.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(_ticket.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
            if (_cancellable) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.cancel_outlined, color: Colors.red),
                label: Text(
                  _cancelling ? 'Cancelando...' : 'Cancelar chamado',
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
