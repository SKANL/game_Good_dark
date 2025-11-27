part of 'surgery_cubit.dart';

enum GameStatus { loading, playing, success, failure }

class SurgeryState extends Equatable {
  const SurgeryState({
    this.nerves = const [],
    this.selectedNerve,
    this.timeRemaining = 60,
    this.isLaserCharged = false,
    this.gameStatus = GameStatus.loading,
    this.endGameMessage = '',
    this.subjectNumber = 1,
    this.subjectLetter = 'A',
  });
  final List<Nerve> nerves;
  final Nerve? selectedNerve;
  final int timeRemaining;
  final bool isLaserCharged;
  final GameStatus gameStatus;
  final String endGameMessage;
  final int subjectNumber;
  final String subjectLetter;

  SurgeryState copyWith({
    List<Nerve>? nerves,
    Nerve? selectedNerve,
    int? timeRemaining,
    bool? isLaserCharged,
    GameStatus? gameStatus,
    String? endGameMessage,
    int? subjectNumber,
    String? subjectLetter,
    bool clearSelectedNerve = false,
  }) {
    return SurgeryState(
      nerves: nerves ?? this.nerves,
      selectedNerve: clearSelectedNerve
          ? null
          : (selectedNerve ?? this.selectedNerve),
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isLaserCharged: isLaserCharged ?? this.isLaserCharged,
      gameStatus: gameStatus ?? this.gameStatus,
      endGameMessage: endGameMessage ?? this.endGameMessage,
      subjectNumber: subjectNumber ?? this.subjectNumber,
      subjectLetter: subjectLetter ?? this.subjectLetter,
    );
  }

  String get currentSubjectLabel => 'SUJETO-$subjectNumber$subjectLetter';

  @override
  List<Object?> get props => [
    nerves,
    selectedNerve,
    timeRemaining,
    isLaserCharged,
    gameStatus,
    endGameMessage,
    subjectNumber,
    subjectLetter,
  ];
}
