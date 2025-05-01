// lib/models/care_event.dart
enum CareType { water, fertilize }

class CareEvent {
  final DateTime date;       // 世話予定日 (00:00)
  final CareType type;       // 水やり or 追肥
  bool done;                 // 完了フラグ

  CareEvent({required this.date, required this.type, this.done = false});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'type': type.index,
        'done': done,
      };

  factory CareEvent.fromJson(Map<String, dynamic> j) => CareEvent(
        date: DateTime.parse(j['date'] as String),
        type: CareType.values[j['type'] as int],
        done: j['done'] as bool,
      );
}
