import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/user.dart';
import '../../../../../domain/repositories/user_repository.dart';

/// 認証状態
enum AuthState {
  /// 初期化中
  initializing,

  /// 認証済み
  authenticated,

  /// 未認証
  unauthenticated,
}

/// 認証プロバイダーの状態
class AuthStateNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  User? _currentUser;

  /// 現在のユーザー
  User? get currentUser => _currentUser;

  AuthStateNotifier({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(AuthState.initializing) {
    _initialize();
  }

  /// 初期化
  Future<void> _initialize() async {
    try {
      _currentUser = await _userRepository.getCurrentUser();
      state = _currentUser != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
    }
  }

  /// サインアップ
  Future<void> signUp(String email, String password, String displayName) async {
    state = AuthState.initializing;
    try {
      _currentUser =
          await _userRepository.signUp(email, password, displayName);
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// サインイン
  Future<void> signIn(String email, String password) async {
    state = AuthState.initializing;
    try {
      _currentUser = await _userRepository.signIn(email, password);
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Googleサインイン
  Future<void> signInWithGoogle() async {
    state = AuthState.initializing;
    try {
      _currentUser = await _userRepository.signInWithGoogle();
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Appleサインイン
  Future<void> signInWithApple() async {
    state = AuthState.initializing;
    try {
      _currentUser = await _userRepository.signInWithApple();
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    state = AuthState.initializing;
    try {
      await _userRepository.signOut();
      _currentUser = null;
      state = AuthState.unauthenticated;
    } catch (e) {
      state = _currentUser != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
      rethrow;
    }
  }

  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    await _userRepository.resetPassword(email);
  }

  /// プロフィール更新
  Future<void> updateProfile(String? displayName, UserGoals? goals) async {
    try {
      _currentUser = await _userRepository.updateUserProfile(displayName, goals);
    } catch (e) {
      rethrow;
    }
  }
}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthStateNotifier(userRepository: userRepository);
});

/// ユーザーリポジトリプロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  // TODO: DIコンテナから取得するように修正
  throw UnimplementedError();
});

/// 現在のユーザープロバイダー
final currentUserProvider = Provider<User?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.currentUser;
});