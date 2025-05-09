// lib/local_store.dart
//
// ❶ 必要なパッケージは path_provider だけ（既に pubspec.yaml に入っている）
// ❷ 保存するのは「ステータス」と「careTips」の２つだけ
//
//   {
//     "status": { stage, growthDaysEst, ... , disease },
//     "careTips": ["水やり…", "追肥…", "ランナー…"]
//   }

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint;


class LocalStore {
  static const _fileName = 'status.json';

  // ---------------- SAVE ----------------
  static Future<void> save(Map<String, dynamic> src) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');

    final obj = {
      'status': {
        'stage'          : src['stage'],
        'growthDaysEst'  : src['growthDaysEst'],
        'daysToFlower'   : src['daysToFlower'],
        'daysToHarvest'  : src['daysToHarvest'],
        'growthStatus'   : src['growthStatus'],
        'disease'        : src['disease'],
      },
      'careTips': src['careTips'] ?? [],
    };

    await file.writeAsString(jsonEncode(obj));
  }

  // ---------------- LOAD ----------------
  /// 保存が無い場合は null を返す
  static Future<Map<String, dynamic>?> load() async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');

//debugPrint('[LS] looking for => ${file.path}');


      if (!await file.exists()) {
        debugPrint('[LS] file NOT found');
        return null;
      }

      final raw = await file.readAsString();
//debugPrint('[LS] raw json => $raw');


      final obj = jsonDecode(raw);
      // HomePage に渡せる形へ復元して返す
      return {
        ...obj['status'] as Map<String, dynamic>,
        'careTips': obj['careTips'] as List<dynamic>,
      };
    } catch (e, st) {
      debugPrint('[LS] load error => $e\n$st'); 
      return null; // 壊れたファイルは無視
    }
  }

  /// デバッグ用：保存データを消す
  static Future<void> clear() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (await file.exists()) await file.delete();
  }
}
