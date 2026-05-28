import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(home: GamePage()));
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = SoulKnightGame();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
          game.onKeyEvent(event, keysPressed);
        },
        child: GameWidget(game: game),
      ),
    );
  }
}