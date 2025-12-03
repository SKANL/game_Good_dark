import 'package:echo_world/multiplayer/repository/multiplayer_repository.dart';
import 'package:echo_world/multiplayer/ui/multiplayer_menu.dart';
import 'package:echo_world/utils/unawaited.dart';
import 'package:flutter/material.dart';

class MultiplayerLoginPage extends StatefulWidget {
  const MultiplayerLoginPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const MultiplayerLoginPage());
  }

  @override
  State<MultiplayerLoginPage> createState() => _MultiplayerLoginPageState();
}

class _MultiplayerLoginPageState extends State<MultiplayerLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repository = MultiplayerRepository();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email and Password are required");
      return;
    }

    if (_isRegistering && username.isEmpty) {
      _showError("Username is required for registration");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegistering) {
        await _repository.signUp(
          email: email,
          password: password,
          username: username,
        );
        _showError(
          "Account created! Please check your email if confirmation is required, or Login.",
        );
        setState(() => _isRegistering = false);
      } else {
        await _repository.signIn(
          email: email,
          password: password,
        );
        if (mounted) {
          unawaited(Navigator.of(context).pushReplacement(MultiplayerMenu.route()));
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.all(30),
            constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withAlpha((0.8 * 255).round()),
              boxShadow: const [
                BoxShadow(color: Colors.cyan, blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isRegistering ? "NEW OPERATIVE" : "IDENTITY PROTOCOL",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'Courier',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                  ),
                  decoration: const InputDecoration(
                    labelText: "EMAIL",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                  ),
                  decoration: const InputDecoration(
                    labelText: "PASSWORD",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                if (_isRegistering) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      labelText: "OPERATIVE ID",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.cyanAccent)
                else
                  Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isRegistering ? "REGISTER" : "ESTABLISH UPLINK",
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isRegistering = !_isRegistering),
                        child: Text(
                          _isRegistering
                              ? "ALREADY HAVE AN ID? LOGIN"
                              : "NEED ACCESS? REGISTER",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
