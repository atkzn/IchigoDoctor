

// lib/app.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cameras.dart';  // ← cameras.dart の cameras を参照
import 'notification_service.dart';
import 'local_store.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:provider/provider.dart';
import 'theme_model.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'pages/tips_page.dart';
//import 'widgets/today_tip.dart';
import 'dart:io';
import 'repositories/diary_repo.dart';
import 'models/diary.dart';
import 'pages/diary_page.dart';
import 'pages/setting_page.dart';
import 'pages/calendar_page.dart';
import 'services/care_logic.dart';
import 'repositories/care_repo.dart';   // 撮影後イベント生成用
import 'models/care_event.dart';
import 'widgets/latest_header.dart';
import 'widgets/stage_image.dart';
import 'widgets/stage_status_card.dart';
import 'widgets/top_bar.dart';
import 'widgets/advice_card.dart';
import 'widgets/color_nav.dart';


class BerryApp extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const BerryApp({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return RootPage(initialData: initialData);
  }
}

// ---------------- RootPage --------------------------------------------------

class RootPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
   const RootPage({super.key, this.initialData});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;
  late Map<String, dynamic>? _lastResult = widget.initialData;

  List<Widget> get _pages => [
        HomePage(data: _lastResult),
        CameraPage(onResult: (r) {
          setState(() {
            _lastResult = r;
            _index = 0;
          });
        }),
        
        //const CalendarPage(), // Dairy
        const DiaryPage(),
        const TipsPage(), // Tips
        //const Placeholder(), // Shop
        const SettingsPage(), // Setting
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        bottomNavigationBar: ColorNav(
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      );
}

// ---------------- HomePage --------------------------------------------------

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? data;
  const HomePage({Key? key, this.data}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BannerAd _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    // テスト用バナーIDで初期化
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data ?? _dummy;
    final day = d['growthDaysEst'];

    return Scaffold(
      appBar: const TopBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          children: [
            const LatestHeader(),
            const SizedBox(height: 12),
            StageStatusCard(d: d),
            AdviceCard(tips: List<String>.from(d['careTips'])),
            const SizedBox(height: 12),

            // ── バナー広告 ──
            if (_bannerReady)
              Center(
                child: Container(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700, width: 2),
                    color: Colors.grey.shade400,
                  ),
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Map<String, dynamic> get _dummy => {
        'growthDaysEst': '21-25',
        'daysToFlower': '20-25',
        'daysToHarvest': '35-45',
        'growthStatus': '良好',
        'disease': 'なし',
        'careTips': [
          '水やり：土表面が乾いたらたっぷり',
          '追肥：液肥1000倍を週1',
          'ランナー整理：不要ランナーを切除',
        ]
      };

}

// ---------------- CameraPage ------------------------------------------------

class CameraPage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onResult;
  const CameraPage({Key? key, required this.onResult}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();

}

class _CameraPageState extends State<CameraPage> {
  late CameraController ctrl;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    // カメラが0台の例外を防ぐ
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('カメラが見つかりません')));
      return;
    }
    ctrl = CameraController(cameras.first, ResolutionPreset.medium);
    ctrl.initialize().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> classify() async {
    if (busy) return;
    setState(() => busy = true);

    final xfile = await ctrl.takePicture();
    final b64 = base64Encode(await xfile.readAsBytes());

    // ── ①まずイチゴ判定 ──
    final ok = await _isStrawberry(b64);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('イチゴが検出できません。もう一度撮影してください')));
      }
      setState(() => busy = false);
      return;
    }


    // ── ②既存の診断プロセス（stage/disease JSON 取得など） ──
    final key = const String.fromEnvironment('GEMINI_KEY');
    final uri =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';

    // 画像を解析し、実際の生育状況を返すプロンプト
    const prompt = '''
あなたはイチゴ栽培の専門家です。以下のフォーマットに従い、
ユーザーが撮影した画像をもとに実際の生育情報を判断し、
**必ずこの JSON 形式のみ** を返してください（余計な説明・バッククォート不要）。

{
  "stage":"S0〜S7 のいずれか",
  "growthDaysEst":"例 21-25",
  "daysToFlower":"例 20-25",
  "daysToHarvest":"例 35-45",
  "growthStatus":"良好／要注意／弱弱",
  "disease":"なし または 疑わしい病名",
   "careTips":[]
}

実際の画像をよく観察して、値を当てはめてください。
''';

