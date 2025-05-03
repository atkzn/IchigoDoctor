import 'dart:convert';

/// Diary レコード
///   • id        … 一意キー（ISO8601 文字列）
///   • dateTime  … 撮影日時
///   • image     … 端末内に保存した画像パス
///   • memo      … ユーザー入力メモ（空文字可）
class Diary {
  final String id;
  final DateTime dateTime;
  final String image;
  final String memo;

  Diary({
    required this.id,
    required this.dateTime,
    required this.image,
    required this.memo,
  });

  // JSON ⇆ モデル
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'image': image,
        'memo': memo,
      };

  factory Diary.fromJson(Map<String, dynamic> j) => Diary(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        image: j['image'] as String,
        memo: j['memo'] as String,
      );


  static List<Diary> listFromJson(String json) =>
      (jsonDecode(json) as List).map((e) => Diary.fromJson(e)).toList();

  static String listToJson(List<Diary> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());
}
