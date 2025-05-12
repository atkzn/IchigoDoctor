// lib/pages/disease_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../repositories/diary_repo.dart';
import '../models/diary.dart';
import '../cameras.dart';      // global cameras = await availableCameras()
import '../camera_manager.dart';


class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  late CameraController ctrl;
  bool busy = false;

  // ③ controller を外から参照できるように（追加）
  CameraController get controller => ctrl;


  @override
  void initState() {
    super.initState();
    ctrl = CameraController(cameras.first, ResolutionPreset.medium);
    CameraManager.controller = ctrl;
    ctrl.initialize().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    ctrl.dispose();
    CameraManager.controller = null;
    super.dispose();
  }

  /// 撮影 → Gemini へ送信 → 病名候補を表示 & 保存
  Future<void> _diagnose() async {
    if (busy) return;
    setState(() => busy = true);

    try {
      // 1) 写真撮影
      final xfile = await ctrl.takePicture();
      final base64 = base64Encode(await xfile.readAsBytes());

      // 2) Gemini へクエリ
      const prompt = '''
あなたはイチゴ栽培の病害診断医です。画像を解析し、病気と思われる症状があれば
病名を日本語1〜2語で、無い場合は "健康" とだけ答えてください。
JSON で返答し、キーは "disease" のみとします。例:
{"disease":"うどんこ病"}
または
{"disease":"健康"}
''';

      final uri =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${const String.fromEnvironment('GEMINI_KEY')}';

      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {"inlineData": {"mimeType": "image/jpeg", "data": base64}}
            ]
          }
        ]
      };

      final res = await http.post(Uri.parse(uri),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      final txt =
          (jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text']
                  as String)
              .trim();
      final disease = (jsonDecode(
          txt.substring(txt.indexOf('{'), txt.lastIndexOf('}') + 1)))['disease'];

      // 3) 結果ダイアログ
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('診断結果'),
          content: Text(disease == '健康'
              ? '病気の兆候は見られませんでした。\n引き続き観察しましょう。'
              : '「$disease」の可能性があります。\n早めの対処をおすすめします。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );

      // 4) 履歴に保存（memo に病名）
      final path = await DiaryRepo.saveImage(File(xfile.path));
      await DiaryRepo.add(
        Diary(id: DateTime.now().toIso8601String(), image: path, memo: '病気診断: $disease'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('診断失敗: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('病気診断')),
      body: ctrl.value.isInitialized
          ? Stack(children: [
              CameraPreview(ctrl),
              if (busy) const Center(child: CircularProgressIndicator())
            ])
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: busy ? null : _diagnose,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
