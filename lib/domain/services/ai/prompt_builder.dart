import 'package:fatgram/domain/services/ai/context_analyzer.dart';
import 'package:fatgram/core/error/exceptions.dart';

// プロンプトテンプレートの定義
enum PromptTemplate {
  fitnessChat,
  workoutRecommendation,
  nutritionAdvice,
  goalSetting,
  motivationalMessage,
}

// カスタムプロンプトテンプレート
class CustomPromptTemplate {
  final String id;
  final String name;
  final String description;
  final String template;
  final List<String> variables;
  final Map<String, dynamic>? metadata;

  const CustomPromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.variables,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPromptTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// 生成されたプロンプト
class GeneratedPrompt {
  final String systemPrompt;
  final String userPrompt;
  final Map<String, dynamic> contextData;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;
  final double? qualityScore;

  const GeneratedPrompt({
    required this.systemPrompt,
    required this.userPrompt,
    required this.contextData,
    required this.metadata,
    required this.generatedAt,
    this.qualityScore,
  });
}

// プロンプト品質評価
class PromptQuality {
  final double score; // 0.0 - 1.0
  final Map<String, double> criteria;
  final List<String> suggestions;
  final DateTime evaluatedAt;

  const PromptQuality({
    required this.score,
    required this.criteria,
    required this.suggestions,
    required this.evaluatedAt,
  });
}

// 改善提案
enum ImprovementType {
  contextEnrichment,
  specificity,
  clarity,
  relevance,
  structure,
}

class PromptImprovement {
  final ImprovementType type;
  final String description;
  final String suggestion;
  final double impact; // 予想される改善度 0.0 - 1.0

  const PromptImprovement({
    required this.type,
    required this.description,
    required this.suggestion,
    required this.impact,
  });
}

// テンプレート使用統計
class TemplateUsageStats {
  final int usageCount;
  final DateTime? lastUsed;
  final double averageQualityScore;
  final Map<String, int> contextTypes;

  const TemplateUsageStats({
    required this.usageCount,
    this.lastUsed,
    required this.averageQualityScore,
    required this.contextTypes,
  });
}

// プロンプトビルダーサービス
class PromptBuilder {
  final ContextAnalyzer contextAnalyzer;
  final Map<String, CustomPromptTemplate> _customTemplates = {};
  final Map<String, TemplateUsageStats> _usageStats = {};
  final Map<String, List<double>> _qualityHistory = {};

