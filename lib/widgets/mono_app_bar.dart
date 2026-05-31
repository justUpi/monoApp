import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';

class MonoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogoutPressed;

  const MonoAppBar({super.key, this.onLogoutPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'MONO',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
            color: AppColors.textGrey.withOpacity(0.6),
          ),
        ).animate().fadeIn(duration: 600.ms),
      ),
      actions: [
        if (onLogoutPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.redAccent.withOpacity(0.6),
                size: 20,
              ),
              tooltip: 'Keluar',
              onPressed: onLogoutPressed,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
