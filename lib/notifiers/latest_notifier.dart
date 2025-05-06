// lib/notifiers/latest_notifier.dart
import 'package:flutter/foundation.dart';
import '../models/diary.dart';

class LatestNotifier extends ChangeNotifier {
  Diary? _latest;
  Diary? get latest => _latest;

  void update(Diary d) {
    _latest = d;
    notifyListeners();
  }
}
