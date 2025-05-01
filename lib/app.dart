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
import 'widgets/today_tip.dart';
import 'dart:io';
import 'repositories/diary_repo.dart';
import 'models/diary.dart';
import 'pages/diary_page.dart';
import 'pages/setting_page.dart';
import 'pages/calendar_page.dart';
import 'services/care_logic.dart';
import 'repositories/care_repo.dart';   // 撮影後イベント生成用
import 'models/care_event.dart';


class BerryApp extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const BerryApp({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return RootPage(initialData: initialData);
  }
}


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
        
        const CalendarPage(), // Dairy
        const TipsPage(), // Tips
        //const Placeholder(), // Shop
        const SettingsPage(), // Setting
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
            NavigationDestination(icon: Icon(Icons.book), label: 'Diary'),
            NavigationDestination(icon: Icon(Icons.lightbulb), label: 'Tips'),
            //NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shop'),
            NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      );
}

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => context.read<ThemeModel>().toggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TodayTip(),
            const SizedBox(height: 12),
           // ── キャラクター＋日数バッジ ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Image.asset(
                    'assets/characters/fairy.png',
                    height: 200,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF2D8),
                      border: Border.all(color: const Color(0xFFCFC2A0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(day,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── メインテキスト ──
            Center(
              child: Text(
                AppLocalizations.of(context)!.homeToday(day),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            // ── 成育ステータス ──
            StatusCard(data: d),
            const Divider(),

            // ── 今日の世話カード ──
            CareCard(careTips: d['careTips']),
            const SizedBox(height: 12),

            // ── リマインダーボタン ──
            ElevatedButton(
              onPressed: () {
                const time = "08:00";
                NotificationService.scheduleDailyReminder(
                  id: 1,
                  title: '水やりの時間です',
                  body: '土表面が乾いたらたっぷり水をあげましょう',
                  hour: 8,
                  minute: 0,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.waterReminder(time)),
                  ),
                );
              },
              child: const Text('水やりリマインダー設定'),
            ),

            const SizedBox(height: 24),

            // ── バナー広告（準備できている時だけ） ──
            if (_bannerReady)
              Center(
                child: SizedBox(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
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
  "careTips":["水やり…","追肥…","ランナー整理…"]
}

実際の画像をよく観察して、値を当てはめてください。
''';

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
      final data = json.decode(jsonStr) as Map<String, dynamic>;

/*
      final today = DateTime.now();
      await CareRepo.add(CareEvent(
        //date: today.add(const Duration(days: 0)),  // 今日 水やり
        date: today,
        type: CareType.water,
      ));
      await CareRepo.add(CareEvent(
        date: today.add(const Duration(days: 7)),  // 7日後 追肥
        type: CareType.fertilize,
      ));

      // ── P1: ランナー整理を 15日後に追加 ──
      await CareRepo.add(CareEvent(
        date: today.add(const Duration(days: 15)),
        type: CareType.runner,
      ));

      // ── P1: 受粉を「花芽形成以降」に翌日に追加 ──
      final stage = data['stage'] as String;
      if (stage == 'S5' || stage == 'S6') {
        await CareRepo.add(CareEvent(
          date: today.add(const Duration(days: 1)),
          type: CareType.pollination,
        ));
      }
*/
      final today = DateTime.now();
      final stage = data['stage'] as String;
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



      await LocalStore.save(data);
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

class StatusCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const StatusCard({required this.data, super.key});

  @override
  Widget build(BuildContext context) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _row('生育日数', data['growthDaysEst']),
              _row('開花まであと', data['daysToFlower']),
              _row('収穫まであと', data['daysToHarvest']),
              _row('状態', data['growthStatus']),
              _row('病気', data['disease'],
                  valueStyle: TextStyle(
                    color: data['disease'] != 'なし' ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold)
                  ),
            ],
          ),
        ),
      );

  Widget _row(String label, String value, {TextStyle? valueStyle}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}

class CareCard extends StatelessWidget {
  final List<dynamic> careTips;
  const CareCard({required this.careTips, super.key});

  @override
  Widget build(BuildContext context) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: careTips
                .map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('・$tip'),
                    ))
                .toList(),
          ),
        ),
      );
}
