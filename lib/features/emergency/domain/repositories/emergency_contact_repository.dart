import '../entities/emergency_contact.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> getContacts();
  Future<void> addContact(EmergencyContact contact);
  Future<void> deleteContact(String id);
}
