/*
// lib/pages/camera_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../cameras.dart';
import '../models/diary.dart';
import '../repositories/diary_repo.dart';
import '../utils/logger.dart';
import '../notifiers/latest_notifier.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late final CameraController _ctrl;
  bool _busy = false;
  bool _closed = false;          // ★ プレビュー非表示フラグ

  @override
  void initState() {
    super.initState();
    _ctrl = CameraController(cameras.first, ResolutionPreset.medium);
    _ctrl.initialize().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _classify() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // ───1 撮影 ───────────────────────────
      final xfile  = await _ctrl.takePicture();
      final bytes  = await xfile.readAsBytes();
      final b64    = base64Encode(bytes);
      await Log.d('📸 captured bytes=${bytes.length}');

      // ───2 Gemini へ送信────────────────────
      const prompt = '''
あなたはイチゴ栽培の専門家です。以下 JSON 形式のみ返してください。

{
 "stage":"S0〜S7",
 "growthDaysEst":"21-25",
 "daysToFlower":"20-25",
 "daysToHarvest":"35-45",
 "growthStatus":"良好",
 "disease":"なし",
 "careTips":["水やり…","追肥…"]
}
''';

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': b64,
                }
              }
            ]
          }
        ]
      });

      final key = const String.fromEnvironment('GEMINI_KEY');
      final uri =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';

      final res = await http
          .post(Uri.parse(uri),
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));

      await Log.d('🌐 gemini status=${res.statusCode}');
      await Log.d('🌐 gemini body=${res.body.substring(0, 400)}…');

      // ───3 JSON 抽出───────────────────────
      final Map<String, dynamic> raw = jsonDecode(res.body);
      final String? textPart =
          raw['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (textPart == null) throw 'diagnosis text null';


      final match = RegExp(r'\{[\s\S]*\}').firstMatch(textPart);
      if (match == null) throw 'JSON not found in diagnosis text';
      final jsonStr = match.group(0)!;
      await Log.d('🔍 jsonStr=$jsonStr');

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // ───4 Diary 保存──────────────────────
      final diary = await DiaryRepo.add(
        imagePath: xfile.path,
        memo: '',
        result: data,
      );

      // Home に通知
      if (!mounted) return;
      context.read<LatestNotifier>().update(diary);

      //if (mounted) Navigator.pop(context);
      if (!mounted) return;

      // ① プレビューを隠す → setState 済みの状態でポップ
      setState(() => _closed = true);
      await Log.d('📷 set _closed=true & pop');

      Navigator.pop(context);

    } catch (e, st) {
      await Log.d('❌ classify error=$e\n$st');
/*
      // ★失敗しても Diary に「画像だけ」残す
      await DiaryRepo.add(
        imagePath: xfile?.path ?? '',
        memo: '診断エラー: $e',
        result: {},                   // ← 空 Map
      );
*/      
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
/*
    if (!_ctrl.value.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
*/
    if (!_ctrl.value.isInitialized || _closed) {
      // _closed=true なら空白画面にしてプレビューを出さない
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('撮影して診断')),
      body: Stack(
        children: [
          CameraPreview(_ctrl),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _classify,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
*/

// lib/pages/camera_page.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../repositories/diary_repo.dart';
import '../notifiers/latest_notifier.dart';

// —— 端末にあるカメラ一覧は global 変数で保持（cameras.dart で定義）——
import '../cameras.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late final CameraController _ctrl;
  bool _busy = false;
  String? _error;                           // ← 失敗メッセージ保管

  @override
  void initState() {
    super.initState();
    if (cameras.isEmpty) {
      _error = 'カメラが見つかりません';
      return;
    }
    _ctrl = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
      // ★ Impeller 対策 ------------------------------
      //useAndroidViewSurface: true,
    );
    _ctrl.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((e, st) {
      _error = '$e';
      _log(e, st);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ------ 撮影して Gemini API へ ------------------
  Future<void> _classify() async {
    if (_busy || !_ctrl.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      // 1) 撮影 → base64
      final xfile = await _ctrl.takePicture();
      final imgBytes = await xfile.readAsBytes();
      final b64 = base64Encode(imgBytes);

      // 2) Gemini へ投げる
      const prompt = '''
あなたはイチゴ栽培の専門家です。次の JSON 形式のみで回答してください。

{
  "stage":"S0〜S7",
  "growthDaysEst":"例 21-25",
  "daysToFlower":"例 20-25",
  "daysToHarvest":"例 35-45",
  "growthStatus":"良好／要注意／弱弱",
  "disease":"なし または 疑わしい病名",
  "careTips":["水やり…","追肥…","ランナー整理…"]
}
''';

      final uri =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${const String.fromEnvironment('GEMINI_KEY')}';

      final res = await http.post(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': b64,
                  }
                },
              ]
            }
          ]
        }),
      );

      final raw = jsonDecode(res.body);
      final String txt =
          raw['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final jsonStr = txt.substring(txt.indexOf('{'), txt.lastIndexOf('}') + 1);
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      // 3) 端末 DB へ保存 ＆ HomePage へ通知
      final diary = await DiaryRepo.add(
        //imagePath: xfile.path,
        image: xfile.path,
        result: data,
        memo: '',
      );
      if (!mounted) return;
      context.read<LatestNotifier>().update(diary);  // Home に渡す
      Navigator.pop(context);                        // Home へ戻る
    } catch (e, st) {
      _error = '$e';
      _log(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------ UI --------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('撮影して診断')),
        body: Center(child: Text(_error!)),
      );
    }
    if (!_ctrl.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('撮影して診断')),
      body: Stack(
        children: [
          CameraPreview(_ctrl),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _classify,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  // ------ エラーを内部ストレージに書き出し ----------
  Future<void> _log(Object e, StackTrace st) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/babyberry_error.log');
      await file.writeAsString('$e\n$st\n\n', mode: FileMode.append);
    } catch (_) {
      /* ignore */ // 失敗しても落とさない
    }
  }
}
