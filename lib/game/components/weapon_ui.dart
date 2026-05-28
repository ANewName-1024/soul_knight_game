import 'package:flutter/material.dart';

/// 武器切换UI按钮
/// 显示在屏幕顶部武器徽章旁边，点击切换主/副武器
class WeaponSwitchButton extends StatelessWidget {
  final VoidCallback onTap;
  final int backupCount; // 备选武器数量

  const WeaponSwitchButton({
    super.key,
    required this.onTap,
    this.backupCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white60, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
            if (backupCount > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$backupCount',
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 武器获取提示（屏幕中央弹出）
class WeaponPickupToast extends StatelessWidget {
  final String weaponName;
  final Color color;

  const WeaponPickupToast({
    super.key,
    required this.weaponName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white70, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(
            '+ $weaponName',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}