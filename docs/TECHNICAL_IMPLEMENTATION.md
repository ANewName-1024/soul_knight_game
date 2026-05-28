# Soul Knight Clone — 技术实现方案

## 文档信息

- **项目**：Soul Knight Clone
- **技术栈**：Flutter 3.41.6 + Flame 1.37.0
- **目标平台**：Android
- **最后更新**：2026-05-29

---

## 第一部分：架构概览

### 1.1 分层架构

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                  │
│  ┌─────────────┐ ┌──────────┐ ┌─────────────┐  │
│  │ GamePage   │ │ HUD      │ │ UIOverlays │  │
│  └─────────────┘ └──────────┘ └─────────────┘  │
├─────────────────────────────────────────────────┤
│               Game Engine Layer                 │
│  ┌─────────────────────────────────────┐     │
│  │        SoulKnightGame (FlameGame)      │     │
│  │  ├── update() 循环                  │     │
│  │  ├── 碰撞检测系统               │     │
│  │  └── 相机/视口管理              │     │
│  └─────────────────────────────────────┘     │
├─────────────────────────────────────────────────┤
│              Component Layer                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ Player  │ │ Enemy   │ │ Bullet  │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│  ┌──────────┐ ┌──────────┐                 │
│  │ Weapon  │ │ Room    │                 │
│  └──────────┘ └──────────┘                 │
├─────────────────────────────────────────────────┤
│                Core Layer                    │
│  ┌──────────────┐ ┌──────────────┐         │
│  │GameConstants│ │ Extensions  │         │
│  └──────────────┘ └──────────────┘         │
├─────────────────────────────────────────────────┤
│               Platform Layer                  │
│  ┌─────────────┐ ┌─────────────┐            │
│  │  Input    │ │  Storage   │            │
│  └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────┘
```

### 1.2 核心类图

```
FlameGame<World>
    │
    └── SoulKnightGame (main game controller)
            │
            ├── Player (玩家组件)
            │       └── weapon: Weapon
            │
            ├── Enemy (敌人基类)
            │       ├── BasicEnemy
            │       ├─�� EliteEnemy
            │       └── BossEnemy
            │
            ├── Bullet (子弹基类)
            │       ├── NormalBullet
            │       ├── MissileBullet
            │       └── MagicBullet
            │
            ├── RoomComponent (地牢房间)
            │       └── RoomGenerator
            │
            └── GameHUD (UI层)
```

---

## 第二部分：核心模块实现

### 2.1 游戏主类 (SoulKnightGame)

```dart
// 位置: lib/game/game.dart
class SoulKnightGame extends FlameGame<World>
    with HasKeyboardHandlerComponents, TapCallbacks {
  
  // 游戏配置
  final Vector2 gameSize = Vector2(480, 720);
  
  // 核心组件引用
  late Player player;
  GameHUD? hud;
  RoomManager? roomManager;
  
  // 游戏状态
  GameState state = GameState.menu; // menu/playing/paused/gameover
  
  // 定时器
  double enemySpawnTimer = 0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 1. 初始化视口
    camera.viewport = FixedSizeViewport(480, 720);
    camera.viewfinder.anchor = Anchor.topLeft;
    
    // 2. 添加背景
    add(BackgroundComponent());
    
    // 3. 初始化玩家
    player = Player(position: gameSize / 2);
    add(player);
  }
  
  @override
  void update(double dt) {
    if (state != GameState.playing) return;
    super.update(dt);
    // 游戏循环逻辑
  }
  
  // 键盘事件处理
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    // 处理输入
  }
}
```

### 2.2 游戏状态机

```dart
enum GameState {
  menu,      // 开始菜单
  playing,   // 游戏进行中
  paused,    // 暂停
  gameover,  // 游戏结束
  victory,  // 通关
}
```

---

## 第三部分：输入系统

### 3.1 PC端键盘输入（当前实现）

```dart
// 在 SoulKnightGame.onKeyEvent() 中
@override
KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  if (event is KeyDownEvent) {
    _keysPressed.add(event.logicalKey);
  } else if (event is KeyUpEvent) {
    _keysPressed.remove(event.logicalKey);
  }
  return super.onKeyEvent(event, keysPressed); // 传播给组件
}

// 在 update() 中移动玩家
void _handleMovement(double dt) {
  double dx = 0, dy = 0;
  if (keysPressed.contains(LogicalKeyboardKey.keyW)) dy -= 1;
  if (keysPressed.contains(LogicalKeyboardKey.keyS)) dy += 1;
  if (keysPressed.contains(LogicalKeyboardKey.keyA)) dx -= 1;
  if (keysPressed.contains(LogicalKeyboardKey.keyD)) dx += 1;
  
  if (dx != 0 || dy != 0) {
    final dir = Vector2(dx, dy)..normalize();
    player.move(dir * playerSpeed * dt);
  }
}
```

### 3.2 移动端虚拟摇杆（待实现）

```dart
class VirtualJoystick extends PositionComponent {
  // 触控区域检测
  // 拖动方向计算
  // 返回移动向量(Vector2)
}

