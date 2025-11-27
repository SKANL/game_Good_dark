import 'package:echo_world/minigames/surgery/entities/nerve_model.dart';

class MockGeminiService {
  Future<List<Nerve>> fetchNerveData() async {
    // Return static fallback data directly
    return [
      Nerve(
        id: 'mem-01',
        name: 'Chrono-synaptic Conduit',
        description:
            'Regulates temporal perception. Severing could cause time dilation '
            'madness.',
        isVital: true,
      ),
      Nerve(
        id: 'sub-02',
        name: 'Sub-harmonic Resonator',
        description: 'Processes low-frequency data streams. Redundant system.',
        isVital: false,
      ),
      Nerve(
        id: 'eth-03',
        name: 'Ether-link Modulator',
        description:
            'Direct link to the global data-net. Critical for consciousness.',
        isVital: true,
      ),
      Nerve(
        id: 'dmp-04',
        name: 'Dopamine Damper',
        description:
            'Regulates emotional response to stimuli. Cutting may cause apathy.',
        isVital: false,
      ),
      Nerve(
        id: 'log-05',
        name: 'Logic Core Processor',
        description:
            'Handles primary logical functions and reasoning. Essential for '
            'survival.',
        isVital: true,
      ),
      Nerve(
        id: 'aux-06',
        name: 'Auxiliary Sensory Input',
        description:
            'Processes non-standard sensory data (e.g., radiation levels). Can '
            'be safely bypassed.',
        isVital: false,
      ),
      Nerve(
        id: 'blt-07',
        name: 'Blacklight Filter',
        description:
            'Filters harmful data packets from black market sources. Obsolete '
            'protocol.',
        isVital: false,
      ),
    ];
  }
}
