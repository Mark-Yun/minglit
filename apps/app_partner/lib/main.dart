import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321', // 로컬 기본값
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH', // 로컬 기본값
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(const MinglitPartnerApp());
}

final supabase = Supabase.instance.client;

class MinglitPartnerApp extends StatelessWidget {
  const MinglitPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minglit Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7043), // Spark Orange (Partner Theme)
          primary: const Color(0xFFFF7043),
          secondary: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: const ConnectionCheckPage(),
    );
  }
}

class ConnectionCheckPage extends StatefulWidget {
  const ConnectionCheckPage({super.key});

  @override
  State<ConnectionCheckPage> createState() => _ConnectionCheckPageState();
}

class _ConnectionCheckPageState extends State<ConnectionCheckPage> {
  String _status = 'Supabase 연결 확인 중...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // profiles 테이블 조회 시도 (연결 확인용)
      await supabase.from('profiles').select().limit(1);
      
      setState(() {
        _status = '✅ Partner DB 연결 성공!';
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _status = '❌ 연결 실패: $e';
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Minglit Partner',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7043), // Orange
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                fontSize: 18,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (!_isConnected)
              ElevatedButton(
                onPressed: _checkConnection,
                child: const Text('다시 시도'),
              ),
          ],
        ),
      ),
    );
  }
}