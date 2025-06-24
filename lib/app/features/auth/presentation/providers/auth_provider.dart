import 'package:flutter_riverpod/flutter_riverpod.dart';

// lib版の既存エンティティとリポジトリを使用
import '../../../../../domain/models/user_model.dart';
import '../../../../../domain/repositories/user_repository.dart';
import '../../../../../core/services/injector.dart';

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
  UserModel? _currentUser;

  /// 現在のユーザー
  UserModel? get currentUser => _currentUser;

  AuthStateNotifier({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(AuthState.initializing) {
    _initialize();
  }

  /// 初期化
  Future<void> _initialize() async {
    try {
      // lib版のUserRepositoryを使用
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
      _currentUser = await _userRepository.signUp(email, password, displayName);
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

  /// プロフィール更新（lib版のUserModelに合わせて調整）
  Future<void> updateProfile(String? displayName, Map<String, dynamic>? metadata) async {
    try {
      if (_currentUser != null) {
        // lib版のUserModelの構造に合わせて更新
        final updatedUser = _currentUser!.copyWith(
          displayName: displayName,
          metadata: metadata,
        );
        _currentUser = await _userRepository.updateUser(updatedUser);
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// 認証プロバイダー（lib版のDIコンテナを使用）
final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final userRepository = getIt<UserRepository>();
  return AuthStateNotifier(userRepository: userRepository);
});

/// 現在のユーザープロバイダー
final currentUserProvider = Provider<UserModel?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.currentUser;
});

/// 認証状態のストリームプロバイダー（リアルタイム更新用）
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authProvider.notifier).stream;
});

/// ログイン状態の簡易チェックプロバイダー
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) == AuthState.authenticated;
});

/// 初期化完了状態のプロバイダー
final isInitializedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != AuthState.initializing;
});