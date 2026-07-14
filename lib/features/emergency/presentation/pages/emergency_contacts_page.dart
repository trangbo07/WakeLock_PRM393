import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
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
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.contact_emergency_outlined,
                          size: 64, color: AppColors.destructive),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Chưa có liên hệ khẩn cấp',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Thêm người thân để gọi/nhắn tin khi cần trợ giúp lúc báo thức reo.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: contacts.length,
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.destructive.withValues(alpha: 0.18),
                          child: Text(
                            c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.destructive,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(c.phone,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.destructive),
                          onPressed: () async {
                            await ref
                                .read(emergencyContactRepositoryProvider)
                                .deleteContact(c.id);
                            ref.invalidate(emergencyContactListProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _addFromContacts(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm liên hệ'),
      ),
    );
  }
}
