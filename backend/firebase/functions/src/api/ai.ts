import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as express from 'express';
import * as cors from 'cors';
import {defineString} from 'firebase-functions/params';
import axios from 'axios';

// 環境変数
const region = defineString('REGION', {default: 'asia-northeast1'});

// Express アプリケーション
const app = express();
app.use(cors({origin: true}));
app.use(express.json({limit: '10mb'})); // 画像アップロード用に制限を拡大

// Firebase Admin初期化確認
const db = admin.firestore();

// 認証ミドルウェア
const verifyToken = async (req: any, res: any, next: any) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({error: 'Unauthorized: No token provided'});
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Token verification failed:', error);
    return res.status(401).json({error: 'Unauthorized: Invalid token'});
  }
};

// プレミアム機能チェック
const checkPremiumAccess = async (req: any, res: any, next: any) => {
  try {
    const userId = req.user.uid;

    // サブスクリプション状態を確認
    const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();

    if (!subscriptionDoc.exists) {
      return res.status(403).json({error: 'Premium subscription required'});
    }

    const subscriptionData = subscriptionDoc.data();

    if (subscriptionData?.subscriptionTier !== 'premium' || subscriptionData?.status !== 'active') {
      return res.status(403).json({error: 'Active premium subscription required'});
    }

    next();
  } catch (error) {
    console.error('Premium access check failed:', error);
    res.status(500).json({error: 'Internal server error'});
  }
};

// Gemini APIクライアント設定
const getGeminiApiKey = async (): Promise<string> => {
  try {
    const apiKeyDoc = await db.collection('api_keys').doc('gemini').get();
    if (!apiKeyDoc.exists) {
      throw new Error('Gemini API key not found');
    }
    return apiKeyDoc.data()?.key || '';
  } catch (error) {
    console.error('Failed to get Gemini API key:', error);
    throw error;
  }
};

// 食事画像分析
app.post('/analyze-meal', verifyToken, checkPremiumAccess, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {imageBase64, imageFormat = 'jpeg'} = req.body;

    if (!imageBase64) {
      return res.status(400).json({error: 'Image data is required'});
    }

    // 画像サイズチェック（10MB制限）
    const imageSizeBytes = (imageBase64.length * 3) / 4;
    if (imageSizeBytes > 10 * 1024 * 1024) {
      return res.status(400).json({error: 'Image size too large (max 10MB)'});
    }

    const apiKey = await getGeminiApiKey();

    // Gemini API リクエスト
    const geminiResponse = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [
              {
                text: `Analyze this food image and provide detailed nutritional information in JSON format:
                {
                  "detectedFoods": [
                    {
                      "name": "food name",
                      "category": "category",
                      "confidence": 0.95,
                      "portion": {
                        "amount": 150,
                        "unit": "grams"
                      }
                    }
                  ],
                  "nutritionEstimate": {
                    "totalCalories": 350,
                    "macronutrients": {
                      "carbohydrates": 45.5,
                      "protein": 25.2,
                      "fat": 12.8,
                      "fiber": 5.1
                    },
                    "micronutrients": {
                      "sodium": 450,
                      "potassium": 380,
                      "calcium": 120,
                      "iron": 2.1,
                      "vitaminC": 15.5
                    }
                  },
                  "healthScore": 8.5,
                  "recommendations": [
                    "Add more vegetables for better nutrition balance",
                    "Consider reducing sodium content"
                  ]
                }`
              },
              {
                inlineData: {
                  mimeType: `image/${imageFormat}`,
                  data: imageBase64
                }
              }
            ]
          }],
          generationConfig: {
            temperature: 0.3,
            topK: 32,
            topP: 1,
            maxOutputTokens: 2048
          }
        }
    );

    const analysisText = geminiResponse.data.candidates[0].content.parts[0].text;

    // JSONを抽出
    const jsonMatch = analysisText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Failed to parse AI response');
    }

    const analysisResult = JSON.parse(jsonMatch[0]);

    // 分析結果をFirestoreに保存
    const mealAnalysis = {
      userId,
      imageFormat,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      analysisResult,
      confidence: analysisResult.detectedFoods?.reduce((avg: number, food: any) =>
        avg + food.confidence, 0) / (analysisResult.detectedFoods?.length || 1),
      processingTime: Date.now() - req.startTime
    };

    const docRef = await db.collection('meal_analyses').add(mealAnalysis);

    res.json({
      success: true,
      data: {
        id: docRef.id,
        ...analysisResult,
        analysisId: docRef.id
      }
    });
  } catch (error) {
    console.error('Meal analysis error:', error);
    res.status(500).json({error: 'Failed to analyze meal image'});
  }
});

