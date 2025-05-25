# FatGram API コントラクト

このドキュメントは、FatGramのフロントエンドとバックエンド間のAPI契約を定義します。

## 認証API

### ユーザー登録

```
POST /api/v1/auth/register
```

**リクエスト**

```json
{
  "email": "string",
  "password": "string",
  "display_name": "string"
}
```

**レスポンス**

```json
{
  "user_id": "string",
  "token": "string",
  "refresh_token": "string",
  "expires_at": "number"
}
```

**エラーコード**
- `400` - 入力データが無効
- `409` - メールアドレスが既に使用されている

### ログイン

```
POST /api/v1/auth/login
```

**リクエスト**

```json
{
  "email": "string",
  "password": "string"
}
```

**レスポンス**

```json
{
  "user_id": "string",
  "token": "string",
  "refresh_token": "string",
  "expires_at": "number"
}
```

**エラーコード**
- `400` - 入力データが無効
- `401` - 認証失敗

### トークンリフレッシュ

```
POST /api/v1/auth/refresh
```

**リクエスト**

```json
{
  "refresh_token": "string"
}
```

**レスポンス**

```json
{
  "token": "string",
  "refresh_token": "string",
  "expires_at": "number"
}
```

**エラーコード**
- `401` - 無効なリフレッシュトークン

## ユーザープロファイルAPI

### プロファイル取得

```
GET /api/v1/users/profile
```

**ヘッダー**
- `Authorization: Bearer {token}`

**レスポンス**

```json
{
  "id": "string",
  "email": "string",
  "display_name": "string",
  "profile_image_url": "string",
  "created_at": "string",
  "subscription_tier": "string",
  "goals": {
    "daily_fat_burn": "number",
    "weekly_activity_minutes": "number"
  }
}
```

**エラーコード**
- `401` - 未認証

### プロファイル更新

```
PUT /api/v1/users/profile
```

**ヘッダー**
- `Authorization: Bearer {token}`

**リクエスト**

```json
{
  "display_name": "string",
  "goals": {
    "daily_fat_burn": "number",
    "weekly_activity_minutes": "number"
  }
}
```

**レスポンス**

```json
{
  "id": "string",
  "email": "string",
  "display_name": "string",
  "profile_image_url": "string",
  "created_at": "string",
  "subscription_tier": "string",
  "goals": {
    "daily_fat_burn": "number",
    "weekly_activity_minutes": "number"
  }
}
```

**エラーコード**
- `400` - 入力データが無効
- `401` - 未認証

## アクティビティデータAPI

### アクティビティデータ同期

```
POST /api/v1/activities/sync
```

**ヘッダー**
- `Authorization: Bearer {token}`

**リクエスト**

```json
{
  "activities": [
    {
      "activity_id": "string",
      "activity_type": "string",
      "start_time": "string",
      "end_time": "string",
      "calories_burned": "number",
      "heart_rate_data": [
        {
          "timestamp": "string",
          "value": "number"
        }
      ],
      "steps": "number",
      "distance": "number"
    }
  ]
}
```

**レスポンス**

```json
{
  "synced_activities": "number",
  "fat_burned_grams": "number",
  "sync_timestamp": "string"
}
```

**エラーコード**
- `400` - 入力データが無効
- `401` - 未認証

### アクティビティ履歴取得

```
GET /api/v1/activities?start_date={date}&end_date={date}
```

**ヘッダー**
- `Authorization: Bearer {token}`

**クエリパラメータ**
- `start_date` - 開始日 (ISO 8601形式)
- `end_date` - 終了日 (ISO 8601形式)

**レスポンス**

```json
{
  "activities": [
    {
      "activity_id": "string",
      "activity_type": "string",
      "start_time": "string",
      "end_time": "string",
      "calories_burned": "number",
      "fat_burned_grams": "number",
      "heart_rate_avg": "number",
      "heart_rate_max": "number",
      "steps": "number",
      "distance": "number"
    }
  ],
  "summary": {
    "total_activities": "number",
    "total_fat_burned_grams": "number",
    "total_calories_burned": "number",
    "total_duration_minutes": "number"
  }
}
```

