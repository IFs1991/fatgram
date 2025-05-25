import '../models/user.dart';

/// ユーザーリポジトリインターフェース
abstract class UserRepository {
  /// ユーザー登録
  Future<User> signUp(String email, String password, String displayName);

  /// ユーザーログイン
  Future<User> signIn(String email, String password);

  /// Googleでログイン
  Future<User> signInWithGoogle();

  /// Appleでログイン
  Future<User> signInWithApple();

  /// ログアウト
  Future<void> signOut();

  /// ユーザー認証状態の確認
  Future<bool> isAuthenticated();

  /// トークンリフレッシュ
  Future<void> refreshToken();

  /// 現在のユーザー取得
  Future<User?> getCurrentUser();

  /// ユーザープロファイル取得
  Future<User> getUserProfile();

  /// ユーザープロファイル更新
  Future<User> updateUserProfile(String? displayName, UserGoals? goals);

  /// パスワードリセット
  Future<void> resetPassword(String email);
}