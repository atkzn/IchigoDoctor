// lib/repositories/care_repo.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/care_event.dart';
import '../notification_service.dart';

class CareRepo {
  static const _key = 'care_events';

  /// すべてのイベントをロード
  static Future<List<CareEvent>> load() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_key);
    if (txt == null) return [];
    final list = (json.decode(txt) as List).cast<Map<String, dynamic>>();
    return list.map(CareEvent.fromJson).toList();
  }

  /// 保存（全上書き）
  static Future<void> _save(List<CareEvent> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _key, json.encode(list.map((e) => e.toJson()).toList()));
  }

  /// 追加 & 通知スケジュール
  static Future<void> add(CareEvent e) async {
    final list = await load();
    list.add(e);
    await _save(list);
    _scheduleNotification(e);
  }

  /// 完了トグル
  static Future<void> toggleDone(CareEvent e) async {
    final list = await load();
    final idx = list.indexWhere(
        (ev) => ev.date == e.date && ev.type == e.type); // 同一判定
    if (idx >= 0) {
      list[idx].done = !list[idx].done;
      await _save(list);
    }
  }

  /// 指定月のイベント
  static Future<List<CareEvent>> monthEvents(DateTime month) async {
    final list = await load();
    return list.where((e) =>
        e.date.year == month.year && e.date.month == month.month).toList();
  }

  static void _scheduleNotification(CareEvent e) {
    final dt = DateTime(e.date.year, e.date.month, e.date.day, 8);
    String title, body;
    switch (e.type) {
      case CareType.water:
        title = '水やりの時間です';
        body = '土表面が乾いたらたっぷり水を！';
        break;
      case CareType.fertilize:
        title = '追肥の時間です';
        body = '液肥1000倍を与えましょう';
        break;
      case CareType.runner:
        title = 'ランナー整理の時間です';
        body = '不要ランナーを切り取りましょう';
        break;
      case CareType.pollination:
        title = '人工授粉の時間です';
        body = '花をそっと揺すって受粉を助けましょう';
        break;
    }
    NotificationService.schedule(
      id: dt.hashCode ^ e.type.index,
      dateTime: dt,
      title: title,
      body: body,
    );
  }

  /// すべての CareEvent を削除
  static Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

}
