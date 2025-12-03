part of 'tutorial_bloc.dart';

enum TutorialStep {
  none,
  welcome, // "SYSTEM DETECTED. INITIATING CALIBRATION..."
  calibrateEco, // Highlight Eco
  calibrateAttack, // Highlight Ruptura
  calibrateStealth, // Highlight Sigilo
  calibrateEnfoque, // Highlight Enfoque (Y)
  calibrateJump, // Highlight Jump (Secondary)
  complete, // "CALIBRATION COMPLETE. SYSTEMS ONLINE."
}

class TutorialState extends Equatable {
  const TutorialState({
    this.completed = false,
    this.step = TutorialStep.none,
  });

  final bool completed;
  final TutorialStep step;

  TutorialState copyWith({
    bool? completed,
    TutorialStep? step,
  }) {
    return TutorialState(
      completed: completed ?? this.completed,
      step: step ?? this.step,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'step': step.index,
    };
  }

  factory TutorialState.fromJson(Map<String, dynamic> json) {
    return TutorialState(
      completed: json['completed'] as bool? ?? false,
      step: TutorialStep.values[json['step'] as int? ?? 0],
    );
  }

  @override
  List<Object> get props => [completed, step];
}
