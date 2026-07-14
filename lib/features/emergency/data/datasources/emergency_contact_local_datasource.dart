import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/emergency_contact.dart';

class EmergencyContactLocalDataSource {
  EmergencyContactLocalDataSource(this._db);

  final AppDatabase _db;

  static const _table = AppConstants.emergencyContactsTable;

  Future<List<EmergencyContact>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> insert(EmergencyContact contact) async {
    final db = await _db.database;
    await db.insert(_table, {
      'id': contact.id,
      'name': contact.name,
      'phone': contact.phone,
      'created_at': contact.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  EmergencyContact _fromRow(Map<String, Object?> row) => EmergencyContact(
        id: row['id'] as String,
        name: row['name'] as String,
        phone: row['phone'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );
}
