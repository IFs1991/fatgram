import '../models/user_model.dart';

abstract class UserRepository {
  /// ユーザーログインを行う
  Future<User?> login({
    required String email,
    required String password,
  });

  /// サインアップを行う
  Future<User?> signup({
    required String email,
    required String password,
    String? displayName,
  });

  /// Googleでサインインを行う
  Future<User?> signInWithGoogle();

  /// Appleでサインインを行う
  Future<User?> signInWithApple();

  /// パスワードリセットを行う
  Future<bool> resetPassword(String email);

  /// ログアウトを行う
  Future<void> logout();

  /// 現在のユーザーを取得する
  Future<User?> getCurrentUser();

  /// ユーザー情報を更新する
  Future<User> updateUser(User user);
}