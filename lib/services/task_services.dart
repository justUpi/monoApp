import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  // Access the Supabase client initialized in main.dart
  final _supabase = Supabase.instance.client;

  Future<bool> saveTask({
    required String title,
    required int importance,
    String? userId, // Made optional since you are testing without RLS
  }) async {
    try {
      // If you don't have a login system yet, userId can be null
      // Ensure your Supabase table column 'user_id' allows NULL values
      await _supabase.from('tasks').insert({
        'title': title,
        'importance_level': importance,
        'user_id': userId, // Can be null for now
        'is_completed': false,
      });

      return true;
    } catch (e) {
      // This will now print actual Supabase/PostgreSQL errors in your console
      print("Supabase Save Error: $e");
      return false;
    }
  }

  Future<List<String>> fetchTasks() async {
    try {
      final List<dynamic> response = await _supabase
          .from('tasks')
          .select('title');
      return response.map((task) => task['title'] as String).toList();
    } catch (e) {
      // Re-throw so the UI can catch it
      throw Exception("Check your internet connection.");
    }
  }
}
