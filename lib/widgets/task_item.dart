import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart'; // Sesuaikan dengan path constants milikmu

class TaskItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.title,
    this.isCompleted = false, // Default bernilai false jika tidak diisi
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Jika selesai, buat sedikit transparan atau warna berbeda
          color: isCompleted ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted 
                ? Colors.grey[200]! 
                : AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            if (!isCompleted)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Ikon Status Centang / Bulatan
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : AppColors.primary.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(width: 14),
            
            // Teks Judul Tugas
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w400 : FontWeight.w500,
                  color: isCompleted ? Colors.grey[400] : AppColors.primary,
                  // Berikan efek coret jika tugas sudah selesai
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}