// パーソナライズドワークアウト生成
app.post('/generate-workout', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {
      workoutType = 'strength',
      duration = 30,
      equipment = 'none',
      fitnessLevel = 'beginner',
      targetMuscles = [],
      goals = [],
      preferences = {}
    } = req.body;

    // ユーザーの過去のワークアウトデータを取得
    const recentActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(10)
        .get();

    const userActivity = recentActivities.docs.map(doc => doc.data());

    const apiKey = await getGeminiApiKey();

    // プロンプト構築
    const prompt = `Generate a personalized workout plan in JSON format:

User Profile:
- Fitness Level: ${fitnessLevel}
- Workout Type: ${workoutType}
- Duration: ${duration} minutes
- Available Equipment: ${equipment}
- Target Muscles: ${targetMuscles.join(', ')}
- Goals: ${goals.join(', ')}
- Recent Activity: ${userActivity.length} workouts in the last 10 sessions

Generate in this format:
{
  "workoutPlan": {
    "name": "Personalized Strength Training",
    "description": "Customized workout based on your profile",
    "totalDuration": ${duration},
    "difficulty": "${fitnessLevel}",
    "exercises": [
      {
        "name": "Push-ups",
        "targetMuscles": ["chest", "triceps"],
        "sets": 3,
        "reps": "10-12",
        "duration": 120,
        "instructions": "Keep your body straight, lower slowly",
        "restTime": 60,
        "caloriesBurn": 8
      }
    ]
  },
  "estimatedCaloriesBurn": 250,
  "tips": [
    "Warm up for 5 minutes before starting",
    "Focus on proper form over speed"
  ],
  "progressions": [
    "Next week, increase reps to 12-15",
    "Add weight when bodyweight becomes easy"
  ]
}`;

    const geminiResponse = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [{text: prompt}]
          }],
          generationConfig: {
            temperature: 0.4,
            topK: 32,
            topP: 1,
            maxOutputTokens: 2048
          }
        }
    );

    const workoutText = geminiResponse.data.candidates[0].content.parts[0].text;

    // JSONを抽出
    const jsonMatch = workoutText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Failed to parse workout plan');
    }

    const workoutPlan = JSON.parse(jsonMatch[0]);

    // ワークアウトプランを保存
    const savedPlan = {
      userId,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      parameters: {
        workoutType,
        duration,
        equipment,
        fitnessLevel,
        targetMuscles,
        goals
      },
      workoutPlan: workoutPlan.workoutPlan,
      estimatedCaloriesBurn: workoutPlan.estimatedCaloriesBurn,
      tips: workoutPlan.tips,
      progressions: workoutPlan.progressions,
      status: 'generated'
    };

    const docRef = await db.collection('generated_workouts').add(savedPlan);

    res.json({
      success: true,
      data: {
        id: docRef.id,
        ...workoutPlan
      }
    });
  } catch (error) {
    console.error('Workout generation error:', error);
    res.status(500).json({error: 'Failed to generate workout plan'});
  }
});

