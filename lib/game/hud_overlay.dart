import 'package:flutter/material.dart';
import '../core/constants/game_constants.dart';
import 'game.dart';

/// HUD覆盖层
/// 位于游戏画布之上，显示血量/武器/技能冷却等信息
class HUDOverlay extends StatelessWidget {
  final SoulKnightGame game;
  const HUDOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(game: game),
          const Spacer(),
          _BottomBar(game: game),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final SoulKnightGame game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(game.player.hp, (i) => const Padding(
          padding: EdgeInsets.only(right: 3),
          child: Icon(Icons.favorite, color: Colors.red, size: 24),
        )),
        ...List.generate(GameConstants.playerMaxHp - game.player.hp, (i) => const Padding(
          padding: EdgeInsets.only(right: 3),
          child: Icon(Icons.favorite_border, color: Colors.grey, size: 24),
        )),
        const Spacer(),
        _WeaponBadge(game: game),
        const SizedBox(width: 10),
        Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text('${game.killCount}', style: const TextStyle(
              color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ],
    );
  }
}

class _WeaponBadge extends StatelessWidget {
  final SoulKnightGame game;
  const _WeaponBadge({required this.game});

  @override
  Widget build(BuildContext context) {
    final w = game.player.weapon;
    final color = w != null ? Color(w.colorValue) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(180), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 6),
          Text(game.weaponName, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final SoulKnightGame game;
  const _BottomBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final labels = ['Q', 'W', 'E', 'R'];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        if (i >= game.skills.length) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _SkillIcon(label: labels[i], color: colors[i], skill: game.skills[i]),
        );
      }),
    );
  }
}

class _SkillIcon extends StatelessWidget {
  final String label;
  final Color color;
  final Skill skill;

  const _SkillIcon({required this.label, required this.color, required this.skill});

  @override
  Widget build(BuildContext context) {
    final canUse = skill.canUse();
    final cdRatio = skill.cooldown > 0
        ? (skill.cooldownRemaining / skill.cooldown).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 44, height: 44,
      child: Stack(alignment: Alignment.center, children: [
        if (!canUse)
          ClipOval(child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: cdRatio,
            child: Container(width: 44, height: 44, color: Colors.black.withAlpha(180)),
          )),
        if (canUse)
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
          ),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: canUse ? color.withAlpha(220) : Colors.grey.withAlpha(160),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white70, width: 1.5),
          ),
          child: Center(child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
          ))),
        ),
        if (!canUse)
          Positioned(
            bottom: 2,
            child: Text(
              skill.cooldownRemaining.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
          ),
      ]),
    );
  }
}

class HUDFresher extends ChangeNotifier {
  static final instance = HUDFresher._();
  HUDFresher._();
  int _frame = 0;
  int get frame => _frame;
  void refresh() { _frame++; notifyListeners(); }
  void tick() { Future.delayed(const Duration(milliseconds: 100), refresh); }
}