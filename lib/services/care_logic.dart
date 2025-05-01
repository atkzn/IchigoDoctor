// lib/services/care_logic.dart

import '../models/care_event.dart';



/// ステージごとに世話の間隔を定義
class CareLogic {
  /// stage は "S0"～"S7"
  static List<CareEvent> eventsForStage(String stage, DateTime today) {
    final List<CareEvent> out = [];
    // すべての処理は「日付を 00:00」で揃えます
    DateTime atMidnight(DateTime dt) =>
        DateTime(dt.year, dt.month, dt.day);

    final base = atMidnight(today);

    // 定義例：ステージごとの次回間隔（日数）
    // S0: 植え付け→2日後水やり, 7日後追肥
    // S1: 活着期→3日後水やり, 10日後追肥
    // S2: 新芽→2日おき水やり, 14日後追肥
    // … 以下はサンプルですので要調整してください
    final map = {
      'S0': {'water': 2, 'fertilize': 7, 'runner': 15, 'pollination': null},
      'S1': {'water': 3, 'fertilize': 10, 'runner': 15, 'pollination': null},
      'S2': {'water': 2, 'fertilize': 14, 'runner': 20, 'pollination': null},
      'S3': {'water': 2, 'fertilize': 14, 'runner': 20, 'pollination': null},
      'S4': {'water': 1, 'fertilize': 14, 'runner': 20, 'pollination': null},
      'S5': {'water': 1, 'fertilize': 14, 'runner': 20, 'pollination': 1},
      'S6': {'water': 1, 'fertilize': 7,  'runner': 20, 'pollination': 1},
      'S7': {'water': 2, 'fertilize': 7,  'runner': 20, 'pollination': null},
    };

    final cfg = map[stage]!;
    // helper
    void addEvent(String typeKey, int? days) {
      if (days == null) return;
      final type = CareType.values.firstWhere((e) => e.name == typeKey);
      out.add(CareEvent(date: base.add(Duration(days: days)), type: type));
    }

    addEvent('water', cfg['water'] as int?);
    addEvent('fertilize', cfg['fertilize'] as int?);
    addEvent('runner', cfg['runner'] as int?);
    addEvent('pollination', cfg['pollination'] as int?);

    return out;
  }
}
