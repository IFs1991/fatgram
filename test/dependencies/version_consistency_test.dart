import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 依存関係バージョン一貫性検証テスト
/// TDD Red Phase: 期待する統一された依存関係を定義
class DependencyVersionValidator {
  static const String projectRoot = '/mnt/c/Users/seekf/Desktop/fatgram';
  
  /// 期待される統一依存関係バージョン
  static const Map<String, String> expectedVersions = {
    // Core Flutter
    'flutter_sdk': '>=3.4.4 <4.0.0',
    
    // UI & Design
    'cupertino_icons': '^1.0.6',
    'fl_chart': '^0.66.2',
    'cached_network_image': '^3.3.0',
    'shimmer': '^3.0.0',
    'lottie': '^2.6.0',
    
    // Firebase
    'firebase_core': '^2.32.0',
    'firebase_auth': '^4.16.0',
    'cloud_firestore': '^4.17.5',
    'firebase_analytics': '^10.10.7',
    
    // Authentication
    'google_sign_in': '^6.2.2',
    'sign_in_with_apple': '^7.0.1',
    
    // Storage & Database
    'shared_preferences': '^2.3.3',
    'sqflite': '^2.3.0',
    'flutter_secure_storage': '^9.2.4',
    
    // Health & Activity
    'health': '^12.2.0',
    
    // Network & API
    'dio': '^5.4.0',
    'connectivity_plus': '^5.0.2',
    
    // State Management & DI
    'get_it': '^7.6.4',
    'injectable': '^2.3.2',
    'flutter_riverpod': '^2.4.0',
    'riverpod_annotation': '^2.2.1',
    
    // AI & ML
    'google_generative_ai': '^0.4.7',
    
    // Subscription
    'purchases_flutter': '^6.5.0',
    
    // Utilities
    'uuid': '^4.5.1',
    'intl': '^0.19.0',
    'path': '^1.8.3',
    'equatable': '^2.0.5',
    'dartz': '^0.10.1',
    'crypto': '^3.0.6',
    'logger': '^2.0.2',
    'permission_handler': '^11.1.0',
    'image_picker': '^1.0.4',
    
    // Environment
    'flutter_dotenv': '^5.1.0',
    
    // Chat
    'flutter_chat_ui': '^1.6.10',
    'flutter_chat_types': '^3.6.2',
  };
  
  /// セキュリティが重要なパッケージ
  static const List<String> securityCriticalPackages = [
    'firebase_core',
    'firebase_auth',
    'flutter_secure_storage',
    'crypto',
    'dio',
    'google_sign_in',
  ];
  
  /// 開発依存関係の期待バージョン
  static const Map<String, String> expectedDevDependencies = {
    'flutter_test': 'sdk: flutter',
    'flutter_lints': '^3.0.0',
    'mocktail': '^1.0.3',
    'faker': '^2.1.0',
    'test': '^1.24.9',
    'build_runner': '^2.4.7',
    'json_annotation': '^4.8.1',
    'json_serializable': '^6.7.1',
    'injectable_generator': '^2.4.1',
    'riverpod_generator': '^2.3.9',
    'integration_test': 'sdk: flutter',
  };
}

