import 'package:flutter/material.dart';

import 'pages/account_page.dart';
import 'pages/bank_sampah_page.dart';
import 'pages/detect_page.dart';
import 'pages/eco_challenges_page.dart';
import 'pages/education_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/report_page.dart';
import 'pages/rewards_page.dart';
import 'pages/sorting_guide_page.dart';
import 'pages/tpa_page.dart';
import 'services/auth_service.dart';
import 'services/classifier_service.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'services/report_service.dart';

class SampahDetectorApp extends StatelessWidget {
  const SampahDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F8A70);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deteksi Sampah',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.35),
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.55),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.55),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.35),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 76,
          backgroundColor: Colors.white,
          indicatorColor: colorScheme.primaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
      ),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _prepareApp();
  }

  Future<void> _prepareApp() async {
    await Future.wait([
      ClassifierService.instance.initialize(),
      HistoryService.instance.loadHistory(),
      ReportService.instance.loadReports(),
      NotificationService.instance.initialize(),
      AuthService.instance.initialize(),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingPage();
        }
        return AnimatedBuilder(
          animation: AuthService.instance,
          builder: (context, _) {
            if (AuthService.instance.isAuthenticated) {
              return const HomeShell();
            }
            return const LoginPage();
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7F5), Color(0xFFE8F5EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F8A70), Color(0xFF5BC0A5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F8A70).withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sampah Detector',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Menyiapkan model, sesi login, riwayat, dan data aplikasi...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _appRefreshToken = 0;

  void _handleDataChanged() {
    setState(() {
      _appRefreshToken++;
    });
  }

  void _openFeature(AppFeature feature) {
    switch (feature) {
      case AppFeature.detect:
        setState(() {
          _currentIndex = 1;
        });
        break;
      case AppFeature.history:
        setState(() {
          _currentIndex = 2;
        });
        break;
      case AppFeature.rewards:
        setState(() {
          _currentIndex = 3;
        });
        break;
      case AppFeature.sortingGuide:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SortingGuidePage(),
          ),
        );
        break;
      case AppFeature.education:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EducationPage(),
          ),
        );
        break;
      case AppFeature.report:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportPage(
              onReportChanged: _handleDataChanged,
            ),
          ),
        );
        break;
      case AppFeature.challenges:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EcoChallengesPage(
              refreshToken: _appRefreshToken,
            ),
          ),
        );
        break;
      case AppFeature.tpa:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TpaPage(),
          ),
        );
        break;
      case AppFeature.bankSampah:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BankSampahPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        refreshToken: _appRefreshToken,
        onOpenFeature: _openFeature,
      ),
      DetectPage(
        onHistorySaved: _handleDataChanged,
        onOpenGuide: () => _openFeature(AppFeature.sortingGuide),
      ),
      HistoryPage(
        refreshToken: _appRefreshToken,
        onHistoryChanged: _handleDataChanged,
      ),
      RewardsPage(
        refreshToken: _appRefreshToken,
        onOpenChallenges: () => _openFeature(AppFeature.challenges),
      ),
    ];

    final user = AuthService.instance.currentUser;
    final titles = <String>[
      'Beranda',
      'Deteksi Sampah',
      'Riwayat Scan',
      'Reward & Poin',
    ];
    final subtitles = <String>[
      user == null
          ? 'Semua fitur utama pengelolaan sampah dalam satu dashboard.'
          : 'Seluruh fitur utama pengelolaan sampah tersedia dalam satu dashboard.',
      'Scan kamera atau galeri, preprocessing, dan klasifikasi lokal.',
      'Seluruh hasil klasifikasi tersimpan dan dapat dikelola kapan saja.',
      'Pantau poin, badge, dan progres tantangan secara terpusat.',
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitles[_currentIndex],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Akun',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountPage(),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt_rounded),
            label: 'Deteksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Reward',
          ),
        ],
      ),
    );
  }
}
