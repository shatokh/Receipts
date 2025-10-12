import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/data/database_update_bus.dart';

final databaseUpdateBusProvider = Provider<DatabaseUpdateBus>((ref) {
  final bus = DatabaseUpdateBus();
  ref.onDispose(bus.dispose);
  return bus;
});
