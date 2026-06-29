import 'package:flutter/material.dart';
import '../models/ticket.dart';

class StatusChip extends StatelessWidget {
  final TicketStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TicketStatus.pending => (Colors.amber.shade700, Icons.hourglass_empty_rounded),
      TicketStatus.accepted => (Colors.blue.shade600, Icons.check_circle_outline_rounded),
      TicketStatus.inProgress => (Colors.purple.shade600, Icons.engineering_rounded),
      TicketStatus.completed => (Colors.green.shade600, Icons.task_alt_rounded),
      TicketStatus.cancelled => (Colors.grey.shade500, Icons.cancel_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
