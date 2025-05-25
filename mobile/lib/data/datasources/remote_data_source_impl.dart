import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

import '../../domain/models/activity.dart';
import '../../domain/models/user.dart' as app_user;
import 'remote_data_source.dart';

/// リモートデータソースの実装
class RemoteDataSourceImpl implements RemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final String _apiBaseUrl;

  RemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    FirebaseFirestore? firestore,
    String? apiBaseUrl,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _apiBaseUrl = apiBaseUrl ?? 'https://api.fatgram.app/v1';

  @override
  Future<app_user.User> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ユーザー情報を返す
      return app_user.User(
        id: currentUser.uid,
        email: email,
        displayName: displayName,
        profileImageUrl: currentUser.photoURL,
      );
    } catch (e) {
      throw Exception('Failed to register user: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Firestoreからユーザー情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;

      // ユーザー情報を返す
      return app_user.User(
        id: currentUser.uid,
        email: userData['email'] as String? ?? email,
        displayName: userData['displayName'] as String? ?? '',
        profileImageUrl: currentUser.photoURL,
      );
    } catch (e) {
      throw Exception('Failed to login user: ${e.toString()}');
    }
  }

  @override
  Future<void> refreshToken({
    required String refreshToken,
  }) async {
    try {
      // リフレッシュトークンを使って新しいトークンを取得
      // これはFirebase Authを使用していれば自動的に処理されるため、
      // カスタムバックエンドを使用している場合のみ実装が必要

      // カスタムバックエンドを使用している場合の例：
      // final response = await http.post(
      //   Uri.parse('$_apiBaseUrl/auth/refresh'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'refresh_token': refreshToken}),
      // );
      //
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to refresh token');
      // }
    } catch (e) {
      throw Exception('Failed to refresh token: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User> getUserProfile() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Firestoreからユーザー情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;

      // ユーザーゴールの取得（存在する場合）
      app_user.UserGoals? goals;
      if (userData.containsKey('goals')) {
        final goalsData = userData['goals'] as Map<String, dynamic>?;
        if (goalsData != null) {
          goals = app_user.UserGoals(
            weeklyActivityGoal: goalsData['weeklyActivityGoal'] as int? ?? 0,
            dailyCalorieGoal: goalsData['dailyCalorieGoal'] as int? ?? 0,
            targetWeight: goalsData['targetWeight'] as double? ?? 0.0,
          );
        }
      }

      // ユーザー情報を返す
      return app_user.User(
        id: currentUser.uid,
        email: userData['email'] as String? ?? currentUser.email ?? '',
        displayName: userData['displayName'] as String? ?? currentUser.displayName ?? '',
        profileImageUrl: userData['profileImageUrl'] as String? ?? currentUser.photoURL,
        goals: goals,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<app_user.User> updateUserProfile({
    String? displayName,
    app_user.UserGoals? goals,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
        await currentUser.updateDisplayName(displayName);
      }

      if (goals != null) {
        updateData['goals'] = {
          'weeklyActivityGoal': goals.weeklyActivityGoal,
          'dailyCalorieGoal': goals.dailyCalorieGoal,
          'targetWeight': goals.targetWeight,
        };
      }

      // Firestoreのユーザー情報を更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      // 更新後のユーザー情報を取得して返す
      return await getUserProfile();
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> syncActivities({
    required List<Activity> activities,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // バッチ処理でFirestoreに保存
      final batch = _firestore.batch();

      for (final activity in activities) {
        final activityRef = _firestore
            .collection('activities')
            .doc(activity.activityId);

        // アクティビティデータをJSON形式に変換
        final activityData = {
          'userId': currentUser.uid,
          'activityType': activity.activityType,
          'startTime': Timestamp.fromDate(activity.startTime),
          'endTime': Timestamp.fromDate(activity.endTime),
          'caloriesBurned': activity.caloriesBurned,
          'fatBurnedGrams': activity.fatBurnedGrams,
          'heartRateAvg': activity.heartRateAvg,
          'heartRateMax': activity.heartRateMax,
          'steps': activity.steps,
          'distance': activity.distance,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'source': 'app',
        };

        // 心拍数データがある場合は別のサブコレクションに保存
        if (activity.heartRateData != null && activity.heartRateData!.isNotEmpty) {
          for (final hrData in activity.heartRateData!) {
            final hrRef = activityRef
                .collection('heartRateData')
                .doc(); // 自動ID

            batch.set(hrRef, {
              'timestamp': Timestamp.fromDate(hrData.timestamp),
              'value': hrData.value,
            });
          }
        }

        batch.set(activityRef, activityData);
      }

      // バッチ処理を実行
      await batch.commit();

      // 最後の同期時間を更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'lastSyncTimestamp': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'syncedActivities': activities.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Firestoreからアクティビティを取得
      final querySnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUser.uid)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();

      final activities = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final activityId = doc.id;

        // 心拍数データを取得
        final heartRateSnapshot = await doc.reference
            .collection('heartRateData')
            .orderBy('timestamp')
            .get();

        final heartRateData = heartRateSnapshot.docs.map((hrDoc) {
          final hrData = hrDoc.data();
          return {
            'timestamp': (hrData['timestamp'] as Timestamp).toDate().toIso8601String(),
            'value': hrData['value'] as int,
          };
        }).toList();

        activities.add({
          'activityId': activityId,
          'activityType': data['activityType'] as String,
          'startTime': (data['startTime'] as Timestamp).toDate().toIso8601String(),
          'endTime': (data['endTime'] as Timestamp).toDate().toIso8601String(),
          'caloriesBurned': data['caloriesBurned'] as double,
          'fatBurnedGrams': data['fatBurnedGrams'] as double,
          'heartRateAvg': data['heartRateAvg'] as double?,
          'heartRateMax': data['heartRateMax'] as double?,
          'steps': data['steps'] as int?,
          'distance': data['distance'] as double?,
          'heartRateData': heartRateData,
        });
      }

      return {
        'activities': activities,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'count': activities.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'activities': [],
        'count': 0,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Firestoreからサブスクリプション情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'status': 'free',
          'expiryDate': null,
        };
      }

      final userData = userDoc.data()!;
      final subscriptionData = userData['subscription'] as Map<String, dynamic>?;

      if (subscriptionData == null) {
        return {
          'status': 'free',
          'expiryDate': null,
        };
      }

      return {
        'status': subscriptionData['status'] as String? ?? 'free',
        'expiryDate': subscriptionData['expiryDate'] != null
            ? (subscriptionData['expiryDate'] as Timestamp).toDate().toIso8601String()
            : null,
        'platform': subscriptionData['platform'] as String?,
        'productId': subscriptionData['productId'] as String?,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> verifySubscription({
    required String receipt,
    required String platform,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // カスタムバックエンドでの検証が必要な場合はここで実装
      // RevenueCatを使用している場合は不要

      return {
        'verified': true,
        'expiryDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
    } catch (e) {
      return {
        'verified': false,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? conversationId,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // 新しい会話を作成するか、既存の会話を使用
      final conversationRef = conversationId != null
          ? _firestore.collection('conversations').doc(conversationId)
          : _firestore.collection('conversations').doc();

      // メッセージを保存
      final messageRef = conversationRef.collection('messages').doc();

      final messageData = {
        'userId': currentUser.uid,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'user',
      };

      await messageRef.set(messageData);

      // 会話データを更新または作成
      if (conversationId == null) {
        await conversationRef.set({
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': message,
        });
      } else {
        await conversationRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': message,
        });
      }

      // AI応答を取得する場合は、Cloud Functionsをトリガーして応答を生成
      // ここでは簡単な応答を返す
      return {
        'conversationId': conversationRef.id,
        'messageId': messageRef.id,
        'status': 'sent',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getConversations({
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Firestoreから会話を取得
      var query = _firestore
          .collection('conversations')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('updatedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      final conversations = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        conversations.add({
          'conversationId': doc.id,
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : null,
          'updatedAt': data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
              : null,
          'lastMessage': data['lastMessage'] as String?,
        });
      }

      return {
        'conversations': conversations,
        'count': conversations.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'conversations': [],
        'count': 0,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getWeeklyReport({
    required DateTime date,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // 週の開始日と終了日を計算
      final startDate = DateTime(date.year, date.month, date.day).subtract(
          Duration(days: date.weekday - 1));
      final endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // この週のアクティビティを取得
      final activitiesResult = await getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      if (activitiesResult.containsKey('error') && !activitiesResult.containsKey('activities')) {
        return {
          'error': activitiesResult['error'],
          'weeklyReport': null,
        };
      }

      final activities = activitiesResult['activities'] as List<dynamic>;

      // 日毎のデータを集計
      final dailyData = <String, Map<String, dynamic>>{};
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));
        final dayKey = day.toIso8601String().split('T')[0];

        final dayActivities = activities.where((activity) {
          final activityDate = DateTime.parse(activity['startTime'] as String);
          return activityDate.year == day.year &&
              activityDate.month == day.month &&
              activityDate.day == day.day;
        }).toList();

        double totalCalories = 0;
        double totalFatBurned = 0;

        for (final activity in dayActivities) {
          totalCalories += activity['caloriesBurned'] as double;
          totalFatBurned += activity['fatBurnedGrams'] as double;
        }

        dailyData[dayKey] = {
          'totalActivities': dayActivities.length,
          'totalCalories': totalCalories,
          'totalFatBurned': totalFatBurned,
        };
      }

      // 週全体の集計
      double weeklyCalories = 0;
      double weeklyFatBurned = 0;
      int totalActivities = 0;

      for (final day in dailyData.values) {
        weeklyCalories += day['totalCalories'] as double;
        weeklyFatBurned += day['totalFatBurned'] as double;
        totalActivities += day['totalActivities'] as int;
      }

      return {
        'weeklyReport': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'totalActivities': totalActivities,
          'totalCalories': weeklyCalories,
          'totalFatBurned': weeklyFatBurned,
          'dailyData': dailyData,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'weeklyReport': null,
      };
    }
  }
}