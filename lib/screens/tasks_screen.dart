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
  final List<dynamic> _tasks = []; // Holds the full Supabase map rows
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
        _loadData(); // Syncs the UI state perfectly back up
        _taskController.clear();
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save to Supabase')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.orange,
        ),
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'TASKS',
          style: GoogleFonts.outfit(
            letterSpacing: 4,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.primary) 
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _tasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];    
                            return TaskItem(
                              title: task['title'] ?? 'Untitled Task', 
                              onTap: () {
                                print('Tapped on task ID: ${task['id']}');
                              },
                            )
                            .animate()
                            .fadeIn(delay: (index * 80).ms)
                            .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.assignment_turned_in_outlined,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 20),
        Text(
          'No tasks for today.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      ],
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
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))
                ),
                const SizedBox(height: 25),
                
                TextField(
                  controller: _taskController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Type your focus task...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 20),

                Text("How important is this?", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3].map((level) {
                    return ChoiceChip(
                      label: Text('Level $level'),
                      selected: _selectedImportance == level,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (selected) {
                        setSheetState(() => _selectedImportance = level);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: _addNewTask, 
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Add Task', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}