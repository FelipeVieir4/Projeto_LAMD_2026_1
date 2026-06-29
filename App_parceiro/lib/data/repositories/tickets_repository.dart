import 'package:sqflite/sqflite.dart';
import '../local/local_database.dart';
import '../remote/api_client.dart';
import '../../models/ticket.dart';

class TicketsRepository {
  final String token;

  TicketsRepository({required this.token});

  Future<void> _cacheTickets(List<Ticket> tickets, {required String scope}) async {
    final db = await LocalDatabase.instance.database;
    final batch = db.batch();
    batch.delete('tickets', where: 'status = ?', whereArgs: [scope]);
    for (final t in tickets) {
      batch.insert('tickets', t.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Ticket>> _listCached({required List<String> statuses}) async {
    final db = await LocalDatabase.instance.database;
    final placeholders = statuses.map((_) => '?').join(',');
    final rows = await db.query(
      'tickets',
      where: 'status IN ($placeholders)',
      whereArgs: statuses,
      orderBy: 'created_at ASC',
    );
    return rows.map(Ticket.fromLocalMap).toList();
  }

  /// Chamados pendentes (pool compartilhado entre todos os parceiros).
  Future<List<Ticket>> listPending() async {
    try {
      final client = ApiClient(token: token);
      final response = await client.get('/tickets?pending=true') as Map<String, dynamic>;
      final data = response['data'] as List;
      final tickets = data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      await _cacheTickets(tickets, scope: 'pending');
      return tickets;
    } catch (_) {
      return _listCached(statuses: const ['pending']);
    }
  }

  /// Chamados assumidos por este parceiro (aceitos, em andamento ou concluídos).
  Future<List<Ticket>> listMine() async {
    try {
      final client = ApiClient(token: token);
      final response = await client.get('/tickets') as Map<String, dynamic>;
      final data = response['data'] as List;
      final tickets = data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      final db = await LocalDatabase.instance.database;
      final batch = db.batch();
      batch.delete(
        'tickets',
        where: 'status IN (?, ?, ?)',
        whereArgs: ['accepted', 'in_progress', 'completed'],
      );
      for (final t in tickets) {
        batch.insert('tickets', t.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      return tickets;
    } catch (_) {
      return _listCached(statuses: const ['accepted', 'in_progress', 'completed']);
    }
  }

  Future<Ticket> updateStatus(String ticketId, TicketStatus status) async {
    final client = ApiClient(token: token);
    await client.patch('/tickets/$ticketId/status', {'status': status.value});
    final db = await LocalDatabase.instance.database;
    await db.update(
      'tickets',
      {'status': status.value, 'updated_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [ticketId],
    );
    final rows = await db.query('tickets', where: 'id = ?', whereArgs: [ticketId]);
    return Ticket.fromLocalMap(rows.first);
  }

  Future<Ticket> accept(String ticketId) => updateStatus(ticketId, TicketStatus.accepted);
  Future<Ticket> startWork(String ticketId) => updateStatus(ticketId, TicketStatus.inProgress);
  Future<Ticket> complete(String ticketId) => updateStatus(ticketId, TicketStatus.completed);
}
