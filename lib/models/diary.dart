class Diary {
  final String id;        // 例: 2024-04-30T12:34:56
  final String image;     // ファイルパス
  final String memo;

  Diary({required this.id, required this.image, required this.memo});

  Map<String, String> toJson() => {
        'id': id,
        'image': image,
        'memo': memo,
      };

  factory Diary.fromJson(Map<String, dynamic> j) => Diary(
        id: j['id'] as String,
        image: j['image'] as String,
        memo: j['memo'] as String,
      );
}
