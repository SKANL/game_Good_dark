import 'package:echo_world/l10n/l10n.dart';
import 'package:echo_world/loading/loading.dart';
import 'package:echo_world/title/title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Future<void> onPreloadComplete(NavigatorState navigator) async {
    await Future<void>.delayed(AnimatedProgressBar.intrinsicAnimationDuration);
    if (!mounted) return;
    await navigator.pushReplacement<void, void>(TitlePage.route());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreloadCubit, PreloadState>(
      listenWhen: (prevState, state) =>
          !prevState.isComplete && state.isComplete,
      listener: (context, state) => onPreloadComplete(Navigator.of(context)),
      child: const Scaffold(
        body: _LoadingInternal(),
      ),
    );
  }
}

class _LoadingInternal extends StatelessWidget {
  const _LoadingInternal();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PreloadCubit, PreloadState>(
      builder: (context, state) {
        final loadingLabel = l10n.loadingPhaseLabel(state.currentLabel);
        final loadingMessage = l10n.loading(loadingLabel);
        final progressPercent = (state.progress * 100).toInt();

        return Stack(
          children: [
            // Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/img/Pantalla_de_inicio.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Dark overlay for better text readability
            Container(
              color: Colors.black.withOpacity(0.4),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title Line 1: "PROYECTO CASANDRA"
                  Text(
                    'PROYECTO CASANDRA',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FFFF),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.5),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title Line 2: "// SUJETO 07"
                  Text(
                    '// SUJETO 07',
                    style: GoogleFonts.robotoMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00FFFF),
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.8),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Neon Progress Bar
                  NeonProgressBar(
                    progress: state.progress,
                  ),
                  const SizedBox(height: 20),
                  // Loading status text
                  Text(
                    loadingMessage,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress percentage
                  Text(
                    '[$progressPercent%]',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: const Color(0xFF00FFFF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
