import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/constants.dart';
import '../widgets/task_item.dart';
import '../services/task_services.dart';

class TasksScreen extends StatefulWidget {
  final bool
  isActive; // Parameter untuk mendeteksi apakah tab ini sedang aktif/terbuka

  const TasksScreen({super.key, this.isActive = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  late TabController _tabController;

  bool _isLoading = true;
  int _selectedImportance = 1;
  final TextEditingController _taskController = TextEditingController();

  // Memisahkan penampung data tugas aktif dan selesai
  final List<dynamic> _activeTasks = [];
  final List<dynamic> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(
      showSpinner: true,
    ); // Pertama kali dibuka, tampilkan loading spinner
  }

  // Mendeteksi perubahan parameter dari HomeScreen secara otomatis saat berpindah tab
  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika tab yang tadinya tidak aktif sekarang menjadi aktif, muat ulang data secara senyap
    if (widget.isActive && !oldWidget.isActive) {
      _loadData(showSpinner: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  // Memuat data dengan penanganan tipe data yang super ketat dan aman
  void _loadData({bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await _taskService.fetchTasks();
      if (mounted) {
        final List<dynamic> active = [];
        final List<dynamic> completed = [];

        for (var task in results) {
          final dynamic rawCompleted = task['is_completed'];

          // Pengecekan menyeluruh mencakup tipe boolean, integer, string, hingga karakter inisial postgres ('t')
          bool isDone = false;
          if (rawCompleted != null) {
            if (rawCompleted is bool) {
              isDone = rawCompleted;
            } else if (rawCompleted is int) {
              isDone = rawCompleted == 1;
            } else if (rawCompleted is String) {
              final normalized = rawCompleted.trim().toLowerCase();
              isDone =
                  normalized == 'true' ||
                  normalized == '1' ||
                  normalized == 't';
            }
          }

          if (isDone) {
            completed.add(task);
          } else {
            active.add(task);
          }
        }

        setState(() {
          _activeTasks.clear();
          _activeTasks.addAll(active);

          _completedTasks.clear();
          _completedTasks.addAll(completed);

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addNewTask() async {
    final title = _taskController.text.trim();

    if (title.isNotEmpty) {
      bool success = await _taskService.saveTask(
        title: title,
        importance: _selectedImportance,
      );

      if (success) {
        _loadData(showSpinner: false);
        _taskController.clear();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar('Failed to save to Supabase', Colors.redAccent);
      }
    } else {
      _showSnackBar('Please enter a task title', Colors.orange);
    }
  }

  void _showSnackBar(String text, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Header & Tab Bar Switcher
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TASKS HUB',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_activeTasks.length} pending',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Custom Minimalist Tab Bar Design
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textGrey.withOpacity(
                            0.5,
                          ),
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Active Quests'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tab View Content Area
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: Daftar Tugas Aktif
                            _buildTaskList(_activeTasks, isHistory: false),

                            // TAB 2: Riwayat Tugas (Sudah Selesai)
                            _buildTaskList(_completedTasks, isHistory: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildTaskList(List<dynamic> taskSource, {required bool isHistory}) {
    if (taskSource.isEmpty) {
      return _buildEmptyState(isHistory);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(showSpinner: false),
      color: AppColors.primary,
      strokeWidth: 2,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: taskSource.length,
        itemBuilder: (context, index) {
          final task = taskSource[index];
          return TaskItem(
                title: task['title'] ?? 'Untitled Task',
                isCompleted:
                    isHistory, // Otomatis mencoret teks jika dirender di tab History
                onTap: () {
                  // Kosong: Perubahan status dikunci, hanya bisa dari Focus Screen
                },
              )
              .animate()
              .fadeIn(delay: (index * 40).ms, duration: 350.ms)
              .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isHistory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory
                ? Icons.history_toggle_off_rounded
                : Icons.assignment_turned_in_outlined,
            size: 56,
            color: AppColors.textGrey.withOpacity(0.15),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 14),
          Text(
            isHistory
                ? 'No completed tasks yet.'
                : 'All catch up! No pending tasks.',
            style: GoogleFonts.inter(
              color: AppColors.textGrey.withOpacity(0.4),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _taskController,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your focus task...',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textGrey.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "How important is this?",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [1, 2, 3].map((level) {
                    final isSelected = _selectedImportance == level;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: level == 1 ? 0 : 6,
                          right: level == 3 ? 0 : 6,
                        ),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Level $level',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          showCheckmark: false,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          onSelected: (selected) {
                            setSheetState(() => _selectedImportance = level);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _addNewTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Task',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
