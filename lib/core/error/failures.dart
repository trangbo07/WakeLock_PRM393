/// Base type for domain-level failures surfaced to the UI.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// Local SQLite read/write failed.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// A required Android permission was not granted (overlay, exact alarm, etc.).
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
