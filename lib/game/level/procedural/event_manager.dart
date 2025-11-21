import 'dart:math';

/// Dynamic events that can occur during procedural level generation
enum LevelEvent {
  none,
  lockdown, // Doors lock until enemies defeated
  blackout, // Reduced visibility, requires echolocation
}

/// Manages dynamic events for procedural levels
class EventManager {
  final Random _random = Random();

  /// Rolls for a random event based on probability
  LevelEvent rollEvent() {
    final roll = _random.nextDouble();

    // 10% chance of Lockdown
    if (roll < 0.10) {
      return LevelEvent.lockdown;
    }

    // 5% chance of Blackout
    if (roll < 0.15) {
      return LevelEvent.blackout;
    }

    // 85% chance of no event
    return LevelEvent.none;
  }

  /// Gets the difficulty multiplier for an event
  double getDifficultyMultiplier(LevelEvent event) {
    switch (event) {
      case LevelEvent.lockdown:
        return 1.3; // 30% more enemies
      case LevelEvent.blackout:
        return 1.2; // 20% more enemies
      case LevelEvent.none:
        return 1.0;
    }
  }

  /// Gets a user-facing description of the event
  String getDescription(LevelEvent event) {
    switch (event) {
      case LevelEvent.lockdown:
        return 'Lockdown Protocol Active';
      case LevelEvent.blackout:
        return 'Emergency Power Failure';
      case LevelEvent.none:
        return '';
    }
  }
}
