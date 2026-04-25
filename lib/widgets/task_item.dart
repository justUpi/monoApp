import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const TaskItem({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.circle_outlined, color: Colors.grey),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w400),
        ),
        onTap: onTap,
      ),
    );
  }
}