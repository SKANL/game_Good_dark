import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';

class SoundBusComponent extends Component {
  final List<EstimuloDeSonido> _stimuli = [];

  void emit(Vector2 pos, NivelSonido nivel, {double ttl = 1.0}) {
    if (nivel == NivelSonido.nulo) return;
    _stimuli.add(
      EstimuloDeSonido(posicion: pos.clone(), nivel: nivel, ttl: ttl),
    );
  }

  @override
  void update(double dt) {
    for (final s in _stimuli) {
      s.ttl -= dt;
    }
    _stimuli.removeWhere((s) => s.ttl <= 0);
    super.update(dt);
  }

  // Devuelve el estímulo más fuerte dentro de un radio dado
  EstimuloDeSonido? queryStrongest(Vector2 origin, double radius) {
    EstimuloDeSonido? best;
    var bestScore = -1;
    for (final s in _stimuli) {
      final d = s.posicion.distanceTo(origin);
      if (d > radius) continue;
      final levelScore = switch (s.nivel) {
        NivelSonido.alto => 3,
        NivelSonido.medio => 2,
        NivelSonido.bajo => 1,
        NivelSonido.nulo => 0,
      };
      final score = levelScore * (1.0 / (1.0 + d));
      if (score > bestScore) {
        best = s;
        bestScore = score.toInt();
      }
    }
    return best;
  }
}
