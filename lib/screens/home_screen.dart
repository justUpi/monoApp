import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'focus_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const FocusScreen(), const TasksScreen()];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 600;

        return Scaffold(
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() => _selectedIndex = index);
                  },
                  backgroundColor: Colors.white,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primary,
                  ),
                  unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
                  labelType: NavigationRailLabelType.selected,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.lens_outlined),
                      selectedIcon: Icon(Icons.lens),
                      label: Text('Focus'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_outlined),
                      selectedIcon: Icon(Icons.list),
                      label: Text('Tasks'),
                    ),
                  ],
                ),

              if (isDesktop) const VerticalDivider(thickness: 1, width: 1),

              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),

          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    backgroundColor: Colors.white,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: Colors.grey[400],
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.lens_outlined),
                        label: 'Focus',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.list_outlined),
                        label: 'Tasks',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