  // 標準テンプレート定義
  static const Map<PromptTemplate, Map<String, String>> _defaultTemplates = {
    PromptTemplate.fitnessChat: {
      'system': '''You are an expert fitness assistant in the FatGram app, specializing in personalized fitness advice and fat loss guidance.

User Profile:
- Fitness Level: {fitness_level}
- Primary Goals: {primary_goals}
- Age Group: {age_group}
- Gender: {gender}
- Available Time: {available_time} minutes

Context Analysis:
{context_summary}

Key Metrics:
{key_metrics}

Recommendations:
{recommendations}

Instructions:
- Provide personalized, actionable advice
- Consider the user's fitness level and goals
- Be encouraging and supportive
- Focus on sustainable lifestyle changes
- Reference their specific metrics when relevant
- Suggest concrete next steps''',
      'user': '''User Message: {user_message}

Conversation Tone: {conversation_tone}

Please provide a helpful, personalized response based on the user's profile and current context.''',
    },
    PromptTemplate.workoutRecommendation: {
      'system': '''You are a professional workout specialist creating personalized exercise programs.

User Profile:
- Fitness Level: {fitness_level}
- Primary Goals: {primary_goals}
- Available Time: {available_time} minutes
- Equipment: {equipment}
- Preferred Workout Types: {preferred_workouts}

Context Analysis:
{context_summary}

Instructions:
- Create specific, detailed workout recommendations
- Consider available equipment and time constraints
- Match intensity to fitness level
- Include warm-up and cool-down suggestions
- Provide exercise modifications for different levels
- Focus on progressive overload principles''',
      'user': '''Workout Request:
- Target Muscle Groups: {target_muscle_groups}
- Workout Type: {workout_split}
- Session Duration: {available_time} minutes

Please create a detailed workout plan with specific exercises, sets, reps, and rest periods.''',
    },
    PromptTemplate.nutritionAdvice: {
      'system': '''You are a certified nutrition specialist providing personalized dietary guidance.

User Profile:
- Primary Goals: {primary_goals}
- Dietary Restrictions: {dietary_restrictions}
- Meal Preferences: {meal_preferences}
- Fitness Level: {fitness_level}

Context Analysis:
{context_summary}

Instructions:
- Provide specific, actionable nutrition advice
- Consider dietary restrictions and preferences
- Focus on sustainable eating habits
- Include practical meal planning tips
- Reference caloric and macronutrient targets
- Suggest meal timing around workouts''',
      'user': '''Nutrition Request:
- Meal Type: {meal_type}
- Calorie Target: {calorie_target}
- Special Requirements: {special_requirements}

Please provide specific nutrition recommendations and meal suggestions.''',
    },
    PromptTemplate.goalSetting: {
      'system': '''You are an expert goal-setting coach specialized in fitness and health objectives.

User Profile:
- Current Fitness Level: {fitness_level}
- Primary Goals: {primary_goals}
- Activity History: {activity_summary}

Context Analysis:
{context_summary}

Performance Metrics:
{key_metrics}

Instructions:
- Set SMART goals (Specific, Measurable, Achievable, Relevant, Time-bound)
- Consider current fitness level and activity patterns
- Provide milestone checkpoints
- Include both outcome and process goals
- Suggest tracking methods
- Account for potential obstacles''',
      'user': '''Goal Setting Request:
- Time Frame: {time_frame}
- Focus Area: {focus_area}
- Current Performance: {current_metrics}

Please suggest specific, achievable goals with clear milestones and tracking methods.''',
    },
    PromptTemplate.motivationalMessage: {
      'system': '''You are a motivational fitness coach providing encouragement and support.

User Context:
{context_summary}

Recent Activity:
{activity_summary}

Progress Indicators:
{progress_metrics}

Instructions:
- Be genuinely encouraging and positive
- Reference specific achievements and progress
- Provide actionable motivation
- Address potential challenges
- Celebrate small wins
- Inspire continued commitment''',
      'user': '''Motivational Request:
- Current Mood: {user_mood}
- Recent Challenges: {recent_challenges}
- Upcoming Goals: {upcoming_goals}

Please provide personalized motivation and encouragement.''',
    },
  };

  PromptBuilder({
    required this.contextAnalyzer,
  });

  // 利用可能なテンプレート一覧
  List<PromptTemplate> get availableTemplates => PromptTemplate.values;

  // コンテキスト分析
  Future<ContextAnalysis> analyzeContext(UserContext userContext) async {
    return await contextAnalyzer.analyzeUserContext(userContext);
  }

  Future<ContextAnalysis> analyzeActivityContext(List<Activity> activities) async {
    return await contextAnalyzer.analyzeActivityData(activities);
  }

