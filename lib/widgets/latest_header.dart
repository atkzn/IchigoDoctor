// lib/widgets/latest_header.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../repositories/diary_repo.dart';

/// ─────────────────────────────────────────────
///   最新撮影写真ヘッダ
///   • アスペクト 1:1（正方形）
///   • 左右に 16 px パディング
///   • 角丸 12 px
///   • 写真が無い場合は撮影ガイド文を表示
/// ─────────────────────────────────────────────
class LatestHeader extends StatelessWidget {
  const LatestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Diary?>(
      future: DiaryRepo.latest(),               // ❶ 最新 1 件取得
      builder: (context, snapshot) {
        final diary = snapshot.data;            // Diary? 型で受け取る

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 1,                     // 正方形
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ❷ 背景：写真 or プレースホルダー
                  if (diary != null)
                    Image.file(
                      File(diary.image),        // diary は null ではない
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: const Color(0xFFEFEFEF)),

                  // ❸ 写真が無い時だけ中央にガイド
                  if (diary == null)
                    Center(
                      child: Text(
                        '📷 まずは撮影して診断しよう！',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
