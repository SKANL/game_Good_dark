import 'package:echo_world/multiplayer/repository/multiplayer_repository.dart';
import 'package:echo_world/multiplayer/ui/multiplayer_menu.dart';
import 'package:echo_world/utils/unawaited.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MultiplayerLoginPage extends StatefulWidget {
  const MultiplayerLoginPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const MultiplayerLoginPage(),
    );
  }

  @override
  State<MultiplayerLoginPage> createState() => _MultiplayerLoginPageState();
}

class _MultiplayerLoginPageState extends State<MultiplayerLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repo = MultiplayerRepository();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Missing credentials');
      return;
    }
    if (!_isLogin && username.isEmpty) {
      _showError('Username required for registration');
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthResponse response;
      if (_isLogin) {
        response = await _repo.signIn(email: email, password: password);
      } else {
        response = await _repo.signUp(
          email: email,
          password: password,
          username: username,
        );
      }

      if (response.user != null) {
        if (mounted) {
          unawaited(
            Navigator.of(context).pushReplacement(MultiplayerMenu.route()),
          );
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Courier',
            color: Colors.redAccent,
          ),
        ),
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLogin ? 'SYSTEM LOGIN' : 'NEW OPERATIVE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  _buildTextField(
                    controller: _usernameController,
                    label: 'CODENAME',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _emailController,
                  label: 'EMAIL FREQUENCY',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'SECURITY KEY',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: const BeveledRectangleBorder(),
                    ),
                    child: Text(
                      _isLogin ? 'AUTHENTICATE' : 'INITIALIZE',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? '[ CREATE NEW IDENTITY ]'
                        : '[ ACCESS EXISTING NODE ]',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '< ABORT OPERATION',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'Courier'),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
        filled: true,
        fillColor: Colors.black,
      ),
    );
  }
}
