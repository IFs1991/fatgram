import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

/// プロジェクト統合テスト
/// Green Phase: 統合が正常に完了したことを確認
void main() {
  group('Project Integration Tests (Green Phase)', () {
    const String projectRoot = '/mnt/c/Users/seekf/Desktop/fatgram';
    
    test('should have integrated app structure', () async {
      // 統合されたapp構造の確認
      final appDir = Directory(path.join(projectRoot, 'lib', 'app'));
      expect(appDir.existsSync(), isTrue, 
        reason: 'lib/app ディレクトリが作成されている必要があります');
      
      // アプリケーションファイルの確認
      final appFile = File(path.join(appDir.path, 'app.dart'));
      expect(appFile.existsSync(), isTrue,
        reason: 'app.dart が存在する必要があります');
    });
    
    test('should have integrated environment config', () async {
      // 統合された環境設定の確認
      final envConfigFile = File(path.join(projectRoot, 'lib', 'core', 'config', 'env_config.dart'));
      expect(envConfigFile.existsSync(), isTrue);
      
      final content = await envConfigFile.readAsString();
      
      // Gemini AI設定の統合確認
      expect(content, contains('geminiApiKey'),
        reason: 'Gemini API設定が統合されている必要があります');
      
      // ウェブ検索設定の統合確認  
      expect(content, contains('webSearchApiKey'),
        reason: 'ウェブ検索API設定が統合されている必要があります');
      
      // 設定検証メソッドの確認
      expect(content, contains('isGeminiConfigured'),
        reason: '設定検証メソッドが統合されている必要があります');
    });
    
    test('should have integrated main.dart', () async {
      // メインファイルの統合確認
      final mainFile = File(path.join(projectRoot, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      
      final content = await mainFile.readAsString();
      
      // Firebase + Riverpod統合の確認
      expect(content, contains('ProviderScope'),
        reason: 'Riverpod統合が確認される必要があります');
      
      expect(content, contains('Firebase.initializeApp'),
        reason: 'Firebase初期化が含まれている必要があります');
      
      expect(content, contains('EnvConfig.load'),
        reason: '環境設定読み込みが含まれている必要があります');
      
      // 統合されたアプリケーションの使用確認
      expect(content, contains('FatGramApp'),
        reason: '統合されたFatGramAppが使用されている必要があります');
    });
    
    test('should have integrated auth provider', () async {
      // 認証プロバイダーの統合確認
      final authProviderFile = File(path.join(
        projectRoot, 'lib', 'app', 'features', 'auth', 
        'presentation', 'providers', 'auth_provider.dart'
      ));
      expect(authProviderFile.existsSync(), isTrue);
      
      final content = await authProviderFile.readAsString();
      
      // lib版のエンティティ使用確認
      expect(content, contains('UserModel'),
        reason: 'lib版のUserModelが使用されている必要があります');
      
      // DIコンテナ統合確認
      expect(content, contains('getIt<UserRepository>'),
        reason: 'lib版のDIコンテナが使用されている必要があります');
    });
    
    test('should preserve lib version core functionality', () async {
      // lib版のコア機能が保持されていることを確認
      final coreDirectories = [
        'core/config',
        'core/error', 
        'core/security',
        'core/storage',
        'core/services',
      ];
      
      for (final dirPath in coreDirectories) {
        final dir = Directory(path.join(projectRoot, 'lib', dirPath));
        expect(dir.existsSync(), isTrue,
          reason: 'lib版の$dirPath が保持されている必要があります');
      }
    });
    
    test('should preserve lib version data layer', () async {
      // lib版のデータ層が保持されていることを確認
      final dataDirectories = [
        'data/datasources',
        'data/repositories', 
        'data/sync',
      ];
      
      for (final dirPath in dataDirectories) {
        final dir = Directory(path.join(projectRoot, 'lib', dirPath));
        expect(dir.existsSync(), isTrue,
          reason: 'lib版の$dirPath が保持されている必要があります');
      }
    });
    
    test('should preserve lib version domain layer', () async {
      // lib版のドメイン層が保持されていることを確認
      final domainDirectories = [
        'domain/entities',
        'domain/models',
        'domain/repositories',
        'domain/services',
      ];
      
      for (final dirPath in domainDirectories) {
        final dir = Directory(path.join(projectRoot, 'lib', dirPath));
        expect(dir.existsSync(), isTrue,
          reason: 'lib版の$dirPath が保持されている必要があります');
      }
    });
    
    test('should preserve lib version presentation layer', () async {
      // lib版のプレゼンテーション層が保持されていることを確認
      final presentationDirectories = [
        'presentation/screens',
        'presentation/widgets',
      ];
      
      for (final dirPath in presentationDirectories) {
        final dir = Directory(path.join(projectRoot, 'lib', dirPath));
        expect(dir.existsSync(), isTrue,
          reason: 'lib版の$dirPath が保持されている必要があります');
      }
    });
    
    test('should have integrated features successfully', () async {
      // mobile版の機能が適切に統合されていることを確認
      
      // アプリケーション機能の統合確認
      final featuresDir = Directory(path.join(projectRoot, 'lib', 'app', 'features'));
      expect(featuresDir.existsSync(), isTrue,
        reason: 'featuresディレクトリが統合されている必要があります');
      
      // 認証機能の統合確認
      final authDir = Directory(path.join(featuresDir.path, 'auth'));
      expect(authDir.existsSync(), isTrue,
        reason: '認証機能が統合されている必要があります');
    });
  });
  
  group('Integration Quality Checks', () {
    test('should not have duplicate import conflicts', () async {
      // import文の競合がないことを確認
      final dartFiles = await _getAllDartFiles();
      final conflictingImports = <String>[];
      
      for (final file in dartFiles) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        
        final imports = lines.where((line) => 
          line.trim().startsWith('import') && 
          line.contains('.dart')).toList();
        
        // 同じライブラリへの複数インポートをチェック
        final importSet = <String>{};
        for (final import in imports) {
          if (importSet.contains(import)) {
            conflictingImports.add('${file.path}: duplicate $import');
          }
          importSet.add(import);
        }
      }
      
      expect(conflictingImports, isEmpty,
        reason: 'import文の重複があります: ${conflictingImports.join(', ')}');
    });
    
    test('should have consistent naming patterns', () async {
      // 統合後の命名規則が一貫していることを確認
      final dartFiles = await _getAllDartFiles();
      final namingIssues = <String>[];
      
      for (final file in dartFiles) {
        final filename = path.basename(file.path);
        
        // スネークケースファイル名の確認
        if (!RegExp(r'^[a-z_][a-z0-9_]*\.dart$').hasMatch(filename)) {
          namingIssues.add('${file.path}: ファイル名がスネークケースではありません');
        }
      }
      
      expect(namingIssues, isEmpty,
        reason: '命名規則の問題があります: ${namingIssues.join(', ')}');
    });
  });
}

/// すべてのDartファイルを取得
Future<List<File>> _getAllDartFiles() async {
  const projectRoot = '/mnt/c/Users/seekf/Desktop/fatgram';
  final projectDir = Directory(projectRoot);
  final dartFiles = <File>[];
  
  await for (final entity in projectDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // ビルド生成ディレクトリを除外
      if (!entity.path.contains('/build/') && 
          !entity.path.contains('/.dart_tool/') &&
          !entity.path.contains('/android/') &&
          !entity.path.contains('/ios/') &&
          !entity.path.contains('/macos/')) {
        dartFiles.add(entity);
      }
    }
  }
  
  return dartFiles;
}