import 'package:echo_world/common/widgets/glitch_overlay.dart';
import 'package:echo_world/minigames/surgery/cubit/surgery_cubit.dart';
import 'package:echo_world/minigames/surgery/view/intro_page.dart';
import 'package:echo_world/minigames/surgery/view/surgery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SurgeryGame extends StatelessWidget {
  const SurgeryGame({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SurgeryCubit(),
      child: Theme(
        data: _buildDarkTheme(),
        child: GlitchOverlay(
          child: Navigator(
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/':
                  page = const IntroPage();
                case '/surgery':
                  page = const SurgeryPage();
                default:
                  page = const IntroPage();
              }
              return MaterialPageRoute(builder: (_) => page);
            },
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF008080); // Teal (Medical)
    const accentColor = Color(0xFF8B0000); // Deep Red (Blood/Danger)
    const backgroundColor = Color(0xFF050A10); // Very dark blue/black

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: accentColor,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),

        bodyLarge: GoogleFonts.robotoMono(color: Colors.grey[300]),
        bodyMedium: GoogleFonts.robotoMono(color: Colors.grey[300]),
        labelLarge: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}
