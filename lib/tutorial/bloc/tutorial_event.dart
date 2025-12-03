part of 'tutorial_bloc.dart';

abstract class TutorialEvent extends Equatable {
  const TutorialEvent();

  @override
  List<Object> get props => [];
}

class TutorialStarted extends TutorialEvent {}

class TutorialStepCompleted extends TutorialEvent {}

class TutorialSkipped extends TutorialEvent {}

class TutorialReset extends TutorialEvent {} // For debugging
