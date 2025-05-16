# FatGram

スマートウォッチと連携して脂肪燃焼量をリアルタイム表示・分析するアプリ。AIによるパーソナルアドバイス機能搭載。

## 概要

FatGramは、ユーザーのスマートウォッチから心拍数や運動データを取得し、脂肪燃焼量をグラム単位で視覚的に表示するアプリです。
脂肪燃焼の効率化をサポートする生成AIアシスタント機能や、詳細な分析レポートなどを提供します。

## 主な機能

- スマートウォッチ（Apple Watch / Wear OS）連携
- リアルタイム脂肪燃焼量の計算・表示
- AIチャットアシスタント（フリーミアム設計）
- 運動タイプ別・時間帯別の脂肪燃焼効率分析
- 目標設定・進捗管理機能
- 多言語対応（日本語・英語）

## 技術スタック

- Frontend: Flutter / Dart
- Backend: Google Cloud Platform (Firebase, Cloud Run, Vertex AI)
- Authentication: Firebase Authentication
- Database: Firestore
- AI/ML: Vertex AI (Gemini)

## インストール

```bash
git clone https://github.com/IFs1991/fatgram.git
cd fatgram
flutter pub get
flutter run
```

## 開発計画

詳細な開発計画と実装スケジュールは [FatGram_アプリ_AI駆動開発計画.yaml](./FatGram_アプリ_AI駆動開発計画.yaml) を参照してください。
