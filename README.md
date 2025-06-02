# FatGram

スマートウォッチと連携して脂肪燃焼量をリアルタイム表示・分析するアプリ。AIによるパーソナルアドバイス機能搭載。

## 概要

FatGramは、スマートウォッチ（Apple Watch、Wear OS対応デバイス）と連携して、ユーザーの活動データから脂肪燃焼量を計算し、分かりやすく可視化するアプリケーションです。Google Cloud Platform上のVertex AIを活用し、ユーザーのフィットネス目標達成をサポートします。

### 主な機能

- **脂肪燃焼量のリアルタイム計算**: 7.2kcal/gの換算係数を使用して、カロリー消費から脂肪燃焼量を計算
- **スマートウォッチとの連携**: Apple HealthKit、Health Connectを通じて活動データを自動取得
- **詳細なデータ分析**: 活動タイプ別、時間帯別の脂肪燃焼量を分析
- **AI会話アシスタント**: フィットネスに特化したAIアシスタントが質問に回答
- **パーソナライズされた目標設定**: AIによる適切な目標設定と進捗追跡
- **週間/月間レポート**: 詳細なレポートで継続的なモチベーション維持をサポート

## プロジェクト構造

```
fatgram/
├── docs/                       # プロジェクトドキュメント
│   ├── architecture/           # アーキテクチャドキュメント
│   ├── api/                    # API ドキュメント
│   └── structure/              # 構造ドキュメント
├── mobile/                     # Flutter モバイルアプリケーション
├── backend/                    # バックエンドサービス
│   ├── auth-service/           # 認証サービス
│   ├── activity-service/       # アクティビティデータ処理サービス
│   ├── subscription-service/   # サブスクリプション管理サービス
│   ├── ai-service/             # AIアシスタントサービス
│   ├── report-service/         # レポート生成サービス
│   ├── firebase/               # Firebase設定とセキュリティルール
│   └── terraform/              # インフラストラクチャコード
├── packages/                   # 共有パッケージ
├── scripts/                    # デプロイメントと開発スクリプト
└── README.md                   # このファイル
```

## 技術スタック

- **フロントエンド**: Flutter/Dart, Riverpod（状態管理）
- **バックエンド**: Google Cloud Platform (Cloud Run, Cloud Functions)
- **データベース**: Cloud Firestore
- **認証**: Firebase Authentication
- **AI**: Vertex AI Gemini
- **インフラストラクチャ**: Terraform
- **CI/CD**: GitHub Actions

## 開発環境のセットアップ

### 前提条件

- Flutter 3.10.0以上
- Dart 3.0.0以上
- Node.js 18.x以上
- Firebase CLI
- Google Cloud SDK

### インストール手順

1. リポジトリのクローン:
   ```bash
   git clone https://github.com/IFs1991/fatgram.git
   cd fatgram
   ```

2. Flutter依存関係のインストール:
   ```bash
   cd mobile
   flutter pub get
   cd ..
   ```

3. Firebase設定:
   ```bash
   cd backend/firebase/functions
   npm install
   cd ../../..
   ```

4. ローカル開発サーバーの起動:
   ```bash
   cd ../../../
   ./scripts/dev.sh
   ```

## アーキテクチャ

FatGramはクリーンアーキテクチャの原則に基づいて設計されています。詳細については[アーキテクチャドキュメント](docs/architecture/system_architecture.md)を参照してください。

## API契約

フロントエンドとバックエンド間の通信インターフェースは明確に定義されています。詳細については[API契約ドキュメント](docs/api/api_contract.md)を参照してください。

## 開発ワークフロー

開発プロセスと貢献方法については[開発ワークフロードキュメント](docs/workflow/development_workflow.md)を参照してください。

## ライセンス

Copyright © 2023 IFs1991. All rights reserved.
