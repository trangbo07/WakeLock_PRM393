/// Friend-invite payload shared by QR codes and deep links:
/// `wakelock://add?u=<username>`.
String buildInviteLink(String username) => 'wakelock://add?u=$username';

/// Extract a username from a scanned QR value or an opened deep link.
/// Accepts the full URI (`wakelock://add?u=x`, `https://…/add?u=x`) or a bare
/// username. Returns null if nothing usable.
String? parseInviteUsername(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  final u = uri?.queryParameters['u'];
  if (u != null && u.isNotEmpty) return u.toLowerCase();
  // Bare username fallback.
  final lower = value.toLowerCase();
  if (RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(lower)) return lower;
  return null;
}
