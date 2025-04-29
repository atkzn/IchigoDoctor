// lib/repositories/tip_repo.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tip.dart';

class TipRepo {
  static Future<List<Tip>> load() async {
    final txt = await rootBundle.loadString('assets/tips.json');
    final list = (json.decode(txt) as List).cast<Map<String, dynamic>>();
    return list.map(Tip.fromJson).toList();
  }
}
