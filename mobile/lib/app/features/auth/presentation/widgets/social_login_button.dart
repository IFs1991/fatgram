import 'package:flutter/material.dart';

/// ソーシャルログインボタン
class SocialLoginButton extends StatelessWidget {
  /// アイコン画像パス
  final String icon;

  /// ボタンテキスト
  final String text;

  /// タップ時の処理
  final VoidCallback? onPressed;

  /// 背景色
  final Color? backgroundColor;

  /// テキスト色
  final Color? textColor;

  /// コンストラクタ
  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: textColor ?? Colors.black87,
        elevation: 1,
        side: const BorderSide(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}