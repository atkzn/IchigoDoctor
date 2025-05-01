import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../repositories/care_repo.dart';
import '../models/care_event.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('カレンダー')),
        body: FutureBuilder(
          future: CareRepo.monthEvents(_focused),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            return TableCalendar(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2023),
              lastDay: DateTime.utc(2030),
              focusedDay: _focused,
              selectedDayPredicate: (day) =>
                  _selected != null &&
                  day.year == _selected!.year &&
                  day.month == _selected!.month &&
                  day.day == _selected!.day,
              eventLoader: (day) => events
                  .where((e) =>
                      e.date.year == day.year &&
                      e.date.month == day.month &&
                      e.date.day == day.day)
                  .toList(),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, list) {
                  if (list.isEmpty) return null;
                  final ev = list.first as CareEvent;
                  final color = ev.type == CareType.water
                      ? Colors.blue
                      : Colors.green;
                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ev.done ? Colors.grey : color,
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selected, focused) async {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
                final list = events.where((e) =>
                    e.date.year == selected.year &&
                    e.date.month == selected.month &&
                    e.date.day == selected.day);
                if (list.isEmpty) return;
                final e = list.first;
                final toggled = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(e.type == CareType.water ? '水やり' : '追肥'),
                    content: Text(
                        e.done ? '完了を取り消しますか？' : '完了にしますか？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('閉じる')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(e.done ? '未完了に戻す' : '完了 ✔️')),
                    ],
                  ),
                );
                if (toggled ?? false) {
                  await CareRepo.toggleDone(e);
                  setState(() {}); // リロード
                }
              },
            );
          },
        ),
      );
}
