import 'package:flutter/foundation.dart';
import '../models/diary.dart';

/// 「最新の撮影結果」を Home / Calendar 等に共有する
class LatestNotifier extends ChangeNotifier {
  Diary? _latest;             // null = まだ撮影していない
  Diary? get latest => _latest;

  /// 画像を撮影・診断した直後に呼び出す
  void update(Diary d) {
    _latest = d;
    notifyListeners();
  }
}
