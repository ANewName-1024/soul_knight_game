import 'package:flutter/material.dart';

/// 开始界面 - 简化版，无动画，纯调试
class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
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
              // Debug: simple ElevatedButton first
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  '开始游戏',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'WASD 移动 | X 切换武器 | Q/W/E/R 技能',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
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
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withAlpha(80), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('暂停', style: TextStyle(
              color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 24),
            _MenuButton(label: '继续', onTap: onResume),
            const SizedBox(height: 12),
            _MenuButton(label: '重新开始', onTap: onRestart),
            const SizedBox(height: 12),
            _MenuButton(label: '退出', onTap: onQuit),
          ]),
        ),
      ),
    );
  }
}

/// 游戏结束
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
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withAlpha(80), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('游戏结束', style: TextStyle(
              color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            _StatRow(label: '击杀', value: killCount.toString()),
            const SizedBox(height: 8),
            _StatRow(label: '波次', value: waveReached.toString()),
            const SizedBox(height: 24),
            _MenuButton(label: '再来一局', onTap: onRestart),
            const SizedBox(height: 12),
            _MenuButton(label: '退出', onTap: onQuit),
          ]),
        ),
      ),
    );
  }
}

/// 通关
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
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withAlpha(80), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('通关！', style: TextStyle(
              color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            _StatRow(label: '击杀', value: killCount.toString()),
            const SizedBox(height: 8),
            _StatRow(label: '波次', value: waveReached.toString()),
            const SizedBox(height: 24),
            _MenuButton(label: '下一关', onTap: onNextLevel),
            const SizedBox(height: 12),
            _MenuButton(label: '退出', onTap: onQuit),
          ]),
        ),
      ),
    );
  }
}

/// 关卡切换
class LevelTransition extends StatefulWidget {
  final int level;
  final VoidCallback onComplete;

  const LevelTransition({
    super.key,
    required this.level,
    required this.onComplete,
  });

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
      color: Colors.black,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('第 ${widget.level} 关', style: const TextStyle(
            color: Color(0xFFFFD700), fontSize: 36, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),
          const Text('即将开始...', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ]),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withAlpha(120), width: 1),
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(
          color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold,
        )),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }
}