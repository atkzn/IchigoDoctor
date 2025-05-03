// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/care_event.dart';
import '../repositories/care_repo.dart';

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
        body: FutureBuilder<List<CareEvent>>(
          future: CareRepo.monthEvents(_focused),
          builder: (c, snap) {
            final events = snap.data ?? [];
            return TableCalendar(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) =>
                  _selected != null &&
                  d.year == _selected!.year &&
                  d.month == _selected!.month &&
                  d.day == _selected!.day,
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
                  Color color;
                  switch (ev.type) {
                    case CareType.water:
                      color = Colors.blue;
                      break;
                    case CareType.fertilize:
                      color = Colors.green;
                      break;
                    case CareType.runner:
                      color = Colors.orange;
                      break;
                    case CareType.pollination:
                      color = Colors.purple;
                      break;
                    case CareType.disease:
                      color = Colors.red;
                      break;
                  }
                  // 完了なら灰色
                  if (ev.done) color = Colors.grey;
                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                  );
                },
              ),
              onDaySelected: (sel, foc) async {
                //Navigator.pushNamed(context, DiaryListPage.route, arguments: sel);
                setState(() {
                  _selected = sel;
                  _focused = foc;
                });
                final dayEvents = events.where((e) =>
                    e.date.year == sel.year &&
                    e.date.month == sel.month &&
                    e.date.day == sel.day);
                if (dayEvents.isEmpty) return;
                final e = dayEvents.first;
                final doIt = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text({
                      CareType.water: '水やり',
                      CareType.fertilize: '追肥',
                      CareType.runner: 'ランナー整理',
                      CareType.pollination: '人工授粉',
                    }[e.type]!),
                    content: Text(e.done ? '完了をキャンセルしますか？' : '完了にしますか？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('いいえ')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(e.done ? 'キャンセル' : '完了')),
                    ],
                  ),
                );
                if (doIt ?? false) {
                  await CareRepo.toggleDone(e);
                  setState(() {});
                }
              },
            );
          },
        ),
      );
}
