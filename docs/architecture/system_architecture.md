# FatGram システムアーキテクチャ

## 概要

FatGramは、以下の主要コンポーネントで構成されるアプリケーションです：

1. **Flutterモバイルアプリケーション** - iOS/Androidデバイス向けのクロスプラットフォームUIアプリケーション
2. **クラウドバックエンド** - Google Cloud Platformで稼働するバックエンドシステム
3. **AIサービス** - Vertex AIを活用した会話型AIおよび分析機能

## システムコンポーネント

```
┌───────────────────┐      ┌───────────────────────────────────┐
│                   │      │                                   │
│  Flutter アプリ    │ ←──→ │  Google Cloud Platform バックエンド  │
│  (iOS/Android)    │      │                                   │
│                   │      └───────────┬───────────────────────┘
└─────────┬─────────┘                  │
          │                            │
          │                            │
          ↓                            ↓
┌───────────────────┐      ┌───────────────────────────────────┐
│                   │      │                                   │
│ スマートウォッチAPI  │      │  Vertex AI / その他AIサービス      │
│ (HealthKit/Fit)   │      │                                   │
│                   │      │                                   │
└───────────────────┘      └───────────────────────────────────┘
```

## 責任の分離

### Flutterアプリケーション

- ユーザーインターフェース（UI/UX）
- ローカルデータキャッシュ
- スマートウォッチとの連携（Apple HealthKit, Google Fit）
- オフライン操作の処理
- 状態管理（Riverpodを使用）

### GCPバックエンド

- ユーザー認証と認可（Firebase Auth）
- データの永続化（Cloud Firestore）
- プレミアム機能の管理（RevenueCat連携）
- REST APIエンドポイント（Cloud Run）
- バックグラウンド処理（Cloud Functions）

### AIサービス

- チャットアシスタント（Vertex AI Gemini）
- 脂肪燃焼分析アルゴリズム
- パーソナライズされた推奨事項の生成
- 目標設定のAIサポート
- ウェブ情報検索連携

## データフロー

1. ユーザーのアクティビティデータはスマートウォッチから Flutter アプリに同期されます
2. Flutter アプリはデータを処理し、ローカルでの表示と分析を行います
3. データはGCPバックエンドに送信され、永続化されます
4. AIサービスはバックエンドからのデータを使用して高度な分析と個人化されたアドバイスを提供します
5. 結果はバックエンドを通じてアプリに返され、ユーザーに表示されます

## 技術スタック

### フロントエンド（Flutter）

- Flutter SDK
- Dart言語
- Riverpod（状態管理）
- flutter_chart（データ可視化）
- ヘルスAPIライブラリ
- HTTP/REST クライアント

### バックエンド（GCP）

- Firebase Authentication
- Cloud Firestore
- Cloud Run
- Cloud Functions
- Cloud Storage
- Vertex AI API

### CI/CD

- GitHub Actions
- Firebase App Distribution
- Flutter テスト自動化

## エラーハンドリング戦略

- フロントエンドでのUI表示によるエラー通知
- バックログと例外追跡（Firebase Crashlytics）
- グレースフルデグラデーション（機能低下時の代替操作）
- ネットワーク接続の復元力（オフラインモード対応）

## セキュリティ

- Firebase Authentication を使用したセキュアな認証
- HTTPS によるすべての通信の暗号化
- Firebase Security Rules による権限管理
- センシティブデータの安全な保存