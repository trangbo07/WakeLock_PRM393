import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/emergency_contact.dart';
import '../providers/emergency_providers.dart';
import 'emergency_contacts_page.dart';

const _sosMessage = 'Mình cần trợ giúp, không dậy nổi khi báo thức reo!';

/// Pushed from the "Cần trợ giúp" button on the ringing screen. Lists saved
/// SOS contacts with quick "Nhắn tin"/"Gọi" actions — both open the system
/// SMS/dialer app pre-filled via `url_launcher` (no SEND_SMS/CALL_PHONE
/// permission; the user still has to tap send/call themselves). Does NOT
/// touch the alarm's ringing state — backing out returns to the still-ringing
/// screen underneath.
class EmergencySosPage extends ConsumerWidget {
  const EmergencySosPage({super.key});

  Future<void> _message(BuildContext context, EmergencyContact c) async {
    final uri = Uri(scheme: 'sms', path: c.phone, queryParameters: {'body': _sosMessage});
    await _launch(context, uri);
  }

  Future<void> _call(BuildContext context, EmergencyContact c) async {
    final uri = Uri(scheme: 'tel', path: c.phone);
    await _launch(context, uri);
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không mở được ứng dụng')));
      }
    } catch (e) {
      AppLogger.w('Launch $uri failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cần trợ giúp')),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (contacts) => contacts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chưa có liên hệ khẩn cấp nào.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmergencyContactsPage()),
                        ),
                        child: const Text('Thêm liên hệ'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: contacts.length,
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sms),
                            tooltip: 'Nhắn tin',
                            onPressed: () => _message(context, c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call),
                            tooltip: 'Gọi',
                            onPressed: () => _call(context, c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
