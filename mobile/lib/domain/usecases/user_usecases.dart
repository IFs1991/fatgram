import '../models/user.dart';
import '../repositories/user_repository.dart';

/// ユーザー登録ユースケース
class RegisterUser {
  final UserRepository repository;

  RegisterUser(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return repository.register(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

/// ユーザーログインユースケース
class LoginUser {
  final UserRepository repository;

  LoginUser(this.repository);

  Future<User> call({
    required String email,
    required String password,
  }) {
    return repository.login(
      email: email,
      password: password,
    );
  }
}

/// ユーザーログアウトユースケース
class LogoutUser {
  final UserRepository repository;

  LogoutUser(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

/// 現在のユーザー取得ユースケース
class GetCurrentUser {
  final UserRepository repository;

  GetCurrentUser(this.repository);

  Future<User?> call() {
    return repository.getCurrentUser();
  }
}

/// ユーザープロファイル更新ユースケース
class UpdateUserProfile {
  final UserRepository repository;

  UpdateUserProfile(this.repository);

  Future<User> call({
    String? displayName,
    UserGoals? goals,
  }) {
    return repository.updateUserProfile(
      displayName: displayName,
      goals: goals,
    );
  }
}

/// 認証状態確認ユースケース
class CheckAuthentication {
  final UserRepository repository;

  CheckAuthentication(this.repository);

  Future<bool> call() {
    return repository.isAuthenticated();
  }
}