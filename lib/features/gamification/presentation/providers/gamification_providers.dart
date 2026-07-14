import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gamification_firestore_datasource.dart';

/// Coin/XP mutations for the shop and daily missions. Gamification READ state
/// comes from [myProfileProvider] (the users doc), so no extra read provider.
final gamificationDataSourceProvider = Provider<GamificationFirestoreDataSource>(
  (ref) => GamificationFirestoreDataSource(),
);
