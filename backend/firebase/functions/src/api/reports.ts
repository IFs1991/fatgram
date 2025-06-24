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

// 進捗レポート生成
app.get('/progress', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {startDate, endDate, groupBy = 'week'} = req.query;

    // 期間設定
    let start: Date, end: Date;
    if (startDate && endDate) {
      start = new Date(startDate as string);
      end = new Date(endDate as string);
    } else {
      // デフォルトは過去3ヶ月
      end = new Date();
      start = dayjs(end).subtract(3, 'month').toDate();
    }

    // アクティビティデータを取得
    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(start))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(end))
        .orderBy('timestamp', 'asc')
        .get();

    const activities = activitiesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // グループ化関数
    const getGroupKey = (date: Date): string => {
      switch (groupBy) {
        case 'day':
          return dayjs(date).format('YYYY-MM-DD');
        case 'week':
          return dayjs(date).startOf('week').format('YYYY-MM-DD');
        case 'month':
          return dayjs(date).format('YYYY-MM');
        default:
          return dayjs(date).startOf('week').format('YYYY-MM-DD');
      }
    };

    // データをグループ化
    const groupedData: any = {};
    activities.forEach(activity => {
      const date = activity.timestamp.toDate();
      const key = getGroupKey(date);

      if (!groupedData[key]) {
        groupedData[key] = {
          period: key,
          activities: 0,
          totalCalories: 0,
          totalDuration: 0,
          totalDistance: 0,
          totalFatBurn: 0,
          activityTypes: new Set(),
          averageIntensity: 0
        };
      }

      groupedData[key].activities++;
      groupedData[key].totalCalories += activity.caloriesBurned || 0;
      groupedData[key].totalDuration += activity.durationInSeconds || 0;
      groupedData[key].totalDistance += activity.distanceInMeters || 0;
      groupedData[key].totalFatBurn += (activity.caloriesBurned || 0) * 0.133;
      groupedData[key].activityTypes.add(activity.type);
    });

    // Set を配列に変換し、平均値を計算
    const progressData = Object.values(groupedData).map((group: any) => ({
      ...group,
      activityTypes: Array.from(group.activityTypes),
      averageCaloriesPerActivity: group.activities > 0 ? group.totalCalories / group.activities : 0,
      averageDurationPerActivity: group.activities > 0 ? group.totalDuration / group.activities : 0
    }));

    // 全体統計
    const totalStats = {
      totalActivities: activities.length,
      totalCalories: activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0),
      totalDuration: activities.reduce((sum, a) => sum + (a.durationInSeconds || 0), 0),
      totalDistance: activities.reduce((sum, a) => sum + (a.distanceInMeters || 0), 0),
      totalFatBurn: activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0) * 0.133,
      averageActivitiesPerPeriod: progressData.length > 0 ? activities.length / progressData.length : 0,
      averageCaloriesPerActivity: activities.length > 0 ?
        activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0) / activities.length : 0
    };

    // トレンド分析
    const trends = {
      caloriesTrend: calculateTrend(progressData.map((p: any) => p.totalCalories)),
      activityTrend: calculateTrend(progressData.map((p: any) => p.activities)),
      durationTrend: calculateTrend(progressData.map((p: any) => p.totalDuration))
    };

    res.json({
      success: true,
      data: {
        period: {
          start: start.toISOString(),
          end: end.toISOString(),
          groupBy
        },
        progressData,
        totalStats,
        trends
      }
    });
  } catch (error) {
    console.error('Progress report error:', error);
    res.status(500).json({error: 'Failed to generate progress report'});
  }
});

