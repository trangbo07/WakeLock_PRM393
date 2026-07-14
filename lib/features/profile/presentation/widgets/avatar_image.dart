import 'dart:convert';

import 'package:flutter/widgets.dart';

/// Resolve an avatar [ImageProvider]: prefer an inline base64 image (stored in
/// Firestore to avoid paid Cloud Storage), then a remote URL, else null (the
/// caller shows initials).
ImageProvider? avatarImageProvider({String? base64Data, String? url}) {
  if (base64Data != null && base64Data.isNotEmpty) {
    try {
      return MemoryImage(base64Decode(base64Data));
    } catch (_) {/* corrupt data → fall through */}
  }
  if (url != null && url.isNotEmpty) return NetworkImage(url);
  return null;
}