void main() {
  group('Dependency Version Consistency Tests (TDD Red Phase)', () {
    late Directory projectDir;
    
    setUpAll(() {
      projectDir = Directory(DependencyVersionValidator.projectRoot);
    });
    
    test('should have single unified pubspec.yaml', () async {
      // Red Phase: このテストは現在失敗するはず（複数のpubspecが存在するため）
      
      final mainPubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      final mobilePubspec = File(path.join(projectDir.path, 'mobile', 'pubspec.yaml'));
      
      // 期待：メインpubspec.yamlのみ存在
      expect(mainPubspec.existsSync(), isTrue,
        reason: 'メインのpubspec.yamlが存在する必要があります');
      
      // 期待：mobile/pubspec.yamlは存在しない（統合済み）
      expect(mobilePubspec.existsSync(), isFalse,
        reason: 'mobile/pubspec.yamlは統合により削除されている必要があります');
    });
    
    test('should have consistent Flutter SDK version', () async {
      // Red Phase: Flutter SDKバージョンの統一確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      expect(pubspecFiles.length, equals(1),
        reason: 'pubspec.yamlは1つのみ存在する必要があります');
      
      final pubspec = await _loadPubspecYaml(pubspecFiles.first);
      final environment = pubspec['environment'] as Map?;
      final sdkVersion = environment?['sdk'] as String?;
      
      expect(sdkVersion, equals(DependencyVersionValidator.expectedVersions['flutter_sdk']),
        reason: 'Flutter SDKバージョンが ${DependencyVersionValidator.expectedVersions['flutter_sdk']} である必要があります');
    });
    
    test('should have unified package versions', () async {
      // Red Phase: パッケージバージョンの統一確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      expect(pubspecFiles.isNotEmpty, isTrue);
      
      for (final pubspecFile in pubspecFiles) {
        final pubspec = await _loadPubspecYaml(pubspecFile);
        final dependencies = pubspec['dependencies'] as Map? ?? {};
        
        // 重要パッケージのバージョンチェック
        for (final entry in DependencyVersionValidator.expectedVersions.entries) {
          if (entry.key != 'flutter_sdk' && dependencies.containsKey(entry.key)) {
            final actualVersion = dependencies[entry.key];
            expect(actualVersion, equals(entry.value),
              reason: '${entry.key} のバージョンが ${entry.value} である必要があります (現在: $actualVersion)');
          }
        }
      }
    });
    
    test('should have security-critical packages at latest versions', () async {
      // Red Phase: セキュリティ重要パッケージの最新版確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      final securityIssues = <String>[];
      
      for (final pubspecFile in pubspecFiles) {
        final pubspec = await _loadPubspecYaml(pubspecFile);
        final dependencies = pubspec['dependencies'] as Map? ?? {};
        
        for (final packageName in DependencyVersionValidator.securityCriticalPackages) {
          if (dependencies.containsKey(packageName)) {
            final version = dependencies[packageName] as String;
            final expectedVersion = DependencyVersionValidator.expectedVersions[packageName];
            
            if (expectedVersion != null && version != expectedVersion) {
              securityIssues.add('$packageName: expected $expectedVersion, got $version');
            }
          }
        }
      }
      
      expect(securityIssues, isEmpty,
        reason: 'セキュリティ重要パッケージが最新版である必要があります: ${securityIssues.join(', ')}');
    });
    
    test('should have consistent dev dependencies', () async {
      // Red Phase: 開発依存関係の一貫性確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      
      for (final pubspecFile in pubspecFiles) {
        final pubspec = await _loadPubspecYaml(pubspecFile);
        final devDependencies = pubspec['dev_dependencies'] as Map? ?? {};
        
        // 必須開発依存関係の確認
        for (final entry in DependencyVersionValidator.expectedDevDependencies.entries) {
          if (devDependencies.containsKey(entry.key)) {
            final actualVersion = devDependencies[entry.key];
            expect(actualVersion, equals(entry.value),
              reason: '${entry.key} のdev依存関係バージョンが ${entry.value} である必要があります');
          }
        }
      }
    });
    
    test('should not have conflicting package versions', () async {
      // Red Phase: パッケージバージョン競合の検出
      
      final pubspecFiles = await _getAllPubspecFiles();
      final versionConflicts = <String>[];
      
      if (pubspecFiles.length > 1) {
        final packageVersions = <String, Set<String>>{};
        
        for (final pubspecFile in pubspecFiles) {
          final pubspec = await _loadPubspecYaml(pubspecFile);
          final dependencies = pubspec['dependencies'] as Map? ?? {};
          
          for (final entry in dependencies.entries) {
            final packageName = entry.key as String;
            final version = entry.value.toString();
            
            packageVersions.putIfAbsent(packageName, () => <String>{}).add(version);
          }
        }
        
        for (final entry in packageVersions.entries) {
          if (entry.value.length > 1) {
            versionConflicts.add('${entry.key}: ${entry.value.join(', ')}');
          }
        }
      }
      
      expect(versionConflicts, isEmpty,
        reason: 'パッケージバージョンの競合があります: ${versionConflicts.join('; ')}');
    });
    
    test('should have all required packages for features', () async {
      // Red Phase: 機能実装に必要なパッケージの確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      expect(pubspecFiles.length, equals(1));
      
      final pubspec = await _loadPubspecYaml(pubspecFiles.first);
      final dependencies = pubspec['dependencies'] as Map? ?? {};
      
      final missingPackages = <String>[];
      
      // 必須パッケージの確認
      final requiredPackages = [
        'flutter',
        'health',
        'firebase_core',
        'firebase_auth',
        'fl_chart',
        'dio',
        'get_it',
        'injectable',
      ];
      
      for (final packageName in requiredPackages) {
        if (!dependencies.containsKey(packageName)) {
          missingPackages.add(packageName);
        }
      }
      
      expect(missingPackages, isEmpty,
        reason: '必須パッケージが不足しています: ${missingPackages.join(', ')}');
    });
    
    test('should validate pubspec.yaml syntax and structure', () async {
      // Red Phase: pubspec.yamlの構文と構造の確認
      
      final pubspecFiles = await _getAllPubspecFiles();
      
      for (final pubspecFile in pubspecFiles) {
        final content = await pubspecFile.readAsString();
        
        // YAML構文の確認
        expect(() => loadYaml(content), returnsNormally,
          reason: '${pubspecFile.path} のYAML構文が正しくありません');
        
        final pubspec = loadYaml(content) as Map;
        
        // 必須フィールドの確認
        expect(pubspec, containsPair('name', isA<String>()),
          reason: 'pubspec.yamlにnameフィールドが必要です');
        expect(pubspec, containsPair('environment', isA<Map>()),
          reason: 'pubspec.yamlにenvironmentフィールドが必要です');
        expect(pubspec, containsPair('dependencies', isA<Map>()),
          reason: 'pubspec.yamlにdependenciesフィールドが必要です');
      }
    });
  });
  
  group('Dependency Analysis Helper Methods', () {
    test('should analyze current dependency state', () async {
      final pubspecFiles = await _getAllPubspecFiles();
      final analysisResult = await _analyzeDependencyState(pubspecFiles);
      
      print('Current dependency analysis:');
      print('- Total pubspec files: ${pubspecFiles.length}');
      print('- Unique packages: ${analysisResult['uniquePackages']}');
      print('- Version conflicts: ${analysisResult['conflicts']}');
      print('- Missing critical packages: ${analysisResult['missing']}');
    });
  });
}

