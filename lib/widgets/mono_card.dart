import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';

class MonoCard extends StatelessWidget {
  final String text;
  final int level;
  final Color accentColor;
  final IconData levelIcon;
  final bool isCompleted;

  const MonoCard({
    super.key,
    required this.text,
    this.level = 1,
    this.accentColor = Colors.blueAccent,
    this.levelIcon = Icons.eco_rounded,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shadowColor: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withOpacity(0.35), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // Aksen lingkaran background dekoratif khas kartu RPG
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
                    // Bagian Atas Kartu (Rank Badge & Pelindung/Shield)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Icon(levelIcon, size: 14, color: accentColor),
                              const SizedBox(width: 6),
                              Text(
                                'LVL $level QUEST',
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

                    // Konten Judul Tugas Utama di Tengah Kartu
                    Center(
                      child: Text(
                        text,
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

                    // Bagian Bawah Kartu (Status Quest & Petunjuk Gerakan)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                            color: AppColors.textGrey.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted
                                ? 'QUEST SELESAI'
                                : 'GESER KANAN UNTUK MEMULAI',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: AppColors.textGrey.withOpacity(0.6),
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
    );
  }
}
