import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'tutorial_event.dart';
part 'tutorial_state.dart';

class TutorialBloc extends HydratedBloc<TutorialEvent, TutorialState> {
  TutorialBloc() : super(const TutorialState()) {
    on<TutorialStarted>(_onStarted);
    on<TutorialStepCompleted>(_onStepCompleted);
    on<TutorialSkipped>(_onSkipped);
    on<TutorialReset>(_onReset);
  }

  void _onStarted(TutorialStarted event, Emitter<TutorialState> emit) {
    if (state.completed) return;
    emit(state.copyWith(step: TutorialStep.welcome));
  }

  void _onStepCompleted(
    TutorialStepCompleted event,
    Emitter<TutorialState> emit,
  ) {
    switch (state.step) {
      case TutorialStep.none:
      case TutorialStep.welcome:
        emit(state.copyWith(step: TutorialStep.calibrateEco));
        break;
      case TutorialStep.complete:
        break;
      case TutorialStep.calibrateEco:
        emit(state.copyWith(step: TutorialStep.calibrateAttack));
        break;
      case TutorialStep.calibrateAttack:
        emit(state.copyWith(step: TutorialStep.calibrateStealth));
        break;
      case TutorialStep.calibrateStealth:
        emit(state.copyWith(step: TutorialStep.calibrateEnfoque));
        break;
      case TutorialStep.calibrateEnfoque:
        emit(state.copyWith(step: TutorialStep.calibrateJump));
        break;
      case TutorialStep.calibrateJump:
        emit(state.copyWith(step: TutorialStep.complete, completed: true));
        break;
    }
  }

  void _onSkipped(TutorialSkipped event, Emitter<TutorialState> emit) {
    emit(state.copyWith(completed: true, step: TutorialStep.complete));
  }

  void _onReset(TutorialReset event, Emitter<TutorialState> emit) {
    emit(const TutorialState(completed: false, step: TutorialStep.none));
  }

  @override
  void onEvent(TutorialEvent event) {
    super.onEvent(event);
    print('🟣 TutorialBloc: Event received: $event');
  }

  @override
  void onTransition(Transition<TutorialEvent, TutorialState> transition) {
    super.onTransition(transition);
    print(
      '🟣 TutorialBloc: Transition: ${transition.currentState.step} -> ${transition.nextState.step}',
    );
  }

  @override
  void onChange(Change<TutorialState> change) {
    super.onChange(change);
    print(
      '🟣 TutorialBloc: Change: ${change.currentState.step} -> ${change.nextState.step}',
    );
  }

  @override
  TutorialState? fromJson(Map<String, dynamic> json) {
    return TutorialState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(TutorialState state) {
    return state.toJson();
  }
}
