// lib/models/tip.dart
class Tip {
  final int id;
  final String title;
  final String body;
  Tip({required this.id, required this.title, required this.body});

  factory Tip.fromJson(Map<String, dynamic> j) =>
      Tip(id: j['id'], title: j['title'], body: j['body']);
}
