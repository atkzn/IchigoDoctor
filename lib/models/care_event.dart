// lib/models/care_event.dart
enum CareType { water, fertilize, runner, pollination, disease }

class CareEvent {
  final DateTime date;
  final CareType type;
  bool done;
  String? note;

  CareEvent({required this.date, required this.type, this.done = false, this.note});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'type': type.index,
        'done': done,
        'note': note,
      };

  factory CareEvent.fromJson(Map<String, dynamic> j) => CareEvent(
        date: DateTime.parse(j['date'] as String),
        type: CareType.values[j['type'] as int],
        done: j['done'] as bool,
        note: j['note'] as String?,
      );
}