/*
  "careTips":["水やり…","追肥…","ランナー整理…"]

*/

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {"inlineData": {"mimeType": "image/jpeg", "data": b64}}
          ]
        }
      ]
    };

    try {
      final res = await http.post(Uri.parse(uri),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final raw = json.decode(res.body);
      final txt =
          raw['candidates'][0]['content']['parts'][0]['text'] as String;
      final jsonStr = txt.substring(txt.indexOf('{'), txt.lastIndexOf('}') + 1);
      //final data = json.decode(jsonStr) as Map<String, dynamic>;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // ② careTips を上書きするテキストのみリクエスト
      final stage = map['stage'] as String? ?? 'S0';
      final items = CareLogic.itemsForStage(stage).join('、');


      final prompt2 = '''
以下 JSON の "careTips" を、項目ごとに 1 行アドバイスへ上書きして返してください。
必ず JSON のみ。項目: $items

元 JSON:
${jsonEncode(map)}
''';

      final res2 = await http.post(Uri.parse(uri),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt2}
                ]
              }
            ]
          }));
      final txt2 = jsonDecode(res2.body)
          ['candidates'][0]['content']['parts'][0]['text'] as String;
      final json2 =
          txt2.substring(txt2.indexOf('{'), txt2.lastIndexOf('}') + 1);
      final data = jsonDecode(json2) as Map<String, dynamic>;




      final today = DateTime.now();
      //final stage = data['stage'] as String;
      final events = CareLogic.eventsForStage(stage, today);


      // 既存イベントをクリアしてから登録するなら、以下を事前に実行
      await CareRepo.clearAll();
      for (final e in events) {
        await CareRepo.add(e);
      }

      // ── P3: disease が "なし" でなければ防除タスクを当日 18:00 に追加
      final disease = data['disease'] as String;
      if (disease != 'なし') {
        final today18 = DateTime(today.year, today.month, today.day, 18);
        await CareRepo.add(CareEvent(
          date: today18,
          type: CareType.disease,
          note: disease,          // note 用フィールドを追加する場合
        ));
      }


      //await LocalStore.save(map);
      await LocalStore.save(data);

      // ── 写真を Diary に保存して最新ヘッダに反映 ──
      await DiaryRepo.add(Diary(
        id: DateTime.now().toIso8601String(),
        image: xfile.path,
        memo: '',
      ));

      final memo = await _askMemo();       // ユーザーにメモ入力を求める
      if (memo != null && memo.isNotEmpty) {
        final imgPath = await DiaryRepo.saveImage(File(xfile.path));
        await DiaryRepo.add(Diary(
          id: DateTime.now().toIso8601String(),
          image: imgPath,
          memo: memo,
        ));
      }

      FirebaseAnalytics.instance.logEvent(
        name: 'capture_diagnosis',
        parameters: {'result_stage': data['stage']},
      );



      widget.onResult(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }


  Future<bool> _isStrawberry(String base64) async {
    final key = const String.fromEnvironment('GEMINI_KEY');
    const detectPrompt = '''
  あなたは画像判定AIです。
  この画像に「イチゴ（苗・株・果実）」が **主要な被写体として** 写っているか判定し、
  必ず {"isStrawberry":true} もしくは {"isStrawberry":false} だけを返してください。
  ''';
    final uri =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';
    final body = {
      "contents": [
        {
          "parts": [
            {"text": detectPrompt},
            {"inlineData": {"mimeType": "image/jpeg", "data": base64}}
          ]
        }
      ]
    };
    final res = await http.post(Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    final raw = json.decode(res.body);
    final txt = raw['candidates'][0]['content']['parts'][0]['text'] as String;
    final jsonStr = txt.substring(txt.indexOf('{'), txt.lastIndexOf('}') + 1);
    final obj = json.decode(jsonStr) as Map<String, dynamic>;
    return obj['isStrawberry'] as bool;
  }



  Future<String?> _askMemo() async {
    String tmp = '';
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('メモを追加'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => tmp = v,
          decoration: const InputDecoration(hintText: '例）今日は気温25℃'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(c, tmp), child: const Text('保存')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('撮影して診断')),
        body: ctrl.value.isInitialized
            ? Stack(
                children: [
                  CameraPreview(ctrl),
                  if (busy) const Center(child: CircularProgressIndicator()),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        floatingActionButton: FloatingActionButton(
          onPressed: busy ? null : classify,
          child: const Icon(Icons.camera_alt),
        ),
      );
}


