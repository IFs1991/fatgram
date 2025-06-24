import * as admin from 'firebase-admin';
import {Request, Response, NextFunction} from 'express';

// カスタムリクエスト型定義
export interface AuthenticatedRequest extends Request {
  user?: admin.auth.DecodedIdToken;
  userId?: string;
}

// 認証エラー型定義
export class AuthenticationError extends Error {
  public statusCode: number;

  constructor(message: string, statusCode: number = 401) {
    super(message);
    this.name = 'AuthenticationError';
    this.statusCode = statusCode;
  }
}

export class AuthorizationError extends Error {
  public statusCode: number;

  constructor(message: string, statusCode: number = 403) {
    super(message);
    this.name = 'AuthorizationError';
    this.statusCode = statusCode;
  }
}

// 基本認証ミドルウェア
export const verifyToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('No valid authorization header provided');
    }

    const token = authHeader.replace('Bearer ', '');

    if (!token) {
      throw new AuthenticationError('No token provided');
    }

    // トークンの検証
    const decodedToken = await admin.auth().verifyIdToken(token);

    // リクエストオブジェクトにユーザー情報を追加
    req.user = decodedToken;
    req.userId = decodedToken.uid;

    // セキュリティ監査ログ
    await logSecurityEvent('token_verified', {
      userId: decodedToken.uid,
      userAgent: req.headers['user-agent'],
      ip: req.ip,
      endpoint: req.path,
      method: req.method
    });

    next();
  } catch (error) {
    console.error('Token verification failed:', error);

    // セキュリティ監査ログ（失敗）
    await logSecurityEvent('token_verification_failed', {
      userAgent: req.headers['user-agent'],
      ip: req.ip,
      endpoint: req.path,
      method: req.method,
      error: error instanceof Error ? error.message : 'Unknown error'
    });

    if (error instanceof AuthenticationError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
        code: 'AUTHENTICATION_FAILED'
      });
    }

    res.status(401).json({
      success: false,
      error: 'Authentication failed',
      code: 'INVALID_TOKEN'
    });
  }
};

// 管理者権限チェックミドルウェア
export const requireAdmin = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      throw new AuthenticationError('User not authenticated');
    }

    // カスタムクレームから管理者権限を確認
    if (req.user.role !== 'admin') {
      throw new AuthorizationError('Admin access required');
    }

    // 管理者アクションのログ
    await logSecurityEvent('admin_access', {
      userId: req.user.uid,
      endpoint: req.path,
      method: req.method,
      userAgent: req.headers['user-agent'],
      ip: req.ip
    });

    next();
  } catch (error) {
    console.error('Admin authorization failed:', error);

    if (error instanceof AuthorizationError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
        code: 'ADMIN_ACCESS_REQUIRED'
      });
    }

    res.status(403).json({
      success: false,
      error: 'Access denied',
      code: 'AUTHORIZATION_FAILED'
    });
  }
};

// プレミアムアクセスチェックミドルウェア
export const requirePremium = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      throw new AuthenticationError('User not authenticated');
    }

    // データベースからサブスクリプション状態を確認
    const db = admin.firestore();
    const subscriptionDoc = await db.collection('subscriptions').doc(req.user.uid).get();

    if (!subscriptionDoc.exists) {
      throw new AuthorizationError('Premium subscription required');
    }

    const subscriptionData = subscriptionDoc.data();

    // サブスクリプション状態をチェック
    if (subscriptionData?.subscriptionTier !== 'premium' || subscriptionData?.status !== 'active') {
      // 期限切れチェック
      if (subscriptionData?.endDate && subscriptionData.endDate.toDate() < new Date()) {
        throw new AuthorizationError('Premium subscription expired');
      }

      throw new AuthorizationError('Active premium subscription required');
    }

    next();
  } catch (error) {
    console.error('Premium authorization failed:', error);

    if (error instanceof AuthorizationError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
        code: 'PREMIUM_ACCESS_REQUIRED'
      });
    }

    res.status(403).json({
      success: false,
      error: 'Premium access required',
      code: 'SUBSCRIPTION_REQUIRED'
    });
  }
};

