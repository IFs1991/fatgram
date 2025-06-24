import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as express from 'express';
import * as cors from 'cors';
import {defineString} from 'firebase-functions/params';

// 環境変数
const region = defineString('REGION', {default: 'asia-northeast1'});

// Express アプリケーション
const app = express();
app.use(cors({origin: true}));
app.use(express.json());

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

// ユーザープロフィール取得
app.get('/profile', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // Firestoreからユーザー情報を取得
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({error: 'User not found'});
    }

    const userData = userDoc.data();

    // Firebase Authからの情報と結合
    const userRecord = await admin.auth().getUser(userId);

    const profile = {
      uid: userId,
      email: userRecord.email,
      displayName: userRecord.displayName || userData?.displayName,
      profileImageUrl: userRecord.photoURL || userData?.profileImageUrl,
      phoneNumber: userRecord.phoneNumber,
      emailVerified: userRecord.emailVerified,
      createdAt: userData?.createdAt,
      updatedAt: userData?.updatedAt,
      subscriptionTier: req.user.subscriptionTier || 'free',
      goals: userData?.goals || {},
      preferences: userData?.preferences || {},
      stats: userData?.stats || {},
    };

    res.json({success: true, data: profile});
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// ユーザープロフィール更新
app.put('/profile', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const updateData = req.body;

    // バリデーション
    const allowedFields = [
      'displayName', 'profileImageUrl', 'goals', 'preferences', 'height', 'weight', 'age', 'gender'
    ];
    const filteredData: any = {};

    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key)) {
        filteredData[key] = updateData[key];
      }
    });

    if (Object.keys(filteredData).length === 0) {
      return res.status(400).json({error: 'No valid fields to update'});
    }

    // 更新日時を追加
    filteredData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    // Firestore更新
    await db.collection('users').doc(userId).update(filteredData);

    // Firebase Auth情報も更新（displayName, photoURL）
    const authUpdateData: any = {};
    if (filteredData.displayName) authUpdateData.displayName = filteredData.displayName;
    if (filteredData.profileImageUrl) authUpdateData.photoURL = filteredData.profileImageUrl;

    if (Object.keys(authUpdateData).length > 0) {
      await admin.auth().updateUser(userId, authUpdateData);
    }

    res.json({success: true, message: 'Profile updated successfully'});
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// カスタムクレーム更新（サブスクリプション管理用）
app.post('/update-claims', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {subscriptionTier, customClaims} = req.body;

    // 管理者権限チェック（必要に応じて）
    if (req.user.role !== 'admin' && customClaims) {
      return res.status(403).json({error: 'Forbidden: Admin required for custom claims'});
    }

    const claims: any = {};
    if (subscriptionTier) claims.subscriptionTier = subscriptionTier;
    if (customClaims) Object.assign(claims, customClaims);

    await admin.auth().setCustomUserClaims(userId, claims);

    // Firestoreも更新
    if (subscriptionTier) {
      await db.collection('users').doc(userId).update({
        subscriptionTier,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.json({success: true, message: 'Claims updated successfully'});
  } catch (error) {
    console.error('Update claims error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// トークン更新
app.post('/refresh-token', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // 新しいカスタムトークンを生成
    const customToken = await admin.auth().createCustomToken(userId);

    res.json({success: true, data: {customToken}});
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// アカウント削除
app.delete('/account', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // ユーザーの確認（パスワード再認証が推奨）
    const {password} = req.body;
    if (!password) {
      return res.status(400).json({error: 'Password required for account deletion'});
    }

    // 関連データの削除は onUserDeleted トリガーで処理される
    await admin.auth().deleteUser(userId);

    res.json({success: true, message: 'Account deleted successfully'});
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// ユーザー統計取得
app.get('/stats', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // 基本統計を取得
    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(100)
        .get();

    const activities = activitiesSnapshot.docs.map(doc => doc.data());

    // 統計計算
    const totalActivities = activities.length;
    const totalCaloriesBurned = activities.reduce((sum, activity) => sum + (activity.caloriesBurned || 0), 0);
    const totalFatBurned = totalCaloriesBurned * 0.133; // 1kcal = 0.133g脂肪
    const totalDuration = activities.reduce((sum, activity) => sum + (activity.durationInSeconds || 0), 0);

    // 過去7日間の統計
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentActivities = activities.filter(activity =>
      activity.timestamp && activity.timestamp.toDate() > sevenDaysAgo
    );

    const weeklyStats = {
      activities: recentActivities.length,
      caloriesBurned: recentActivities.reduce((sum, activity) => sum + (activity.caloriesBurned || 0), 0),
      fatBurned: recentActivities.reduce((sum, activity) => sum + (activity.caloriesBurned || 0), 0) * 0.133,
      duration: recentActivities.reduce((sum, activity) => sum + (activity.durationInSeconds || 0), 0),
    };

    const stats = {
      total: {
        activities: totalActivities,
        caloriesBurned: totalCaloriesBurned,
        fatBurned: totalFatBurned,
        durationInSeconds: totalDuration,
      },
      weekly: weeklyStats,
      averagePerWorkout: totalActivities > 0 ? {
        caloriesBurned: totalCaloriesBurned / totalActivities,
        fatBurned: totalFatBurned / totalActivities,
        durationInSeconds: totalDuration / totalActivities,
      } : null,
    };

    res.json({success: true, data: stats});
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// エラーハンドリング
app.use((error: any, req: any, res: any, next: any) => {
  console.error('Auth API Error:', error);
  res.status(500).json({error: 'Internal server error'});
});

// Firebase Functions としてエクスポート
export const auth = functions
    .region(region.value())
    .https
    .onRequest(app);