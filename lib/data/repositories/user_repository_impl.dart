import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  UserRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        await _localDataSource.saveCurrentUser(user);
      }

      return user;
    } catch (e) {
      print('Login failed: $e');
      return null;
    }
  }

  @override
  Future<User?> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _remoteDataSource.signupWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        await _localDataSource.saveCurrentUser(user);
      }

      return user;
    } catch (e) {
      print('Signup failed: $e');
      return null;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();

      if (user != null) {
        await _localDataSource.saveCurrentUser(user);
      }

      return user;
    } catch (e) {
      print('Google sign in failed: $e');
      return null;
    }
  }

  @override
  Future<User?> signInWithApple() async {
    try {
      final user = await _remoteDataSource.signInWithApple();

      if (user != null) {
        await _localDataSource.saveCurrentUser(user);
      }

      return user;
    } catch (e) {
      print('Apple sign in failed: $e');
      return null;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      return await _remoteDataSource.resetPassword(email);
    } catch (e) {
      print('Password reset failed: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
      await _localDataSource.clearUser();
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // まずローカルから取得を試みる
      final localUser = await _localDataSource.getCurrentUser();
      if (localUser != null) {
        return localUser;
      }

      // ローカルになければリモートから取得
      final remoteUser = await _remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await _localDataSource.saveCurrentUser(remoteUser);
      }

      return remoteUser;
    } catch (e) {
      print('Get current user failed: $e');
      return null;
    }
  }

  @override
  Future<User> updateUser(User user) async {
    try {
      await _remoteDataSource.saveUser(user);
      await _localDataSource.saveCurrentUser(user);
      return user;
    } catch (e) {
      print('Update user failed: $e');
      return user;
    }
  }
}