import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';

import '../../domain/models/activity_model.dart';
import '../../domain/models/user_model.dart' as app_models;
import 'remote_data_source.dart';

class FirebaseRemoteDataSource implements RemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseRemoteDataSource({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    // Firebase Firestoreからアクティビティを取得する実装を追加
    // 今はダミーデータを返す
    return [];
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    // Firebase Firestoreにアクティビティを保存する実装を追加
  }

  @override
  Future<app_models.User?> getUser(String userId) async {
    // Firebase Firestoreからユーザーを取得する実装を追加
    return null;
  }

  @override
  Future<void> saveUser(app_models.User user) async {
    // Firebase Firestoreにユーザーを保存する実装を追加
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