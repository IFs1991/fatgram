import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final int? height; // in cm
  final int? weight; // in kg
  final int? age;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    String? id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.height,
    this.weight,
    this.age,
    this.isPremium = false,
    DateTime? createdAt,
    this.lastLoginAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Create a user from Firebase Auth
  factory User.fromFirebase(Map<String, dynamic> data) {
    return User(
      id: data['uid'] ?? const Uuid().v4(),
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoURL'],
      isPremium: data['isPremium'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'height': height,
      'weight': weight,
      'age': age,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  // Copy with
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? height,
    int? weight,
    int? age,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}