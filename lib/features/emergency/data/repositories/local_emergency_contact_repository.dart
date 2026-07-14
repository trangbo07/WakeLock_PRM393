import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../datasources/emergency_contact_local_datasource.dart';

class LocalEmergencyContactRepository implements EmergencyContactRepository {
  LocalEmergencyContactRepository(this._ds);

  final EmergencyContactLocalDataSource _ds;

  @override
  Future<List<EmergencyContact>> getContacts() => _ds.fetchAll();

  @override
  Future<void> addContact(EmergencyContact contact) => _ds.insert(contact);

  @override
  Future<void> deleteContact(String id) => _ds.delete(id);
}
