import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/constants.dart';
import '../widgets/task_item.dart';
import '../services/task_services.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true; 
  int _selectedImportance = 1;
  final List<dynamic> _tasks = []; // Kept your critical dynamic list for Supabase rows
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  void _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await _taskService.fetchTasks();
      if (mounted) {
        setState(() {
          _tasks.clear();
          _tasks.addAll(results);
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
        _loadData(); // Syncs UI state back up
        _taskController.clear();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save to Supabase'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } 
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
                      // Sub-Header Elegan khas Desain MONO (Friend's Premium Design)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 20,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TASKS POOL',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                                color: AppColors.textGrey.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              '${_tasks.length} active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGrey.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List View area safely parsing map data to UI components
                      Expanded(
                        child: _tasks.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async => _loadData(),
                                color: AppColors.primary,
                                strokeWidth: 2,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  itemCount: _tasks.length,
                                  itemBuilder: (context, index) {
                                    final task = _tasks[index];    
                                    return TaskItem(
                                      title: task['title'] ?? 'Untitled Task', 
                                      onTap: () {
                                        debugPrint('Tapped on task ID: ${task['id']}');
                                      },
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: (index * 60).ms,
                                      duration: 400.ms,
                                    )
                                    .slideY(
                                      begin: 0.05,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: AppColors.textGrey.withOpacity(0.2),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            'No tasks for today.',
            style: GoogleFonts.inter(
              color: AppColors.textGrey.withOpacity(0.5),
              fontSize: 14,
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
                // Drag handle
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

                // Judul Input
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

                // Pilihan tingkat urgensi (Friend's Premium Layout)
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
                                color: isSelected ? Colors.white : AppColors.textGrey,
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

                // Tombol Submit Premium
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