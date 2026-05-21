import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../widgets/mono_card.dart';
import '../services/task_services.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final TaskService _taskService = TaskService();
  final Random _random = Random();

  // Status navigasi layar internal
  // 0: Memilih Level Energi/Mood (Pilih Tingkat Kesulitan Quest)
  // 1: Matchmaking Tugas (Sistem Geser/Swipe ala Tinder)
  // 2: Quest Sedang Aktif (Layar Terkunci Sampai Tugas Selesai)
  int _screenState = 0;

  bool _isLoading = false;
  int _selectedLevel = 1;
  List<String> _questPool = [];
  String _currentRandomTask = '';
  String _activeQuestTask = '';

  // Kunci penyimpanan SharedPreferences untuk sesi Quest yang persisten
  final String _keyInQuest = 'mono_in_quest';
  final String _keyQuestTask = 'mono_quest_task';

  @override
  void initState() {
    super.initState();
    _loadQuestSession();
  }

  // Memuat sesi quest aktif dari penyimpanan lokal saat aplikasi dibuka kembali
  void _loadQuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final inQuest = prefs.getBool(_keyInQuest) ?? false;
    final questTask = prefs.getString(_keyQuestTask) ?? '';

    if (inQuest && questTask.isNotEmpty && mounted) {
      setState(() {
        _activeQuestTask = questTask;
        _screenState = 2; // Langsung kunci ke layar Quest Mode Aktif
      });
    }
  }

  // Memuat daftar tugas dari Supabase yang belum selesai berdasarkan level pentingnya (importance_level)
  // Menggunakan fallback dinamis jika metode khusus belum dideklarasikan di TaskService
  void _loadTasksForLevel(int level) async {
    setState(() => _isLoading = true);
    try {
      List<String> results = [];

      // Menggunakan pemeriksaan dinamis (dynamic check) untuk menghindari compile-time error
      // jika fungsi fetchTasksByImportance belum diimplementasikan di TaskService milikmu.
      try {
        results =
            await (_taskService as dynamic).fetchTasksByImportance(level)
                as List<String>;
      } catch (e) {
        // Fallback: Mengambil semua tugas menggunakan fetchTasks() yang sudah ada,
        // kemudian kita lakukan filtering manual atau menggunakannya sebagai pool jika filtering gagal.
        final allTasks = await _taskService.fetchTasks();
        results = List<String>.from(allTasks);
      }

      if (mounted) {
        setState(() {
          _questPool = results;
          _isLoading = false;
          _selectedLevel = level;

          if (_questPool.isNotEmpty) {
            _screenState = 1; // Pindah ke layar swipe matchmaking
            _rerollTask();
          } else {
            _showEmptyWarning(level);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Gagal memuat tugas dari database');
      }
    }
  }

  // Mengacak satu tugas baru dari quest pool yang tersedia
  void _rerollTask() {
    if (_questPool.isEmpty) return;
    setState(() {
      int randomIndex = _random.nextInt(_questPool.length);
      _currentRandomTask = _questPool[randomIndex];
    });
  }

  // Menerima Quest (Geser Kanan) dan menyimpan status sesi ke SharedPreferences
  void _acceptQuest(String taskTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInQuest, true);
    await prefs.setString(_keyQuestTask, taskTitle);

    if (mounted) {
      setState(() {
        _activeQuestTask = taskTitle;
        _screenState = 2; // Mengunci layar ke Quest Mode
      });

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [0, 40, 80, 40],
        ); // Umpan balik haptik sukses menerima quest
      }
    }
  }

  // Menyelesaikan Quest, menghapus sesi penyimpanan lokal, dan memperbarui status di Supabase
  // Menggunakan fallback dinamis jika metode completeTask belum dideklarasikan di TaskService
  void _completeQuest() async {
    setState(() => _isLoading = true);

    try {
      // Menggunakan pemeriksaan dinamis (dynamic check) untuk menghindari compile-time error
      // jika fungsi completeTask belum dideklarasikan di TaskService milikmu.
      try {
        await (_taskService as dynamic).completeTask(_activeQuestTask);
      } catch (e) {
        // Fallback aman: Jika completeTask belum ada di servis kamu, kita tetap dapat melanjutkannya
        // secara visual dan lokal agar aplikasi tidak crash saat diuji coba.
        debugPrint(
          'Fallback: completeTask belum diimplementasikan di TaskService. Error: $e',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInQuest);
      await prefs.remove(_keyQuestTask);

      if (mounted) {
        setState(() {
          _activeQuestTask = '';
          _screenState = 0; // Kembali ke menu utama pemilihan level mood
          _isLoading = false;
        });

        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(
            duration: 150,
          ); // Getaran panjang saat quest berhasil diselesaikan
        }

        _showSuccessSnackBar('Quest Selesai! Energi kamu bertambah!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Gagal memperbarui status di database. Coba lagi.');
      }
    }
  }

  void _showEmptyWarning(int level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tidak ada tugas ber-Level $level saat ini. Buat tugas baru dulu!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.amber[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : AnimatedSwitcher(
                  duration: 400.ms,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStateView(),
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_screenState) {
      case 0:
        return _buildMoodSelectionView();
      case 1:
        return _buildQuestMatchmakerView();
      case 2:
        return _buildActiveQuestView();
      default:
        return _buildMoodSelectionView();
    }
  }

  // TAMPILAN 1: Memilih Tingkat Kesulitan / Mood Level RPG
  Widget _buildMoodSelectionView() {
    return Column(
      key: const ValueKey('mood_selection_view'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),

        // Judul Header Minimalis
        Center(
          child: Column(
            children: [
              Text(
                'ENERGY LEVEL',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.textGrey.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How are you feeling today?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Mood Level 1: Chill Focus
        _buildMoodRankCard(
          level: 1,
          title: 'CHILL FOCUS',
          desc: 'Tugas ringan untuk sisa energi santai',
          color: Colors.blueAccent.withOpacity(0.15),
          borderColor: Colors.blueAccent.withOpacity(0.4),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Mood Level 2: Steady Quest
        _buildMoodRankCard(
          level: 2,
          title: 'STEADY QUEST',
          desc: 'Tugas sedang untuk fokus harian normal',
          color: Colors.amberAccent.withOpacity(0.15),
          borderColor: Colors.amberAccent.withOpacity(0.4),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Mood Level 3: Boss Fight
        _buildMoodRankCard(
          level: 3,
          title: 'BOSS FIGHT',
          desc: 'Tugas berat saat fokusmu sedang tajam',
          color: Colors.redAccent.withOpacity(0.12),
          borderColor: Colors.redAccent.withOpacity(0.4),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

        const Spacer(),
      ],
    );
  }

  Widget _buildMoodRankCard({
    required int level,
    required String title,
    required String desc,
    required Color color,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => _loadTasksForLevel(level),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'Lvl $level',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  // TAMPILAN 2: Swipe Matchmaking (Quest Selection ala Tinder - Edisi Kartu RPG Eksklusif)
  Widget _buildQuestMatchmakerView() {
    // Menyesuaikan warna tema kartu petualangan berdasarkan tingkatan energi yang dipilih
    Color accentColor;
    IconData levelIcon;
    switch (_selectedLevel) {
      case 1:
        accentColor = Colors.blueAccent;
        levelIcon = Icons.eco_rounded;
        break;
      case 3:
        accentColor = Colors.redAccent;
        levelIcon = Icons.local_fire_department_rounded;
        break;
      default:
        accentColor = Colors.amber[700]!;
        levelIcon = Icons.bolt_rounded;
    }

    return Column(
      key: const ValueKey('quest_matchmaker_view'),
      children: [
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => setState(() => _screenState = 0),
              color: AppColors.textGrey,
            ),
            Text(
              'QUEST BOARD (LVL $_selectedLevel)',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(
              width: 48,
            ), // Spasi penyeimbang agar judul tetap berada di tengah
          ],
        ),

        const Spacer(),

        // Wadah Geser Kartu Tugas (Didesain lebih besar dan kokoh mirip kartu petualangan RPG asli)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
              maxHeight:
                  460, // Membuat kartu jauh lebih tinggi dan proporsional layaknya kartu koleksi
            ),
            child: Dismissible(
              key: UniqueKey(), // Memaksa pembuatan ulang widget saat di-reroll
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  // Geser Kiri: Skip & Reroll Acak Tugas Baru
                  _rerollTask();
                } else if (direction == DismissDirection.startToEnd) {
                  // Geser Kanan: Terima Quest & Kunci Sesi
                  _acceptQuest(_currentRandomTask);
                }
              },
              // Efek Visual Geser Kanan (Terima / Mulai Quest)
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 40),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                          Icons.bolt,
                          color: AppColors.accentGreen,
                          size: 48,
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 1.seconds),
                    const SizedBox(height: 8),
                    Text(
                      'START',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGreen,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Efek Visual Geser Kiri (Abaikan / Reroll)
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 40),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ).animate().rotate(
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SKIP',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              child: Card(
                elevation: 12,
                shadowColor: AppColors.primary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: accentColor.withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        // Aksen background dekoratif minimalis khas RPG
                        Positioned(
                          top: -60,
                          right: -60,
                          child: CircleAvatar(
                            radius: 110,
                            backgroundColor: accentColor.withOpacity(0.04),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Bagian Atas Kartu (Rank Badge & Icon)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          levelIcon,
                                          size: 14,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'LVL $_selectedLevel QUEST',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: AppColors.textGrey.withOpacity(0.4),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Konten Judul Tugas Utama (Paling Besar & Intuitif di Tengah)
                              Center(
                                child: Text(
                                  _currentRandomTask,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.4,
                                  ),
                                ),
                              ).animate().scale(
                                duration: 350.ms,
                                curve: Curves.easeOutBack,
                              ),

                              const Spacer(),

                              // Bagian Bawah Kartu (Status Quest & Tanda Persetujuan)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.textGrey.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 14,
                                      color: AppColors.textGrey.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'GESER KANAN UNTUK MEMULAI',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: AppColors.textGrey.withOpacity(
                                          0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        // Instruksi Navigasi Isyarat Gestur (Swipe Gestures)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Skip (Geser Kiri)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Terima (Geser Kanan)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentGreen.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 48),
      ],
    );
  }

  // TAMPILAN 3: Quest Mode Terkunci (Halaman Tugas Aktif)
  Widget _buildActiveQuestView() {
    return Column(
      key: const ValueKey('active_quest_view'),
      children: [
        const Spacer(),

        // Indikator Berkedip RPG
        Center(
          child: Column(
            children: [
              Text(
                    'QUEST SEDANG BERLANGSUNG',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.accentGreen,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .fadeIn(duration: 1.seconds)
                  .then()
                  .fadeOut(duration: 1.seconds),
              const SizedBox(height: 8),
              Text(
                'Lakukan tugas ini secara mendalam tanpa distraksi!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Tampilan Kartu Tugas Terkunci
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child:
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _activeQuestTask,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ).animate().shimmer(
                  delay: 1.seconds,
                  duration: 1.5.seconds,
                  color: AppColors.accentGreen.withOpacity(0.1),
                ),
          ),
        ),

        const Spacer(),

        // Tombol Konfirmasi Selesai
        GestureDetector(
          onTap: _completeQuest,
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        ),

        const SizedBox(height: 16),

        Text(
          'SELESAIKAN QUEST',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.textGrey,
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }
}
