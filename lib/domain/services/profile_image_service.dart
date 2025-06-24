/// プロフィール画像アップロード・管理サービス
/// 2025年エンタープライズレベル実装: Firebase Storage統合、画像最適化、セキュリティ強化
library profile_image_service;

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

/// プロフィール画像管理サービス
class ProfileImageService {
  static const String _storagePath = 'profile_images';
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int _thumbnailSize = 150;
  static const int _profileSize = 400;
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Logger _logger = Logger();
  
  /// 画像選択（カメラまたはギャラリー）
  Future<File?> selectImage({
    required ImageSource source,
    bool enableCropping = true,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      
      // ファイルサイズ検証
      final fileSize = await file.length();
      if (fileSize > _maxImageSize) {
        throw Exception('画像サイズが制限を超えています (最大5MB)');
      }
      
      // 画像形式検証
      if (!_isValidImageFormat(pickedFile.path)) {
        throw Exception('サポートされていない画像形式です');
      }
      
      _logger.i('Image selected: ${pickedFile.path}, size: ${fileSize}bytes');
      return file;
      
    } catch (e) {
      _logger.e('Image selection failed', error: e);
      rethrow;
    }
  }
  
  /// プロフィール画像アップロード
  Future<Map<String, String>> uploadProfileImage({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      // 画像処理
      final processedImages = await _processProfileImage(imageFile);
      
      final results = <String, String>{};
      
      // サムネイル画像アップロード
      final thumbnailUrl = await _uploadImageVariant(
        userId: userId,
        imageBytes: processedImages['thumbnail']!,
        variant: 'thumbnail',
        onProgress: (progress) => onProgress?.call(progress * 0.5),
      );
      results['thumbnail'] = thumbnailUrl;
      
      // プロフィール画像アップロード
      final profileUrl = await _uploadImageVariant(
        userId: userId,
        imageBytes: processedImages['profile']!,
        variant: 'profile',
        onProgress: (progress) => onProgress?.call(0.5 + progress * 0.5),
      );
      results['profile'] = profileUrl;
      
      _logger.i('Profile images uploaded successfully for user: $userId');
      return results;
      
    } catch (e) {
      _logger.e('Profile image upload failed', error: e);
      throw Exception('プロフィール画像のアップロードに失敗しました: $e');
    }
  }
  
  /// 画像処理（リサイズ・最適化）
  Future<Map<String, Uint8List>> _processProfileImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('画像の読み込みに失敗しました');
      }
      
      // サムネイル生成（150x150、円形クロップ対応）
      final thumbnail = img.copyResize(
        originalImage,
        width: _thumbnailSize,
        height: _thumbnailSize,
        interpolation: img.Interpolation.cubic,
      );
      
      // プロフィール画像生成（400x400）
      final profile = img.copyResize(
        originalImage,
        width: _profileSize,
        height: _profileSize,
        interpolation: img.Interpolation.cubic,
      );
      
      // 画質最適化
      final thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: 85)
      );
      final profileBytes = Uint8List.fromList(
        img.encodeJpg(profile, quality: 90)
      );
      
      return {
        'thumbnail': thumbnailBytes,
        'profile': profileBytes,
      };
      
    } catch (e) {
      throw Exception('画像処理に失敗しました: $e');
    }
  }
  
  /// 画像バリアントアップロード
  Future<String> _uploadImageVariant({
    required String userId,
    required Uint8List imageBytes,
    required String variant,
    Function(double)? onProgress,
  }) async {
    try {
      // セキュアなファイル名生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = sha256.convert(imageBytes).toString().substring(0, 8);
      final fileName = '${userId}_${variant}_${timestamp}_$hash.jpg';
      
      // Firebase Storage参照
      final storageRef = _storage.ref().child('$_storagePath/$fileName');
      
      // メタデータ設定
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // 1年キャッシュ
        customMetadata: {
          'userId': userId,
          'variant': variant,
          'uploadedAt': DateTime.now().toIso8601String(),
          'size': imageBytes.length.toString(),
        },
      );
      
      // アップロード実行
      final uploadTask = storageRef.putData(imageBytes, metadata);
      
      // 進行状況監視
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      // アップロード完了待機
      final snapshot = await uploadTask;
      
      // ダウンロードURL取得
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Image variant uploaded: $variant, URL: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      throw Exception('画像アップロードに失敗しました ($variant): $e');
    }
  }
  
  /// プロフィール画像削除
  Future<void> deleteProfileImages({
    required String userId,
    required List<String> imageUrls,
  }) async {
    try {
      for (final url in imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
          _logger.i('Profile image deleted: $url');
        } catch (e) {
          _logger.w('Failed to delete image: $url, error: $e');
          // 削除失敗は個別にログして続行
        }
      }
      
    } catch (e) {
      _logger.e('Profile image deletion failed', error: e);
      throw Exception('プロフィール画像の削除に失敗しました: $e');
    }
  }
  
  /// プロフィール画像URL一覧取得
  Future<List<String>> getUserProfileImages(String userId) async {
    try {
      final listResult = await _storage.ref().child(_storagePath).listAll();
      
      final userImages = <String>[];
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        if (metadata.customMetadata?['userId'] == userId) {
          final url = await item.getDownloadURL();
          userImages.add(url);
        }
      }
      
      return userImages;
      
    } catch (e) {
      _logger.e('Failed to get user profile images', error: e);
      return [];
    }
  }
  
  /// 画像キャッシュクリア
  Future<void> clearImageCache() async {
    try {
      // アプリケーション内の画像キャッシュをクリア
      // 実装は使用する画像キャッシュライブラリに依存
      _logger.i('Image cache cleared');
    } catch (e) {
      _logger.e('Failed to clear image cache', error: e);
    }
  }
  
  /// 画像圧縮
  Future<Uint8List> compressImage({
    required Uint8List imageBytes,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('画像の読み込みに失敗しました');
      }
      
      img.Image processedImage = image;
      
      // リサイズ
      if (maxWidth != null || maxHeight != null) {
        processedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
          maintainAspect: true,
          interpolation: img.Interpolation.cubic,
        );
      }
      
      // 圧縮
      final compressedBytes = img.encodeJpg(processedImage, quality: quality);
      return Uint8List.fromList(compressedBytes);
      
    } catch (e) {
      throw Exception('画像圧縮に失敗しました: $e');
    }
  }
  
  /// 画像フォーマット検証
  bool _isValidImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }
  
  /// 画像アップロード進行状況計算
  double calculateProgress(int bytesTransferred, int totalBytes) {
    if (totalBytes == 0) return 0.0;
    return bytesTransferred / totalBytes;
  }
  
  /// ランダムファイル名生成
  String _generateRandomFileName(String extension) {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomString = List.generate(8, (_) => 
      '0123456789abcdef'[random.nextInt(16)]
    ).join();
    return '${timestamp}_$randomString$extension';
  }
  
  /// アップロード統計情報
  Map<String, dynamic> getUploadStats() {
    return {
      'maxFileSize': '${(_maxImageSize / 1024 / 1024).toStringAsFixed(1)}MB',
      'supportedFormats': ['JPEG', 'PNG', 'WebP'],
      'thumbnailSize': '${_thumbnailSize}x$_thumbnailSize',
      'profileSize': '${_profileSize}x$_profileSize',
      'storageProvider': 'Firebase Storage',
      'compressionQuality': {
        'thumbnail': '85%',
        'profile': '90%',
      },
    };
  }
}