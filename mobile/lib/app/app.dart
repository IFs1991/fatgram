import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

/// FatGram アプリケーションのメインエントリポイント
class FatGramApp extends ConsumerWidget {
  const FatGramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'FatGram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: _getScreenBasedOnAuthState(authState),
    );
  }

  Widget _getScreenBasedOnAuthState(AuthState authState) {
    switch (authState) {
      case AuthState.initializing:
        return const SplashScreen();
      case AuthState.authenticated:
        return const HomeScreen();
      case AuthState.unauthenticated:
        return const LoginScreen();
    }
  }
}

/// ホーム画面
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FatGram'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'FatGram',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'スマートウォッチと連携して脂肪燃焼量を追跡',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // TODO: 実装
              },
              child: const Text('はじめる'),
            ),
          ],
        ),
      ),
    );
  }
}