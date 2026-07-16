import 'package:flutter/material.dart';

import '../features/events/screen/events_screen.dart';
import '../features/history/screen/history_screen.dart';
import '../features/leaderboard/screen/leaderboard_screen.dart';
import '../features/orders/screen/order_screen.dart';
import '../features/tracking/screen/tracking_screen.dart';
import 'connection_status_wrapper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TrackingScreen(),
    const HistoryScreen(),
    const LeaderboardScreen(),
    const EventsScreen(),
    const OrderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionStatusWrapper(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.run_circle_outlined),
            activeIcon: Icon(Icons.run_circle),
            label: 'Chạy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Xếp hạng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Đặt hàng',
          ),
        ],
      ),
    );
  }
}
