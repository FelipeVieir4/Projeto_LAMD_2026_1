import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../local/local_database.dart';
import '../remote/api_client.dart';
import '../../models/ticket.dart';

class TicketsRepository {
  final String token;

  TicketsRepository({required this.token});

  Future<List<Ticket>> listLocal() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('tickets', orderBy: 'created_at DESC');
    return rows.map(Ticket.fromLocalMap).toList();
  }

  Future<void> _upsertLocal(Ticket ticket) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      'tickets',
      ticket.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Ticket>> syncAndList() async {
    try {
      final client = ApiClient(token: token);
      final response = await client.get('/tickets') as Map<String, dynamic>;
      final data = response['data'] as List;
      final remoteTickets =
          data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      final remoteIds = remoteTickets.map((t) => t.id).toList();

      final db = await LocalDatabase.instance.database;
      final batch = db.batch();

      // Reconciliação completa: remove do cache local qualquer chamado já
      // sincronizado que não veio mais na resposta do servidor (ex.: excluído
      // diretamente no banco por um admin, fora do fluxo normal do app).
      // Chamados ainda não sincronizados (is_synced = 0) são preservados.
      if (remoteIds.isEmpty) {
        batch.delete('tickets', where: 'is_synced = 1');
      } else {
        final placeholders = remoteIds.map((_) => '?').join(',');
        batch.delete(
          'tickets',
          where: 'is_synced = 1 AND id NOT IN ($placeholders)',
          whereArgs: remoteIds,
        );
      }

      for (final t in remoteTickets) {
        batch.insert(
          'tickets',
          t.toLocalMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // offline — return what's cached
    }
    return listLocal();
  }

  Future<Ticket> createTicket({
    required String customerId,
    required String specialty,
    required String title,
    String? description,
    String? addressText,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final ticket = Ticket(
      id: id,
      customerId: customerId,
      specialty: specialty,
      title: title,
      description: description,
      status: TicketStatus.pending,
      addressText: addressText,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await _upsertLocal(ticket);

    try {
      final client = ApiClient(token: token);
      await client.post('/tickets', {
        'ticketId': id,
        'specialty': specialty,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (addressText != null && addressText.isNotEmpty)
          'addressText': addressText,
      });
      final synced = ticket.copyWith(isSynced: true);
      await _upsertLocal(synced);
      return synced;
    } catch (_) {
      return ticket;
    }
  }

  Future<void> cancelTicket(String ticketId) async {
    final client = ApiClient(token: token);
    await client.patch('/tickets/$ticketId/status', {'status': 'cancelled'});
    final db = await LocalDatabase.instance.database;
    await db.update(
      'tickets',
      {
        'status': 'cancelled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  Future<void> syncPending() async {
    final db = await LocalDatabase.instance.database;
    final pending = await db.query('tickets', where: 'is_synced = 0');
    if (pending.isEmpty) return;

    final client = ApiClient(token: token);
    for (final row in pending) {
      try {
        await client.post('/tickets', {
          'ticketId': row['id'],
          'specialty': row['specialty'],
          'title': row['title'],
          if (row['description'] != null) 'description': row['description'],
          if (row['address_text'] != null) 'addressText': row['address_text'],
        });
        await db.update(
          'tickets',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (_) {
        // leave unsynced
      }
    }
  }
}