**エラーコード**
- `400` - 無効なクエリパラメータ
- `401` - 未認証

## サブスクリプションAPI

### サブスクリプション状態取得

```
GET /api/v1/subscriptions/status
```

**ヘッダー**
- `Authorization: Bearer {token}`

**レスポンス**

```json
{
  "subscription_tier": "string",
  "is_active": "boolean",
  "expires_at": "string",
  "auto_renew": "boolean",
  "features": [
    {
      "feature_id": "string",
      "feature_name": "string",
      "is_enabled": "boolean"
    }
  ]
}
```

**エラーコード**
- `401` - 未認証

### サブスクリプション検証

```
POST /api/v1/subscriptions/verify
```

**ヘッダー**
- `Authorization: Bearer {token}`

**リクエスト**

```json
{
  "receipt": "string",
  "platform": "string" // "apple" または "google"
}
```

**レスポンス**

```json
{
  "is_valid": "boolean",
  "subscription_tier": "string",
  "expires_at": "string",
  "auto_renew": "boolean"
}
```

**エラーコード**
- `400` - 入力データが無効
- `401` - 未認証

## AI アシスタントAPI

### チャットメッセージ送信

```
POST /api/v1/ai/chat
```

**ヘッダー**
- `Authorization: Bearer {token}`

**リクエスト**

```json
{
  "message": "string",
  "conversation_id": "string"
}
```

**レスポンス**

```json
{
  "response": "string",
  "conversation_id": "string",
  "message_id": "string",
  "sources": [
    {
      "title": "string",
      "url": "string"
    }
  ]
}
```

**エラーコード**
- `400` - 入力データが無効
- `401` - 未認証
- `402` - サブスクリプションの支払いが必要

### 会話履歴取得

```
GET /api/v1/ai/conversations?limit={number}&offset={number}
```

**ヘッダー**
- `Authorization: Bearer {token}`

**クエリパラメータ**
- `limit` - 取得する会話の最大数
- `offset` - ページネーションのオフセット

**レスポンス**

```json
{
  "conversations": [
    {
      "conversation_id": "string",
      "title": "string",
      "last_message": "string",
      "created_at": "string",
      "updated_at": "string"
    }
  ],
  "total": "number"
}
```

**エラーコード**
- `400` - 無効なクエリパラメータ
- `401` - 未認証

## レポートAPI

### 週間レポート取得

```
GET /api/v1/reports/weekly?date={date}
```

**ヘッダー**
- `Authorization: Bearer {token}`

**クエリパラメータ**
- `date` - レポートを生成する週の任意の日 (ISO 8601形式)

**レスポンス**

```json
{
  "start_date": "string",
  "end_date": "string",
  "total_fat_burned_grams": "number",
  "daily_breakdown": [
    {
      "date": "string",
      "fat_burned_grams": "number",
      "calories_burned": "number",
      "activity_minutes": "number"
    }
  ],
  "activity_breakdown": [
    {
      "activity_type": "string",
      "fat_burned_grams": "number",
      "duration_minutes": "number",
      "count": "number"
    }
  ],
  "goal_progress": {
    "weekly_fat_burn": {
      "target": "number",
      "actual": "number",
      "percentage": "number"
    },
    "weekly_activity_minutes": {
      "target": "number",
      "actual": "number",
      "percentage": "number"
    }
  },
  "insights": [
    {
      "type": "string",
      "message": "string"
    }
  ]
}
```

**エラーコード**
- `400` - 無効なクエリパラメータ
- `401` - 未認証
- `402` - サブスクリプションの支払いが必要（詳細レポート機能）

## エラーレスポンスフォーマット

すべてのAPIエラーは以下の形式で返されます：

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "object"
  }
}
```