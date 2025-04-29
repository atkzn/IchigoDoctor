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



class BerryApp extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const BerryApp({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return RootPage(initialData: initialData);
  }
}

/*
class BerryApp extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const BerryApp({super.key, this.initialData});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ベビイチゴ診断',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFAF3F3F),
        scaffoldBackgroundColor: const Color(0xFFFAF2D8),
        textTheme: GoogleFonts.mPlusRounded1cTextTheme(),
      ),
      home: RootPage(initialData: initialData),
    );
  }
}
*/

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
        const Placeholder(),
        const Placeholder(),
        const Placeholder(),
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
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shop'),
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


/*
class HomePage extends StatelessWidget {
  final Map<String, dynamic>? data;
  const HomePage({Key? key, this.data}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final d = data ?? _dummy;                         // ← 変数宣言を最初に
    final String day = d['growthDaysEst'];            // ← day もここで
    //final today = DateFormat.MMMd('ja').format(DateTime.now());
    return Scaffold(                             // ← Scaffold を追加
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),     // 多言語タイトル
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Image.asset('assets/characters/fairy.png', height: 200),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            Center(
              child: Text(
                AppLocalizations.of(context)!.homeToday(day),     // ← 多言語化
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            StatusCard(data: d),
            const Divider(),
            CareCard(careTips: d['careTips']),
            const SizedBox(height: 12),  // 少し余白を入れます
            ElevatedButton(
              onPressed: () {
                final time = "08:00";
                // 水やりを毎日8:00に通知するスケジュールを登録
                NotificationService.scheduleDailyReminder(
                  id: 1,
                  title: '水やりの時間です',
                  body: '土表面が乾いたらたっぷり水をあげましょう',
                  hour: 8,
                  minute: 0,
                );
                // 設定完了を画面下部に一瞬だけ表示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.waterReminder(time))),
                );
              },
              child: const Text('水やりリマインダー設定'),
            ),
            SizedBox(
              height: 60,
              child: AdWidget(
                ad: BannerAd(
                  adUnitId: 'ca-app-pub-3940256099942544/6300978111', // テスト用
                  size: AdSize.banner,
                  request: const AdRequest(),
                  listener: BannerAdListener(),
                )..load(),
              ),
            ),
          ],
        ),
      )
    );
  }
}
*/

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
      await LocalStore.save(data);

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
              _row('病気', data['disease']),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
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
