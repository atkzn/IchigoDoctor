// lib/repositories/diary_repo.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/diary.dart';

/// 画像保存用フォルダ名
const _dirName = 'diary_images';

class DiaryRepo {
  /// メモリキャッシュ（新しい順）
  static final List<Diary> _cache = [];

  // ────────────────────────────  Public  ──

  /// すべて取得（キャッシュが空ならファイルを読む）
  static Future<List<Diary>> all() async {
    if (_cache.isNotEmpty) return _cache;
    final file = await _dbFile();
    if (!file.existsSync()) return [];
    final txt = await file.readAsString();
    if (txt.isEmpty) return [];
    _cache
      ..clear()
      ..addAll(Diary.listFromJson(txt))
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return _cache;
  }


  /// 最新 1 件（無ければ null）
  static Future<Diary?> latest() async {
    final list = await all();
    return list.isNotEmpty ? list.first : null;
  }

   /// リアルタイムに全件を返すストリーム
  /// 1 秒間隔で再読み込みして通知します
  static Stream<List<Diary>> stream() async* {
    while (true) {
      yield await all();                        // 最新一覧を返す
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// 1件追加して永続化
  static Future<void> add(Diary d) async {
    _cache.insert(0, d);          // 先頭に入れる＝最新が最初
    await _saveAll();
  }

  /// 画像を /documents/diary_images へコピーしてパスを返す
  static Future<String> saveImage(File src) async {
    final dir = await _imgDir();
    dir.createSync(recursive: true);
    final dst =
        File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await src.copy(dst.path);
    return dst.path;
  }

  // ────────────────────────────  Internal ──

  /// キャッシュ更新後にコントローラへ通知
  //static final _controller = Stream<void>.periodic(const Duration(seconds: 1));

  static Future<void> _saveAll() async {
    final file = await _dbFile();
    final jsonStr = Diary.listToJson(_cache);
    await file.writeAsString(jsonStr);
  }

  static Future<File> _dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/diary_db.json');
  }

  static Future<Directory> _imgDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/$_dirName');
  }
}
