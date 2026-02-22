import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/markets/screens/markets_screen.dart';
import 'features/debug/websocket_test_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: BitXApp(),
    ),
  );
}

class BitXApp extends StatelessWidget {
  const BitXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BitX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MarketsScreen(),
    const PlaceholderPage(titleKey: 'trade'),
    const PlaceholderPage(titleKey: 'copyTrading'),
    const PlaceholderPage(titleKey: 'assets'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            activeIcon: const Icon(Icons.show_chart),
            label: l10n.markets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.swap_horiz),
            activeIcon: const Icon(Icons.swap_horiz),
            label: l10n.trade,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: l10n.copyTrading,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.assets,
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String titleKey;

  const PlaceholderPage({super.key, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title;
    
    switch (titleKey) {
      case 'trade':
        title = l10n.trade;
        break;
      case 'copyTrading':
        title = l10n.copyTrading;
        break;
      case 'assets':
        title = l10n.assets;
        break;
      default:
        title = titleKey;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.loading}...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIcon() {
    switch (titleKey) {
      case 'trade':
        return Icons.swap_horiz;
      case 'copyTrading':
        return Icons.people;
      case 'assets':
        return Icons.account_balance_wallet;
      default:
        return Icons.info;
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebSocketTestScreen(),
                ),
              );
            },
            tooltip: 'Debug',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.currency_bitcoin,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BitX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional Crypto Exchange',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 功能模块
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '核心功能',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 功能网格 - 使用自适应布局
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 根据屏幕宽度计算列数
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      final cardWidth = (constraints.maxWidth - 12) / crossAxisCount;
                      final cardHeight = cardWidth * 0.85; // 调整高宽比
                      
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth - 6,
                            height: cardHeight,
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.show_chart,
                              title: l10n.markets,
                              subtitle: '实时行情',
                              color: Colors.blue,
                              onTap: () {
                                // 切换到行情Tab
                                final navigator = context.findAncestorStateOfType<_MainNavigatorState>();
                                navigator?.setState(() {
                                  navigator._currentIndex = 1;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth - 6,
                            height: cardHeight,
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.swap_horiz,
                              title: l10n.trade,
                              subtitle: '快速交易',
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth - 6,
                            height: cardHeight,
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.people,
                              title: l10n.copyTrading,
                              subtitle: '跟随高手',
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth - 6,
                            height: cardHeight,
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.account_balance_wallet,
                              title: l10n.assets,
                              subtitle: '资产管理',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 技术栈信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              '技术栈',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTechItem('Flutter 3.22.3'),
                        _buildTechItem('Riverpod State Management'),
                        _buildTechItem('WebSocket Real-time Data'),
                        _buildTechItem('Multi-language Support'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

