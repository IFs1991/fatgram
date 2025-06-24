import 'dart:io';
import 'dart:convert';

/// GitHub Actionsワークフローファイルの妥当性をチェックするスクリプト
void main(List<String> args) async {
  print('🔍 Validating GitHub Actions workflows...\n');

  final workflowDir = Directory('.github/workflows');

  if (!workflowDir.existsSync()) {
    print('❌ .github/workflows directory not found');
    exit(1);
  }

  final workflowFiles = workflowDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'))
      .toList();

  if (workflowFiles.isEmpty) {
    print('❌ No workflow files found');
    exit(1);
  }

  var hasErrors = false;

  for (final file in workflowFiles) {
    final fileName = file.path.split('/').last;
    print('📄 Validating $fileName...');

    try {
      final content = await file.readAsString();
      final validation = validateWorkflow(fileName, content);

      if (validation.isValid) {
        print('✅ $fileName is valid');
        if (validation.warnings.isNotEmpty) {
          print('⚠️  Warnings:');
          for (final warning in validation.warnings) {
            print('   - $warning');
          }
        }
      } else {
        print('❌ $fileName has errors:');
        for (final error in validation.errors) {
          print('   - $error');
        }
        hasErrors = true;
      }

      print('');
    } catch (e) {
      print('❌ Error reading $fileName: $e\n');
      hasErrors = true;
    }
  }

  if (hasErrors) {
    print('❌ Some workflow files have errors');
    exit(1);
  } else {
    print('✅ All workflow files are valid');
  }
}

class WorkflowValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  WorkflowValidation({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

WorkflowValidation validateWorkflow(String fileName, String content) {
  final errors = <String>[];
  final warnings = <String>[];

  // 基本構造のチェック
  if (!content.contains('name:')) {
    errors.add('Missing workflow name');
  }

  if (!content.contains('on:')) {
    errors.add('Missing trigger configuration');
  }

  if (!content.contains('jobs:')) {
    errors.add('Missing jobs configuration');
  }

  // ファイル固有のチェック
  switch (fileName) {
    case 'test.yml':
      _validateTestWorkflow(content, errors, warnings);
      break;
    case 'build.yml':
      _validateBuildWorkflow(content, errors, warnings);
      break;
  }

  // 共通チェック
  _validateCommonPatterns(content, errors, warnings);

  return WorkflowValidation(
    isValid: errors.isEmpty,
    errors: errors,
    warnings: warnings,
  );
}

void _validateTestWorkflow(String content, List<String> errors, List<String> warnings) {
  if (!content.contains('flutter test')) {
    errors.add('Test workflow should include flutter test command');
  }

  if (!content.contains('flutter analyze')) {
    warnings.add('Consider adding flutter analyze step');
  }

  if (!content.contains('coverage')) {
    warnings.add('Consider adding test coverage reporting');
  }

  if (!content.contains('matrix:')) {
    warnings.add('Consider testing with multiple Flutter versions');
  }
}

void _validateBuildWorkflow(String content, List<String> errors, List<String> warnings) {
  if (!content.contains('flutter build')) {
    errors.add('Build workflow should include flutter build command');
  }

  if (!content.contains('upload-artifact')) {
    warnings.add('Consider uploading build artifacts');
  }

  if (!content.contains('secrets.')) {
    warnings.add('Production builds should use GitHub secrets for sensitive data');
  }
}

void _validateCommonPatterns(String content, List<String> errors, List<String> warnings) {
  // Flutter アクションの使用チェック
  if (!content.contains('subosito/flutter-action')) {
    warnings.add('Consider using subosito/flutter-action for Flutter setup');
  }

  // Java セットアップチェック
  if (content.contains('flutter build') && !content.contains('setup-java')) {
    warnings.add('Android builds require Java setup');
  }

  // Flutter バージョンの固定チェック
  if (content.contains('flutter-version:') && content.contains('latest')) {
    warnings.add('Consider pinning Flutter version instead of using latest');
  }

  // セキュリティチェック
  if (content.contains('API_KEY') && !content.contains('secrets.')) {
    errors.add('API keys should be stored in GitHub secrets');
  }

  // キャッシュの使用チェック
  if (!content.contains('cache:')) {
    warnings.add('Consider enabling caching for faster builds');
  }
}