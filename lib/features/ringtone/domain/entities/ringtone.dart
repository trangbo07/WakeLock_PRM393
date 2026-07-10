import 'package:equatable/equatable.dart';

/// A selectable alarm sound.
///
/// [highFrequency] flags the "khủng bố" tones (piercing, hard to sleep through)
/// used by the terror-ringtone library.
class Ringtone extends Equatable {
  const Ringtone({
    required this.id,
    required this.name,
    required this.assetPath,
    this.highFrequency = false,
  });

  final String id;
  final String name;
  final String assetPath;
  final bool highFrequency;

  @override
  List<Object?> get props => [id, name, assetPath, highFrequency];
}
