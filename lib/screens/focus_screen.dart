import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';

import '../core/constants.dart';
import '../widgets/mono_card.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  bool _isDone = false;

  void _handleToggleTask() async {
    setState(() {
      _isDone = !_isDone;
    });

    if (_isDone) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 50);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Text(
                'MONO',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: AppColors.textGrey.withOpacity(0.6),
                ),
              ).animate().fadeIn(duration: 600.ms),

              const Spacer(),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child:
                      MonoCard(
                            text: _isDone
                                ? 'All caught up for now.'
                                : 'Finish the UI layout for Mono',
                            isCompleted: _isDone,
                          )
                          .animate(target: _isDone ? 1 : 0)
                          .shimmer(
                            delay: 2.seconds,
                            duration: 1.5.seconds,
                            color: Colors.white24,
                          )
                          .toggle(
                            builder: (_, value, child) => child
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                          ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                    onTap: _handleToggleTask,
                    child: AnimatedContainer(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: _isDone
                            ? AppColors.accentGreen
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isDone
                                        ? AppColors.accentGreen
                                        : AppColors.primary)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isDone ? Icons.done_all : Icons.check,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  )
                  .animate(target: _isDone ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                  .then()
                  .shake(hz: 3, curve: Curves.easeOut),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {},
                child: Text(
                  'View All Tasks',
                  style: GoogleFonts.inter(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
