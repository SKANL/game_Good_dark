import 'package:echo_world/lore/lore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pantalla de diario que muestra todos los Ecos Narrativos
/// desbloqueados por el jugador.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const JournalScreen());
  }

  @override
  Widget build(BuildContext context) {
    // Lista de todos los ecos en orden
    const allEcoIds = [
      'ecoNarrativo_001',
      'ecoNarrativo_002',
      'ecoNarrativo_003',
      'ecoNarrativo_004',
      'ecoNarrativo_005',
      'ecoNarrativo_006',
      'ecoNarrativo_007',
      'ecoNarrativo_008',
      'ecoNarrativo_009',
      'ecoNarrativo_010',
      'ecoNarrativo_011',
      'ecoNarrativo_012',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Narrative Echoes',
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FFFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<LoreBloc, LoreState>(
        builder: (context, state) {
          if (state.ecosDesbloqueados.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'You have not discovered any echoes yet. Use [ECO] to reveal them in the darkness.',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allEcoIds.length,
            itemBuilder: (context, index) {
              final ecoId = allEcoIds[index];
              final isUnlocked = state.ecosDesbloqueados.contains(ecoId);

              return _EcoCard(
                ecoId: ecoId,
                isUnlocked: isUnlocked,
              );
            },
          );
        },
      ),
    );
  }
}

/// Card individual para mostrar un Eco Narrativo
class _EcoCard extends StatelessWidget {
  const _EcoCard({
    required this.ecoId,
    required this.isUnlocked,
  });

  final String ecoId;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isUnlocked ? const Color(0xFF1A1A1A) : const Color(0xFF0A0A0A),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUnlocked ? const Color(0xFF00FFFF) : const Color(0xFF333333),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.visibility : Icons.visibility_off,
                  color: isUnlocked
                      ? const Color(0xFF00FFFF)
                      : const Color(0xFF666666),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUnlocked ? _getEcoTitle(ecoId) : '???',
                    style: TextStyle(
                      color: isUnlocked
                          ? const Color(0xFF00FFFF)
                          : const Color(0xFF666666),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              isUnlocked
                  ? _getEcoDescription(ecoId)
                  : 'This echo remains hidden in the depths of the facility.',
              style: TextStyle(
                color: isUnlocked
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF555555),
                fontSize: 14,
                fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
              ),
            ),

            // Badge de Mental Noise si está desbloqueado
            if (isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                    color: const Color(0xFF8A2BE2).withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF8A2BE2),
                  ),
                ),
                child: const Text(
                  '+ Mental Noise',
                  style: TextStyle(
                    color: Color(0xFF8A2BE2),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Obtiene el título del eco
  String _getEcoTitle(String ecoId) {
    switch (ecoId) {
      case 'ecoNarrativo_001':
        return 'Subject 7: Awakening';
      case 'ecoNarrativo_002':
        return 'The Sonic Infiltrator';
      case 'ecoNarrativo_003':
        return 'The Resonances: Failed Subjects';
      case 'ecoNarrativo_004':
        return 'Energetic Cannibalism';
      case 'ecoNarrativo_005':
        return "Dr. Mirren's Log: Day 1";
      case 'ecoNarrativo_006':
        return 'The Incident';
      case 'ecoNarrativo_007':
        return 'The Hunt for Silence';
      case 'ecoNarrativo_008':
        return 'Mental Noise: The Price';
      case 'ecoNarrativo_009':
        return 'Sector 1: Containment';
      case 'ecoNarrativo_010':
        return 'Sector 2: Laboratories';
      case 'ecoNarrativo_011':
        return 'Sector 3: Exit';
      case 'ecoNarrativo_012':
        return "Dr. Mirren's Log: Final Entry";
      default:
        return 'Unknown Echo';
    }
  }

  /// Obtiene la descripción del eco
  String _getEcoDescription(String ecoId) {
    switch (ecoId) {
      case 'ecoNarrativo_001':
        return 'You wake in your shattered containment cell. The silence is deafening, broken only by distant groans. Project Cassandra has failed. You are the only success... and your prison has become your tomb.';
      case 'ecoNarrativo_002':
        return 'Project Cassandra aimed to create the ultimate infiltration agent: blind, invisible to thermal sensors, capable of navigating in total darkness. The Rupture Scream was meant to be a demolition tool. Instead, it became your only weapon.';
      case 'ecoNarrativo_003':
        return 'Your "brothers" could not contain the power. Their minds flooded with unbearable noise, an eternal sonic agony. They hunt any external sound to silence their own torment. They are not evil. They are suffering.';
      case 'ecoNarrativo_004':
        return 'The Resonant Nuclei pulse with pure sonic energy. To survive, you must absorb them. But each absorption carries a fragment of their madness, their memories, their noise. How much can you take before you become one of them?';
      case 'ecoNarrativo_005':
        return '"Subject 7 shows remarkable adaptation. Unlike previous subjects, their brain has successfully rerouted visual cortex pathways to auditory processing. The Imbuing process may finally work. Aethel will be pleased."';
      case 'ecoNarrativo_006':
        return 'Emergency logs indicate a containment failure in Sector 2. Subject 13, classified as "Alpha Resonance", unleashed an uncontrolled Rupture Scream. The facility collapsed within 3 minutes. Casualty count: unknown. Survivors: unknown.';
      case 'ecoNarrativo_007':
        return 'The Resonances do not hunt from malice. Every footstep, every echo, every breath is a needle piercing their already tortured minds. They seek silence with the desperation of the damned. You are just another source of noise to be eliminated.';
      case 'ecoNarrativo_008':
        return 'Each nucleus you absorb increases your "Mental Noise". The whispers grow louder. False echoes appear. At 100, your mind will collapse. You will become what you hunt. Escape before the noise consumes you.';
      case 'ecoNarrativo_009':
        return 'This sector housed the subject cells. Reinforced walls, soundproof chambers, biometric locks. All useless now. The "Hunters" patrol these corridors, drawn to the familiar spaces of their former captivity.';
      case 'ecoNarrativo_010':
        return 'The heart of Project Cassandra. Here, the Imbuing took place. Equipment still hums with residual power. "Sentries" remain, their static alarm ready to summon the horde. Stealth is no longer optional.';
      case 'ecoNarrativo_011':
        return 'Collapsed access tunnels lead to the surface. "Brutes", the Alpha Resonances, guard this path. They can demolish walls, require multiple Rupture Screams to defeat, and their footsteps alone betray your position. This is the final gauntlet.';
      case 'ecoNarrativo_012':
        return '"Subject 7 is stable. They are the key. But I fear we\'ve created something beyond our control. If Subject 13 breaks containment... God forgive us. I\'m evacuating. If anyone finds this: Subject 7 can survive. Let them escape. End this project."';
      default:
        return 'This echo has been lost to the void.';
    }
  }
}
