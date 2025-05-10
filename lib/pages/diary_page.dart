/*
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
*/

// lib/pages/diary_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary.dart';
import '../repositories/diary_repo.dart';

/// ─────────────────────────────────────────────
/// 「撮影履歴」を 3 列グリッドで表示するページ
/// ─────────────────────────────────────────────
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
          // id(ISO文字列) を新しい順に
          list.sort((a, b) =>
              DateTime.parse(b.id).compareTo(DateTime.parse(a.id)));

          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,          // ★ 3 列
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.75,     // 画像 : テキスト ≒ 4 : 1
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _DiaryTile(diary: list[i]),
          );
        },
      ),
    );
  }
}

/// 1 タイル＝サムネ画像 + 日付 + メモ
class _DiaryTile extends StatelessWidget {
  final Diary diary;
  const _DiaryTile({required this.diary});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(diary.id);
    final dateStr =
        dt != null ? DateFormat('MM/dd').format(dt) : diary.id; // 下部に小さく

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DetailPage(diary: diary)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── サムネ画像 ──
            Expanded(
              child: Image.file(
                File(diary.image),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // ── 日付 & メモ ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey)),
                  Text(
                    diary.memo.isNotEmpty ? diary.memo : '(メモなし)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 詳細ページはそのまま流用
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
