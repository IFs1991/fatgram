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

// サブスクリプション情報型定義
interface SubscriptionInfo {
  userId: string;
  subscriptionTier: 'free' | 'premium';
  status: 'active' | 'inactive' | 'cancelled' | 'expired';
  startDate?: admin.firestore.Timestamp;
  endDate?: admin.firestore.Timestamp;
  productId?: string;
  transactionId?: string;
  originalTransactionId?: string;
  receiptData?: string;
  revenueCatCustomerId?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// 利用可能なプラン取得
app.get('/plans', async (req: any, res: any) => {
  try {
    const plans = [
      {
        id: 'premium_monthly',
        name: 'Premium Monthly',
        description: 'All premium features, monthly billing',
        price: '$9.99',
        currency: 'USD',
        interval: 'month',
        features: [
          'Advanced AI analysis',
          'Unlimited workout tracking',
          'Personalized meal plans',
          'Detailed progress analytics',
          'Priority support'
        ],
        isPopular: false
      },
      {
        id: 'premium_yearly',
        name: 'Premium Yearly',
        description: 'All premium features, save 30% with yearly billing',
        price: '$84.99',
        currency: 'USD',
        interval: 'year',
        originalPrice: '$119.88',
        features: [
          'Advanced AI analysis',
          'Unlimited workout tracking',
          'Personalized meal plans',
          'Detailed progress analytics',
          'Priority support',
          'Exclusive workout programs'
        ],
        isPopular: true
      },
      {
        id: 'free',
        name: 'Free',
        description: 'Basic features for getting started',
        price: '$0',
        currency: 'USD',
        interval: 'forever',
        features: [
          'Basic activity tracking',
          'Simple analytics',
          'Community access'
        ],
        isPopular: false
      }
    ];

    res.json({success: true, data: plans});
  } catch (error) {
    console.error('Get plans error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// ユーザーのサブスクリプション状態取得
app.get('/status', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // Firestoreからサブスクリプション情報を取得
    const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();

    let subscriptionInfo: any = {
      userId,
      subscriptionTier: 'free',
      status: 'inactive',
      isPremium: false,
      features: {
        advancedAnalytics: false,
        unlimitedTracking: false,
        personalizedMealPlans: false,
        prioritySupport: false
      }
    };

    if (subscriptionDoc.exists) {
      const data = subscriptionDoc.data();
      subscriptionInfo = {
        ...subscriptionInfo,
        ...data,
        isPremium: data.subscriptionTier === 'premium' && data.status === 'active'
      };

      // 期限チェック
      if (data.endDate && data.endDate.toDate() < new Date()) {
        subscriptionInfo.status = 'expired';
        subscriptionInfo.isPremium = false;
      }

      // プレミアム機能の設定
      if (subscriptionInfo.isPremium) {
        subscriptionInfo.features = {
          advancedAnalytics: true,
          unlimitedTracking: true,
          personalizedMealPlans: true,
          prioritySupport: true
        };
      }
    }

    res.json({success: true, data: subscriptionInfo});
  } catch (error) {
    console.error('Get subscription status error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// サブスクリプション購入確認/レシート検証
app.post('/verify-purchase', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {
      receiptData,
      productId,
      transactionId,
      originalTransactionId,
      purchaseDate,
      expirationDate
    } = req.body;

    // 必須フィールドの確認
    if (!receiptData || !productId || !transactionId) {
      return res.status(400).json({error: 'Missing required fields'});
    }

    // 重複購入チェック
    const existingPurchase = await db.collection('purchases')
        .where('userId', '==', userId)
        .where('transactionId', '==', transactionId)
        .get();

    if (!existingPurchase.empty) {
      return res.status(409).json({error: 'Purchase already processed'});
    }

    // サブスクリプションティアを決定
    let subscriptionTier: 'free' | 'premium' = 'free';
    if (productId.includes('premium')) {
      subscriptionTier = 'premium';
    }

    // サブスクリプション情報を更新
    const subscriptionData: Partial<SubscriptionInfo> = {
      userId,
      subscriptionTier,
      status: 'active',
      productId,
      transactionId,
      originalTransactionId,
      receiptData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp() as any
    };

    if (purchaseDate) {
      subscriptionData.startDate = admin.firestore.Timestamp.fromDate(new Date(purchaseDate));
    }

    if (expirationDate) {
      subscriptionData.endDate = admin.firestore.Timestamp.fromDate(new Date(expirationDate));
    }

    // Firestoreに保存
    await db.collection('subscriptions').doc(userId).set(subscriptionData, {merge: true});

    // 購入記録を保存
    await db.collection('purchases').add({
      userId,
      productId,
      transactionId,
      originalTransactionId,
      receiptData,
      purchaseDate: purchaseDate ? admin.firestore.Timestamp.fromDate(new Date(purchaseDate)) : admin.firestore.FieldValue.serverTimestamp(),
      verificationDate: admin.firestore.FieldValue.serverTimestamp(),
      status: 'verified'
    });

    // Firebase Authのカスタムクレームを更新
    await admin.auth().setCustomUserClaims(userId, {
      subscriptionTier,
      isPremium: subscriptionTier === 'premium'
    });

    res.json({
      success: true,
      message: 'Purchase verified successfully',
      data: {
        subscriptionTier,
        status: 'active',
        isPremium: subscriptionTier === 'premium'
      }
    });
  } catch (error) {
    console.error('Verify purchase error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// サブスクリプションのキャンセル
app.post('/cancel', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;
    const {reason} = req.body;

    // 現在のサブスクリプション状態を確認
    const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();

    if (!subscriptionDoc.exists) {
      return res.status(404).json({error: 'No subscription found'});
    }

    const subscriptionData = subscriptionDoc.data();

    if (subscriptionData?.status !== 'active') {
      return res.status(400).json({error: 'Subscription is not active'});
    }

    // キャンセル処理
    await db.collection('subscriptions').doc(userId).update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancellationReason: reason || 'User requested',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Firebase Authのカスタムクレームを更新
    await admin.auth().setCustomUserClaims(userId, {
      subscriptionTier: 'free',
      isPremium: false
    });

    res.json({
      success: true,
      message: 'Subscription cancelled successfully'
    });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// サブスクリプション復元
app.post('/restore', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    // ユーザーの購入履歴を確認
    const purchasesSnapshot = await db.collection('purchases')
        .where('userId', '==', userId)
        .where('status', '==', 'verified')
        .orderBy('purchaseDate', 'desc')
        .limit(1)
        .get();

    if (purchasesSnapshot.empty) {
      return res.status(404).json({error: 'No valid purchases found'});
    }

    const latestPurchase = purchasesSnapshot.docs[0].data();

    // サブスクリプション状態を復元
    let subscriptionTier: 'free' | 'premium' = 'free';
    if (latestPurchase.productId.includes('premium')) {
      subscriptionTier = 'premium';
    }

    await db.collection('subscriptions').doc(userId).set({
      userId,
      subscriptionTier,
      status: 'active',
      productId: latestPurchase.productId,
      transactionId: latestPurchase.transactionId,
      originalTransactionId: latestPurchase.originalTransactionId,
      receiptData: latestPurchase.receiptData,
      restoredAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});

    // Firebase Authのカスタムクレームを更新
    await admin.auth().setCustomUserClaims(userId, {
      subscriptionTier,
      isPremium: subscriptionTier === 'premium'
    });

    res.json({
      success: true,
      message: 'Subscription restored successfully',
      data: {
        subscriptionTier,
        status: 'active',
        isPremium: subscriptionTier === 'premium'
      }
    });
  } catch (error) {
    console.error('Restore subscription error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// 購入履歴取得
app.get('/purchases', verifyToken, async (req: any, res: any) => {
  try {
    const userId = req.user.uid;

    const purchasesSnapshot = await db.collection('purchases')
        .where('userId', '==', userId)
        .orderBy('purchaseDate', 'desc')
        .get();

    const purchases = purchasesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      receiptData: undefined // セキュリティのため除外
    }));

    res.json({success: true, data: purchases});
  } catch (error) {
    console.error('Get purchases error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// 管理者用：全サブスクリプション統計
app.get('/admin/stats', verifyToken, async (req: any, res: any) => {
  try {
    // 管理者権限チェック
    if (req.user.role !== 'admin') {
      return res.status(403).json({error: 'Forbidden: Admin access required'});
    }

    // アクティブサブスクリプション数
    const activeSubscriptions = await db.collection('subscriptions')
        .where('status', '==', 'active')
        .where('subscriptionTier', '==', 'premium')
        .count()
        .get();

    // 今月の新規サブスクリプション
    const monthStart = dayjs().startOf('month').toDate();
    const newSubscriptionsThisMonth = await db.collection('subscriptions')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(monthStart))
        .count()
        .get();

    // キャンセル率
    const cancelledSubscriptions = await db.collection('subscriptions')
        .where('status', '==', 'cancelled')
        .count()
        .get();

    const totalSubscriptions = await db.collection('subscriptions')
        .count()
        .get();

    const stats = {
      activeSubscriptions: activeSubscriptions.data().count,
      newSubscriptionsThisMonth: newSubscriptionsThisMonth.data().count,
      cancelledSubscriptions: cancelledSubscriptions.data().count,
      totalSubscriptions: totalSubscriptions.data().count,
      cancellationRate: totalSubscriptions.data().count > 0 ?
          (cancelledSubscriptions.data().count / totalSubscriptions.data().count) * 100 : 0
    };

    res.json({success: true, data: stats});
  } catch (error) {
    console.error('Get admin stats error:', error);
    res.status(500).json({error: 'Internal server error'});
  }
});

// エラーハンドリング
app.use((error: any, req: any, res: any, next: any) => {
  console.error('Subscriptions API Error:', error);
  res.status(500).json({error: 'Internal server error'});
});

// Firebase Functions としてエクスポート
export const subscriptions = functions
    .region(region.value())
    .https
    .onRequest(app);