// 脂肪燃焼分析レポート
app.get('/fat-burn-analysis', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {period = 30} = req.query;

    const startDate = dayjs().subtract(Number(period), 'day').toDate();
    const endDate = new Date();

    const activitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(endDate))
        .orderBy('timestamp', 'desc')
        .get();

    const activities = activitiesSnapshot.docs.map(doc => doc.data());

    // 脂肪燃焼効率分析
    const fatBurnAnalysis = activities.map(activity => {
      const caloriesBurned = activity.caloriesBurned || 0;
      const durationMinutes = (activity.durationInSeconds || 0) / 60;
      const fatBurned = caloriesBurned * 0.133; // 1kcal = 0.133g fat

      return {
        date: activity.timestamp.toDate(),
        type: activity.type,
        caloriesBurned,
        fatBurned,
        durationMinutes,
        fatBurnRate: durationMinutes > 0 ? fatBurned / durationMinutes : 0, // g/min
        efficiency: caloriesBurned > 0 ? fatBurned / caloriesBurned : 0 // g fat per kcal
      };
    });

    // アクティビティタイプ別分析
    const byActivityType: any = {};
    fatBurnAnalysis.forEach(analysis => {
      const type = analysis.type;
      if (!byActivityType[type]) {
        byActivityType[type] = {
          count: 0,
          totalFatBurned: 0,
          totalDuration: 0,
          totalCalories: 0,
          averageFatBurnRate: 0,
          efficiency: 0
        };
      }

      byActivityType[type].count++;
      byActivityType[type].totalFatBurned += analysis.fatBurned;
      byActivityType[type].totalDuration += analysis.durationMinutes;
      byActivityType[type].totalCalories += analysis.caloriesBurned;
    });

    // 平均値を計算
    Object.keys(byActivityType).forEach(type => {
      const data = byActivityType[type];
      data.averageFatBurnRate = data.totalDuration > 0 ? data.totalFatBurned / data.totalDuration : 0;
      data.efficiency = data.totalCalories > 0 ? data.totalFatBurned / data.totalCalories : 0;
      data.averageFatBurnedPerSession = data.count > 0 ? data.totalFatBurned / data.count : 0;
    });

    // 週別トレンド
    const weeklyTrends: any = {};
    fatBurnAnalysis.forEach(analysis => {
      const week = dayjs(analysis.date).startOf('week').format('YYYY-MM-DD');
      if (!weeklyTrends[week]) {
        weeklyTrends[week] = {
          week,
          totalFatBurned: 0,
          totalCalories: 0,
          totalSessions: 0,
          averageFatBurnRate: 0
        };
      }

      weeklyTrends[week].totalFatBurned += analysis.fatBurned;
      weeklyTrends[week].totalCalories += analysis.caloriesBurned;
      weeklyTrends[week].totalSessions++;
    });

    // 週別平均値計算
    Object.values(weeklyTrends).forEach((week: any) => {
      week.averageFatBurnRate = week.totalSessions > 0 ? week.totalFatBurned / week.totalSessions : 0;
    });

    // 目標設定と達成度
    const weeklyFatBurnGoal = 100; // g (例：週100g脂肪燃焼目標)
    const currentWeekStart = dayjs().startOf('week').format('YYYY-MM-DD');
    const currentWeekProgress = weeklyTrends[currentWeekStart]?.totalFatBurned || 0;
    const goalProgress = (currentWeekProgress / weeklyFatBurnGoal) * 100;

    res.json({
      success: true,
      data: {
        period: `${period} days`,
        totalFatBurned: fatBurnAnalysis.reduce((sum, a) => sum + a.fatBurned, 0),
        averageFatBurnRate: fatBurnAnalysis.length > 0 ?
          fatBurnAnalysis.reduce((sum, a) => sum + a.fatBurnRate, 0) / fatBurnAnalysis.length : 0,
        byActivityType,
        weeklyTrends: Object.values(weeklyTrends).sort((a: any, b: any) => a.week.localeCompare(b.week)),
        goalTracking: {
          weeklyGoal: weeklyFatBurnGoal,
          currentProgress: currentWeekProgress,
          progressPercentage: Math.min(goalProgress, 100),
          remainingToGoal: Math.max(weeklyFatBurnGoal - currentWeekProgress, 0)
        }
      }
    });
  } catch (error) {
    console.error('Fat burn analysis error:', error);
    res.status(500).json({error: 'Failed to generate fat burn analysis'});
  }
});

