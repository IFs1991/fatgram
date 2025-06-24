import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import {defineString} from 'firebase-functions/params';

// APIおよびサービスのインポート
import './api/auth';
import './api/activities';
import './api/subscriptions';
import './api/ai';
import './api/reports';
import './api/secrets';

// 環境変数
const region = defineString('REGION', {default: 'asia-northeast1'});

// Firebase Adminの初期化
admin.initializeApp();

// データベース参照
const db = admin.firestore();

// ユーザー作成時にカスタムクレームを設定する
export const onUserCreated = functions
    .region(region.value())
    .auth.user()
    .onCreate(async (user) => {
      // 新規ユーザーに無料プランを設定
      await admin.auth().setCustomUserClaims(user.uid, {
        subscriptionTier: 'free',
      });

      // Firestoreにユーザードキュメントを作成
      await db.collection('users').doc(user.uid).set({
        displayName: user.displayName || '',
        email: user.email || '',
        profileImageUrl: user.photoURL || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        subscriptionTier: 'free',
        goals: {
          dailyFatBurn: null,
          weeklyActivityMinutes: null,
        },
      });

      return null;
    });

// ユーザー削除時の処理
export const onUserDeleted = functions
    .region(region.value())
    .auth.user()
    .onDelete(async (user) => {
      // ユーザー関連のデータを削除
      const batch = db.batch();

      // ユーザードキュメントの削除
      batch.delete(db.collection('users').doc(user.uid));

      // ユーザーのアクティビティを取得して削除
      const activities = await db.collection('activities')
          .where('userId', '==', user.uid)
          .get();

      activities.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // ユーザーの会話を取得して削除
      const conversations = await db.collection('conversations')
          .where('userId', '==', user.uid)
          .get();

      conversations.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // バッチコミット
      await batch.commit();

      return null;
    });

// デフォルトエクスポート
export default {onUserCreated, onUserDeleted};