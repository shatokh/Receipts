import 'dart:async';

import 'package:receipts/data/database_update_bus.dart';

Stream<T> watchDatabase<T>({
  required DatabaseUpdateBus updateBus,
  required Future<T> Function() loader,
}) {
  return Stream.multi((controller) async {
    Future<void> emit() async {
      try {
        final data = await loader();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    await emit();
    final sub = updateBus.stream.listen((_) => emit());
    controller.onCancel = sub.cancel;
  });
}
