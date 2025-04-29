import 'dart:io';                       // ★ 追加
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
