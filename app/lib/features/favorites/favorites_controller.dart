import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/api.dart';
import '../../data/models.dart';

final favoritesProvider = FutureProvider<List<PropertySummary>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(apiProvider).favorites();
});
