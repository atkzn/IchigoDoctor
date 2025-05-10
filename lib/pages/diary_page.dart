/*
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../repositories/diary_repo.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Diary>>(
      future: DiaryRepo.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 読み込み中
          return Scaffold(
            appBar: AppBar(title: const Text('Diary')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final list = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Diary')),    // ★ 同じく修正
          body: list.isEmpty
              ? const Center(child: Text('まだ記録がありません'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    return ListTile(
                      leading: Image.file(               // ← File が使える
                        File(d.image),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                      title: Text(d.memo),
                      subtitle: Text(
                        DateTime.parse(d.id)
                            .toLocal()
                            .toString()
                            .substring(0, 16), // yyyy-MM-dd HH:mm
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
*/

// lib/pages/diary_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary.dart';
import '../repositories/diary_repo.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diary')),
      body: FutureBuilder<List<Diary>>(
        future: DiaryRepo.all(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('まだ履歴がありません'));
          }
          // id を DateTime として降順ソート
          list.sort((a, b) =>
              DateTime.parse(b.id).compareTo(DateTime.parse(a.id)));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) => _DiaryCard(diary: list[i]),
          );
        },
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final Diary diary;
  const _DiaryCard({required this.diary});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(diary.id);
    final dateStr =
        dt != null ? DateFormat('yyyy/MM/dd HH:mm').format(dt) : diary.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _DetailPage(diary: diary)),
        ),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.file(File(diary.image), fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dateStr,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      diary.memo.isNotEmpty ? diary.memo : '(メモなし)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  final Diary diary;
  const _DetailPage({required this.diary});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(diary.id);
    final dateStr =
        dt != null ? DateFormat('yyyy/MM/dd HH:mm').format(dt) : diary.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.file(File(diary.image)),
          const SizedBox(height: 12),
          Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(diary.memo.isNotEmpty ? diary.memo : '(メモなし)'),
        ],
      ),
    );
  }
}