  // プロンプト生成
  Future<GeneratedPrompt> buildPrompt({
    required PromptTemplate template,
    required UserContext userContext,
    List<Activity>? activityHistory,
    Map<String, dynamic>? additionalContext,
    bool fallbackOnError = false,
  }) async {
    try {
      final startTime = DateTime.now();

      // コンテキスト分析
      final userAnalysis = await contextAnalyzer.analyzeUserContext(userContext);

      ContextAnalysis? activityAnalysis;
      if (activityHistory != null && activityHistory.isNotEmpty) {
        activityAnalysis = await contextAnalyzer.analyzeActivityData(activityHistory);
      }

      // テンプレート取得
      final templateData = _getTemplateData(template);

      // プロンプト変数準備
      final variables = _prepareVariables(
        userContext: userContext,
        userAnalysis: userAnalysis,
        activityAnalysis: activityAnalysis,
        additionalContext: additionalContext ?? {},
      );

      // プロンプト生成
      final systemPrompt = _interpolateTemplate(templateData['system']!, variables);
      final userPrompt = _interpolateTemplate(templateData['user']!, variables);

      // メタデータ作成
      final templateName = _getTemplateMetadataName(template);
      final metadata = <String, dynamic>{
        'template': templateName,
        'generation_time': DateTime.now().difference(startTime).inMilliseconds,
        'user_fitness_level': userContext.fitnessLevel?.toString().split('.').last,
        'has_activity_data': activityHistory != null && activityHistory.isNotEmpty,
        'context_priority': userAnalysis.priority.toString().split('.').last,
        'fallback_used': false,
      };

      // 追加コンテキストをメタデータに追加
      if (additionalContext != null) {
        metadata.addAll(additionalContext);
      }

      final prompt = GeneratedPrompt(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        contextData: _createContextData(userAnalysis, activityAnalysis),
        metadata: metadata,
        generatedAt: DateTime.now(),
      );

      // 使用統計を更新
      _updateUsageStats(template, prompt);

      return prompt;

    } catch (e) {
      if (fallbackOnError) {
        return _createFallbackPrompt(template, userContext, e.toString());
      }

      // 必須コンテキストの検証
      _validateRequiredContext(template, userContext);

      rethrow;
    }
  }

  // カスタムテンプレート管理
  void registerCustomTemplate(CustomPromptTemplate template) {
    // テンプレート変数の検証
    _validateTemplateVariables(template);
    _customTemplates[template.id] = template;
  }

  CustomPromptTemplate getCustomTemplate(String id) {
    final template = _customTemplates[id];
    if (template == null) {
      throw NotFoundException(message: 'Custom template not found: $id');
    }
    return template;
  }

