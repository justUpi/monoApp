import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class MonoCard extends StatelessWidget {
  final String text;
  final bool isCompleted;

  const MonoCard({super.key, required this.text, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.grey[100] : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: isCompleted
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: isCompleted ? AppColors.textGrey : AppColors.primary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
