import 'package:equatable/equatable.dart';

/// A friend wake-up challenge (`challenges/{id}`). Participants race to log the
/// most successful wake-ups before [endAt].
class Challenge extends Equatable {
  const Challenge({
    required this.id,
    this.title = '',
    this.days = 7,
    this.createdBy = '',
    this.startAt,
    this.endAt,
    this.participantUids = const [],
  });

  final String id;
  final String title;

  /// Duration in days (7 / 14 / 30).
  final int days;
  final String createdBy;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Denormalized member list so "my challenges" is one arrayContains query.
  final List<String> participantUids;

  bool get isActive => endAt == null || DateTime.now().isBefore(endAt!);

  /// Whole days remaining (0 once ended).
  int get daysLeft {
    if (endAt == null) return days;
    final diff = endAt!.difference(DateTime.now()).inHours / 24;
    return diff <= 0 ? 0 : diff.ceil();
  }

  int get participantCount => participantUids.length;

  @override
  List<Object?> get props =>
      [id, title, days, createdBy, startAt, endAt, participantUids];
}

/// One member of a challenge (`challenges/{id}/participants/{uid}`).
class ChallengeParticipant extends Equatable {
  const ChallengeParticipant({
    required this.uid,
    this.name = '',
    this.username = '',
    this.avatarUrl,
    this.avatarBase64,
    this.score = 0,
    this.lastCheckIn,
  });

  final String uid;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? avatarBase64;

  /// Successful wake-ups logged in this challenge.
  final int score;
  final DateTime? lastCheckIn;

  /// Whether this member already checked in on [day] (defaults to today).
  bool checkedInOn([DateTime? day]) {
    if (lastCheckIn == null) return false;
    final d = day ?? DateTime.now();
    return lastCheckIn!.year == d.year &&
        lastCheckIn!.month == d.month &&
        lastCheckIn!.day == d.day;
  }

  @override
  List<Object?> get props =>
      [uid, name, username, avatarUrl, avatarBase64, score, lastCheckIn];
}
