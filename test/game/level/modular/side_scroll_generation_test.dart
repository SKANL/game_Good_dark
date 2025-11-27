import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/modular/modular_level_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModularLevelBuilder Side-Scroll Generation', () {
    late ModularLevelBuilder builder;

    setUp(() {
      builder = ModularLevelBuilder();
    });

    test(
      'should force at least one Side-Scroll chunk in a level of length 5',
      () async {
        final level = await builder.buildLevel(
          length: 5,
          dificultad: Dificultad.media,
          sector: Sector.laboratorios,
        );

        // Check if any of the placed chunks (from their IDs) correspond to a side-scroll chunk
        // Since we don't have direct access to the blueprint tags in the final LevelMapData easily
        // without parsing IDs or adding metadata to ChunkInstance, we'll check the IDs.
        // Side-scroll chunks in library are 'side_scroll_gap' and 'side_scroll_tunnel'.

        var hasSideScroll = false;
        for (final chunk in level.chunks) {
          if (chunk.id.contains('side_scroll')) {
            hasSideScroll = true;
            break;
          }
        }

        expect(
          hasSideScroll,
          isTrue,
          reason: 'Level should contain at least one Side-Scroll chunk',
        );
      },
    );
  });
}
