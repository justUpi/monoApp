import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../services/auth_service.dart'; // Pastikan path-nya benar
import '../widgets/mono_app_bar.dart'; // Import custom AppBar
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

  List<Widget> get _pages => [
    const FocusScreen(),
    TasksScreen(
      isActive: _selectedIndex == 1,
    ), // Mengirim info status aktif tab secara real-time
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          true, // Memungkinkan user mengetuk area luar untuk membatalkan
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.textGrey.withOpacity(0.1),
              width: 1,
            ),
          ),
          title: Text(
            'Keluar dari MONO',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
          ),
          actions: [
            // Tombol "Batal" (No)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Tombol "Ya, Keluar" (Yes)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _handleLogout(); // Jalankan logic logout
              },
              child: Text(
                'Ya, Keluar',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
          backgroundColor: AppColors.background,
          // Memasang MonoAppBar baru yang sudah terintegrasi tombol logout di atas HomeScreen
          appBar: MonoAppBar(onLogoutPressed: _showLogoutDialog),
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
                      showSelectedLabels:
                          true, // Menampilkan nama halaman saat aktif
                      showUnselectedLabels:
                          false, // Menyembunyikan nama halaman saat tidak aktif
                      selectedLabelStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
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
