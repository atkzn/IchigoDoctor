// lib/main.dart

/*
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';   // ← flutterfire configure で生成
import 'app.dart';               // ← 下記の app.dart を参照
import 'cameras.dart';           // ← 上の cameras.dart を参照
import 'notification_service.dart';
import 'local_store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'theme_model.dart';          // ← Step3 で作成したファイル
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'notifiers/latest_notifier.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日本語の DateFormat データを初期化
  await initializeDateFormatting('ja', null);

  // Firebase 初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await MobileAds.instance.initialize();

  // カメラデバイスを取得して cameras にセット
  cameras = await availableCameras();
  // ── Step2: 通知サービス初期化 ──
  await NotificationService.init();

  // 🔽 起動時に保存済みデータを読み込む
  final saved = await LocalStore.load();
  runApp(
    MultiProvider(            // ★ Provider をまとめて登録
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModel()),
        ChangeNotifierProvider(create: (_) => LatestNotifier()), // ★追加
      ],
      child: const BabyBerryApp(),
    ),
  );

}


class BabyBerryApp extends StatelessWidget {
  const BabyBerryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (_, theme, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: theme.mode,             // ← ここだけ動的
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFAF3F3F),
        ),
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const RootPage(),            // ← 以降は再生成されない
      ),
    );
  }
}


/// サインイン状態に応じて画面を切り替え
class EntryPoint extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const EntryPoint({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (_, theme, __) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: theme.mode,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: const Color(0xFFAF3F3F),
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: const Color(0xFFAF3F3F),
                brightness: Brightness.dark,
              ),
              navigatorObservers: [
                FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
              ],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: snap.hasData
                  ? BerryApp(initialData: initialData)   // ← ここで渡す
                  : const SignInPage(),
            );
          },
        );
      },
    );
  }
}


/// 簡易メール＋匿名サインインページ
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _mail = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  // ① ログイン
  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _mail.text.trim(),
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('ログイン失敗: ${e.message}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ② 新規登録
  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _mail.text.trim(),
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('登録失敗: ${e.message}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ③ 匿名サインイン
  Future<void> _anonymousSignIn() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('匿名ログイン失敗: ${e.message}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ログイン / 新規登録')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _mail,
            decoration: const InputDecoration(labelText: 'メールアドレス'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _pass,
            decoration: const InputDecoration(labelText: 'パスワード'),
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // ログイン／登録ボタン
          ElevatedButton(
            onPressed: _loading ? null : _signIn,
            child: _loading 
              ? const CircularProgressIndicator() 
              : const Text('ログイン'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _signUp,
            child: const Text('新規登録'),
          ),
          const SizedBox(height: 16),

          // 匿名サインイン
          TextButton(
            onPressed: _loading ? null : _anonymousSignIn,
            child: const Text('匿名で試す'),
          ),
        ],
      ),
    ),
  );
}
*/
// lib/main.dart
//
// * Firebase / Ads / カメラ初期化
// * MultiProvider で Theme と 最新ダイアリーを共有
// * MaterialApp は BabyBerryApp が 1 回だけ生成
// ------------------------------------------------------

import 'dart:async';                 // ← Zone, runZonedGuarded
import 'dart:io';                    // ← File, FileMode
import 'package:path_provider/path_provider.dart';  // ← getTemporaryDirectory

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'firebase_options.dart';
import 'cameras.dart';
import 'pages/home_page.dart';           // ← Home 画面
import 'pages/root_page.dart';
import 'notifiers/theme_notifier.dart';    // ← ライト／ダーク切替
import 'notifiers/latest_notifier.dart';
import 'utils/logger.dart';             // ← ファイルログ
import 'notifiers/theme_notifier.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final List<CameraDescription> cams = await availableCameras();
  cameras = cams;                      // ← global 変数にセット


  FlutterError.onError = (details) {
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  };

  runZonedGuarded(() async {
    // ★ここに今までの初期化処理をそのまま書く
    await initializeDateFormatting('ja');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MobileAds.instance.initialize();
    cameras = await availableCameras();


    //runApp(const BabyBerryApp());
    runApp(
      /// ここを MultiProvider でまとめて包む
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => LatestNotifier()),
        ],
        child: const BabyBerryApp(),   // ← root ウィジェット名は自分のファイルと合わせて
      ),
    );


  }, (e, st) async {
    final dir = await getTemporaryDirectory();   // 端末内の一時フォルダ
    final file = File('${dir.path}/fatal.log');  // fatal.log に追記
    await file.writeAsString('$e\n$st\n\n', mode: FileMode.append);
  });



  /*
  await initializeDateFormatting('ja');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();

  // ※ cameras は global 変数（lib/cameras.dart で宣言済み）
  cameras = await availableCameras();

  await Log.d('🚀 BabyBerry 起動');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LatestNotifier()),
      ],
      child: const BabyBerryApp(),
    ),
  );
  */
}

//──────────────────────────────────────────── BabyBerryApp
class BabyBerryApp extends StatelessWidget {
  const BabyBerryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'BabyBerry',
      debugShowCheckedModeBanner: false,
      //themeMode: theme.mode,
      themeMode: context.watch<ThemeNotifier>().mode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFAF3F3F),
        scaffoldBackgroundColor: const Color(0xFFFDF6F6),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const RootPage(),
    );
  }
}
