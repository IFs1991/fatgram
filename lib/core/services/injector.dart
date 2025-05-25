import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';

import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/datasources/remote_data_source_impl.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// 依存関係の注入を管理するクラス
class Injector {
  static final Injector _instance = Injector._internal();

  factory Injector() {
    return _instance;
  }

  Injector._internal();

  // シングルトンのインスタンス
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final HealthFactory _health = HealthFactory();

  // ローカルデータソース (ここではダミー実装を使用)
  late final LocalDataSource _localDataSource = _createLocalDataSource();

  // リモートデータソース
  late final RemoteDataSource _remoteDataSource = FirebaseRemoteDataSource(
    firebaseAuth: _firebaseAuth,
    googleSignIn: _googleSignIn,
  );

  // レポジトリ
  UserRepository? _userRepository;
  ActivityRepository? _activityRepository;

  // ユーザーリポジトリを取得
  UserRepository getUserRepository() {
    return _userRepository ??= UserRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
  }

  // アクティビティリポジトリを取得 (要ユーザーID)
  ActivityRepository getActivityRepository(String userId) {
    return _activityRepository ??= ActivityRepositoryImpl(
      health: _health,
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
      userId: userId,
    );
  }

  // ローカルデータソースを作成（実際の実装はここでは省略）
  LocalDataSource _createLocalDataSource() {
    // 実際はShared PreferencesやHiveなどを使った実装を作成
    return _DummyLocalDataSource();
  }
}

/// ダミーのローカルデータソース実装（実際の実装では削除）
class _DummyLocalDataSource implements LocalDataSource {
  @override
  Future<void> clearUser() async {}

  @override
  Future<List<dynamic>> getActivities({required DateTime startDate, required DateTime endDate, required String userId}) async {
    return [];
  }

  @override
  Future<dynamic> getCurrentUser() async {
    return null;
  }

  @override
  Future<List<dynamic>> getUnsyncedActivities(String userId) async {
    return [];
  }

  @override
  Future<void> markActivityAsSynced(String activityId) async {}

  @override
  Future<void> saveActivities(List activities) async {}

  @override
  Future<void> saveActivity(dynamic activity) async {}

  @override
  Future<void> saveCurrentUser(dynamic user) async {}
}