// 使用方式：
// 1. 监听 onPanStart/Update/End
// 2. 计算手指相对起始点的偏移
// 3. 规范化为方向向量
// 4. 传给 Player.move()
```

---

## 第四部分：组件系统

### 4.1 Player组件

```dart
class Player extends PositionComponent with HasGameReference<SoulKnightGame> {
  // 属性
  int hp = 5;
  int maxHp = 5;
  double speed = 200;
  Weapon? weapon;
  
  // 状态
  bool isInvincible = false;
  double invincibilityTimer = 0;
  double fireTimer = 0;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 自动射击最近的敌人
    if (weapon != null && fireTimer <= 0) {
      autoFire();
    }
    fireTimer -= dt;
    invincibilityTimer -= dt;
  }
  
  void autoFire() {
    final target = _findNearestEnemy();
    if (target != null) {
      weapon?.fire(target.position - position);
      fireTimer = weapon.cooldown;
    }
  }
  
  void takeDamage(int damage) {
    if (!isInvincible) {
      hp -= damage;
      // 闪避/无敌帧逻辑
      if (hp <= 0) {
        game.onPlayerDeath();
      }
    }
  }
}
```

### 4.2 Enemy组件

```dart
abstract class Enemy extends PositionComponent with HasGameReference<SoulKnightGame> {
  int hp;
  float speed;
  int attackPower;
  EnemyType type;
  
  // AI状态
  Vector2? targetPos;  // 巡逻点
  bool isAggro = false;  // 是否激活
  
  @override
  void update(double dt) {
    super.update(dt);
    _ai(dt);
  }
  
  void _ai(double dt) {
    if (!isAggro) return;
    final dir = (player.position - position)..normalize();
    position += dir * speed * dt;
  }
}
```

### 4.3 Bullet组件

```dart
class Bullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 velocity;
  int damage = 1;
  int penetrate = 0;  // 穿透数
  BulletType type;
  
  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    
    // 出界移除
    if (!_isInBounds()) {
      destroy();
    }
    
    // 碰撞检测
    _checkCollisions();
  }
}
```

---

## 第五部分：碰撞系统

### 5.1 当前实现（AABB）

```dart
// 在 Bullet.update() 中
void _checkCollisions() {
  for (final enemy in game.children.query<Enemy>()) {
    if (toRect().overlaps(enemy.toRect())) {
      enemy.takeDamage(damage);
      if (penetrate <= 0) {
        destroy();
      }
    }
  }
}
```

### 5.2 CircleHitbox（Flame内置）

```dart
// 给组件添加圆形碰撞体
@override
Future<void> onLoad() async {
  await super.onLoad();
  add(CircleHitbox(radius: size.x / 2));
}

// 检测方式：
// collisionCallbacks 回调
```

### 5.3 进阶：四叉树优化

```dart
// 当敌人数量 > 50 时，使用四叉树加速碰撞检测
class QuadTree<T> {
  final Rect bounds;
  final int capacity;
  List<T> objects = [];
  // 插入、查询、删除
}
```

---

## 第六部分：地牢生成系统

### 6.1 房间定义

```dart
struct Room {
  String id;
  RoomType type;  // normal/elite/boss/shop/treasure/pass
  List<Wave> waves;
  bool unlocked = false;
  bool cleared = false;
}
```

### 6.2 关卡生成

```dart
class RoomGenerator {
  static List<Room> generateFloor(int floorLevel) {
    final roomCount = 3 + floorLevel;
    final rooms = <Room>[];
    
    // 1. 生成普通房间
    for (var i = 0; i < roomCount - 2; i++) {
      rooms.add(_createNormalRoom(floorLevel));
    }
    
    // 2. 奖励房
    rooms.add(Room(type: RoomType.treasure));
    
    // 3. Boss房
    rooms.add(Room(type: RoomType.boss));
    
    // 4. 连接关系
    _connectRooms(rooms);
    
    return rooms;
  }
}
```

### 6.3 波次系统

```dart
struct Wave {
  List<EnemyType> enemies;
  int count;
  int spawnDelay;  // 每批间隔秒
  float spawnInterval;  // 每只间隔秒
}
```

---

## 第七部分：武器与技能系统

### 7.1 武器基类

```dart
abstract class Weapon {
  String id;
  String name;
  int damage;
  double fireRate;  // 射击间隔（秒）
  int maxAmmo;  // 弹容量，-1为无限
  int currentAmmo;
  BulletType bulletType;
  
