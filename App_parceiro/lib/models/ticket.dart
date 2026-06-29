enum TicketStatus { pending, accepted, inProgress, completed, cancelled }

extension TicketStatusX on TicketStatus {
  String get value {
    switch (this) {
      case TicketStatus.pending:
        return 'pending';
      case TicketStatus.accepted:
        return 'accepted';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.completed:
        return 'completed';
      case TicketStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.pending:
        return 'Aguardando aceite';
      case TicketStatus.accepted:
        return 'Aceito';
      case TicketStatus.inProgress:
        return 'Em andamento';
      case TicketStatus.completed:
        return 'Concluído';
      case TicketStatus.cancelled:
        return 'Cancelado';
    }
  }
}

TicketStatus ticketStatusFromString(String? value) {
  switch (value) {
    case 'accepted':
      return TicketStatus.accepted;
    case 'in_progress':
      return TicketStatus.inProgress;
    case 'completed':
      return TicketStatus.completed;
    case 'cancelled':
      return TicketStatus.cancelled;
    default:
      return TicketStatus.pending;
  }
}

class Ticket {
  final String id;
  final String customerId;
  final String? partnerId;
  final String specialty;
  final String title;
  final String? description;
  final TicketStatus status;
  final String? addressText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.customerId,
    this.partnerId,
    required this.specialty,
    required this.title,
    this.description,
    required this.status,
    this.addressText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      partnerId: json['partnerId'] as String?,
      specialty: json['specialty'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ticketStatusFromString(json['status'] as String?),
      addressText: json['addressText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'partner_id': partnerId,
      'specialty': specialty,
      'title': title,
      'description': description,
      'status': status.value,
      'address_text': addressText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Ticket.fromLocalMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      partnerId: map['partner_id'] as String?,
      specialty: map['specialty'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: ticketStatusFromString(map['status'] as String?),
      addressText: map['address_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
