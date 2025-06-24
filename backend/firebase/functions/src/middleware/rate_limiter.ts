import * as admin from 'firebase-admin';
import {Request, Response, NextFunction} from 'express';
import {AuthenticatedRequest} from './auth';

// レート制限設定
interface RateLimitConfig {
  windowMs: number;      // 時間窓（ミリ秒）
  maxRequests: number;   // 最大リクエスト数
  keyGenerator?: (req: Request) => string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
  message?: string;
}

// レート制限エラー
export class RateLimitError extends Error {
  public statusCode: number = 429;
  public retryAfter: number;

  constructor(message: string, retryAfter: number) {
    super(message);
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
  }
}

// レート制限データ
interface RateLimitData {
  count: number;
  resetTime: number;
  firstRequest: number;
}

// メモリベースの制限データストア（本番環境ではRedisやFirestoreを使用）
const rateLimitStore = new Map<string, RateLimitData>();

// 基本レート制限ミドルウェア
export const createRateLimit = (config: RateLimitConfig) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const key = config.keyGenerator ? config.keyGenerator(req) : getDefaultKey(req);
      const now = Date.now();

      // 既存のデータを取得または作成
      let limitData = rateLimitStore.get(key);

      if (!limitData || now > limitData.resetTime) {
        // 新しい時間窓を開始
        limitData = {
          count: 0,
          resetTime: now + config.windowMs,
          firstRequest: now
        };
      }

      // リクエスト数をインクリメント
      limitData.count++;
      rateLimitStore.set(key, limitData);

      // 制限チェック
      if (limitData.count > config.maxRequests) {
        const retryAfter = Math.ceil((limitData.resetTime - now) / 1000);

        // レート制限ログ
        await logRateLimitEvent('rate_limit_exceeded', {
          key,
          count: limitData.count,
          maxRequests: config.maxRequests,
          windowMs: config.windowMs,
          ip: req.ip,
          userAgent: req.headers['user-agent'],
          endpoint: req.path
        });

        res.set({
          'X-RateLimit-Limit': config.maxRequests.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': Math.ceil(limitData.resetTime / 1000).toString(),
          'Retry-After': retryAfter.toString()
        });

        return res.status(429).json({
          success: false,
          error: config.message || 'Too many requests',
          code: 'RATE_LIMIT_EXCEEDED',
          retryAfter
        });
      }

      // レスポンスヘッダーに制限情報を追加
      res.set({
        'X-RateLimit-Limit': config.maxRequests.toString(),
        'X-RateLimit-Remaining': (config.maxRequests - limitData.count).toString(),
        'X-RateLimit-Reset': Math.ceil(limitData.resetTime / 1000).toString()
      });

      next();
    } catch (error) {
      console.error('Rate limit middleware error:', error);
      // レート制限エラーでもリクエストを通す（フォールバック）
      next();
    }
  };
};

// デフォルトのキー生成（IP + User Agent）
const getDefaultKey = (req: Request): string => {
  const ip = req.ip || 'unknown';
  const userAgent = req.headers['user-agent'] || 'unknown';
  return `${ip}:${userAgent.substring(0, 50)}`;
};

// ユーザーベースのレート制限
export const createUserRateLimit = (config: RateLimitConfig) => {
  return createRateLimit({
    ...config,
    keyGenerator: (req: Request) => {
      const authReq = req as AuthenticatedRequest;
      return authReq.userId || authReq.user?.uid || getDefaultKey(req);
    }
  });
};

// API エンドポイント別レート制限
export const createEndpointRateLimit = (config: RateLimitConfig) => {
  return createRateLimit({
    ...config,
    keyGenerator: (req: Request) => {
      const authReq = req as AuthenticatedRequest;
      const userId = authReq.userId || 'anonymous';
      return `${userId}:${req.path}`;
    }
  });
};

// グローバルレート制限（全ユーザー共通）
export const globalRateLimit = createRateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  maxRequests: 10000, // 15分間で10,000リクエスト
  message: 'Global rate limit exceeded'
});

// ユーザー別レート制限（認証済みユーザー）
export const userRateLimit = createUserRateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  maxRequests: 1000, // 15分間で1,000リクエスト
  message: 'User rate limit exceeded'
});

// 厳格なレート制限（認証・重要操作用）
export const strictRateLimit = createUserRateLimit({
  windowMs: 60 * 1000, // 1分
  maxRequests: 10, // 1分間で10リクエスト
  message: 'Strict rate limit exceeded'
});

