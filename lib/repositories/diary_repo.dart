
/*
// lib/repos/diary_repo.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diary.dart';
import '../utils/logger.dart';

class DiaryRepo {
  /* ファイルパス -------------------------------------------------------- */
  static Future<File> _jsonFile() async {
    final dir = await getExternalStorageDirectory();
    return File('${dir!.path}/diary.json');
  }

  static Future<Directory> _imageDir() async {
    final dir = await getExternalStorageDirectory();
    final imgDir = Directory('${dir!.path}/images');
    if (!imgDir.existsSync()) imgDir.createSync(recursive: true);
    return imgDir;
  }

  /* すべて取得 ---------------------------------------------------------- */
  static Future<List<Diary>> all() async {
    final file = await _jsonFile();
    if (!file.existsSync()) return [];
    final jsonList = jsonDecode(await file.readAsString()) as List;
    return jsonList.map((e) => Diary.fromJson(e)).toList();
  }

  /* 追加 ---------------------------------------------------------------- */
  static Future<Diary> add({
    required String imagePath,
    required String memo,
    Map<String, dynamic>? result,
  }) async {
    final list = await all();

    // 画像をアプリ専用 images フォルダにコピー
    final imgDir  = await _imageDir();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath  = '${imgDir.path}/$fileName';
    await File(imagePath).copy(newPath);

    final diary = Diary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      image: newPath,
      memo: memo,
      result: result ?? {},
    );
    list.add(diary);

    final f = await _jsonFile();
    await f.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()));

    await Log.d('✅ Diary saved id=${diary.id}');
    return diary;
  }

  /* 最新 1 件 ----------------------------------------------------------- */
  static Future<Diary?> latest() async {
    final list = await all();
    return list.isNotEmpty ? list.last : null;
  }
}
*/

// lib/repos/diary_repo.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diary.dart';
import '../utils/logger.dart';

class DiaryRepo {
  /* パス ------------------------------------------------------------ */
  static Future<File> _jsonFile() async {
    final dir = await getExternalStorageDirectory();
    return File('${dir!.path}/diary.json');
  }

  static Future<Directory> _imageDir() async {
    final dir = await getExternalStorageDirectory();
    final imgDir = Directory('${dir!.path}/images');
    if (!imgDir.existsSync()) imgDir.createSync(recursive: true);
    return imgDir;
  }

  /* すべて取得 ------------------------------------------------------ */
  static Future<List<Diary>> all() async {
    final file = await _jsonFile();
    if (!file.existsSync()) return [];
    final jsonList = jsonDecode(await file.readAsString()) as List;
    return jsonList.map((e) => Diary.fromJson(e)).toList();
  }

  /* 追加 ------------------------------------------------------------ */
  static Future<Diary> add({
    //required String imagePath,
    required String image,
    String memo = '',
    Map<String, dynamic>? result,
  }) async {
    final list = await all();

    // 画像を images フォルダにコピー
    final imgDir   = await _imageDir();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath  = '${imgDir.path}/$fileName';
    //await File(imagePath).copy(newPath);
    await File(image).copy(newPath);

    // result が null なら空 Map にする 💡
    final diary = Diary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      image: newPath,
      memo: memo,
      result: result ?? {},
    );
    list.add(diary);

    // 保存
    final f = await _jsonFile();
    await f.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()));
    await Log.d('✅ Diary saved id=${diary.id}');
    return diary;
  }

  /* 最新 1 件 ------------------------------------------------------- */
  static Future<Diary?> latest() async {
    final list = await all();
    return list.isNotEmpty ? list.last : null;
  }
}
