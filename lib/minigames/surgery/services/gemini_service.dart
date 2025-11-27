// // lib/services/gemini_service.dart
// import 'dart:convert';

// import 'package:echo_world/minigames/surgery/entities/nerve_model.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// class GeminiService {
//   // IMPORTANT: Replace with your actual API Key
//   // You can get one from Google AI Studio: https://aistudio.google.com/
//   // For production, use environment variables or a secure key management solution.
//   static const String _apiKey = String.fromEnvironment(
//     'API_KEY',
//     defaultValue: 'YOUR_API_KEY_HERE', // Default value for safety
//   );

//   Future<List<Nerve>> fetchNerveData() async {
//     if (_apiKey == 'YOUR_API_KEY_HERE') {
//       print('API Key not found. Using fallback data.');
//       return _getFallbackData();
//     }

//     try {
//       final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
//       const prompt =
//           'Generate a list of 7 fictional cyberpunk nerves for a brain surgery '
//           'simulation game. '
//           'Provide the data in a valid JSON array format. '
//           "Each object in the array should have the following keys: 'id' (a "
//           "unique string), 'name' (a creative string), 'description' (a short, "
//           "sci-fi string), and 'isVital' (a boolean). "
//           "Include exactly 3 nerves where 'isVital' is true and 4 where it's "
//           'false. '
//           'Do not include any text outside of the JSON array.';

//       final content = [Content.text(prompt)];
//       final response = await model.generateContent(content);

//       if (response.text == null) {
//         print('API response was null. Using fallback data.');
//         return _getFallbackData();
//       }

//       // Clean the response to get only the JSON part
//       final jsonString = response.text!
//           .replaceAll('`', '')
//           .replaceAll('json', '')
//           .trim();

//       final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
//       return jsonList
//           .map((json) => Nerve.fromJson(json as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       print('Failed to fetch data from API: $e');
//       print('Using fallback data.');
//       return _getFallbackData();
//     }
//   }

//   List<Nerve> _getFallbackData() {
//     return [
//       Nerve(
//         id: 'mem-01',
//         name: 'Chrono-synaptic Conduit',
//         description:
//             'Regulates temporal perception. Severing could cause time dilation '
//             'madness.',
//         isVital: true,
//       ),
//       Nerve(
//         id: 'sub-02',
//         name: 'Sub-harmonic Resonator',
//         description: 'Processes low-frequency data streams. Redundant system.',
//         isVital: false,
//       ),
//       Nerve(
//         id: 'eth-03',
//         name: 'Ether-link Modulator',
//         description:
//             'Direct link to the global data-net. Critical for consciousness.',
//         isVital: true,
//       ),
//       Nerve(
//         id: 'dmp-04',
//         name: 'Dopamine Damper',
//         description:
//             'Regulates emotional response to stimuli. Cutting may cause apathy.',
//         isVital: false,
//       ),
//       Nerve(
//         id: 'log-05',
//         name: 'Logic Core Processor',
//         description:
//             'Handles primary logical functions and reasoning. Essential for '
//             'survival.',
//         isVital: true,
//       ),
//       Nerve(
//         id: 'aux-06',
//         name: 'Auxiliary Sensory Input',
//         description:
//             'Processes non-standard sensory data (e.g., radiation levels). Can '
//             'be safely bypassed.',
//         isVital: false,
//       ),
//       Nerve(
//         id: 'blt-07',
//         name: 'Blacklight Filter',
//         description:
//             'Filters harmful data packets from black market sources. Obsolete '
//             'protocol.',
//         isVital: false,
//       ),
//     ];
//   }
// }
