import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/local_data_source.dart';
import '../data/datasources/local_data_source_impl.dart';
import '../data/datasources/remote_data_source.dart';
import '../data/datasources/remote_data_source_impl.dart';
import '../data/repositories/activity_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/user_repository.dart';

/// 依存性注入コンテナ
class Injector {
  static final Injector _instance = Injector._internal();
  static ProviderContainer? _container;

  factory Injector() {
    return _instance;
  }

  Injector._internal();

  /// 初期化
  static Future<void> initialize() async {
    // SharedPreferencesを初期化
    final prefs = await SharedPreferences.getInstance();

    // Firebaseサービスの初期化はmain.dartで行われることを想定

    // 依存関係の定義
    final providers = [
      // データソース
      Provider<LocalDataSource>((ref) => LocalDataSourceImpl(prefs: prefs)),
      Provider<RemoteDataSource>((ref) => RemoteDataSourceImpl(
            firebaseAuth: FirebaseAuth.instance,
          )),

      // Firebase認証サービス
      Provider<FirebaseAuth>((ref) => FirebaseAuth.instance),
      Provider<GoogleSignIn>((ref) => GoogleSignIn()),
      Provider<HealthFactory>((ref) => HealthFactory()),

      // リポジトリ
      Provider<UserRepository>((ref) => UserRepositoryImpl(
            firebaseAuth: ref.read(Provider((r) => FirebaseAuth.instance)),
            googleSignIn: ref.read(Provider((r) => GoogleSignIn())),
            remoteDataSource: ref.read(Provider<RemoteDataSource>((r) => throw UnimplementedError())),
            localDataSource: ref.read(Provider<LocalDataSource>((r) => throw UnimplementedError())),
          )),
      Provider<ActivityRepository>((ref) => ActivityRepositoryImpl(
            health: ref.read(Provider((r) => HealthFactory())),
            remoteDataSource: ref.read(Provider<RemoteDataSource>((r) => throw UnimplementedError())),
            localDataSource: ref.read(Provider<LocalDataSource>((r) => throw UnimplementedError())),
          )),
    ];

    _container = ProviderContainer(overrides: providers);
  }

  /// プロバイダーコンテナを取得
  static ProviderContainer get container {
    if (_container == null) {
      throw Exception('Injector is not initialized');
    }
    return _container!;
  }

  /// プロバイダーから値を取得
  static T read<T>(ProviderBase<T> provider) {
    return container.read(provider);
  }
}

/// グローバルプロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return Injector.read(Provider((r) => Injector.container.read(
      Provider<UserRepository>((p) => throw UnimplementedError()))));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return Injector.read(Provider((r) => Injector.container.read(
      Provider<ActivityRepository>((p) => throw UnimplementedError()))));
});