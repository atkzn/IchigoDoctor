

import '../models/care_event.dart';

// lib/services/care_logic.dart
//
// ❶ 追加の import / パッケージは不要です。
// ❷ 「フェーズ」「ステップ」はもう気にせず、stage(数字) に応じて
//     “この３項目だけは Gemini で説明してほしい” という
//     抽象化済みキーワードを返すユーティリティです。

class CareLogic {
  /// 「栽培ステージ番号」→「Gemini に渡す 3 項目リスト」
  ///
  /// ※ “追肥” や “水やり” など、抽象化したキーワードに統一
  /// ※ 4,6,8,10 番台も独立ステップとして用意しました
  static const Map<int, List<String>> careItems = {
    // 0〜1：準備期
    1: ['土壌改良', '畝立て', 'マルチ'],
    // 2：植え付け
    2: ['苗選び', '植え付け', '水やり'],
    // 3：植え付け直後（浅植え→活着）
    3: ['浅植え', '株間', '水やり'],
    // 4：活着促進
    4: ['活着管理', '水やり', '日射管理'],
    // 5：初期生育（追肥開始）
    5: ['追肥', 'ランナー除去', '病害虫観察'],
    // 6：生育中期
    6: ['追肥', '葉整理', '水やり'],
    // 7：開花準備〜開花
    7: ['追肥', '水やり', '温度管理'],
    // 8：受粉
    8: ['受粉', '雨対策', '水やり'],
    // 9：幼果肥大
    9: ['追肥', '摘果', '水やり'],
    // 10：果実肥大・成熟
    10:['敷きわら', '鳥害対策', '水やり'],
    // 11：収穫
    11:['収穫', '収穫方法', '水やり'],
    // 12：収穫後
    12:['追肥', '病害虫管理', '株整理'],
  };

  /// 受け取った "S3" のような stage 文字列を → 数字だけ抜き出す
  static int _stageNum(String stage) =>
      int.tryParse(stage.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

  /// stageNum を 1〜12 の “区分” へ丸め込む
  static int _normalize(int num) {
    if (num <= 1)  return 1;
    if (num == 2)  return 2;
    if (num == 3)  return 3;
    if (num == 4)  return 4;
    if (num == 5)  return 5;
    if (num == 6)  return 6;
    if (num == 7)  return 7;
    if (num == 8)  return 8;
    if (num == 9)  return 9;
    if (num == 10) return 10;
    if (num == 11) return 11;
    return 12; // 12 以降は “収穫後の管理”
  }

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


  /// 外から呼ぶのはコレだけ：
  ///   CareLogic.itemsForStage(map['stage'])
  static List<String> itemsForStage(String stage) {
    final key = _normalize(_stageNum(stage));
    return careItems[key] ?? ['水やり', '追肥', '観察']; // フォールバック
  }
}
