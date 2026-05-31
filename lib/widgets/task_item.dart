import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final int importance;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.title,
    required this.isCompleted,
    this.importance = 1,
    required this.onTap,
  });

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.amber[700]!;
      case 3:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(importance);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? Colors.grey[400] : levelColor.withOpacity(0.6),
            size: 22,
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.grey[400] : Colors.black87,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'LVL $importance',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: levelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
