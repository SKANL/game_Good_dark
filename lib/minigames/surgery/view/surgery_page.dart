// lib/view/surgery_screen.dart
import 'dart:math';

import 'package:echo_world/common/services/haptic_service.dart';
import 'package:echo_world/common/widgets/glitch_overlay.dart';
import 'package:echo_world/minigames/surgery/cubit/surgery_cubit.dart';
import 'package:echo_world/minigames/surgery/widgets/glowing_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SurgeryPage extends StatefulWidget {
  const SurgeryPage({super.key});

  @override
  State<SurgeryPage> createState() => _SurgeryPageState();
}

class _SurgeryPageState extends State<SurgeryPage>
    with TickerProviderStateMixin {
  String? _analyzedId;
  bool _showingResultDialog = false;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Flash animation
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0, end: 0.8).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  void _triggerFlash() {
    _flashController.forward(from: 0).then((_) => _flashController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SurgeryCubit, SurgeryState>(
      listener: (context, state) {
        if ((state.gameStatus == GameStatus.success ||
                state.gameStatus == GameStatus.failure) &&
            !_showingResultDialog) {
          _triggerShake();
          HapticService.heavyImpact();
          _showResultAndAdvance(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0a101a),
          // Add a back button to return to main menu
          floatingActionButton: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              // Exit the minigame navigator
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          body: GlitchOverlay(
            intensity: state.gameStatus == GameStatus.failure ? 0.8 : 0.1,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset =
                        sin(_shakeController.value * pi * 10) *
                        _shakeAnimation.value;
                    return Transform.translate(
                      offset: Offset(offset, offset),
                      child: _buildContent(context, state),
                    );
                  },
                ),
                // Flash Overlay
                AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, child) {
                    if (_flashAnimation.value == 0)
                      return const SizedBox.shrink();
                    return Container(
                      color: Colors.white.withValues(
                        alpha: _flashAnimation.value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResultAndAdvance(
    BuildContext context,
    SurgeryState state,
  ) async {
    _showingResultDialog = true;
    final success = state.gameStatus == GameStatus.success;
    final title = success ? 'EXITOSO' : 'FALLO CRÍTICO';
    final color = success ? const Color(0xFF00FFFF) : Colors.red;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0a101a),
          contentPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 32,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: color)],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.endGameMessage,
                style: GoogleFonts.robotoMono(color: Colors.grey[300]),
              ),
              const SizedBox(height: 18),
              GlowingButton(
                text: 'SIGUIENTE SUJETO...',
                onPressed: () => Navigator.of(ctx).pop(),
                color: color,
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    context.read<SurgeryCubit>().nextSubjectAndRestart();
    setState(() {
      _analyzedId = null;
      _showingResultDialog = false;
    });
  }

  Widget _buildContent(BuildContext context, SurgeryState state) {
    if (state.gameStatus == GameStatus.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              onEnd: () => setState(() {}),
              child: const Column(
                children: [
                  Text(
                    'ANALIZANDO VÍAS...',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Calibrando interfaz móvil...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTopBar(state),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildBrainAndNerves(context, state)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildRightPanel(state)),
              ],
            ),
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: _buildBottomControls(context, state),
        ),
      ],
    );
  }

  Widget _buildTopBar(SurgeryState state) {
    final percent = state.timeRemaining / 60.0;
    var barColor = const Color(0xFF00FF88);
    if (state.timeRemaining <= 15) {
      barColor = Colors.red;
    } else if (state.timeRemaining <= 30) {
      barColor = Colors.orange;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF0a101a).withValues(alpha: 0.6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.currentSubjectLabel,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    color: const Color(0xFF00FFFF),
                  ),
                ),
                Text(
                  'ESTABILIDAD',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              backgroundColor: Colors.grey[800],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.timeRemaining}s',
                  style: GoogleFonts.robotoMono(color: Colors.white),
                ),
                Text(
                  'Objetivo: ELIMINAR VISIÓN (OPTIC)',
                  style: GoogleFonts.robotoMono(color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrainAndNerves(BuildContext context, SurgeryState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(
          constraints.maxWidth * 0.85,
          constraints.maxHeight * 1.1,
        );
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;
        final brainWidth = size * 1.05;

        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Center(
              child: Container(
                width: size * 1.15,
                height: size * 1.15,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage(
                      'assets/minigames/surgery/imagenes/Cerebro.png',
                    ),
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
            ..._buildNerveWidgets(context, state, centerX, centerY, brainWidth),
          ],
        );
      },
    );
  }

  List<Widget> _buildNerveWidgets(
    BuildContext context,
    SurgeryState state,
    double centerX,
    double centerY,
    double brainWidth,
  ) {
    final widgets = <Widget>[];
    final nerveCount = state.nerves.length;
    for (var i = 0; i < nerveCount; i++) {
      final nerve = state.nerves[i];
      if (nerve.isCut) continue;

      final isSelected = state.selectedNerve?.id == nerve.id;

      final brainLeft = centerX - brainWidth / 2;
      final brainTop = centerY - brainWidth / 2;
      final internalPosX = nerve.posX.clamp(0.12, 0.88);
      final internalPosY = nerve.posY.clamp(0.12, 0.88);
      var leftPos = brainLeft + (internalPosX * brainWidth);
      var topPos = brainTop + (internalPosY * brainWidth);
      var movedToCenter = false;

      final brainRight = brainLeft + brainWidth;
      final brainBottom = brainTop + brainWidth;
      if (leftPos < brainLeft ||
          leftPos > brainRight ||
          topPos < brainTop ||
          topPos > brainBottom) {
        leftPos = centerX;
        topPos = centerY;
        movedToCenter = true;
      }

      final sizeCircle = movedToCenter ? 48.0 : (isSelected ? 36.0 : 28.0);
      final borderWidth = movedToCenter ? 3.0 : (isSelected ? 2.5 : 2.0);
      final isChargedAndSelected = state.isLaserCharged && isSelected;
      final fillColor = isChargedAndSelected
          ? Colors.red
          : const Color(0xFF00FFFF);
      final shadowColor = isChargedAndSelected
          ? Colors.red.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: isSelected ? 0.25 : 0.12);

      widgets.add(
        Positioned(
          left: leftPos - sizeCircle / 2,
          top: topPos - sizeCircle / 2,
          child: GestureDetector(
            onTap: () {
              context.read<SurgeryCubit>().selectNerve(nerve);
              setState(() {
                _analyzedId = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: sizeCircle,
              height: sizeCircle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor,
                border: Border.all(color: Colors.white, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: isSelected ? 20 : 8,
                    spreadRadius: isSelected ? 6 : 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildRightPanel(SurgeryState state) {
    final nerve = state.selectedNerve;
    final show = nerve != null && _analyzedId == nerve.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.4),
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANALIZADOR:',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00FFFF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                nerve == null
                    ? 'Seleccione un punto en el cerebro para analizar.'
                    : (show
                          ? nerve.description
                          : 'Presione ANALIZAR para ver la descripción.'),
                style: GoogleFonts.robotoMono(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, SurgeryState state) {
    final nerve = state.selectedNerve;
    final cubit = context.read<SurgeryCubit>();

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GlowingButton(
                text: 'ANALIZAR',
                isDisabled: nerve == null,
                onPressed: () {
                  if (nerve != null) {
                    HapticService.selectionClick();
                    setState(() {
                      _analyzedId = nerve.id;
                    });
                  }
                },
              ),
              const SizedBox(width: 10), // Add spacing for FittedBox
              GlowingButton(
                text: 'CARGAR LÁSER',
                isDisabled:
                    !(nerve != null && _analyzedId == nerve.id) ||
                    state.isLaserCharged,
                onPressed: () {
                  HapticService.mediumImpact();
                  cubit.chargeLaser();
                },
              ),
              const SizedBox(width: 10), // Add spacing for FittedBox
              GlowingButton(
                text: 'CORTAR',
                color: Colors.red,
                isDisabled: !state.isLaserCharged,
                onPressed: () {
                  HapticService.heavyImpact();
                  _triggerShake();
                  _triggerFlash();
                  cubit.cutNerve();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '//: Los tendones están ligados a los 5 sentidos. Objetivo: visión.',
          style: GoogleFonts.robotoMono(color: Colors.grey[400]),
        ),
      ],
    );
  }
}
