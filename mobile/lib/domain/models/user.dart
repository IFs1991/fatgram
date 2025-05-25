/// ユーザーモデル
class User {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final String? subscriptionTier;
  final UserGoals? goals;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.createdAt,
    this.subscriptionTier = 'free',
    this.goals,
  });

  /// JSONからUserを作成
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? json['profileImageUrl'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      subscriptionTier: json['subscription_tier'] as String? ?? json['subscriptionTier'] as String? ?? 'free',
      goals: json['goals'] != null ? UserGoals.fromJson(json['goals'] as Map<String, dynamic>) : null,
    );
  }

  /// UserをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'subscriptionTier': subscriptionTier,
      'goals': goals?.toJson(),
    };
  }
}

/// ユーザー目標モデル
class UserGoals {
  final double? dailyFatBurn;
  final int? weeklyActivityMinutes;
  final int? weeklyActivityGoal;
  final int? dailyCalorieGoal;
  final double? targetWeight;

  UserGoals({
    this.dailyFatBurn,
    this.weeklyActivityMinutes,
    this.weeklyActivityGoal,
    this.dailyCalorieGoal,
    this.targetWeight,
  });

  /// JSONからUserGoalsを作成
  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      dailyFatBurn: json['daily_fat_burn'] as double? ?? json['dailyFatBurn'] as double?,
      weeklyActivityMinutes: json['weekly_activity_minutes'] as int? ?? json['weeklyActivityMinutes'] as int?,
      weeklyActivityGoal: json['weekly_activity_goal'] as int? ?? json['weeklyActivityGoal'] as int?,
      dailyCalorieGoal: json['daily_calorie_goal'] as int? ?? json['dailyCalorieGoal'] as int?,
      targetWeight: json['target_weight'] as double? ?? json['targetWeight'] as double?,
    );
  }

  /// UserGoalsをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'dailyFatBurn': dailyFatBurn,
      'weeklyActivityMinutes': weeklyActivityMinutes,
      'weeklyActivityGoal': weeklyActivityGoal,
      'dailyCalorieGoal': dailyCalorieGoal,
      'targetWeight': targetWeight,
    };
  }
}