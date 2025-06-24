import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// プロジェクト構造の検証テスト
/// TDD Red Phase: 期待する単一構造を定義し、現状の重複を検出
class ProjectStructureValidator {
  static const String projectRoot = '/mnt/c/Users/seekf/Desktop/fatgram';
  
  /// 期待されるプロジェクト構造
  static const Map<String, bool> expectedStructure = {
    'lib': true,                    // メインライブラリディレクトリ
    'mobile/lib': false,            // 重複構造（削除対象）
    'test': true,                   // テストディレクトリ
    'mobile/test': false,           // 重複テスト（統合対象）
    'pubspec.yaml': true,           // メインpubspec
    'mobile/pubspec.yaml': false,   // 重複pubspec（削除対象）
    'android': true,                // Androidプロジェクト
    'ios': true,                    // iOSプロジェクト
    'backend': true,                // バックエンドコード
  };
  
  /// 期待される単一pubspec.yamlの構造
  static const Map<String, dynamic> expectedDependencies = {
    'flutter_sdk_version': '>=3.4.4 <4.0.0',
    'required_packages': [
      'flutter',
      'cupertino_icons',
      'health',
      'firebase_core',
      'firebase_auth',
      'cloud_firestore',
      'fl_chart',
      'dio',
      'get_it',
      'injectable',
    ],
    'consistent_versions': true,
  };
}

void main() {
  group('Project Structure Validation Tests (TDD Red Phase)', () {
    late Directory projectDir;
    
    setUpAll(() {
      projectDir = Directory(ProjectStructureValidator.projectRoot);
    });
    
    test('should detect duplicate project structure', () async {
      // Red Phase: このテストは現在失敗するはず（重複構造が存在するため）
      
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      final mobileLibDir = Directory(path.join(projectDir.path, 'mobile', 'lib'));
      
      // 期待：単一のlibディレクトリのみ存在
      expect(libDir.existsSync(), isTrue, 
        reason: 'メインのlibディレクトリが存在する必要があります');
      
      // 期待：mobile/libディレクトリは存在しない（統合済み）
      expect(mobileLibDir.existsSync(), isFalse, 
        reason: 'mobile/libディレクトリは統合により削除されている必要があります');
    });
    
    test('should have unified pubspec.yaml structure', () async {
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
    
    test('should validate unified lib directory contents', () async {
      // Red Phase: 統合後の期待する構造を定義
      
      final libDir = Directory(path.join(projectDir.path, 'lib'));
      expect(libDir.existsSync(), isTrue);
      
      // 期待される統合後のディレクトリ構造
      final expectedDirectories = [
        'core',           // コア機能
        'data',           // データ層
        'domain',         // ドメイン層
        'presentation',   // プレゼンテーション層
        'app',            // アプリケーション層（mobile/から統合）
        'features',       // 機能別実装（mobile/から統合）
      ];
      
      for (final dirName in expectedDirectories) {
        final dir = Directory(path.join(libDir.path, dirName));
        expect(dir.existsSync(), isTrue,
          reason: '$dirName ディレクトリが統合されている必要があります');
      }
    });
    
    test('should detect duplicate files that need merging', () async {
      // Red Phase: 重複ファイルの検出と統合要件の定義
      
      final duplicateFiles = await _findDuplicateFiles();
      
      // 期待：重複ファイルが適切に処理されている
      expect(duplicateFiles, isEmpty,
        reason: '重複ファイルはすべて統合または削除されている必要があります');
    });
    
    test('should validate import statements consistency', () async {
      // Red Phase: import文の整合性チェック
      
      final dartFiles = await _getAllDartFiles();
      final inconsistentImports = <String>[];
      
      for (final file in dartFiles) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.trim().startsWith('import') && line.contains('mobile/')) {
            inconsistentImports.add('${file.path}: $line');
          }
        }
      }
      
      // 期待：mobile/への参照が存在しない
      expect(inconsistentImports, isEmpty,
        reason: 'mobile/への古い参照が残っています: ${inconsistentImports.join(', ')}');
    });
    
    test('should have consistent project metadata', () async {
      // Red Phase: プロジェクトメタデータの一貫性
      
      final mainPubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      expect(mainPubspec.existsSync(), isTrue);
      
      final content = await mainPubspec.readAsString();
      
      // 期待：統一されたプロジェクト名
      expect(content, contains('name: fatgram'),
        reason: 'プロジェクト名が統一されている必要があります');
      
      // 期待：統一されたSDKバージョン
      expect(content, contains('sdk: \'>=3.4.4 <4.0.0\''),
        reason: 'SDKバージョンが統一されている必要があります');
    });
  });
  
  group('Project Structure Helper Methods', () {
    test('should identify all duplicate file patterns', () async {
      final duplicates = await _findDuplicateFiles();
      
      // 開発者向け情報：重複ファイルのリスト表示
      if (duplicates.isNotEmpty) {
        print('Found duplicate files that need attention:');
        for (final duplicate in duplicates) {
          print('  - $duplicate');
        }
      }
    });
  });
}

/// 重複ファイルを検出するヘルパーメソッド
Future<List<String>> _findDuplicateFiles() async {
  final projectDir = Directory(ProjectStructureValidator.projectRoot);
  final duplicates = <String>[];
  
  // lib/ と mobile/lib/ の比較
  final libDir = Directory(path.join(projectDir.path, 'lib'));
  final mobileLibDir = Directory(path.join(projectDir.path, 'mobile', 'lib'));
  
  if (libDir.existsSync() && mobileLibDir.existsSync()) {
    await for (final entity in mobileLibDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: mobileLibDir.path);
        final correspondingFile = File(path.join(libDir.path, relativePath));
        
        if (correspondingFile.existsSync()) {
          duplicates.add('lib/$relativePath (exists in both lib/ and mobile/lib/)');
        }
      }
    }
  }
  
  // pubspec.yaml の重複チェック
  final mainPubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
  final mobilePubspec = File(path.join(projectDir.path, 'mobile', 'pubspec.yaml'));
  
  if (mainPubspec.existsSync() && mobilePubspec.existsSync()) {
    duplicates.add('pubspec.yaml (exists in both root and mobile/)');
  }
  
  return duplicates;
}

/// すべてのDartファイルを取得するヘルパーメソッド
Future<List<File>> _getAllDartFiles() async {
  final projectDir = Directory(ProjectStructureValidator.projectRoot);
  final dartFiles = <File>[];
  
  await for (final entity in projectDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // build/やnode_modules/などの生成ディレクトリを除外
      if (!entity.path.contains('/build/') && 
          !entity.path.contains('/node_modules/') &&
          !entity.path.contains('/.dart_tool/')) {
        dartFiles.add(entity);
      }
    }
  }
  
  return dartFiles;
}