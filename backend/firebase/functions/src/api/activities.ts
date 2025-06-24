import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as express from 'express';
import * as cors from 'cors';
import {defineString} from 'firebase-functions/params';
import * as dayjs from 'dayjs';

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

// Activity型定義
interface Activity {
  id?: string;
  userId: string;
  type: string;
  timestamp: admin.firestore.Timestamp;
  durationInSeconds: number;
  caloriesBurned: number;
  distanceInMeters?: number;
  metadata?: any;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// アクティビティ一覧取得
app.get('/', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {
      limit = 20,
      offset = 0,
      type,
      startDate,
      endDate,
      sortBy = 'timestamp',
      sortOrder = 'desc'
    } = req.query;

    let query = db.collection('activities')
        .where('userId', '==', userId);

    // フィルター適用
    if (type) {
      query = query.where('type', '==', type);
    }

    if (startDate) {
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate as string));
      query = query.where('timestamp', '>=', start);
    }

    if (endDate) {
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate as string));
      query = query.where('timestamp', '<=', end);
    }

    // ソート
    query = query.orderBy(sortBy as string, sortOrder as any);

    // ページネーション
    query = query.offset(Number(offset)).limit(Number(limit));

    const snapshot = await query.get();
    const activities = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // 総件数を取得（パフォーマンス考慮で別クエリ）
    const countQuery = db.collection('activities').where('userId', '==', userId);
    const countSnapshot = await countQuery.count().get();
    const total = countSnapshot.data().count;

    res.json({
      success: true,
      data: {
        activities,
        pagination: {
          total,
          limit: Number(limit),
          offset: Number(offset),
          hasMore: Number(offset) + activities.length < total
        }
      }
    });
  } catch (error) {
    console.error('Get activities error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// 単一アクティビティ取得
app.get('/:id', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const activityId = req.params.id;

    const doc = await db.collection('activities').doc(activityId).get();

    if (!doc.exists) {
      return res.status(404).json({error: 'Activity not found'});
    }

    const activity = doc.data();

    // ユーザー認可チェック
    if (activity?.userId !== userId) {
      return res.status(403).json({error: 'Forbidden: Access denied'});
    }

    res.json({
      success: true,
      data: {
        id: doc.id,
        ...activity
      }
    });
  } catch (error) {
    console.error('Get activity error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// アクティビティ作成
app.post('/', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const activityData = req.body;

    // バリデーション
    const requiredFields = ['type', 'timestamp', 'durationInSeconds', 'caloriesBurned'];
    for (const field of requiredFields) {
      if (!activityData[field] && activityData[field] !== 0) {
        return res.status(400).json({error: `Missing required field: ${field}`});
      }
    }

    // データの正規化
    const activity: Omit<Activity, 'id'> = {
      userId,
      type: activityData.type,
      timestamp: admin.firestore.Timestamp.fromDate(new Date(activityData.timestamp)),
      durationInSeconds: Number(activityData.durationInSeconds),
      caloriesBurned: Number(activityData.caloriesBurned),
      distanceInMeters: activityData.distanceInMeters ? Number(activityData.distanceInMeters) : undefined,
      metadata: activityData.metadata || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    } as any;

    // バリデーション
    if (activity.durationInSeconds < 0 || activity.caloriesBurned < 0) {
      return res.status(400).json({error: 'Duration and calories must be non-negative'});
    }

    const docRef = await db.collection('activities').add(activity);

    res.status(201).json({
      success: true,
      data: {
        id: docRef.id,
        ...activity
      }
    });
  } catch (error) {
    console.error('Create activity error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// アクティビティ更新
app.put('/:id', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const activityId = req.params.id;
    const updateData = req.body;

    // 存在チェック
    const doc = await db.collection('activities').doc(activityId).get();
    if (!doc.exists) {
      return res.status(404).json({error: 'Activity not found'});
    }

    const existingActivity = doc.data();

    // ユーザー認可チェック
    if (existingActivity?.userId !== userId) {
      return res.status(403).json({error: 'Forbidden: Access denied'});
    }

    // 更新可能フィールドのフィルタリング
    const allowedFields = [
      'type', 'timestamp', 'durationInSeconds', 'caloriesBurned',
      'distanceInMeters', 'metadata'
    ];
    const filteredData: any = {};

    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key)) {
        if (key === 'timestamp') {
          filteredData[key] = admin.firestore.Timestamp.fromDate(new Date(updateData[key]));
        } else if (['durationInSeconds', 'caloriesBurned', 'distanceInMeters'].includes(key)) {
          filteredData[key] = Number(updateData[key]);
        } else {
          filteredData[key] = updateData[key];
        }
      }
    });

    if (Object.keys(filteredData).length === 0) {
      return res.status(400).json({error: 'No valid fields to update'});
    }

    // バリデーション
    if (filteredData.durationInSeconds !== undefined && filteredData.durationInSeconds < 0) {
      return res.status(400).json({error: 'Duration must be non-negative'});
    }
    if (filteredData.caloriesBurned !== undefined && filteredData.caloriesBurned < 0) {
      return res.status(400).json({error: 'Calories must be non-negative'});
    }

    filteredData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('activities').doc(activityId).update(filteredData);

    res.json({
      success: true,
      message: 'Activity updated successfully'
    });
  } catch (error) {
    console.error('Update activity error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// アクティビティ削除
app.delete('/:id', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const activityId = req.params.id;

    // 存在チェック
    const doc = await db.collection('activities').doc(activityId).get();
    if (!doc.exists) {
      return res.status(404).json({error: 'Activity not found'});
    }

    const activity = doc.data();

    // ユーザー認可チェック
    if (activity?.userId !== userId) {
      return res.status(403).json({error: 'Forbidden: Access denied'});
    }

    await db.collection('activities').doc(activityId).delete();

    res.json({
      success: true,
      message: 'Activity deleted successfully'
    });
  } catch (error) {
    console.error('Delete activity error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// 統計取得
app.get('/stats/summary', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {period = 'week'} = req.query;

    let startDate: Date;
    const endDate = new Date();

    // 期間の設定
    switch (period) {
      case 'day':
        startDate = dayjs().startOf('day').toDate();
        break;
      case 'week':
        startDate = dayjs().startOf('week').toDate();
        break;
      case 'month':
        startDate = dayjs().startOf('month').toDate();
        break;
      case 'year':
        startDate = dayjs().startOf('year').toDate();
        break;
      default:
        startDate = dayjs().startOf('week').toDate();
    }

    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endDate))
        .orderBy('timestamp', 'desc')
        .get();

    const activities = activitiesSnapshot.docs.map(doc => doc.data());

    // 統計計算
    const totalActivities = activities.length;
    const totalCaloriesBurned = activities.reduce((sum, activity) => sum + (activity.caloriesBurned || 0), 0);
    const totalFatBurned = totalCaloriesBurned * 0.133; // 1kcal = 0.133g脂肪
    const totalDuration = activities.reduce((sum, activity) => sum + (activity.durationInSeconds || 0), 0);
    const totalDistance = activities.reduce((sum, activity) => sum + (activity.distanceInMeters || 0), 0);

    // アクティビティタイプ別集計
    const byType: any = {};
    activities.forEach(activity => {
      const type = activity.type;
      if (!byType[type]) {
        byType[type] = {
          count: 0,
          caloriesBurned: 0,
          durationInSeconds: 0,
          distanceInMeters: 0
        };
      }
      byType[type].count++;
      byType[type].caloriesBurned += activity.caloriesBurned || 0;
      byType[type].durationInSeconds += activity.durationInSeconds || 0;
      byType[type].distanceInMeters += activity.distanceInMeters || 0;
    });

    // 日別トレンド
    const dailyTrends: any = {};
    activities.forEach(activity => {
      const date = dayjs(activity.timestamp.toDate()).format('YYYY-MM-DD');
      if (!dailyTrends[date]) {
        dailyTrends[date] = {
          date,
          activities: 0,
          caloriesBurned: 0,
          fatBurned: 0,
          durationInSeconds: 0
        };
      }
      dailyTrends[date].activities++;
      dailyTrends[date].caloriesBurned += activity.caloriesBurned || 0;
      dailyTrends[date].fatBurned += (activity.caloriesBurned || 0) * 0.133;
      dailyTrends[date].durationInSeconds += activity.durationInSeconds || 0;
    });

    const summary = {
      period,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      total: {
        activities: totalActivities,
        caloriesBurned: totalCaloriesBurned,
        fatBurned: totalFatBurned,
        durationInSeconds: totalDuration,
        distanceInMeters: totalDistance
      },
      averagePerDay: {
        activities: totalActivities / dayjs(endDate).diff(dayjs(startDate), 'day'),
        caloriesBurned: totalCaloriesBurned / dayjs(endDate).diff(dayjs(startDate), 'day'),
        fatBurned: totalFatBurned / dayjs(endDate).diff(dayjs(startDate), 'day')
      },
      byType,
      dailyTrends: Object.values(dailyTrends).sort((a: any, b: any) => a.date.localeCompare(b.date))
    };

    res.json({success: true, data: summary});
  } catch (error) {
    console.error('Get stats summary error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// 進捗トレンド取得
app.get('/stats/trends', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {days = 30} = req.query;

    const startDate = dayjs().subtract(Number(days), 'day').startOf('day').toDate();
    const endDate = new Date();

    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endDate))
        .orderBy('timestamp', 'asc')
        .get();

    const activities = activitiesSnapshot.docs.map(doc => doc.data());

    // 週別トレンド
    const weeklyTrends: any = {};
    activities.forEach(activity => {
      const week = dayjs(activity.timestamp.toDate()).startOf('week').format('YYYY-MM-DD');
      if (!weeklyTrends[week]) {
        weeklyTrends[week] = {
          week,
          activities: 0,
          caloriesBurned: 0,
          fatBurned: 0,
          durationInSeconds: 0
        };
      }
      weeklyTrends[week].activities++;
      weeklyTrends[week].caloriesBurned += activity.caloriesBurned || 0;
      weeklyTrends[week].fatBurned += (activity.caloriesBurned || 0) * 0.133;
      weeklyTrends[week].durationInSeconds += activity.durationInSeconds || 0;
    });

    res.json({
      success: true,
      data: {
        period: `${days} days`,
        weeklyTrends: Object.values(weeklyTrends).sort((a: any, b: any) => a.week.localeCompare(b.week))
      }
    });
  } catch (error) {
    console.error('Get trends error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// エラーハンドリング
app.use((error: any, req: any, res: any, next: any) => {
  console.error('Activities API Error:', error);
  res.status(500).json({error: 'Internal server error'});
});

// Firebase Functions としてエクスポート
export const activities = functions
    .region(region.value())
    .https
    .onRequest(app);