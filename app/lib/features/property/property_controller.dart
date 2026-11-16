import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api.dart';
import '../../data/models.dart';

final propertyProvider = FutureProvider.family<PropertyDetail, String>(
  (ref, id) => ref.watch(apiProvider).property(id),
);
