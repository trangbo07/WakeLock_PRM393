import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/emergency_contact.dart';
import '../providers/emergency_providers.dart';

/// Manage the global SOS contact list. Adding goes through the system's
/// external contact picker (`openExternalPick`), which needs no READ_CONTACTS
/// permission — only the chosen contact's name/phone are snapshotted locally.
class EmergencyContactsPage extends ConsumerWidget {
  const EmergencyContactsPage({super.key});

  Future<void> _addFromContacts(BuildContext context, WidgetRef ref) async {
    try {
      // openExternalPick() itself needs no permission, but resolving the
      // contact it returns (name/phone) queries the Contacts provider
      // directly, which does require this — request it upfront so that
      // query doesn't fail once a contact is chosen.
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền truy cập danh bạ để thêm liên hệ')),
          );
        }
        return;
      }
      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;
      final phones = picked.phones;
      if (phones.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Liên hệ này không có số điện thoại')),
          );
        }
        return;
      }
      final contact = EmergencyContact(
        id: const Uuid().v4(),
        name: picked.displayName,
        phone: phones.first.number,
        createdAt: DateTime.now(),
      );
      await ref.read(emergencyContactRepositoryProvider).addContact(contact);
      ref.invalidate(emergencyContactListProvider);
    } catch (e) {
      AppLogger.w('Pick emergency contact failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ khẩn cấp')),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (contacts) => contacts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Chưa có liên hệ khẩn cấp nào.\nThêm người thân để có thể gọi/nhắn tin khi cần trợ giúp lúc báo thức reo.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(emergencyContactRepositoryProvider).deleteContact(c.id);
                          ref.invalidate(emergencyContactListProvider);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFromContacts(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
