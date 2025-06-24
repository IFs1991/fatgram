import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 既存のlibファイルをインポート
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';

// mobile版から統合する機能
import 'features/auth/presentation/providers/auth_provider.dart';

/// FatGram アプリケーションのメインエントリポイント
/// mobile版のRiverpod構造とlib版の包括的UI機能を統合
class FatGramApp extends ConsumerWidget {
  const FatGramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'FatGram',
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: _getScreenBasedOnAuthState(authState),
      // 既存のlib版ルート設定があれば統合可能
      routes: _buildRoutes(),
    );
  }

  /// Material 3ベースのテーマ設定
  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50), // FatGramグリーン
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// ダークテーマ設定
  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  /// 認証状態に基づく画面選択
  Widget _getScreenBasedOnAuthState(AuthState authState) {
    switch (authState) {
      case AuthState.initializing:
        return const SplashScreen();
      case AuthState.authenticated:
        return const HomeScreen(); // lib版の包括的ホーム画面を使用
      case AuthState.unauthenticated:
        return const LoginScreen(); // lib版のログイン画面を使用
    }
  }

  /// アプリケーションルート設定
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/splash': (context) => const SplashScreen(),
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      // 追加のルートは必要に応じて設定
    };
  }
}