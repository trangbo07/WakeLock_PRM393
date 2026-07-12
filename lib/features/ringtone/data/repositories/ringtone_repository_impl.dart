import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/platform/system_ringtone_channel.dart';
import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';
import '../datasources/custom_ringtone_datasource.dart';

/// Merges the device's real system alarm sounds (native channel) with the
/// user's own added audio files (SQLite + copied files in app storage).
class RingtoneRepositoryImpl implements RingtoneRepository {
  RingtoneRepositoryImpl(this._channel, this._customDs);

  final SystemRingtoneChannel _channel;
  final CustomRingtoneDataSource _customDs;

  static const Ringtone _fallback =
      Ringtone(uri: 'default', name: 'Mặc định hệ thống');

  Future<List<Ringtone>> _systemList() async {
    try {
      final list = await _channel.list();
      return list.isEmpty ? const [_fallback] : list;
    } catch (_) {
      return const [_fallback];
    }
  }

  @override
  Future<List<Ringtone>> getRingtones() async {
    final custom = await _customDs.fetchAll();
    final system = await _systemList();
    // Custom ringtones first so the user's own picks are easy to reach.
    return [...custom, ...system];
  }

  @override
  Future<Ringtone?> getByUri(String uri) async {
    for (final r in await getRingtones()) {
      if (r.uri == uri) return r;
    }
    return null;
  }

  @override
  Future<Ringtone> addCustom(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'ringtones'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Copy into permanent app storage so it survives reboots / cache clears.
    final dest = p.join(dir.path, '${const Uuid().v4()}${p.extension(sourcePath)}');
    await File(sourcePath).copy(dest);

    final ringtone = Ringtone(
      uri: dest,
      name: p.basenameWithoutExtension(sourcePath),
      isCustom: true,
    );
    await _customDs.insert(ringtone);
    return ringtone;
  }

  @override
  Future<void> removeCustom(String uri) async {
    await _customDs.delete(uri);
    try {
      final file = File(uri);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // File already gone — the DB row removal is what matters.
    }
  }
}
