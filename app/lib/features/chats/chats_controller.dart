import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/api.dart';
import '../../data/models.dart';

final chatsProvider = FutureProvider<List<Conversation>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(apiProvider).conversations();
});

final conversationProvider = FutureProvider.family<Conversation, String>(
  (ref, id) => ref.watch(apiProvider).conversation(id),
);

final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, id) async {
    final messages = await ref.watch(apiProvider).messages(id);
    return messages.reversed.toList();
  },
);
