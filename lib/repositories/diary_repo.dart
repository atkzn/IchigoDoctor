import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary.dart';

/// ─────────────────────────────────────────────────────────────
/// DiaryRepo
///   • SharedPreferences に JSON 保存
///   • Stream で UI 側に変更通知
/// ─────────────────────────────────────────────────────────────
class DiaryRepo {
  static const _key = 'diary_list';

  // broadcast なので複数画面で listen 可
  static final _controller = StreamController<List<Diary>>.broadcast();

  /// 変更通知ストリーム
  static Stream<List<Diary>> get stream => _controller.stream;

  /// 保存済みリストを日時降順で取得
  static Future<List<Diary>> _load() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_key);
    if (txt == null) return [];
    final list = (json.decode(txt) as List).cast<Map<String, dynamic>>();
    return list.map(Diary.fromJson).toList();
  }

  /// 公開 API: すべて取得
  static Future<List<Diary>> all() => _load();

  /// 公開 API: 直近 1 件
  static Future<Diary?> latest() async {
    final list = await _load();
    return list.isNotEmpty ? list.first : null;
  }

  /// 追加して即ストリーム通知
  static Future<void> add(Diary d) async {
    final list = await _load();
    list.insert(0, d); // 新しい順
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, json.encode(list.map((e) => e.toJson()).toList()));
    _controller.add(list); // 変更を配信
  }

  /// 画像をアプリの内部ストレージへコピーし、その保存先パスを返す
  static Future<String> saveImage(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final dst = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await src.copy(dst.path);
    return dst.path;
  }
}