  CustomPromptTemplate duplicateTemplate(
    String originalId, {
    required String newId,
    Map<String, dynamic>? modifications,
  }) {
    final original = getCustomTemplate(originalId);

    return CustomPromptTemplate(
      id: newId,
      name: modifications?['name'] ?? original.name,
      description: modifications?['description'] ?? original.description,
      template: modifications?['template'] ?? original.template,
      variables: original.variables,
      metadata: {
        ...?original.metadata,
        ...?modifications?['metadata'],
        'duplicated_from': originalId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // 統計情報
  Map<String, TemplateUsageStats> getTemplateUsageStats() {
    return Map.from(_usageStats);
  }

  // 品質評価
  PromptQuality evaluatePromptQuality(GeneratedPrompt prompt) {
    final criteria = <String, double>{};
    final suggestions = <String>[];

    // コンテキストの豊富さ評価
    final contextRichness = _evaluateContextRichness(prompt);
    criteria['context_richness'] = contextRichness;
    if (contextRichness < 0.7) {
      suggestions.add('Add more specific context');
    }

    // 特異性評価
    final specificity = _evaluateSpecificity(prompt);
    criteria['specificity'] = specificity;
    if (specificity < 0.6) {
      suggestions.add('Include user metrics');
    }

    // 明確性評価
    final clarity = _evaluateClarity(prompt);
    criteria['clarity'] = clarity;
    if (clarity < 0.7) {
      suggestions.add('Improve prompt structure');
    }

    // 関連性評価
    final relevance = _evaluateRelevance(prompt);
    criteria['relevance'] = relevance;
    if (relevance < 0.8) {
      suggestions.add('Better align with user goals');
    }

    // 総合スコア計算
    final totalScore = (contextRichness * 0.3 +
                       specificity * 0.25 +
                       clarity * 0.25 +
                       relevance * 0.2);

    // 全体的な提案
    if (totalScore < 0.5) {
      suggestions.add('Consider using different template');
    }

    return PromptQuality(
      score: totalScore,
      criteria: criteria,
      suggestions: suggestions,
      evaluatedAt: DateTime.now(),
    );
  }

  // 改善提案
  List<PromptImprovement> suggestImprovements(GeneratedPrompt prompt) {
    final improvements = <PromptImprovement>[];

    // コンテキスト強化
    if (_evaluateContextRichness(prompt) < 0.8) {
      improvements.add(PromptImprovement(
        type: ImprovementType.contextEnrichment,
        description: 'Add more user context',
        suggestion: 'Include recent activity data, preferences, and goals',
        impact: 0.3,
      ));
    }

    // 特異性向上
    if (_evaluateSpecificity(prompt) < 0.7) {
      improvements.add(PromptImprovement(
        type: ImprovementType.specificity,
        description: 'Make prompts more specific',
        suggestion: 'Add numerical targets, specific timeframes, and measurable outcomes',
        impact: 0.25,
      ));
    }

    // 明確性向上
    if (_evaluateClarity(prompt) < 0.8) {
      improvements.add(PromptImprovement(
        type: ImprovementType.clarity,
        description: 'Improve prompt clarity',
        suggestion: 'Use simpler language and clearer structure',
        impact: 0.2,
      ));
    }

    return improvements;
  }

  // プライベートメソッド
  Map<String, String> _getTemplateData(PromptTemplate template) {
    final templateData = _defaultTemplates[template];
    if (templateData == null) {
      throw ValidationException(message: 'Template not found: $template');
    }
    return templateData;
  }

  Map<String, String> _prepareVariables({
    required UserContext userContext,
    required ContextAnalysis userAnalysis,
    ContextAnalysis? activityAnalysis,
    required Map<String, dynamic> additionalContext,
  }) {
    final variables = <String, String>{
      // ユーザー基本情報
      'fitness_level': userContext.fitnessLevel?.toString().split('.').last ?? 'unknown',
      'age_group': userContext.age != null ? _getAgeGroup(userContext.age!) : 'unknown',
      'gender': userContext.gender?.toString().split('.').last ?? 'unknown',
      'available_time': userContext.preferences?.availableTime?.toString() ?? '30',

      // 目標情報
      'primary_goals': userContext.goals?.map((g) =>
          g.toString().split('.').last).join(', ') ?? 'general fitness',

      // 設備・設定
      'equipment': userContext.preferences?.equipment?.map((e) =>
          e.toString().split('.').last).join(', ') ?? 'none',
      'preferred_workouts': userContext.preferences?.workoutTypes?.map((w) =>
          w.toString().split('.').last).join(', ') ?? 'any',
      'dietary_restrictions': userContext.preferences?.dietaryRestrictions?.join(', ') ?? 'none',
      'meal_preferences': userContext.preferences?.mealPreferences?.join(', ') ?? 'any',

      // コンテキスト分析結果
      'context_summary': userAnalysis.summary,
      'key_metrics': userAnalysis.keyMetrics.entries.map((e) =>
          '${e.key}: ${e.value}').join(', '),
      'recommendations': userAnalysis.recommendations.join(', '),

      // アクティビティ情報
      'activity_summary': activityAnalysis?.summary ?? 'No recent activity data',
      'progress_metrics': activityAnalysis?.keyMetrics.entries.map((e) =>
          '${e.key}: ${e.value}').join(', ') ?? 'No metrics available',
    };

    // 追加コンテキストを変数に追加
    for (final entry in additionalContext.entries) {
      variables[entry.key] = entry.value.toString();
    }

    return variables;
  }

  String _interpolateTemplate(String template, Map<String, String> variables) {
    String result = template;

    for (final entry in variables.entries) {
      final placeholder = '{${entry.key}}';
      result = result.replaceAll(placeholder, entry.value);
    }

    // 未置換の変数をチェック
    final remainingPlaceholders = RegExp(r'\{([^}]+)\}').allMatches(result);
    if (remainingPlaceholders.isNotEmpty) {
      final missing = remainingPlaceholders.map((m) => m.group(1)).toSet();
      result = result.replaceAllMapped(
        RegExp(r'\{([^}]+)\}'),
        (match) => '[${match.group(1)}]', // 未置換変数をブラケットで表示
      );
    }

    return result;
  }

  Map<String, dynamic> _createContextData(
    ContextAnalysis userAnalysis,
    ContextAnalysis? activityAnalysis,
  ) {
    return {
      'user_analysis': {
        'summary': userAnalysis.summary,
        'key_metrics': userAnalysis.keyMetrics,
        'recommendations': userAnalysis.recommendations,
        'priority': userAnalysis.priority.toString(),
        'confidence': userAnalysis.confidenceScore,
      },
      if (activityAnalysis != null)
        'activity_analysis': {
          'summary': activityAnalysis.summary,
          'key_metrics': activityAnalysis.keyMetrics,
          'recommendations': activityAnalysis.recommendations,
          'priority': activityAnalysis.priority.toString(),
          'confidence': activityAnalysis.confidenceScore,
        },
    };
  }

  String _getTemplateMetadataName(PromptTemplate template) {
    switch (template) {
      case PromptTemplate.fitnessChat:
        return 'fitness_chat';
      case PromptTemplate.workoutRecommendation:
        return 'workout_recommendation';
      case PromptTemplate.nutritionAdvice:
        return 'nutrition_advice';
      case PromptTemplate.goalSetting:
        return 'goal_setting';
      case PromptTemplate.motivationalMessage:
        return 'motivational_message';
    }
  }

  void _updateUsageStats(PromptTemplate template, GeneratedPrompt prompt) {
    final templateId = _getTemplateMetadataName(template);
    final currentStats = _usageStats[templateId];

    if (currentStats == null) {
      _usageStats[templateId] = TemplateUsageStats(
        usageCount: 1,
        lastUsed: DateTime.now(),
        averageQualityScore: prompt.qualityScore ?? 0.5,
        contextTypes: {},
      );
    } else {
      _usageStats[templateId] = TemplateUsageStats(
        usageCount: currentStats.usageCount + 1,
        lastUsed: DateTime.now(),
        averageQualityScore: currentStats.averageQualityScore, // 後で品質評価後に更新
        contextTypes: currentStats.contextTypes,
      );
    }

    // 品質履歴を更新
    _qualityHistory.putIfAbsent(templateId, () => []);
    if (prompt.qualityScore != null) {
      _qualityHistory[templateId]!.add(prompt.qualityScore!);
    }
  }

  GeneratedPrompt _createFallbackPrompt(
    PromptTemplate template,
    UserContext userContext,
    String errorReason,
  ) {
    final fallbackSystem = '''You are a helpful fitness assistant in the FatGram app.

User ID: ${userContext.userId}
Fitness Level: ${userContext.fitnessLevel?.toString().split('.').last ?? 'unknown'}

Note: Operating with limited context due to analysis error.''';

    final fallbackUser = 'Please provide general fitness advice.';

    return GeneratedPrompt(
      systemPrompt: fallbackSystem,
      userPrompt: fallbackUser,
      contextData: {'error': 'Fallback mode due to context analysis failure'},
      metadata: {
        'template': _getTemplateMetadataName(template),
        'fallback_used': true,
        'error_reason': errorReason,
        'generation_time': 0,
      },
      generatedAt: DateTime.now(),
      qualityScore: 0.3, // 低品質スコア
    );
  }

  void _validateRequiredContext(PromptTemplate template, UserContext userContext) {
    switch (template) {
      case PromptTemplate.workoutRecommendation:
        if (userContext.fitnessLevel == null) {
          throw ValidationException(
            message: 'Fitness level required for workout recommendations',
          );
        }
        break;
      case PromptTemplate.nutritionAdvice:
        if (userContext.goals == null || userContext.goals!.isEmpty) {
          throw ValidationException(
            message: 'Goals required for nutrition advice',
          );
        }
        break;
      default:
        // 基本的な検証
        if (userContext.userId.isEmpty) {
          throw ValidationException(message: 'User ID is required');
        }
    }
  }

  void _validateTemplateVariables(CustomPromptTemplate template) {
    final templateText = template.template;
    final declaredVars = template.variables.toSet();

    // テンプレート内の変数を抽出
    final templateVars = RegExp(r'\{([^}]+)\}')
        .allMatches(templateText)
        .map((m) => m.group(1)!)
        .toSet();

    // 未宣言の変数をチェック
    final undeclared = templateVars.difference(declaredVars);
    if (undeclared.isNotEmpty) {
      throw ValidationException(
        message: 'Template contains undeclared variables: ${undeclared.join(', ')}',
      );
    }
  }

  // 品質評価ヘルパー
  double _evaluateContextRichness(GeneratedPrompt prompt) {
    double score = 0.0;

    // システムプロンプトの長さ
    if (prompt.systemPrompt.length > 500) score += 0.3;
    else if (prompt.systemPrompt.length > 200) score += 0.2;
    else score += 0.1;

    // コンテキストデータの豊富さ
    final contextKeys = prompt.contextData.keys.length;
    if (contextKeys > 10) score += 0.3;
    else if (contextKeys > 5) score += 0.2;
    else score += 0.1;

    // メタデータの存在
    if (prompt.metadata.isNotEmpty) score += 0.2;

    // ユーザー固有情報の存在
    if (prompt.systemPrompt.contains('Fitness Level:')) score += 0.2;

        // 空のコンテキストの場合は大幅減点
    if (prompt.contextData.isEmpty ||
        (prompt.contextData.containsKey('user_analysis') &&
         prompt.contextData['user_analysis']['summary'] == '')) {
      score *= 0.2; // 80%減点
    }

    return score.clamp(0.0, 1.0);
  }

  double _evaluateSpecificity(GeneratedPrompt prompt) {
    double score = 0.0;

    // 数値の存在
    final numberCount = RegExp(r'\d+').allMatches(prompt.systemPrompt).length;
    score += (numberCount * 0.05).clamp(0.0, 0.3);

    // 具体的なキーワード
    final specificKeywords = ['minutes', 'calories', 'sets', 'reps', 'kg', 'lbs', 'km', 'steps'];
    for (final keyword in specificKeywords) {
      if (prompt.systemPrompt.toLowerCase().contains(keyword)) {
        score += 0.1;
      }
    }

    // ユーザー固有の言及
    if (prompt.contextData.containsKey('user_analysis')) score += 0.2;

    // 空のコンテキストの場合は大幅減点
    if (prompt.contextData.isEmpty ||
        (prompt.contextData.containsKey('user_analysis') &&
         prompt.contextData['user_analysis']['summary'] == '')) {
      score *= 0.3; // 70%減点
    }

    return score.clamp(0.0, 1.0);
  }

  double _evaluateClarity(GeneratedPrompt prompt) {
    double score = 0.8; // 基準スコア

    // 長すぎるプロンプトはペナルティ
    if (prompt.systemPrompt.length > 2000) score -= 0.2;

    // 短すぎるプロンプトもペナルティ
    if (prompt.systemPrompt.length < 100) score -= 0.3;

    // 構造化されているかチェック
    final hasStructure = prompt.systemPrompt.contains(':') &&
                        prompt.systemPrompt.contains('\n');
    if (hasStructure) score += 0.2;

    return score.clamp(0.0, 1.0);
  }

  double _evaluateRelevance(GeneratedPrompt prompt) {
    double score = 0.5; // ベースライン

    // テンプレートタイプと内容の一致
    final template = prompt.metadata['template'] as String?;
    if (template != null) {
      switch (template) {
        case 'fitness_chat':
          if (prompt.systemPrompt.contains('fitness assistant')) score += 0.3;
          break;
        case 'workout_recommendation':
          if (prompt.systemPrompt.contains('workout specialist')) score += 0.3;
          break;
        case 'nutrition_advice':
          if (prompt.systemPrompt.contains('nutrition')) score += 0.3;
          break;
        case 'goal_setting':
          if (prompt.systemPrompt.contains('goal-setting coach')) score += 0.3;
          break;
      }
    }

    // ユーザーコンテキストとの関連性
    if (prompt.contextData.isNotEmpty) score += 0.2;

    return score.clamp(0.0, 1.0);
  }

  String _getAgeGroup(int age) {
    if (age < 25) return 'young adult';
    if (age < 35) return 'adult';
    if (age < 50) return 'middle-aged';
    return 'mature adult';
  }
}