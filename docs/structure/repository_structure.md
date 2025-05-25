# FatGram リポジトリ構造

このドキュメントでは、FatGramプロジェクトのリポジトリ構造と各ディレクトリの責任範囲を説明します。

## 概要

FatGramはモノリポとして構成され、フロントエンド（Flutter）とバックエンド（GCP）のコードを明確に分離しつつ、共有コードをパッケージとして管理します。

```
fatgram/
├── .github/                    # GitHub関連ファイル（CI/CD、PR テンプレートなど）
├── .vscode/                    # VSCode設定
├── docs/                       # プロジェクトドキュメント
│   ├── architecture/           # アーキテクチャドキュメント
│   ├── api/                    # API ドキュメント
│   └── structure/              # 構造ドキュメント
├── mobile/                     # Flutter モバイルアプリケーション
│   ├── lib/                    # Dart ソースコード
│   │   ├── main.dart           # エントリポイント
│   │   ├── app/                # アプリケーション設定と初期化
│   │   ├── core/               # コアユーティリティと基本コンポーネント
│   │   ├── data/               # データ層（リポジトリ実装、データソースなど）
│   │   ├── domain/             # ドメイン層（エンティティ、ユースケース、リポジトリインターフェース）
│   │   ├── presentation/       # プレゼンテーション層（ウィジェット、ページ、状態管理）
│   │   │   ├── pages/          # アプリケーションの各ページ
│   │   │   ├── widgets/        # 再利用可能なウィジェット
│   │   │   └── providers/      # Riverpodプロバイダー
│   │   └── utils/              # ユーティリティ関数
│   ├── assets/                 # アセット（画像、フォントなど）
│   ├── android/                # Android固有のコード
│   ├── ios/                    # iOS固有のコード
│   ├── test/                   # テストディレクトリ
│   └── pubspec.yaml            # Flutter依存関係と設定
├── backend/                    # バックエンドサービス
│   ├── auth-service/           # 認証サービス
│   ├── activity-service/       # アクティビティデータ処理サービス
│   ├── subscription-service/   # サブスクリプション管理サービス
│   ├── ai-service/             # AIアシスタントサービス
│   ├── report-service/         # レポート生成サービス
│   ├── firebase/               # Firebase設定とセキュリティルール
│   │   ├── firestore/          # Firestoreセキュリティルールとインデックス
│   │   ├── functions/          # Cloud Functions
│   │   └── storage/            # Cloud Storage設定
│   └── terraform/              # インフラストラクチャコード
│       ├── modules/            # Terraformモジュール
│       ├── environments/       # 環境別Terraform設定
│       └── main.tf             # メインTerraform設定
├── packages/                   # 共有パッケージ
│   ├── fatgram_models/         # 共有データモデル
│   ├── fatgram_api_client/     # APIクライアント
│   └── fatgram_utils/          # 共有ユーティリティ
├── scripts/                    # デプロイメントと開発スクリプト
│   ├── deploy.sh               # デプロイスクリプト
│   ├── setup.sh                # セットアップスクリプト
│   └── dev.sh                  # 開発用スクリプト
├── .gitignore                  # Git無視設定
├── pnpm-workspace.yaml         # pnpm ワークスペース設定
├── README.md                   # プロジェクト説明
└── LICENSE                     # ライセンス情報
```

## ディレクトリの責任

### `/mobile`

Flutterモバイルアプリケーションのコードを格納します。クリーンアーキテクチャに基づいて、データ層、ドメイン層、プレゼンテーション層に分割されています。

- `/lib/app` - アプリケーションの設定と初期化コード
- `/lib/core` - 基本的なコンポーネントとユーティリティ
- `/lib/data` - データソースとリポジトリの実装
- `/lib/domain` - ビジネスロジックとエンティティの定義
- `/lib/presentation` - UIコンポーネントと状態管理

### `/backend`

バックエンドサービスのコードを格納します。マイクロサービスアーキテクチャを採用し、各機能ごとに個別のサービスとして実装します。

- `/auth-service` - ユーザー認証と認可
- `/activity-service` - アクティビティデータ処理と分析
- `/subscription-service` - サブスクリプション管理とRevenueCat連携
- `/ai-service` - Vertex AIを利用したAIアシスタント機能
- `/report-service` - データ分析とレポート生成

### `/packages`

フロントエンドとバックエンド間で共有されるコードを格納します。

- `/fatgram_models` - 共有データモデルと型定義
- `/fatgram_api_client` - APIエンドポイントへのアクセスを提供するクライアント
- `/fatgram_utils` - 共通ユーティリティと補助機能

### `/docs`

プロジェクトドキュメントを格納します。

- `/architecture` - システムアーキテクチャドキュメント
- `/api` - API契約とドキュメント
- `/structure` - コード構造と規約

### `/scripts`

開発とデプロイメントを自動化するスクリプトを格納します。

- `deploy.sh` - 本番およびステージング環境へのデプロイスクリプト
- `setup.sh` - 開発環境のセットアップスクリプト
- `dev.sh` - ローカル開発環境の実行スクリプト

## コード規約

### 命名規則

- **ファイル名** - スネークケース（例: `user_repository.dart`）
- **クラス名** - パスカルケース（例: `UserRepository`）
- **変数/関数名** - キャメルケース（例: `getUserById`）
- **定数** - 大文字スネークケース（例: `API_BASE_URL`）

### インポート順序

1. Dart/Flutter SDK
2. サードパーティパッケージ
3. プロジェクト内パッケージ（packages/下）
4. 現在のパッケージ内のインポート（相対パス）

### コードフォーマット

すべてのコードは、言語に応じた標準フォーマッタを使用してフォーマットします。

- Dartコード: `dart format`
- TypeScriptコード: Prettier

## ブランチ戦略

FatGramプロジェクトではGit Flow戦略を採用します。

- `main` - 本番リリース用ブランチ
- `develop` - 開発ブランチ（次期リリース用）
- `feature/*` - 新機能開発用ブランチ
- `bugfix/*` - バグ修正用ブランチ
- `release/*` - リリース準備用ブランチ
- `hotfix/*` - 緊急修正用ブランチ