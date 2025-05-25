import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fatgram/app/features/home/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FatGramApp(),
    ),
  );
}

class FatGramApp extends StatelessWidget {
  const FatGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FatGram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}