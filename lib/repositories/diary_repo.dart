/*
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
*/
// lib/repositories/diary_repo.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary.dart';

/// 撮影履歴とメモをローカル（SharedPreferences＋端末ストレージ）に
/// 保存／読み込みするシンプルなリポジトリ。
///
/// * 画像ファイルはアプリ専用ディレクトリへコピーしてパスのみ保持  
/// * JSON 文字列化して SharedPreferences に１キーで保存  
/// * **新しい順** に先頭へ insert するだけなのでページングなどは不要
class DiaryRepo {
  // SharedPreferences に使うキー
  static const _key = 'diary_list';

  /// ─────────────────────────────────────────────
  /// 取得系
  /// ─────────────────────────────────────────────

  /// すべての履歴を「新しい順」で返す  
  /// ※ これが `DiaryRepo.all()` として UI 側から呼ばれる
  static Future<List<Diary>> all() async => _load();

  /// 最新 1 件（なければ null）
  static Future<Diary?> latest() async {
    final list = await _load();
    return list.isNotEmpty ? list.first : null;
  }

  /// ─────────────────────────────────────────────
  /// 追加系
  /// ─────────────────────────────────────────────

  /// 新しい履歴を保存（内部で先頭へ insert）
  static Future<void> add(Diary diary) async {
    final list = await _load();
    list.insert(0, diary); // 先頭へ
    await _save(list);
  }

  /// 画像ファイルをアプリの内部ストレージへコピーし、
  /// その **保存先パス** を返す（モデルにはこのパスを保存）
  static Future<String> saveImage(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final dst = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return (await src.copy(dst.path)).path;
  }

  /// ─────────────────────────────────────────────
  /// 内部ユーティリティ
  /// ─────────────────────────────────────────────

  /// SharedPreferences からロード（なければ空リスト）
  static Future<List<Diary>> _load() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_key);
    if (txt == null) return [];
    final raw = json.decode(txt) as List<dynamic>;
    return raw
        .cast<Map<String, dynamic>>()
        .map(Diary.fromJson)
        .toList(growable: true);
  }

  /// List<Diary> を JSON 文字列で保存
  static Future<void> _save(List<Diary> list) async {
    final sp = await SharedPreferences.getInstance();
    final txt = json.encode(list.map((e) => e.toJson()).toList());
    await sp.setString(_key, txt);
  }
}
