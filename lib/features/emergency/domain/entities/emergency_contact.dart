import 'package:equatable/equatable.dart';

/// A saved SOS contact — a name+phone snapshot taken from the device contact
/// book at add-time (not re-synced), used to reach out for help from the
/// alarm-ringing screen.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, phone, createdAt];
}
