import 'package:flutter/material.dart';

import 'pages/detect_page.dart';
import 'pages/history_page.dart';

class SampahDetectorApp extends StatelessWidget {
  const SampahDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deteksi Sampah',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
      ),
      home: const HomeShell(),
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
  int _historyRefreshToken = 0;

  void _handleHistorySaved() {
    setState(() {
      _historyRefreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DetectPage(onHistorySaved: _handleHistorySaved),
      HistoryPage(refreshToken: _historyRefreshToken),
    ];

    final titles = <String>[
      'Deteksi Sampah',
      'Riwayat Deteksi',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
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
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Deteksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
