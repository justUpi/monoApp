import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mono/services/notification_services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../widgets/mono_card.dart';
import '../services/task_services.dart';

class FocusScreen extends StatefulWidget {
  final bool isActive;

  const FocusScreen({super.key, this.isActive = false});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService =
      NotificationService(); // 2. INISIALISASI INSTANCE SERVICE
  final Random _random = Random();

  int _screenState = 0;
  bool _isLoading = false;
  bool _isCountingTasks = false;
  int _selectedLevel = 1;
  List<String> _questPool = [];
  String _currentRandomTask = '';
  String _activeQuestTask = '';

  int _currentTaskIndex = 0;

  Map<int, int> _taskCounts = {1: 0, 2: 0, 3: 0};

  final String _keyInQuest = 'mono_in_quest';
  final String _keyQuestTask = 'mono_quest_task';
  final String _keyQuestLevel =
      'mono_quest_level'; // Key tambahan untuk menyimpan level quest aktif

  @override
  void initState() {
    super.initState();
    _loadQuestSession();
    _countActiveTasks();
  }

  @override
  void didUpdateWidget(covariant FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _countActiveTasks();
    }
  }

  void _loadQuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final inQuest = prefs.getBool(_keyInQuest) ?? false;
    final questTask = prefs.getString(_keyQuestTask) ?? '';
    final questLevel = prefs.getInt(_keyQuestLevel) ?? 1;

    if (inQuest && questTask.isNotEmpty && mounted) {
      setState(() {
        _activeQuestTask = questTask;
        _selectedLevel =
            questLevel; // Kembalikan state level yang aktif sebelum aplikasi ditutup
        _screenState = 2;
      });
    }
  }

  void _countActiveTasks() async {
    if (!mounted) return;
    setState(() => _isCountingTasks = true);

    try {
      final List<dynamic> allTasks = await _taskService.fetchTasks();
      int lvl1 = 0;
      int lvl2 = 0;
      int lvl3 = 0;

      for (var task in allTasks) {
        if (task['is_completed'] == false) {
          final int? level = task['importance'] ?? task['importance_level'];
          if (level == 1) lvl1++;
          if (level == 2) lvl2++;
          if (level == 3) lvl3++;
        }
      }

      if (mounted) {
        setState(() {
          _taskCounts = {1: lvl1, 2: lvl2, 3: lvl3};
          _isCountingTasks = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal menghitung counter tugas: $e');
      if (mounted) setState(() => _isCountingTasks = false);
    }
  }

  void _loadTasksForLevel(int level) async {
    setState(() => _isLoading = true);
    try {
      List<String> results = [];
      try {
        final rawResponse = await (_taskService as dynamic)
            .fetchTasksByImportance(level);
        if (rawResponse is List) {
          results = rawResponse
              .map((task) => task['title'].toString())
              .toList();
        }
      } catch (e) {
        final List<dynamic> allTasks = await _taskService.fetchTasks();
        results = allTasks
            .where(
              (task) =>
                  (task['importance'] == level ||
                      task['importance_level'] == level) &&
                  task['is_completed'] == false,
            )
            .map((task) => task['title'].toString())
            .toList();
      }

      if (mounted) {
        // Pastikan modifikasi list dan index dimasukkan ke dalam satu block setState yang sama
        setState(() {
          _questPool = results;
          _questPool.shuffle(_random);

          _isLoading = false;
          _selectedLevel = level;

          if (_questPool.isNotEmpty) {
            _currentTaskIndex = 0; // Set ke indeks 0 di sini
            _currentRandomTask =
                _questPool[_currentTaskIndex]; // Langsung ambil tugas pertama tanpa memanggil _rerollTask() terpisah
            _screenState = 1; // Pindah screen setelah data siap
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

  void _handleCardDismissed(DismissDirection direction) {
    if (direction == DismissDirection.endToStart) {
      // Geser Kiri: Naikkan indeks ke tugas berikutnya
      setState(() {
        if (_currentTaskIndex < _questPool.length - 1) {
          _currentTaskIndex++;
        } else {
          _currentTaskIndex = 0; // Reset ke 0 jika sudah di akhir list
          _questPool.shuffle(_random); // Acak ulang antrean
        }

        // Perbarui text target langsung di dalam setState agar UI tidak delay
        _currentRandomTask = _questPool[_currentTaskIndex];
      });
    } else if (direction == DismissDirection.startToEnd) {
      // Geser Kanan: Terima quest
      _acceptQuest(_currentRandomTask);
    }
  }

  // 3. UPDATE: Memicu pendaftaran jadwal notifikasi saat quest diterima
  // 1. Fungsi Utama: Langsung update UI tanpa menunggu
  void _acceptQuest(String taskTitle) {
    // Pindahkan setState ke paling atas agar perpindahan layar terjadi SEKETIKA
    setState(() {
      _activeQuestTask = taskTitle;
      _screenState = 2; // Langsung tampilkan _buildActiveQuestView()
    });

    // Panggil proses background (async) secara terpisah
    _processQuestDataInBackground(taskTitle);
  }

  // 2. Fungsi Background: Menangani penyimpanan & notifikasi
  Future<void> _processQuestDataInBackground(String taskTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyInQuest, true);
      await prefs.setString(_keyQuestTask, taskTitle);
      await prefs.setInt(_keyQuestLevel, _selectedLevel);

      // Jadwalkan notifikasi
      await _notificationService.scheduleQuestNotification(
        questLevel: _selectedLevel,
        questTitle: taskTitle,
      );

      // Getaran dijalankan setelah layar berpindah
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 40, 80, 40]);
      }
    } catch (e) {
      debugPrint('Error saat menyimpan sesi quest: $e');
    }
  }

  // 4. UPDATE: Membatalkan jadwal notifikasi jika quest selesai sebelum batas waktu habis
  void _completeQuest() async {
    setState(() => _isLoading = true);
    try {
      try {
        await (_taskService as dynamic).completeTask(_activeQuestTask);
      } catch (e) {
        debugPrint('Fallback completeTask: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInQuest);
      await prefs.remove(_keyQuestTask);
      await prefs.remove(_keyQuestLevel);

      // BATALKAN JADWAL NOTIFIKASI KARENA TUGAS SUDAH SELESAI
      await _notificationService.cancelQuestNotification();

      if (mounted) {
        setState(() {
          _activeQuestTask = '';
          _screenState = 0;
          _isLoading = false;
        });

        _countActiveTasks();

        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 150);
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
          'Tidak ada tugas ber-Level $level saat ini.',
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

  Widget _buildMoodSelectionView() {
    return Column(
      key: const ValueKey('mood_selection_view'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
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
        const SizedBox(height: 16),
        _buildMoodRankCard(
          level: 1,
          title: 'CHILL FOCUS',
          desc: 'Tugas ringan untuk sisa energi santai',
          color: Colors.blueAccent.withOpacity(0.15),
          borderColor: Colors.blueAccent.withOpacity(0.4),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildMoodRankCard(
          level: 2,
          title: 'STEADY QUEST',
          desc: 'Tugas sedang untuk fokus harian normal',
          color: Colors.amberAccent.withOpacity(0.15),
          borderColor: Colors.amberAccent.withOpacity(0.4),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
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
    final int questCount = _taskCounts[level] ?? 0;
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
            _isCountingTasks
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textGrey,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$questCount Quests',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: questCount > 0
                            ? AppColors.primary
                            : AppColors.textGrey.withOpacity(0.6),
                      ),
                    ),
                  ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestMatchmakerView() {
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
              'QUEST ${_currentTaskIndex + 1} OF ${_questPool.length}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),

        const Spacer(),

        const SizedBox(height: 20),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 460),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: _handleCardDismissed,
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
              child: MonoCard(
                text: _currentRandomTask,
                level: _selectedLevel,
                accentColor: accentColor,
                levelIcon: levelIcon,
              ),
            ),
          ),
        ),

        const Spacer(),

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

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActiveQuestView() {
    return Column(
      key: const ValueKey('active_quest_view'),
      children: [
        const Spacer(),
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
        const SizedBox(height: 16),
      ],
    );
  }
}
