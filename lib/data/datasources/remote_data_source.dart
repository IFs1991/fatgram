import '../../domain/models/activity_model.dart';
import '../../domain/models/user_model.dart';

abstract class RemoteDataSource {
  /// アクティビティを取得する
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  });

  /// アクティビティを保存する
  Future<void> saveActivity(Activity activity);

  /// ユーザーを取得する
  Future<User?> getUser(String userId);

  /// ユーザーを保存する
  Future<void> saveUser(User user);

  /// メールとパスワードでログインする
  Future<User?> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// メールとパスワードでサインアップする
  Future<User?> signupWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Googleでサインインする
  Future<User?> signInWithGoogle();

  /// Appleでサインインする
  Future<User?> signInWithApple();

  /// パスワードリセットを行う
  Future<bool> resetPassword(String email);

  /// ログアウトする
  Future<void> logout();

  /// 現在のユーザーを取得する
  Future<User?> getCurrentUser();
}