// ダッシュボード統計
app.get('/dashboard-stats', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const now = new Date();

    // 今日の統計
    const todayStart = dayjs().startOf('day').toDate();
    const todayActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(now))
        .get();

    // 今週の統計
    const weekStart = dayjs().startOf('week').toDate();
    const weekActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(weekStart))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(now))
        .get();

    // 今月の統計
    const monthStart = dayjs().startOf('month').toDate();
    const monthActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(monthStart))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(now))
        .get();

    // 統計計算関数
    const calculateStats = (activities: any[]) => {
      const totalCalories = activities.reduce((sum, doc) => sum + (doc.data().caloriesBurned || 0), 0);
      const totalDuration = activities.reduce((sum, doc) => sum + (doc.data().durationInSeconds || 0), 0);
      const totalDistance = activities.reduce((sum, doc) => sum + (doc.data().distanceInMeters || 0), 0);

      return {
        totalActivities: activities.length,
        totalCalories,
        totalFatBurned: totalCalories * 0.133,
        totalDuration,
        totalDistance,
        averageCaloriesPerActivity: activities.length > 0 ? totalCalories / activities.length : 0
      };
    };

    const todayStats = calculateStats(todayActivities.docs);
    const weekStats = calculateStats(weekActivities.docs);
    const monthStats = calculateStats(monthActivities.docs);

    // 前週との比較
    const lastWeekStart = dayjs().subtract(1, 'week').startOf('week').toDate();
    const lastWeekEnd = dayjs().subtract(1, 'week').endOf('week').toDate();
    const lastWeekActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(lastWeekStart))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(lastWeekEnd))
        .get();

    const lastWeekStats = calculateStats(lastWeekActivities.docs);

    // 改善率計算
    const improvements = {
      activitiesChange: lastWeekStats.totalActivities > 0 ?
        ((weekStats.totalActivities - lastWeekStats.totalActivities) / lastWeekStats.totalActivities) * 100 : 0,
      caloriesChange: lastWeekStats.totalCalories > 0 ?
        ((weekStats.totalCalories - lastWeekStats.totalCalories) / lastWeekStats.totalCalories) * 100 : 0,
      durationChange: lastWeekStats.totalDuration > 0 ?
        ((weekStats.totalDuration - lastWeekStats.totalDuration) / lastWeekStats.totalDuration) * 100 : 0
    };

    // 最近のアクティビティ（上位5件）
    const recentActivitiesSnapshot = await db.collection('activities')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(5)
        .get();

    const recentActivities = recentActivitiesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({
      success: true,
      data: {
        today: todayStats,
        thisWeek: weekStats,
        thisMonth: monthStats,
        improvements,
        recentActivities,
        streaks: {
          current: await calculateCurrentStreak(userId),
          longest: await calculateLongestStreak(userId)
        }
      }
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({error: 'Failed to get dashboard statistics'});
  }
});

