import 'package:echo_world/multiplayer/repository/multiplayer_repository.dart';
import 'package:echo_world/multiplayer/ui/lobby_page.dart';

import 'dart:math';
import 'package:flutter/material.dart';

class MultiplayerMenu extends StatefulWidget {
  const MultiplayerMenu({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MultiplayerMenu());
  }

  @override
  State<MultiplayerMenu> createState() => _MultiplayerMenuState();
}

class _MultiplayerMenuState extends State<MultiplayerMenu> {
  int? _focusedIndex;

  final List<String> _games = [
    'Duelo de Ecos (1v1)',
    'Carrera Sónica (1v1)',
    'Control de Frecuencia (2v2)',
    'Asalto al Núcleo (3v3)',
  ];

  void _handleTap(int index) {
    _showRoomSelectionDialog(context, _games[index]);
  }

  void _showRoomSelectionDialog(BuildContext context, String gameType) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          "DEPLOYMENT: $gameType",
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontFamily: 'Courier',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context);
                _createRoom(gameType);
              },
              child: const Text(
                "CREATE ROOM",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showJoinRoomDialog(context, gameType);
              },
              child: const Text(
                "JOIN ROOM",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createRoom(String gameType) {
    // Generate 4-char code
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    final roomId = List.generate(
      4,
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    Navigator.of(context).push(LobbyPage.route(gameType, roomId));
  }

  void _showJoinRoomDialog(BuildContext context, String gameType) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "ENTER ROOM CODE",
          style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier'),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontSize: 24,
            letterSpacing: 5,
          ),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: "ABCD",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final roomId = controller.text.trim().toUpperCase();
              if (roomId.length == 4) {
                Navigator.pop(context);
                Navigator.of(context).push(LobbyPage.route(gameType, roomId));
              }
            },
            child: const Text(
              "JOIN",
              style: TextStyle(color: Colors.greenAccent, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showInventory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "INVENTORY",
          style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier'),
        ),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: MultiplayerRepository().getInventory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                "NO ITEMS FOUND",
                style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
              );
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return ListTile(
                    title: Text(
                      (item['object_name'] as String?) ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                      ),
                    ),
                    trailing: Text(
                      "x${item['quantity']}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Courier',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.blueGrey.shade900,
                  Colors.black,
                ],
              ),
            ),
          ),

          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "MULTIPLAYER PROTOCOLS",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontFamily: 'Courier',
                      letterSpacing: 4.0,
                      shadows: [
                        BoxShadow(color: Colors.cyan, blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // User Info
                  FutureBuilder<Map<String, dynamic>?>(
                    future: MultiplayerRepository().getPlayerProfile(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          Text(
                            "OPERATIVE: ${data['username']}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'Courier',
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "COINS: ${data['coins']}",
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontFamily: 'Courier',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () => _showInventory(context),
                            child: const Text(
                              "VIEW INVENTORY",
                              style: TextStyle(fontFamily: 'Courier'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  ...List.generate(_games.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _focusedIndex = index),
                        onExit: (_) => setState(() => _focusedIndex = null),
                        child: GestureDetector(
                          onTap: () => _handleTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _focusedIndex == index
                                    ? Colors.cyanAccent
                                    : Colors.grey.withOpacity(0.5),
                                width: 2,
                              ),
                              color: _focusedIndex == index
                                  ? Colors.cyan.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _games[index],
                              style: TextStyle(
                                color: _focusedIndex == index
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 24,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 50),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "< RETURN TO MAIN SYSTEM",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
