import 'package:flutter/foundation.dart';

/// データ競合の解決戦略
enum ConflictResolutionStrategy {
  /// 最新のタイムスタンプを優先
  timestampPriority,
  /// ローカルデータを優先
  localPriority,
  /// リモートデータを優先
  remotePriority,
  /// マージ戦略
  merge,
  /// 手動解決
  manual,
}

/// データ競合の解決を担当するクラス
class ConflictResolver {
  final ConflictResolutionStrategy defaultStrategy;

  ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.timestampPriority,
  });

  /// データ競合を解決
  Map<String, dynamic> resolveConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData, {
    ConflictResolutionStrategy? strategy,
  }) {
    final resolveStrategy = strategy ?? defaultStrategy;

    if (kDebugMode) {
      print('ConflictResolver: Resolving conflict with strategy: $resolveStrategy');
      print('Local data ID: ${localData['id']}');
      print('Remote data ID: ${remoteData['id']}');
    }

    try {
      switch (resolveStrategy) {
        case ConflictResolutionStrategy.timestampPriority:
          return _resolveByTimestamp(localData, remoteData);

        case ConflictResolutionStrategy.localPriority:
          return _resolveWithLocalPriority(localData, remoteData);

        case ConflictResolutionStrategy.remotePriority:
          return _resolveWithRemotePriority(localData, remoteData);

        case ConflictResolutionStrategy.merge:
          return _mergeData(localData, remoteData);

        case ConflictResolutionStrategy.manual:
          throw Exception('Manual resolution required');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ConflictResolver: Error resolving conflict: $e');
      }
      rethrow;
    }
  }

  /// タイムスタンプベースの解決
  Map<String, dynamic> _resolveByTimestamp(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final localTimestamp = _parseTimestamp(localData['updatedAt']);
    final remoteTimestamp = _parseTimestamp(remoteData['updatedAt']);

    if (localTimestamp == null && remoteTimestamp == null) {
      // タイムスタンプがない場合はリモートを優先
      return _addResolutionMetadata(remoteData, 'remote_fallback');
    }

    if (localTimestamp == null) {
      return _addResolutionMetadata(remoteData, 'remote_no_local_timestamp');
    }

    if (remoteTimestamp == null) {
      return _addResolutionMetadata(localData, 'local_no_remote_timestamp');
    }

    if (remoteTimestamp.isAfter(localTimestamp)) {
      return _addResolutionMetadata(remoteData, 'remote_newer');
    } else if (localTimestamp.isAfter(remoteTimestamp)) {
      return _addResolutionMetadata(localData, 'local_newer');
    } else {
      // 同じタイムスタンプの場合はデータをマージ
      return _addResolutionMetadata(_mergeData(localData, remoteData), 'merged_same_timestamp');
    }
  }

  /// ローカル優先の解決
  Map<String, dynamic> _resolveWithLocalPriority(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // ローカルが削除されている場合は特別処理
    if (localData['isDeleted'] == true) {
      return _addResolutionMetadata(localData, 'local_deleted');
    }

    return _addResolutionMetadata(localData, 'local_priority');
  }

  /// リモート優先の解決
  Map<String, dynamic> _resolveWithRemotePriority(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // リモートが削除されている場合は特別処理
    if (remoteData['isDeleted'] == true) {
      return _addResolutionMetadata(remoteData, 'remote_deleted');
    }

    return _addResolutionMetadata(remoteData, 'remote_priority');
  }

  /// データのマージ
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);

    // 特定のフィールドはローカルを優先
    const localPriorityFields = ['notes', 'tags', 'customData'];
    for (final field in localPriorityFields) {
      if (localData.containsKey(field) && localData[field] != null) {
        merged[field] = localData[field];
      }
    }

    // 数値フィールドは最大値を採用
    const numericMaxFields = ['calories', 'duration'];
    for (final field in numericMaxFields) {
      if (localData[field] != null && remoteData[field] != null) {
        final localValue = _parseNumber(localData[field]);
        final remoteValue = _parseNumber(remoteData[field]);
        if (localValue != null && remoteValue != null) {
          merged[field] = localValue > remoteValue ? localValue : remoteValue;
        }
      }
    }

    // 最新のタイムスタンプを使用
    final localTimestamp = _parseTimestamp(localData['updatedAt']);
    final remoteTimestamp = _parseTimestamp(remoteData['updatedAt']);
    if (localTimestamp != null && remoteTimestamp != null) {
      merged['updatedAt'] = localTimestamp.isAfter(remoteTimestamp)
          ? localData['updatedAt']
          : remoteData['updatedAt'];
    }

    return _addResolutionMetadata(merged, 'merged');
  }

  /// 競合検出
  bool hasConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // IDが異なる場合は競合ではない
    if (localData['id'] != remoteData['id']) {
      return false;
    }

    // 両方のタイムスタンプを確認
    final localTimestamp = _parseTimestamp(localData['updatedAt']);
    final remoteTimestamp = _parseTimestamp(remoteData['updatedAt']);

    // タイムスタンプが同じ場合は内容を比較
    if (localTimestamp != null &&
        remoteTimestamp != null &&
        localTimestamp == remoteTimestamp) {
      return _hasContentDifference(localData, remoteData);
    }

    // タイムスタンプが異なるがどちらも最近更新されている場合は競合
    final now = DateTime.now();
    final recentThreshold = now.subtract(const Duration(minutes: 5));

    if (localTimestamp != null &&
        remoteTimestamp != null &&
        localTimestamp.isAfter(recentThreshold) &&
        remoteTimestamp.isAfter(recentThreshold)) {
      return true;
    }

    return false;
  }

  /// 内容の差異をチェック
  bool _hasContentDifference(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // 重要なフィールドを比較
    const importantFields = ['name', 'type', 'calories', 'duration', 'heartRate'];

    for (final field in importantFields) {
      if (localData[field] != remoteData[field]) {
        return true;
      }
    }

    return false;
  }

  /// 競合解決の提案を生成
  List<ConflictResolution> generateResolutionOptions(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final options = <ConflictResolution>[];

    // タイムスタンプベースの解決
    final timestampResolution = _resolveByTimestamp(localData, remoteData);
    options.add(ConflictResolution(
      strategy: ConflictResolutionStrategy.timestampPriority,
      resolvedData: timestampResolution,
      confidence: _calculateConfidence(timestampResolution, localData, remoteData),
      description: 'Use most recently updated version',
    ));

    // マージ解決
    final mergedData = _mergeData(localData, remoteData);
    options.add(ConflictResolution(
      strategy: ConflictResolutionStrategy.merge,
      resolvedData: mergedData,
      confidence: 0.8,
      description: 'Merge both versions intelligently',
    ));

    // ローカル優先
    options.add(ConflictResolution(
      strategy: ConflictResolutionStrategy.localPriority,
      resolvedData: _addResolutionMetadata(localData, 'local_priority'),
      confidence: 0.6,
      description: 'Keep local version',
    ));

    // リモート優先
    options.add(ConflictResolution(
      strategy: ConflictResolutionStrategy.remotePriority,
      resolvedData: _addResolutionMetadata(remoteData, 'remote_priority'),
      confidence: 0.6,
      description: 'Use remote version',
    ));

    // 信頼度でソート
    options.sort((a, b) => b.confidence.compareTo(a.confidence));

    return options;
  }

  /// 解決の信頼度を計算
  double _calculateConfidence(
    Map<String, dynamic> resolvedData,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    double confidence = 0.5;

    // タイムスタンプの差が大きいほど信頼度が高い
    final localTimestamp = _parseTimestamp(localData['updatedAt']);
    final remoteTimestamp = _parseTimestamp(remoteData['updatedAt']);

    if (localTimestamp != null && remoteTimestamp != null) {
      final timeDiff = (localTimestamp.difference(remoteTimestamp)).abs();
      if (timeDiff.inMinutes > 60) {
        confidence += 0.3;
      } else if (timeDiff.inMinutes > 10) {
        confidence += 0.2;
      } else if (timeDiff.inMinutes > 1) {
        confidence += 0.1;
      }
    }

    // データの完全性をチェック
    final resolvedFields = resolvedData.keys.where((key) => resolvedData[key] != null).length;
    final totalFields = resolvedData.keys.length;
    if (totalFields > 0) {
      confidence += (resolvedFields / totalFields) * 0.2;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// 解決メタデータを追加
  Map<String, dynamic> _addResolutionMetadata(
    Map<String, dynamic> data,
    String resolutionType,
  ) {
    final result = Map<String, dynamic>.from(data);
    result['_conflictResolution'] = {
      'type': resolutionType,
      'timestamp': DateTime.now().toIso8601String(),
      'resolver': 'ConflictResolver',
    };
    return result;
  }

  /// タイムスタンプをパース
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ConflictResolver: Error parsing timestamp $timestamp: $e');
      }
      return null;
    }
  }

  /// 数値をパース
  double? _parseNumber(dynamic value) {
    if (value == null) return null;

    try {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// バッチで競合を解決
  List<Map<String, dynamic>> resolveBatchConflicts(
    List<ConflictPair> conflicts, {
    ConflictResolutionStrategy? strategy,
  }) {
    final results = <Map<String, dynamic>>[];

    for (final conflict in conflicts) {
      try {
        final resolved = resolveConflict(
          conflict.localData,
          conflict.remoteData,
          strategy: strategy,
        );
        results.add(resolved);
      } catch (e) {
        if (kDebugMode) {
          print('ConflictResolver: Error resolving conflict for ${conflict.localData['id']}: $e');
        }
        // エラーの場合はタイムスタンプベースで再試行
        try {
          final fallback = _resolveByTimestamp(conflict.localData, conflict.remoteData);
          results.add(fallback);
        } catch (e2) {
          // 最後の手段としてリモートデータを使用
          results.add(_addResolutionMetadata(conflict.remoteData, 'fallback_remote'));
        }
      }
    }

    return results;
  }
}

/// 競合ペア
class ConflictPair {
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;

  ConflictPair({
    required this.localData,
    required this.remoteData,
  });
}

/// 競合解決オプション
class ConflictResolution {
  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic> resolvedData;
  final double confidence;
  final String description;

  ConflictResolution({
    required this.strategy,
    required this.resolvedData,
    required this.confidence,
    required this.description,
  });
}