// AlarmEditPage form flow against a fake repository (no SQLite, no platform
// channels — exact-alarm permission is auto-granted off Android).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/alarm.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/repositories/alarm_repository.dart';
import 'package:wakelock_prm393/features/alarm_management/presentation/pages/alarm_edit_page.dart';
import 'package:wakelock_prm393/features/alarm_management/presentation/providers/alarm_providers.dart';

class _FakeAlarmRepository implements AlarmRepository {
  final upserted = <Alarm>[];
  final deleted = <String>[];

  @override
  Future<List<Alarm>> getAlarms() async => upserted;

  @override
  Future<Alarm?> getAlarmById(String id) async => null;

  @override
  Future<void> upsertAlarm(Alarm alarm) async => upserted.add(alarm);

  @override
  Future<void> deleteAlarm(String id) async => deleted.add(id);

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {}

  @override
  Future<void> rescheduleAllEnabled() async {}
}

void main() {
  late _FakeAlarmRepository fakeRepo;

  // Answer the system-ringtone channel so _save()'s default-uri lookup resolves
  // promptly instead of hanging on a missing plugin.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('wakelock/ringtones'),
      (call) async => call.method == 'list' ? <Map<String, String>>[] : '',
    );
  });

  Future<void> pumpEditPage(WidgetTester tester, {Alarm? existing}) async {
    // Tall logical viewport so the whole form (incl. save button) is on screen.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    fakeRepo = _FakeAlarmRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => AlarmEditPage(existing: existing),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('saving a new alarm hands it to the repository', (tester) async {
    await pumpEditPage(tester);

    expect(find.text('Báo thức mới'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Tập gym');
    await tester.ensureVisible(find.text('Lưu báo thức'));
    await tester.tap(find.text('Lưu báo thức'));
    await tester.pumpAndSettle();

    expect(fakeRepo.upserted, hasLength(1));
    expect(fakeRepo.upserted.single.label, 'Tập gym');
    expect(fakeRepo.upserted.single.id, isNotEmpty);
    // Page popped back to the host screen after saving.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('editing an existing alarm allows confirmed deletion',
      (tester) async {
    const existing = Alarm(id: 'alarm-7', label: 'Ngủ trưa', hour: 13, minute: 0);
    await pumpEditPage(tester, existing: existing);

    expect(find.text('Sửa báo thức'), findsOneWidget);
    expect(find.text('Ngủ trưa'), findsOneWidget); // label prefilled

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Xóa báo thức?'), findsOneWidget);

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();

    expect(fakeRepo.deleted, ['alarm-7']);
    expect(fakeRepo.upserted, isEmpty);
  });
}
