import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 虚拟摇杆组件
/// 用于移动端触摸控制
class VirtualJoystick extends PositionComponent {
  /// 摇杆中心位置
  Vector2 center = Vector2.zero();
  
  /// 当前触摸位置
  Vector2? touchPosition;
  
  /// 有效半径（超过此半径截断到圆周）
  final double maxRadius = 50.0;
  
  /// 摇杆底座半径
  final double baseRadius = 60.0;
  
  /// 摇杆轴半径
  final double knobRadius = 30.0;
  
  /// 是否激活
  bool isActive = false;
  
  /// 当前输出的方向向量（归一化）
  Vector2 direction = Vector2.zero();
  
  /// 是否启用（PC模式可禁用）
  bool enabled = true;
  
  /// 是否在左侧区域（用于区分左右手柄）
  final bool isLeftSide;
  
  /// 是否处于长按状态（用于连射）
  bool isLongPress = false;
  
  /// 长按连射计时器
  double longPressTimer = 0;
  
  /// 需要的连续射击间隔（秒）
  final double autoFireInterval = 0.15;
  
  VirtualJoystick({
    this.isLeftSide = true,
    Vector2? position,
  }) : super(
    position: position ?? Vector2.zero(),
    size: Vector2(120, 120),
    anchor: Anchor.center,
  );

  @override
  void onMount() {
    super.onMount();
    center = position;
  }

  @override
  void render(Canvas canvas) {
    if (!enabled) return;
    
    // 绘制底座（半透明圆环）
    canvas.drawCircle(
      Offset(center.x, center.y),
      baseRadius,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    // 绘制底座内圈
    canvas.drawCircle(
      Offset(center.x, center.y),
      baseRadius - 5,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.fill,
    );
    
    // 绘制摇杆轴（如果激活）
    if (isActive && direction.length > 0) {
      final knobPos = center + direction * maxRadius;
      canvas.drawCircle(
        Offset(knobPos.x, knobPos.y),
        knobRadius,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );
      
      // 方向指示线
      canvas.drawLine(
        Offset(center.x, center.y),
        Offset(knobPos.x, knobPos.y),
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 2,
      );
    } else {
      // 未激活时显示中心点
      canvas.drawCircle(
        Offset(center.x, center.y),
        8,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  /// 处理触摸开始
  void onPanStart(TouchPoint point) {
    if (!enabled) return;
    isActive = true;
    touchPosition = point.localPosition;
    _updateDirection();
  }

  /// 处理触摸移动
  void onPanUpdate(TouchPoint point) {
    if (!enabled || !isActive) return;
    touchPosition = point.localPosition;
    _updateDirection();
  }

  /// 处理触摸结束
  void onPanEnd() {
    isActive = false;
    isLongPress = false;
    touchPosition = null;
    direction = Vector2.zero();
  }

  /// 更新方向向量
  void _updateDirection() {
    if (touchPosition == null) return;
    
    final delta = touchPosition! - center;
    final distance = delta.length;
    
    if (distance < 10) {
      // 太小认为是点击而非拖动，清除方向
      direction = Vector2.zero();
      return;
    }
    
    // 归一化到最大半径
    if (distance > maxRadius) {
      direction = delta..normalize();
    } else {
      direction = delta / distance;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 处理长按连射
    if (isActive && isLongPress && direction.length > 0.5) {
      longPressTimer -= dt;
    }
  }
  
  /// 触发长按模式
  void startLongPress() {
    isLongPress = true;
    longPressTimer = autoFireInterval;
  }
  
  /// 是否应该触发自动射击
  bool shouldAutoFire() {
    return isLongPress && longPressTimer <= 0;
  }
}

/// 触摸屏事件的简单封装
class TouchPoint {
  final Vector2 localPosition;
  final int pointerId;
  
  TouchPoint({
    required this.localPosition,
    this.pointerId = 0,
  });
}