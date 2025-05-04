// lib/utils/logger.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