// 健康インサイト生成
app.get('/insights', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {period = 'week'} = req.query;

    // ユーザーのアクティビティデータを取得
    let startDate: Date;
    if (period === 'week') {
      startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    } else if (period === 'month') {
      startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    } else {
      startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    }

    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .orderBy('timestamp', 'desc')
        .get();

    const activities = activitiesSnapshot.docs.map(doc => doc.data());

    if (activities.length === 0) {
      return res.json({
        success: true,
        data: {
          insights: [],
          recommendations: ['Start tracking your activities to get personalized insights'],
          healthScore: null
        }
      });
    }

    const apiKey = await getGeminiApiKey();

    // 統計を計算
    const totalCalories = activities.reduce((sum, activity) => sum + (activity.caloriesBurned || 0), 0);
    const totalDuration = activities.reduce((sum, activity) => sum + (activity.durationInSeconds || 0), 0);
    const activityTypes = [...new Set(activities.map(activity => activity.type))];

    const prompt = `Analyze this user's fitness data and provide health insights in JSON format:

Activity Summary (${period}):
- Total Activities: ${activities.length}
- Total Calories Burned: ${totalCalories}
- Total Duration: ${Math.round(totalDuration / 60)} minutes
- Activity Types: ${activityTypes.join(', ')}

Generate insights in this format:
{
  "healthScore": 8.5,
  "insights": [
    {
      "type": "progress",
      "title": "Great Consistency!",
      "description": "You've been maintaining a regular workout schedule",
      "trend": "positive"
    },
    {
      "type": "improvement",
      "title": "Diversify Your Workouts",
      "description": "Consider adding cardio to your strength training routine",
      "trend": "neutral"
    }
  ],
  "recommendations": [
    "Try to increase workout duration by 5-10 minutes",
    "Add stretching sessions for better recovery"
  ],
  "achievements": [
    {
      "title": "Consistency Champion",
      "description": "Worked out 5 days this week",
      "icon": "🏆"
    }
  ],
  "weeklyGoal": {
    "current": ${totalCalories},
    "target": ${Math.max(totalCalories * 1.1, 1500)},
    "progress": ${Math.min((totalCalories / Math.max(totalCalories * 1.1, 1500)) * 100, 100)}
  }
}`;

    const geminiResponse = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [{text: prompt}]
          }],
          generationConfig: {
            temperature: 0.3,
            topK: 32,
            topP: 1,
            maxOutputTokens: 1024
          }
        }
    );

    const insightsText = geminiResponse.data.candidates[0].content.parts[0].text;

    // JSONを抽出
    const jsonMatch = insightsText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Failed to parse insights');
    }

    const insights = JSON.parse(jsonMatch[0]);

    // インサイトを保存
    await db.collection('user_insights').add({
      userId,
      period,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      insights,
      dataPoints: {
        totalActivities: activities.length,
        totalCalories,
        totalDuration,
        activityTypes
      }
    });

    res.json({
      success: true,
      data: insights
    });
  } catch (error) {
    console.error('Insights generation error:', error);
    res.status(500).json({error: 'Failed to generate insights'});
  }
});

// チャットボット機能
app.post('/chat', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {message, context = 'fitness'} = req.body;

    if (!message) {
      return res.status(400).json({error: 'Message is required'});
    }

    // 過去の会話履歴を取得
    const conversationSnapshot = await db.collection('conversations')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(5)
        .get();

    const recentMessages = conversationSnapshot.docs.map(doc => doc.data());

    const apiKey = await getGeminiApiKey();

    // コンテキストを構築
    let contextPrompt = '';
    if (context === 'fitness') {
      contextPrompt = 'You are a professional fitness and nutrition coach. Provide helpful, motivating, and scientifically accurate advice.';
    } else if (context === 'nutrition') {
      contextPrompt = 'You are a certified nutritionist. Provide evidence-based nutrition advice and meal planning tips.';
    }

    const conversationHistory = recentMessages.reverse().map(msg =>
      `User: ${msg.userMessage}\nAssistant: ${msg.aiResponse}`
    ).join('\n\n');

    const prompt = `${contextPrompt}

Recent conversation:
${conversationHistory}

Current user message: ${message}

Provide a helpful, personalized response that:
1. Addresses the user's question directly
2. Provides actionable advice
3. Is encouraging and motivating
4. Includes specific recommendations when appropriate
5. Keeps the response concise but informative`;

    const geminiResponse = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [{text: prompt}]
          }],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.8,
            maxOutputTokens: 512
          }
        }
    );

    const aiResponse = geminiResponse.data.candidates[0].content.parts[0].text;

    // 会話を保存
    await db.collection('conversations').add({
      userId,
      userMessage: message,
      aiResponse,
      context,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({
      success: true,
      data: {
        response: aiResponse,
        context
      }
    });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({error: 'Failed to process chat message'});
  }
});

// ミドルウェア：処理時間記録
app.use((req: any, res: any, next: any) => {
  req.startTime = Date.now();
  next();
});

// エラーハンドリング
app.use((error: any, req: any, res: any, next: any) => {
  console.error('AI API Error:', error);
  res.status(500).json({error: 'Internal server error'});
});

// Firebase Functions としてエクスポート
export const ai = functions
    .region(region.value())
    .https
    .onRequest(app);