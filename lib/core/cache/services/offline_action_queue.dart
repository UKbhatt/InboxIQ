import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_action.dart';

class OfflineActionQueue {
  static const String _actionBoxName = 'offline_actions';
  static Box<OfflineAction>? _actionBox;

  static Future<void> init() async {
    _actionBox = await Hive.openBox<OfflineAction>(_actionBoxName);
  }

  static Box<OfflineAction> get actionBox {
    if (_actionBox == null) {
      throw Exception('OfflineActionQueue not initialized. Call init() first.');
    }
    return _actionBox!;
  }

  static Future<void> addAction(OfflineAction action) async {
    await actionBox.put(action.id, action);
  }

  static List<OfflineAction> getPendingActions() {
    return actionBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> removeAction(String actionId) async {
    await actionBox.delete(actionId);
  }

  static Future<void> clearAll() async {
    await actionBox.clear();
  }

  static int getPendingCount() {
    return actionBox.length;
  }
}

