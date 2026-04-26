import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../services/auth_service.dart'; // Pastikan path-nya benar
import 'focus_screen.dart';
import 'tasks_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [const FocusScreen(), const TasksScreen()];

  // Fungsi Logout
  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      // Membersihkan semua route dan kembali ke halaman Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 600;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            surfaceTintColor:
                Colors.transparent, // Menghilangkan warna ungu di Android 12+
            title: Text(
              '',
              style: GoogleFonts.outfit(
                letterSpacing: 4,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              // Logout button yang lebih halus
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) =>
                      setState(() => _selectedIndex = index),
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.primary.withOpacity(0.1),
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primary,
                  ),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
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

              if (isDesktop) const VerticalDivider(thickness: 0.5, width: 0.5),

              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),

          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    top: 10,
                  ),
                  color: AppColors.background,
                  child: ClipRRect(
                    // Membuat bottom bar melayang (Floating effect)
                    borderRadius: BorderRadius.circular(24),
                    child: BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: (index) => setState(() => _selectedIndex = index),
                      backgroundColor: Colors.white,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: Colors.grey[300],
                      showSelectedLabels: false,
                      showUnselectedLabels: false,
                      elevation: 10,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.lens_outlined),
                          activeIcon: Icon(Icons.lens),
                          label: 'Focus',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.list_outlined),
                          activeIcon: Icon(Icons.list),
                          label: 'Tasks',
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
