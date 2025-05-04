// lib/pages/camera_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../cameras.dart';
import '../notifiers/latest_notifier.dart';
import '../repositories/diary_repo.dart';
import '../models/diary.dart';
import '../utils/logger.dart';

class CameraPage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onResult;
  const CameraPage({super.key, required this.onResult});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cam;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _cam = CameraController(cameras.first, ResolutionPreset.medium);
    _cam.initialize().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  //─────────────────────────────────────────── classify
  Future<void> _classify() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // 撮影
      final x = await _cam.takePicture();
      await Log.d('Picture path=${x.path}');
      final b64 = base64Encode(await x.readAsBytes());

      // Gemini 診断
      final diagnosis = await _diagnose(b64);
      await Log.d('diagnosis=$diagnosis');

      // Diary 保存
      final imgPath = await DiaryRepo.saveImage(File(x.path));
      final diary = Diary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        image: imgPath,
        memo: '',
      );
      await DiaryRepo.add(diary);
      if (mounted) context.read<LatestNotifier>().update(diary);

      FirebaseAnalytics.instance.logEvent(name: 'capture', parameters: {
        'stage': diagnosis['stage'],
      });

      widget.onResult(diagnosis);
      if (mounted) Navigator.pop(context);   // Home へ戻る
    } catch (e, st) {
      await Log.d('classify ERROR=$e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //─────────────────────────────────────────── _diagnose
  Future<Map<String, dynamic>> _diagnose(String b64) async {
    const prompt = '''
イチゴ栽培専門家として次の JSON のみ返してください…
{ "stage":"S0", "growthDaysEst":"0-0", "daysToFlower":"0-0",
  "daysToHarvest":"0-0", "growthStatus":"良好", "disease":"なし",
  "careTips":["水やり…","追肥…"] }
''';

    final key = const String.fromEnvironment('GEMINI_KEY');
    final uri =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': b64}
            }
          ]
        }
      ]
    };

    final res = await http.post(Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));

    await Log.d('gemini status=${res.statusCode}');
    await Log.d('gemini body=${res.body}');

    if (res.statusCode != 200) {
      throw '診断 API が失敗 (${res.statusCode})';
    }

    final raw = jsonDecode(res.body);
    final text =
        raw?['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null) throw '診断テキストが空です';

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (match == null) throw 'JSON が検出できません';
    return jsonDecode(match.group(0)!) as Map<String, dynamic>;
  }

  //─────────────────────────────────────────── UI
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('撮影して診断')),
        body: _cam.value.isInitialized
            ? Stack(children: [
                CameraPreview(_cam),
                if (_busy) const Center(child: CircularProgressIndicator()),
              ])
            : const Center(child: CircularProgressIndicator()),
        floatingActionButton: FloatingActionButton(
          onPressed: _busy ? null : _classify,
          child: const Icon(Icons.camera_alt),
        ),
      );
}