// データエクスポート
app.get('/export', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {format = 'json', startDate, endDate, includeAnalytics = false} = req.query;

    // 期間設定
    let start: Date, end: Date;
    if (startDate && endDate) {
      start = new Date(startDate as string);
      end = new Date(endDate as string);
    } else {
      // デフォルトは全期間
      end = new Date();
      start = new Date('2020-01-01'); // 適当な過去の日付
    }

    // ユーザーデータを取得
    const [userDoc, activitiesSnapshot, conversationsSnapshot] = await Promise.all([
      db.collection('users').doc(userId).get(),
      db.collection('activities')
          .where('userId', '==', userId)
          .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(start))
          .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(end))
          .orderBy('timestamp', 'asc')
          .get(),
      includeAnalytics ?
        db.collection('conversations').where('userId', '==', userId).get() :
        Promise.resolve({docs: []})
    ]);

    const userData = userDoc.data();
    const activities = activitiesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp.toDate().toISOString()
    }));

    const conversations = (conversationsSnapshot as any).docs.map((doc: any) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp.toDate().toISOString()
    }));

    const exportData = {
      exportInfo: {
        userId,
        exportDate: new Date().toISOString(),
        period: {
          start: start.toISOString(),
          end: end.toISOString()
        },
        format,
        includeAnalytics: includeAnalytics === 'true'
      },
      userData: {
        displayName: userData?.displayName,
        email: userData?.email,
        createdAt: userData?.createdAt?.toDate()?.toISOString(),
        goals: userData?.goals,
        preferences: userData?.preferences
      },
      activities,
      analytics: includeAnalytics === 'true' ? {
        conversations: conversations,
        totalActivities: activities.length,
        totalCaloriesBurned: activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0),
        totalFatBurned: activities.reduce((sum, a) => sum + (a.caloriesBurned || 0), 0) * 0.133,
        activityTypes: [...new Set(activities.map(a => a.type))]
      } : null
    };

    if (format === 'csv') {
      // CSV形式での出力（簡略化）
      const csv = convertToCSV(activities);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="fatgram-activities-${userId}.csv"`);
      res.send(csv);
    } else {
      // JSON形式での出力
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="fatgram-export-${userId}.json"`);
      res.json(exportData);
    }

    // エクスポート履歴を記録
    await db.collection('export_history').add({
      userId,
      exportDate: admin.firestore.FieldValue.serverTimestamp(),
      format,
      period: {
        start: admin.firestore.Timestamp.fromDate(start),
        end: admin.firestore.Timestamp.fromDate(end)
      },
      recordCount: activities.length,
      includeAnalytics: includeAnalytics === 'true'
    });

  } catch (error) {
    console.error('Export error:', error);
    res.status(500).json({error: 'Failed to export data'});
  }
});

// ヘルパー関数
function calculateTrend(values: number[]): {direction: string, percentage: number} {
  if (values.length < 2) return {direction: 'stable', percentage: 0};

  const recent = values.slice(-Math.min(3, values.length));
  const earlier = values.slice(0, Math.min(3, values.length));

  const recentAvg = recent.reduce((sum, val) => sum + val, 0) / recent.length;
  const earlierAvg = earlier.reduce((sum, val) => sum + val, 0) / earlier.length;

  if (earlierAvg === 0) return {direction: 'stable', percentage: 0};

  const change = ((recentAvg - earlierAvg) / earlierAvg) * 100;

  return {
    direction: change > 5 ? 'increasing' : change < -5 ? 'decreasing' : 'stable',
    percentage: Math.abs(change)
  };
}

async function calculateCurrentStreak(userId: string): Promise<number> {
  const today = dayjs();
  let streak = 0;
  let checkDate = today;

  while (true) {
    const dayStart = checkDate.startOf('day').toDate();
    const dayEnd = checkDate.endOf('day').toDate();

    const dayActivities = await db.collection('activities')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(dayStart))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(dayEnd))
        .limit(1)
        .get();

    if (dayActivities.empty) {
      break;
    }

    streak++;
    checkDate = checkDate.subtract(1, 'day');

    // 最大100日まで
    if (streak > 100) break;
  }

  return streak;
}

async function calculateLongestStreak(userId: string): Promise<number> {
  // 簡略化実装：現在のストリークを返す
  // 実際の実装では全履歴を分析する必要がある
  return calculateCurrentStreak(userId);
}

function convertToCSV(activities: any[]): string {
  const headers = ['Date', 'Type', 'Duration (minutes)', 'Calories Burned', 'Distance (meters)', 'Fat Burned (g)'];
  const rows = activities.map(activity => [
    activity.timestamp,
    activity.type,
    Math.round((activity.durationInSeconds || 0) / 60),
    activity.caloriesBurned || 0,
    activity.distanceInMeters || 0,
    Math.round((activity.caloriesBurned || 0) * 0.133 * 100) / 100
  ]);

  return [headers, ...rows].map(row => row.join(',')).join('\n');
}

// エラーハンドリング
app.use((error: any, req: any, res: any, next: any) => {
  console.error('Reports API Error:', error);
  res.status(500).json({error: 'Internal server error'});
});

// Firebase Functions としてエクスポート
export const reports = functions
    .region(region.value())
    .https
    .onRequest(app);