// lib/pages/diary_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/diary.dart';
import '../repositories/diary_repo.dart';

/// 📅 まず月間カレンダーを出し、日付タップでその日の一覧へ
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  // ── key = yyyy‑MM‑dd でグループ化済みの Map ──
  Map<String, List<Diary>> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DiaryRepo.all();
    setState(() {
      _byDay = {
        for (final d in all)
          DateFormat('yyyy-MM-dd').format(d.dateTime):
              [...?_byDay[DateFormat('yyyy-MM-dd').format(d.dateTime)], d]
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diary')),
        body: TableCalendar(
          locale: 'ja_JP',
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          startingDayOfWeek: StartingDayOfWeek.monday,
          eventLoader: (day) =>
              _byDay[DateFormat('yyyy-MM-dd').format(day)] ?? [],
          calendarBuilders: CalendarBuilders(
            markerBuilder: (_, __, list) =>
                list.isNotEmpty ? const _Dot() : null,
          ),
          onDaySelected: (sel, _) {
            final key = DateFormat('yyyy-MM-dd').format(sel);
            final items = _byDay[key] ?? [];
            if (items.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ListPage(dateKey: key, list: items),
              ),
            );
          },
        ),
      );
}

/// ● 印
class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(_) => const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(right: 2, bottom: 2),
          child: Icon(Icons.circle, size: 6, color: Colors.pink),
        ),
      );
}

/// 指定日の「一覧」ページ
class _ListPage extends StatelessWidget {
  final String dateKey;
  final List<Diary> list;
  const _ListPage({required this.dateKey, required this.list});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(dateKey)),
        body: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final d = list[i];
            return ListTile(
              leading: Image.file(File(d.image), width: 64, fit: BoxFit.cover),
              title: Text(
                DateFormat('HH:mm').format(d.dateTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                d.memo.isEmpty ? 'メモなし' : d.memo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _DetailPage(diary: d)),
              ),
            );
          },
        ),
      );
}

/// 1件の詳細
class _DetailPage extends StatelessWidget {
  final Diary diary;
  const _DetailPage({required this.diary});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(DateFormat('yyyy-MM-dd HH:mm').format(diary.dateTime))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Image.file(File(diary.image)),
            const SizedBox(height: 12),
            SelectableText(
              diary.memo.isEmpty ? 'メモなし' : diary.memo,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
}
