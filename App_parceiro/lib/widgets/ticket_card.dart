import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/ticket.dart';
import 'status_chip.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  Color get _specialtyColor {
    final name = ticket.specialty.toLowerCase();
    if (name.contains('elétri') || name.contains('eletri')) return Colors.blue.shade700;
    if (name.contains('hidráuli') || name.contains('hidrauli')) return Colors.cyan.shade700;
    if (name.contains('pintura')) return Colors.orange.shade700;
    if (name.contains('marcenaria') || name.contains('carpint')) return Colors.brown.shade600;
    if (name.contains('refriger') || name.contains('ar-cond')) return Colors.teal.shade600;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yy 'às' HH:mm").format(ticket.createdAt.toLocal());
    final specialtyColor = _specialtyColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: specialtyColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.specialty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: specialtyColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              if (ticket.addressText != null && ticket.addressText!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.addressText!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
