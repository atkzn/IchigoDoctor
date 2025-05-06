// lib/utils/logger.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/*
class Log {
  static IOSink? _sink;

  static Future<void> _ensure() async {
    if (_sink != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/babyberry.log');
    _sink = file.openWrite(mode: FileMode.append);
  }

  static Future<void> d(Object msg) async {
    await _ensure();
    final now = DateTime.now().toIso8601String();
    _sink!.writeln('$now  $msg');
    await _sink!.flush();
  }
}
*/

class Log {
  static Future<void> d(String msg) async {
    final dir = await getExternalStorageDirectory(); // /sdcard/Android/data/<id>/files
    if (dir == null) return;
    final file = File('${dir.path}/babyberry.log');
    final now  = DateTime.now().toIso8601String();
    await file.writeAsString('$now $msg\n', mode: FileMode.append);
  }
}