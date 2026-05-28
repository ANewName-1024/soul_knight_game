import 'package:flutter/material.dart';

/// 开始界面
class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '元气骑士',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SOUL KNIGHT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: onStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: const Text(
                  '开始游戏',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'WASD / 方向键 移动\nX 切换武器 | Q/W/E/R 技能\n移动端：左侧移动 右侧射击',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 暂停菜单
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '暂停',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _MenuButton(label: '继续', color: const Color(0xFF4CAF50), onTap: onResume),
            const SizedBox(height: 16),
            _MenuButton(label: '重新开始', color: const Color(0xFF2196F3), onTap: onRestart),
            const SizedBox(height: 16),
            _MenuButton(label: '退出游戏', color: const Color(0xFFE53935), onTap: onQuit),
          ],
        ),
      ),
    );
  }
}

/// 游戏结束画面
class GameOverOverlay extends StatelessWidget {
  final int killCount;
  final int waveReached;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const GameOverOverlay({
    super.key,
    required this.killCount,
    required this.waveReached,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '游戏结束',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _StatRow(label: '击杀', value: '$killCount'),
            const SizedBox(height: 12),
            _StatRow(label: '波次', value: '$waveReached'),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('再来一局', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onQuit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('退出', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 通关画面
class VictoryOverlay extends StatelessWidget {
  final int killCount;
  final int waveReached;
  final VoidCallback onNextLevel;
  final VoidCallback onQuit;

  const VictoryOverlay({
    super.key,
    required this.killCount,
    required this.waveReached,
    required this.onNextLevel,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '通关！',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '第 $waveReached 波',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 30),
            _StatRow(label: '击杀', value: '$killCount'),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onNextLevel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('下一关', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onQuit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('退出', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 关卡切换提示
class LevelTransition extends StatefulWidget {
  final int level;
  final VoidCallback onComplete;

  const LevelTransition({super.key, required this.level, required this.onComplete});

  @override
  State<LevelTransition> createState() => _LevelTransitionState();
}

class _LevelTransitionState extends State<LevelTransition> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第 ${widget.level} 波',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '波次来袭！',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// 菜单按钮
class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// 统计行
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 18)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}