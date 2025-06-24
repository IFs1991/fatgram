import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import {defineString, defineSecret} from 'firebase-functions/params';

// 環境設定
const region = defineString('REGION', {default: 'asia-northeast1'});

// シークレット定義
const encryptionKey = defineSecret('API_ENCRYPTION_KEY');
const masterApiKey = defineSecret('MASTER_API_KEY');

// Firestore参照
const db = admin.firestore();

// APIプロバイダー定義
enum ApiProvider {
  OPENAI = 'openai',
  GEMINI = 'gemini',
  WEB_SEARCH = 'webSearch',
  REVENUE_CAT = 'revenueCat',
  FIREBASE = 'firebase'
}

// APIキー情報の型定義
interface ApiKeyInfo {
  provider: ApiProvider;
  encryptedKey: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  lastUsed?: admin.firestore.Timestamp;
  usageCount: number;
  isActive: boolean;
}

// リクエスト型定義
interface StoreApiKeyRequest {
  provider: ApiProvider;
  apiKey: string;
}

interface GetApiKeyRequest {
  provider: ApiProvider;
}

interface RefreshApiKeyRequest {
  provider: ApiProvider;
}

// レスポンス型定義
interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

/**
 * 認証ミドルウェア
 */
async function authenticateUser(authorization: string | undefined): Promise<admin.auth.DecodedIdToken> {
  if (!authorization || !authorization.startsWith('Bearer ')) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Missing or invalid authorization header'
    );
  }

  const token = authorization.substring(7);

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Invalid authentication token'
    );
  }
}

/**
 * 管理者権限チェック
 */
async function checkAdminPermission(uid: string): Promise<void> {
  const userRecord = await admin.auth().getUser(uid);
  const customClaims = userRecord.customClaims;

  if (!customClaims?.isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin privileges required'
    );
  }
}

/**
 * データ暗号化
 */
function encryptData(data: string, key: string): string {
  const algorithm = 'aes-256-gcm';
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipher(algorithm, key);

  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  return `${iv.toString('hex')}:${encrypted}:${authTag.toString('hex')}`;
}

/**
 * データ復号化
 */
function decryptData(encryptedData: string, key: string): string {
  const algorithm = 'aes-256-gcm';
  const parts = encryptedData.split(':');

  if (parts.length !== 3) {
    throw new Error('Invalid encrypted data format');
  }

  const iv = Buffer.from(parts[0], 'hex');
  const encrypted = parts[1];
  const authTag = Buffer.from(parts[2], 'hex');

  const decipher = crypto.createDecipher(algorithm, key);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}

/**
 * APIキーを暗号化して保存
 */
export const storeApiKey = functions
  .region(region.value())
  .runWith({
    secrets: [encryptionKey, masterApiKey]
  })
  .https.onCall(async (data: StoreApiKeyRequest, context) => {
    try {
      // 認証チェック
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required'
        );
      }

      // 管理者権限チェック
      await checkAdminPermission(context.auth.uid);

      // 入力検証
      if (!data.provider || !data.apiKey) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Provider and API key are required'
        );
      }

      if (!Object.values(ApiProvider).includes(data.provider)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid API provider'
        );
      }

      // データ暗号化
      const encrypted = encryptData(data.apiKey, encryptionKey.value());

      // Firestoreに保存
      const apiKeyDoc: ApiKeyInfo = {
        provider: data.provider,
        encryptedKey: encrypted,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        usageCount: 0,
        isActive: true,
      };

      await db.collection('api_keys').doc(data.provider).set(apiKeyDoc);

      const response: ApiResponse<{ provider: string }> = {
        success: true,
        data: { provider: data.provider },
        timestamp: new Date().toISOString(),
      };

      return response;

    } catch (error) {
      console.error('Error storing API key:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to store API key'
      );
    }
  });

/**
 * APIキーを取得・復号化
 */
export const getApiKey = functions
  .region(region.value())
  .runWith({
    secrets: [encryptionKey]
  })
  .https.onCall(async (data: GetApiKeyRequest, context) => {
    try {
      // 認証チェック
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required'
        );
      }

      // 入力検証
      if (!data.provider) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Provider is required'
        );
      }

      if (!Object.values(ApiProvider).includes(data.provider)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid API provider'
        );
      }

      // Firestoreから取得
      const doc = await db.collection('api_keys').doc(data.provider).get();

      if (!doc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'API key not found for this provider'
        );
      }

      const apiKeyInfo = doc.data() as ApiKeyInfo;

      if (!apiKeyInfo.isActive) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'API key is not active'
        );
      }

      // 復号化
      const decryptedKey = decryptData(apiKeyInfo.encryptedKey, encryptionKey.value());

      // 使用回数を更新
      await doc.ref.update({
        lastUsed: admin.firestore.Timestamp.now(),
        usageCount: admin.firestore.FieldValue.increment(1),
      });

      const response: ApiResponse<{ apiKey: string }> = {
        success: true,
        data: { apiKey: decryptedKey },
        timestamp: new Date().toISOString(),
      };

      return response;

    } catch (error) {
      console.error('Error getting API key:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to get API key'
      );
    }
  });

