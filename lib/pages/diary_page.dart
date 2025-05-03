import 'package:flutter/material.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import '../repositories/diary_repo.dart';
import '../models/diary.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  Map<DateTime, List<Diary>> _map = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DiaryRepo.all();
    setState(() {
      _map = {
        for (var d in all) d.dateTime: [d]
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diary')),
        body: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          eventLoader: (day) => _map[DateTime(day.year, day.month, day.day)] ?? [],
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (sel, _) {
            final items = _map[DateTime(sel.year, sel.month, sel.day)] ?? [];
            if (items.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _DetailPage(items.first),
              ),
            );
          },
        ),
      );
}

class _DetailPage extends StatelessWidget {
  final Diary diary;
  const _DetailPage(this.diary);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('メモ')),
        body: Column(
          children: [
            Image.file(File(diary.image)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(diary.memo.isEmpty ? 'メモなし' : diary.memo),
            ),
          ],
        ),
      );


}

