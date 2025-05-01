import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary.dart';

class DiaryRepo {
  static const _key = 'diary_list';

  static Future<List<Diary>> load() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_key);
    if (txt == null) return [];
    final list = (json.decode(txt) as List).cast<Map<String, dynamic>>();
    return list.map(Diary.fromJson).toList();
  }

  static Future<void> add(Diary d) async {
    final list = await load();
    list.insert(0, d);                    // 新しい順
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, json.encode(list.map((e) => e.toJson()).toList()));
  }

  /// 画像をアプリの内部ディレクトリへコピーし、そのパスを返す
  static Future<String> saveImage(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final dst = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    return await src.copy(dst.path).then((f) => f.path);
  }

  /// 保存済み Diary のうち最新（最初に insert しているので index 0）
  static Future<Diary?> latest() async {
    final list = await load();
    return list.isNotEmpty ? list.first : null;
  }


}
