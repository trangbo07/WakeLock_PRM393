/// Base type for domain-level failures surfaced to the UI.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// Network / Supabase request failed.
class RemoteFailure extends Failure {
  const RemoteFailure(super.message);
}

/// Local cache / storage failed.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// A required Android permission was not granted (overlay, exact alarm, etc.).
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
