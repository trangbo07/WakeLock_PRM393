import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/feed_firestore_datasource.dart';
import '../../data/repositories/firestore_feed_repository.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';

final feedDataSourceProvider = Provider<FeedFirestoreDataSource>(
  (ref) => FeedFirestoreDataSource(),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FirestoreFeedRepository(ref.watch(feedDataSourceProvider)),
);

/// The morning-photo feed (newest first). Same stream for guests and signed-in
/// users; per-user reaction state is resolved lazily in the post detail.
final feedProvider = StreamProvider<List<Post>>(
  (ref) => ref.watch(feedRepositoryProvider).watchFeed(),
);

/// Comments on a post, oldest first.
final commentsProvider = StreamProvider.family<List<Comment>, String>(
  (ref, postId) => ref.watch(feedRepositoryProvider).watchComments(postId),
);

/// Everyone who reacted to a post (for the reaction picker sheet).
final reactorsProvider = StreamProvider.family<List<Reactor>, String>(
  (ref, postId) => ref.watch(feedRepositoryProvider).watchReactors(postId),
);
