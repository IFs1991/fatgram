import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../domain/models/activity_model.dart';
import '../../domain/models/user_model.dart' as app_models;
import 'remote_data_source.dart';

class FirebaseRemoteDataSource implements RemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseRemoteDataSource({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Getting activities for user $userId from $startDate to $endDate');
      }

      final querySnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      final activities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ドキュメントIDを設定
        
        // Firestoreのタイムスタンプを適切な形式に変換
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        
        return Activity.fromJson(data);
      }).toList();

      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Retrieved ${activities.length} activities');
      }

      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Error getting activities: $e');
      }
      
      // エラーの種類に応じて適切な例外を投げる
      if (e is FirebaseException) {
        throw Exception('Firebase error: ${e.message}');
      } else {
        throw Exception('Failed to get activities: $e');
      }
    }
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    try {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Saving activity ${activity.id}');
      }

      final activityData = activity.toJson();
      
      // Firestoreのクエリ用にTimestampを保存
      activityData['timestamp'] = Timestamp.fromDate(activity.timestamp);
      
      // サーバータイムスタンプを設定
      activityData['createdAt'] = FieldValue.serverTimestamp();
      activityData['updatedAt'] = FieldValue.serverTimestamp();
      activityData['syncStatus'] = 'synced';

      // アクティビティIDが指定されている場合はそのIDで保存、そうでなければ自動生成
      if (activity.id.isNotEmpty) {
        await _firestore
            .collection('activities')
            .doc(activity.id)
            .set(activityData, SetOptions(merge: true));
      } else {
        final docRef = await _firestore
            .collection('activities')
            .add(activityData);
        
        if (kDebugMode) {
          print('FirebaseRemoteDataSource: Activity saved with auto-generated ID: ${docRef.id}');
        }
      }

      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Activity ${activity.id} saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Error saving activity: $e');
      }
      
      if (e is FirebaseException) {
        throw Exception('Firebase error: ${e.message}');
      } else {
        throw Exception('Failed to save activity: $e');
      }
    }
  }

  @override
  Future<app_models.User?> getUser(String userId) async {
    try {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Getting user $userId');
      }

      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print('FirebaseRemoteDataSource: User $userId not found');
        }
        return null;
      }

      final userData = docSnapshot.data()!;
      userData['id'] = docSnapshot.id; // ドキュメントIDを設定
      
      // Firestoreのタイムスタンプを適切な形式に変換
      if (userData['createdAt'] is Timestamp) {
        userData['createdAt'] = (userData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (userData['lastLoginAt'] is Timestamp) {
        userData['lastLoginAt'] = (userData['lastLoginAt'] as Timestamp).toDate().toIso8601String();
      }

      final user = app_models.User.fromJson(userData);

      if (kDebugMode) {
        print('FirebaseRemoteDataSource: User $userId retrieved successfully');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Error getting user: $e');
      }
      
      if (e is FirebaseException) {
        throw Exception('Firebase error: ${e.message}');
      } else {
        throw Exception('Failed to get user: $e');
      }
    }
  }

  @override
  Future<void> saveUser(app_models.User user) async {
    try {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Saving user ${user.id}');
      }

      final userData = user.toJson();
      
      // サーバータイムスタンプを設定
      userData['updatedAt'] = FieldValue.serverTimestamp();
      
      // createdAtが存在しない場合のみ設定（新規ユーザーの場合）
      if (!userData.containsKey('createdAt') || userData['createdAt'] == null) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('users')
          .doc(user.id)
          .set(userData, SetOptions(merge: true));

      if (kDebugMode) {
        print('FirebaseRemoteDataSource: User ${user.id} saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseRemoteDataSource: Error saving user: $e');
      }
      
      if (e is FirebaseException) {
        throw Exception('Firebase error: ${e.message}');
      } else {
        throw Exception('Failed to save user: $e');
      }
    }
  }

  @override
  Future<app_models.User?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUserToUser(userCredential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Failed to login: ${e.message}');
      return null;
    }
  }

  @override
  Future<app_models.User?> signupWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー名を設定
      if (displayName != null) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return _mapFirebaseUserToUser(userCredential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Failed to signup: ${e.message}');
      return null;
    }
  }

  @override
  Future<app_models.User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return _mapFirebaseUserToUser(userCredential.user);
    } catch (e) {
      print('Failed to sign in with Google: $e');
      return null;
    }
  }

  @override
  Future<app_models.User?> signInWithApple() async {
    try {
      // リクエストを生成
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Apple認証をリクエスト
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // OAuthプロバイダーのクレデンシャルを取得
      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Firebaseでサインイン
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      // Appleは初回のみフルネームを返すため、保存しておく必要がある
      if (appleCredential.givenName != null && appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        await userCredential.user?.updateDisplayName(displayName);
      }

      return _mapFirebaseUserToUser(userCredential.user);
    } catch (e) {
      print('Failed to sign in with Apple: $e');
      return null;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Failed to send password reset email: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<app_models.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    return _mapFirebaseUserToUser(firebaseUser);
  }

  // FirebaseのUserをアプリのUserモデルに変換
  app_models.User? _mapFirebaseUserToUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    return app_models.User.fromFirebase({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'displayName': firebaseUser.displayName,
      'photoURL': firebaseUser.photoURL,
      'createdAt': firebaseUser.metadata.creationTime?.toIso8601String(),
      'lastLoginAt': firebaseUser.metadata.lastSignInTime?.toIso8601String(),
    });
  }

  // Apple Sign-In用のnonceを生成
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // sha256 ハッシュを base64 でエンコード
  String _sha256ofString(String input) {
    // 本来はcrypto packageを使用して実装しますが、簡略化のためダミー実装
    return base64Encode(input.codeUnits);
  }
}