// AI API用レート制限（プレミアム vs 無料）
export const aiRateLimit = (req: Request, res: Response, next: NextFunction) => {
  const authReq = req as AuthenticatedRequest;

  // プレミアムユーザーかチェック
  const isPremium = authReq.user?.subscriptionTier === 'premium' &&
                   authReq.user?.isPremium === true;

  const config: RateLimitConfig = isPremium ? {
    windowMs: 60 * 60 * 1000, // 1時間
    maxRequests: 1000, // プレミアム：1時間1000回
    message: 'AI API rate limit exceeded (Premium)'
  } : {
    windowMs: 60 * 60 * 1000, // 1時間
    maxRequests: 50, // 無料：1時間50回
    message: 'AI API rate limit exceeded (Free tier)'
  };

  return createUserRateLimit(config)(req, res, next);
};

// 管理者API用レート制限
export const adminRateLimit = createUserRateLimit({
  windowMs: 60 * 1000, // 1分
  maxRequests: 100, // 管理者：1分間100リクエスト
  message: 'Admin API rate limit exceeded'
});

// 画像アップロード用レート制限
export const uploadRateLimit = createUserRateLimit({
  windowMs: 60 * 1000, // 1分
  maxRequests: 5, // 1分間で5回
  message: 'Upload rate limit exceeded'
});

// DDoS 防止用の厳格な制限
export const ddosProtection = createRateLimit({
  windowMs: 1 * 60 * 1000, // 1分
  maxRequests: 100, // IP当たり1分間で100リクエスト
  keyGenerator: (req: Request) => req.ip || 'unknown',
  message: 'DDoS protection triggered'
});

// 疑わしい活動の検出
export const suspiciousActivityDetection = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId;
    const ip = req.ip;
    const userAgent = req.headers['user-agent'];

    if (!userId) {
      next();
      return;
    }

    // 最近のリクエストパターンを分析
    const recentRequests = await getRecentRequests(userId, 60 * 1000); // 1分間

    // 疑わしいパターンの検出
    const suspiciousIndicators = {
      rapidRequests: recentRequests.length > 50, // 1分間で50回以上
      multipleIPs: new Set(recentRequests.map(r => r.ip)).size > 3, // 複数IPから
      unusualUserAgent: isUnusualUserAgent(userAgent || ''),
      repeatedFailures: recentRequests.filter(r => r.failed).length > 10
    };

    const suspiciousCount = Object.values(suspiciousIndicators).filter(Boolean).length;

    if (suspiciousCount >= 2) {
      // 疑わしい活動をログ
      await logRateLimitEvent('suspicious_activity_detected', {
        userId,
        ip,
        userAgent,
        indicators: suspiciousIndicators,
        suspiciousCount,
        recentRequestCount: recentRequests.length
      });

      // 一時的な制限を適用
      return res.status(429).json({
        success: false,
        error: 'Suspicious activity detected. Please try again later.',
        code: 'SUSPICIOUS_ACTIVITY',
        retryAfter: 300 // 5分後に再試行
      });
    }

    next();
  } catch (error) {
    console.error('Suspicious activity detection error:', error);
    next(); // エラーでもリクエストを通す
  }
};

// 最近のリクエスト履歴を取得（簡略化実装）
const getRecentRequests = async (userId: string, windowMs: number): Promise<any[]> => {
  try {
    const db = admin.firestore();
    const since = new Date(Date.now() - windowMs);

    const snapshot = await db.collection('request_logs')
        .where('userId', '==', userId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map(doc => doc.data());
  } catch (error) {
    console.error('Failed to get recent requests:', error);
    return [];
  }
};

// 異常なUser Agentの検出
const isUnusualUserAgent = (userAgent: string): boolean => {
  const suspiciousPatterns = [
    /bot/i, /crawler/i, /spider/i, /scraper/i,
    /curl/i, /wget/i, /python/i, /java/i,
    /postman/i, /insomnia/i
  ];

  return suspiciousPatterns.some(pattern => pattern.test(userAgent));
};

// レート制限イベントのログ
const logRateLimitEvent = async (eventType: string, eventData: any): Promise<void> => {
  try {
    const db = admin.firestore();

    await db.collection('rate_limit_logs').add({
      eventType,
      eventData,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    console.error('Failed to log rate limit event:', error);
  }
};

// 定期的なクリーンアップ（メモリリーク防止）
export const cleanupRateLimitStore = (): void => {
  const now = Date.now();

  for (const [key, data] of rateLimitStore.entries()) {
    if (now > data.resetTime + 60000) { // 1分の猶予期間
      rateLimitStore.delete(key);
    }
  }
};

// 定期クリーンアップの開始
let cleanupInterval: NodeJS.Timeout | null = null;

export const startRateLimitCleanup = (): void => {
  if (cleanupInterval) {
    clearInterval(cleanupInterval);
  }

  cleanupInterval = setInterval(cleanupRateLimitStore, 5 * 60 * 1000); // 5分ごと
};

export const stopRateLimitCleanup = (): void => {
  if (cleanupInterval) {
    clearInterval(cleanupInterval);
    cleanupInterval = null;
  }
};