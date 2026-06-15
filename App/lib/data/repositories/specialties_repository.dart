import 'package:sqflite/sqflite.dart';
import '../local/local_database.dart';
import '../remote/api_client.dart';
import '../../models/specialty.dart';

class SpecialtiesRepository {
  final String? token;

  SpecialtiesRepository({this.token});

  Future<List<Specialty>> list() async {
    try {
      final client = ApiClient(token: token);
      final response = await client.get('/specialties') as Map<String, dynamic>;
      final data = response['specialties'] as List;
      final specialties = data
          .map((e) => Specialty.fromJson(e as Map<String, dynamic>))
          .toList();
      await _cacheSpecialties(specialties);
      return specialties;
    } catch (_) {
      return _listCached();
    }
  }

  Future<void> _cacheSpecialties(List<Specialty> specialties) async {
    final db = await LocalDatabase.instance.database;
    final batch = db.batch();
    batch.delete('specialties');
    for (final s in specialties) {
      batch.insert('specialties', s.toLocalMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Specialty>> _listCached() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('specialties', orderBy: 'name ASC');
    return rows.map(Specialty.fromLocalMap).toList();
  }
}