// ユーザー自身のリソースアクセスチェック
export const requireOwnership = (resourceUserIdField: string = 'userId') => {
  return async (
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      if (!req.user) {
        throw new AuthenticationError('User not authenticated');
      }

      // リクエストパラメータまたはボディからリソースのuserIdを取得
      const resourceUserId = req.params[resourceUserIdField] || req.body[resourceUserIdField];

      if (!resourceUserId) {
        throw new AuthorizationError(`Resource ${resourceUserIdField} not found`);
      }

      // 管理者は全てのリソースにアクセス可能
      if (req.user.role === 'admin') {
        next();
        return;
      }

      // ユーザー自身のリソースかチェック
      if (req.user.uid !== resourceUserId) {
        throw new AuthorizationError('Access denied: You can only access your own resources');
      }

      next();
    } catch (error) {
      console.error('Ownership check failed:', error);

      if (error instanceof AuthorizationError) {
        return res.status(error.statusCode).json({
          success: false,
          error: error.message,
          code: 'OWNERSHIP_REQUIRED'
        });
      }

      res.status(403).json({
        success: false,
        error: 'Access denied',
        code: 'OWNERSHIP_VERIFICATION_FAILED'
      });
    }
  };
};

// アカウント状態チェックミドルウェア
export const requireActiveAccount = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      throw new AuthenticationError('User not authenticated');
    }

    // Firebase Authからユーザー情報を取得
    const userRecord = await admin.auth().getUser(req.user.uid);

    // アカウントが無効化されていないかチェック
    if (userRecord.disabled) {
      throw new AuthorizationError('Account has been disabled');
    }

    // メール認証が必要な機能の場合
    if (!userRecord.emailVerified && req.path.includes('/premium/')) {
      throw new AuthorizationError('Email verification required for premium features');
    }

    next();
  } catch (error) {
    console.error('Account status check failed:', error);

    if (error instanceof AuthorizationError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
        code: 'ACCOUNT_STATUS_INVALID'
      });
    }

    res.status(403).json({
      success: false,
      error: 'Account status verification failed',
      code: 'ACCOUNT_CHECK_FAILED'
    });
  }
};

// セキュリティイベントログ記録
const logSecurityEvent = async (
  eventType: string,
  eventData: any
): Promise<void> => {
  try {
    const db = admin.firestore();

    await db.collection('security_audit').add({
      eventType,
      eventData,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      severity: getEventSeverity(eventType)
    });
  } catch (error) {
    console.error('Failed to log security event:', error);
    // セキュリティログの失敗は処理を止めない
  }
};

// イベントの重要度を判定
const getEventSeverity = (eventType: string): 'low' | 'medium' | 'high' | 'critical' => {
  const severityMap: Record<string, 'low' | 'medium' | 'high' | 'critical'> = {
    'token_verified': 'low',
    'token_verification_failed': 'medium',
    'admin_access': 'high',
    'premium_access_denied': 'medium',
    'ownership_violation': 'high',
    'account_disabled': 'critical',
    'suspicious_activity': 'high'
  };

  return severityMap[eventType] || 'medium';
};

// 複数のミドルウェアを組み合わせるユーティリティ
export const combineMiddleware = (...middlewares: any[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const executeMiddleware = (index: number) => {
      if (index >= middlewares.length) {
        return next();
      }

      middlewares[index](req, res, (error?: any) => {
        if (error) {
          return next(error);
        }
        executeMiddleware(index + 1);
      });
    };

    executeMiddleware(0);
  };
};

// 共通ミドルウェアの組み合わせ
export const authMiddleware = combineMiddleware(verifyToken, requireActiveAccount);
export const adminMiddleware = combineMiddleware(verifyToken, requireActiveAccount, requireAdmin);
export const premiumMiddleware = combineMiddleware(verifyToken, requireActiveAccount, requirePremium);