/// すべてのpubspec.yamlファイルを取得
Future<List<File>> _getAllPubspecFiles() async {
  final projectDir = Directory(DependencyVersionValidator.projectRoot);
  final pubspecFiles = <File>[];
  
  await for (final entity in projectDir.list(recursive: true)) {
    if (entity is File && path.basename(entity.path) == 'pubspec.yaml') {
      // build/やnode_modules/などの生成ディレクトリを除外
      if (!entity.path.contains('/build/') && 
          !entity.path.contains('/node_modules/') &&
          !entity.path.contains('/.dart_tool/')) {
        pubspecFiles.add(entity);
      }
    }
  }
  
  return pubspecFiles;
}

/// pubspec.yamlを読み込んでパース
Future<Map> _loadPubspecYaml(File pubspecFile) async {
  final content = await pubspecFile.readAsString();
  return loadYaml(content) as Map;
}

/// 依存関係の状態を分析
Future<Map<String, dynamic>> _analyzeDependencyState(List<File> pubspecFiles) async {
  final allPackages = <String>{};
  final versionMap = <String, Set<String>>{};
  final conflicts = <String>[];
  
  for (final pubspecFile in pubspecFiles) {
    final pubspec = await _loadPubspecYaml(pubspecFile);
    final dependencies = pubspec['dependencies'] as Map? ?? {};
    
    for (final entry in dependencies.entries) {
      final packageName = entry.key as String;
      final version = entry.value.toString();
      
      allPackages.add(packageName);
      versionMap.putIfAbsent(packageName, () => <String>{}).add(version);
    }
  }
  
  for (final entry in versionMap.entries) {
    if (entry.value.length > 1) {
      conflicts.add(entry.key);
    }
  }
  
  final expectedPackages = DependencyVersionValidator.expectedVersions.keys.toSet();
  final missing = expectedPackages.difference(allPackages).toList();
  
  return {
    'uniquePackages': allPackages.length,
    'conflicts': conflicts,
    'missing': missing,
    'totalFiles': pubspecFiles.length,
  };
}