/**
 * APIキーをリフレッシュ
 */
export const refreshApiKey = functions
  .region(region.value())
  .runWith({
    secrets: [encryptionKey, masterApiKey]
  })
  .https.onCall(async (data: RefreshApiKeyRequest, context) => {
    try {
      // 認証チェック
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required'
        );
      }

      // 管理者権限チェック
      await checkAdminPermission(context.auth.uid);

      // 入力検証
      if (!data.provider) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Provider is required'
        );
      }

      if (!Object.values(ApiProvider).includes(data.provider)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid API provider'
        );
      }

      // 実際の実装では、各プロバイダーのAPIから新しいキーを取得
      // ここではデモンストレーション用のロジック
      const newApiKey = await generateNewApiKey(data.provider);

      // 新しいキーを暗号化
      const encrypted = encryptData(newApiKey, encryptionKey.value());

      // Firestoreを更新
      await db.collection('api_keys').doc(data.provider).update({
        encryptedKey: encrypted,
        updatedAt: admin.firestore.Timestamp.now(),
        usageCount: 0,
      });

      const response: ApiResponse<{ provider: string; refreshed: boolean }> = {
        success: true,
        data: {
          provider: data.provider,
          refreshed: true
        },
        timestamp: new Date().toISOString(),
      };

      return response;

    } catch (error) {
      console.error('Error refreshing API key:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to refresh API key'
      );
    }
  });

/**
 * APIキー使用統計を取得
 */
export const getApiKeyStats = functions
  .region(region.value())
  .https.onCall(async (data, context) => {
    try {
      // 認証チェック
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required'
        );
      }

      // 管理者権限チェック
      await checkAdminPermission(context.auth.uid);

      // 全てのAPIキー統計を取得
      const snapshot = await db.collection('api_keys').get();
      const stats: { [key: string]: any } = {};

      snapshot.forEach(doc => {
        const data = doc.data() as ApiKeyInfo;
        stats[doc.id] = {
          provider: data.provider,
          createdAt: data.createdAt.toDate().toISOString(),
          updatedAt: data.updatedAt.toDate().toISOString(),
          lastUsed: data.lastUsed?.toDate().toISOString() || null,
          usageCount: data.usageCount,
          isActive: data.isActive,
        };
      });

      const response: ApiResponse<{ stats: any }> = {
        success: true,
        data: { stats },
        timestamp: new Date().toISOString(),
      };

      return response;

    } catch (error) {
      console.error('Error getting API key stats:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to get API key statistics'
      );
    }
  });

/**
 * APIキーを無効化
 */
export const deactivateApiKey = functions
  .region(region.value())
  .https.onCall(async (data: { provider: ApiProvider }, context) => {
    try {
      // 認証チェック
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required'
        );
      }

      // 管理者権限チェック
      await checkAdminPermission(context.auth.uid);

      // 入力検証
      if (!data.provider) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Provider is required'
        );
      }

      // APIキーを無効化
      await db.collection('api_keys').doc(data.provider).update({
        isActive: false,
        updatedAt: admin.firestore.Timestamp.now(),
      });

      const response: ApiResponse<{ provider: string; deactivated: boolean }> = {
        success: true,
        data: {
          provider: data.provider,
          deactivated: true
        },
        timestamp: new Date().toISOString(),
      };

      return response;

    } catch (error) {
      console.error('Error deactivating API key:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to deactivate API key'
      );
    }
  });

/**
 * 新しいAPIキーを生成（プロバイダー別のロジック）
 */
async function generateNewApiKey(provider: ApiProvider): Promise<string> {
  // 実際の実装では、各プロバイダーのAPIエンドポイントを呼び出す
  // ここではデモンストレーション用の実装

  const timestamp = Date.now();
  const randomSuffix = crypto.randomBytes(16).toString('hex');

  switch (provider) {
    case ApiProvider.OPENAI:
      return `sk-${randomSuffix}${timestamp}`;
    case ApiProvider.GEMINI:
      return `AIza${randomSuffix}${timestamp}`;
    case ApiProvider.WEB_SEARCH:
      return `ws_${randomSuffix}${timestamp}`;
    case ApiProvider.REVENUE_CAT:
      return `rc_${randomSuffix}${timestamp}`;
    case ApiProvider.FIREBASE:
      return `fb_${randomSuffix}${timestamp}`;
    default:
      throw new Error(`Unsupported provider: ${provider}`);
  }
}