  void fire(Vector2 direction, Vector2 origin) {
    final bullet = Bullet(origin: origin, direction: direction)
      ..damage = damage;
    game.add(bullet);
  }
}
```

### 7.2 武器子类

```dart
class Pistol extends Weapon {
  // 单发，简单直射
}

class Shotgun extends Weapon {
  // 扇形发射
  @override
  void fire(Vector2 dir, Vector2 origin) {
    for (var i = -2; i <= 2; i++) {
      final angle = dir.angle + i * 0.15;
      final bulletDir = Vector2(cos(angle), sin(angle));
      game.add(Bullet(origin: origin, direction: bulletDir));
    }
  }
}

class Laser extends Weapon {
  // 瞬发激光束
}

class MagicMissile extends Weapon {
  // 追踪导弹
}
```

### 7.3 技能系统

```dart
enum SkillType {
  shield,    // 护盾
  missile,   // 导弹
  heal,      // 治疗
  dash,      // 冲刺
}

class Skill {
  final SkillType type;
  final int cooldown;
  int currentCooldown = 0;
  
  void activate(Player player) {
    // 技能逻辑
  }
}
```

---

## 第八部分：保存系统

### 8.1 SharedPreferences存储

```dart
class GameStorage {
  static const _KEY_HIGH_SCORE = 'high_score';
  static const _KEY_COINS = 'total_coins';
  static const _KEY_UNLOCKED_CHARS = 'unlocked_chars';  // JSON数组
  static const _KEY_WEAPONS = 'unlocked_weapons';
  static const _KEY_UPGRADES = 'upgrades';  // JSON对象
  
  // 保存游戏进度
  Future<void> saveProgress(GameProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_KEY_HIGH_SCORE, progress.highScore);
    await prefs.setInt(_KEY_COINS, progress.totalCoins);
    await prefs.setString(_KEY_UPGRADES, jsonEncode(progress.upgrades));
  }
  
  // 读取
  Future<GameProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return GameProgress(
      highScore: prefs.getInt(_KEY_HIGH_SCORE) ?? 0,
      totalCoins: prefs.getInt(_KEY_COINS) ?? 0,
    );
  }
}
```

---

## 第九部分：UI系统

### 9.1 HUD层（FlameOverlay）

```dart
class GameHUD extends PositionComponent {
  // 使用 Flame 的 Layer 系统
  // 或者在 main.dart 返回 Stack([
  //   GameWidget(game: game),
  //   Positioned(child: HUD())
  // ])
}
```

### 9.2 虚拟摇杆挂件

```dart
class JoystickOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20, bottom: 20,
      child: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black26,
          ),
          child: Center(
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 第十部分：性能优化

### 10.1 对象池

```dart
class BulletPool {
  static final pool = [];
  
  static Bullet acquire() {
    if (pool.isNotEmpty) return pool.removeLast();
    return Bullet();
  }
  
  static void release(Bullet bullet) {
    pool.add(bullet);
  }
}
```

### 10.2 可见性剔除

```dart
// 只渲染屏幕内的对象
@override
void render(Canvas canvas) {
  if (!camera.worldToScreen(position).isVisible()) {
    return;
  }
  super.render(canvas);
}
```

### 10.3 批量渲染

```dart
// 使用 batchDraw 批量绘制同类Sprite
// Flame 自带的优化
```

---

## 第十一部分：常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 黑屏 | 没有可视化组件 | 添加 RectangleComponent |
| 卡顿 | 对象太多 | 可见性剔除+对象池 |
| 闪退 | 内存泄漏 | dispose()中释放资源 |
| 按键无响应 | focusNode未requestFocus | KeyboardListener设置autofocus:true |
| 构建失败 | Gradle跨盘符 | 创建junction绕过 |

---

## 第十二部分：后续开发计划

### Phase 2: UI系统
- [ ] 虚拟摇杆Overlay
- [ ] 血条UI
- [ ] 技能冷却UI

### Phase 3: 武器扩展
- [ ] Weapon基类与子类
- [ ] 霰弹/激光/魔法实现
- [ ] 词缀系统

### Phase 4: 地牢
- [ ] Room类
- [ ] 生成算法
- [ ] 门与传送

### Phase 5: Enemy AI
- [ ] Elite变体
- [ ] Boss阶段

### Phase 6: 特效
- [ ] 粒子系统
- [ ] 音效

### Phase 7: 存档
- [ ] SharedPreferences封装
- [ ] 云存档（可选）

---

*技术实现方案会随开发迭代持续更新。*