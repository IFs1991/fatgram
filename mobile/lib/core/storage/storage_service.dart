/// ローカルストレージサービスインターフェース
abstract class StorageService {
  /// 文字列の保存
  Future<void> setString(String key, String value);

  /// 文字列の取得
  Future<String?> getString(String key);

  /// 整数の保存
  Future<void> setInt(String key, int value);

  /// 整数の取得
  Future<int?> getInt(String key);

  /// 倍精度浮動小数点数の保存
  Future<void> setDouble(String key, double value);

  /// 倍精度浮動小数点数の取得
  Future<double?> getDouble(String key);

  /// 真偽値の保存
  Future<void> setBool(String key, bool value);

  /// 真偽値の取得
  Future<bool?> getBool(String key);

  /// 文字列リストの保存
  Future<void> setStringList(String key, List<String> value);

  /// 文字列リストの取得
  Future<List<String>?> getStringList(String key);

  /// JSONオブジェクトの保存
  Future<void> setJson(String key, Map<String, dynamic> json);

  /// JSONオブジェクトの取得
  Future<Map<String, dynamic>?> getJson(String key);

  /// キーの削除
  Future<void> remove(String key);

  /// すべての値を削除
  Future<void> clear();

  /// キーの存在確認
  Future<bool> containsKey(String key);

  /// すべてのキーを取得
  Future<Set<String>> getKeys();
}