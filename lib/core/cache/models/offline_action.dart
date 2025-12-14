import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class OfflineAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String emailId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final Map<String, dynamic>? data; 

  OfflineAction({
    required this.id,
    required this.type,
    required this.emailId,
    required this.createdAt,
    this.data,
  });

  factory OfflineAction.markRead(String emailId) {
    return OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'MARK_READ',
      emailId: emailId,
      createdAt: DateTime.now(),
    );
  }

  factory OfflineAction.star(String emailId) {
    return OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'STAR',
      emailId: emailId,
      createdAt: DateTime.now(),
    );
  }

  factory OfflineAction.unstar(String emailId) {
    return OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'UNSTAR',
      emailId: emailId,
      createdAt: DateTime.now(),
    );
  }
}
