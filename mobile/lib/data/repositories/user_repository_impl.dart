import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// ユーザーリポジトリの実装
class UserRepositoryImpl implements UserRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  UserRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<User> signUp(String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー表示名の設定
      await userCredential.user?.updateDisplayName(displayName);

      // リモートにユーザー情報を保存
      final user = await _remoteDataSource.registerUser(
        email: email,
        password: password,
        displayName: displayName,
      );

      // ローカルにユーザー情報を保存
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // リモートからユーザー情報を取得
      final user = await _remoteDataSource.loginUser(
        email: email,
        password: password,
      );

      // ローカルにユーザー情報を保存
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw Exception('Google sign in was aborted');
      }

      final googleAuth = await googleAccount.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);

      // リモートからユーザー情報を取得
      final user = await _remoteDataSource.getUserProfile();

      // ローカルにユーザー情報を保存
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _firebaseAuth.signInWithCredential(oauthCredential);

      // リモートからユーザー情報を取得
      final user = await _remoteDataSource.getUserProfile();

      // ローカルにユーザー情報を保存
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      // ローカルのユーザーデータをクリア
      await _localDataSource.clearUserData();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _localDataSource.getAuthToken();
    if (token == null) {
      return false;
    }

    // トークンの有効期限をチェック
    final expiresAt = DateTime.parse(token['expires_at']);
    final now = DateTime.now();

    if (expiresAt.isBefore(now)) {
      try {
        await refreshToken();
        return true;
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<void> refreshToken() async {
    try {
      final token = await _localDataSource.getAuthToken();
      if (token == null) {
        throw Exception('No refresh token available');
      }

      await _remoteDataSource.refreshToken(
        refreshToken: token['refresh_token'],
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      // ローカルにキャッシュされたユーザーデータがあれば取得
      final cachedUserData = await _localDataSource.getUserData();
      if (cachedUserData != null) {
        return User.fromJson(cachedUserData);
      }

      // キャッシュがなければリモートから取得
      final user = await _remoteDataSource.getUserProfile();
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> getUserProfile() async {
    try {
      final user = await _remoteDataSource.getUserProfile();
      await _localDataSource.cacheUserData(user.toJson());
      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> updateUserProfile(String? displayName, UserGoals? goals) async {
    try {
      if (displayName != null) {
        await _firebaseAuth.currentUser?.updateDisplayName(displayName);
      }

      // リモートでプロファイルを更新
      final user = await _remoteDataSource.updateUserProfile(
        displayName: displayName,
        goals: goals,
      );

      // ローカルのキャッシュを更新
      await _localDataSource.cacheUserData(user.toJson());

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // エラーハンドリング
  Exception _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('このメールアドレスのユーザーが見つかりません');
        case 'wrong-password':
          return Exception('パスワードが間違っています');
        case 'email-already-in-use':
          return Exception('このメールアドレスはすでに使用されています');
        case 'weak-password':
          return Exception('パスワードは6文字以上にしてください');
        case 'invalid-email':
          return Exception('有効なメールアドレスを入力してください');
        default:
          return Exception('認証エラー: ${error.message}');
      }
    }
    return Exception('予期しないエラーが発生しました: $error');
  }
}