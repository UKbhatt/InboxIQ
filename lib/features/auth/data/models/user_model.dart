import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    required super.createdAt,
  });

  factory UserModel.fromSupabase(supabase.User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

