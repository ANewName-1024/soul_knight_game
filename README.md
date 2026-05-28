# Soul Knight Clone — 项目文档

## 1. 项目概述

- **项目名称**：Soul Knight Clone（元气骑士类游戏）
- **类型**：2D 俯视角射击地牢冒险 Roguelike
- **核心玩法**：随机地牢 + 俯视角射击 + 装备收集
- **目标平台**：Android（首发）
- **仓库**：https://github.com/ANewName-1024/soul_knight_game

---

## 2. 技术栈

| 模块 | 技术 | 版本 |
|------|------|------|
| 框架 | Flutter | 3.41.6 |
| 游戏引擎 | Flame | 1.37.0 |
| 语言 | Dart | 3.11.4 |
| 存档 | shared_preferences | 2.2.3 |
| 目标 SDK | Android | 34 |

> ⚠️ **注意**：构建 APK 时项目路径不能包含中文或空格（Windows Gradle bug）。临时解决方案：创建 NTFS junction `mklink /J C:\soul_knight_game D:\workspace\soul_knight_game`，在 C:\soul_knight_game 下执行构建。

---

## 3. 项目结构

```
soul_knight_game/
├── lib/
│   ├── main.dart                           # 入口，GamePage 组件
│   ├── core/constants/
│   │   └── game_constants.dart            # 游戏数值常量（速度/大小/伤害等）
│   └── game/
│       ├── game.dart                       # FlameGame 主类，键盘处理，敌人生成
│       └── components/
│           └── player.dart                # Player / Enemy / Bullet 三个组件
├── assets/
│   ├── images/
│   └── audio/
├── android/
├── pubspec.yaml                            # 依赖配置
└── SPEC.md                                 # 游戏设计文档
```

---

## 4. 核心模块说明

### 4.1 游戏常量 (`game_constants.dart`)

```dart
gameWidth      = 480    // 游戏逻辑宽度（像素）
gameHeight     = 720    // 游戏逻辑高度（像素）
playerSpeed    = 200    // 玩家移动速度（像素/秒）
playerSize     = 32     // 玩家碰撞半径（像素）
playerMaxHp    = 5      // 玩家血量
bulletSpeed    = 400    // 子弹速度（像素/秒）
bulletSize     = 8      // 子弹碰撞半径（像素）
bulletDamage   = 1      // 子弹伤害
fireRate       = 0.3    // 射击间隔（秒）
enemySpeed     = 80     // 敌人移动速度（像素/秒）
enemySize      = 28     // 敌人碰撞半径（像素）
enemySpawnInterval = 2.0 // 敌人生成间隔（秒）
```

### 4.2 游戏主类 (`game.dart`)

`SoulKnightGame extends FlameGame<World>`，包含：

- **生命周期**：`onLoad()` 初始化 camera、背景、Player
- **游戏循环**：`update(dt)` 每帧处理：
  - `_handleMovement(dt)` — 读取 `_keysPressed`，驱动玩家移动
  - `_spawnEnemy()` — 每 `enemySpawnInterval` 秒在屏幕边缘生成一个 Enemy
- **键盘处理**：`onKeyEvent()` 维护 `_keysPressed` Set（WASD + 方向键）
- **射弹**：`addBullet(position, direction)` 由 Player 在 `_shoot()` 时调用
- **碰撞**：`Bullet.update()` 内手动检测与 Enemy 的 AABB 重叠

### 4.3 组件 (`player.dart`)

#### Player
- 蓝色方块 + 枪口小尾巴
- 每帧检测最近的 Enemy，自动朝向射击
- 移动范围钳制在 `[0, gameWidth] × [0, gameHeight]`
- `takeDamage(amount)` 减少 HP 并回调 `game.onPlayerDamaged()`

#### Enemy
- 红色方块 + 两个白色眼睛
- 每帧向 Player 当前位置移动
- HP = 3，被子弹击中扣 1 点，HP ≤ 0 时触发 `game.onEnemyKilled()` 并从父组件移除

#### Bullet
- 黄色小方块
- 按 `direction` 向量匀速移动，超出边界 ±50 像素后移除
- 与 Enemy 的 `toRect()` 做 AABB 重叠检测，命中则对 Enemy 造成伤害并自我移除

---

## 5. 渲染机制

- 使用 `FixedSizeViewport(gameSize)` 锁定游戏逻辑分辨率为 480×720
- `camera.viewfinder.anchor = Anchor.topLeft`，相机位置从 `(0,0)` 开始
- 所有组件使用 `RectangleComponent` 绘制纯色方块（无图片资产）
- 背景是一个铺满整个 gameSize 的深色 RectangleComponent

---

## 6. 输入处理

| 按键 | 动作 |
|------|------|
| W / ↑ | 向上移动 |
| S / ↓ | 向下移动 |
| A / ← | 向左移动 |
| D / → | 向右移动 |

- `SoulKnightGame` 持有 `Set<LogicalKeyboardKey> _keysPressed`
- `onKeyEvent(KeyEvent, Set<LogicalKeyboardKey>)` 在 `KeyDown` 时 add，`KeyUp` 时 remove
- `update()` 每帧根据 Set 内容计算移动向量并 normalize 后乘以速度

---

## 7. 构建与运行

```powershell
# 方式一：PC/Web 运行（开发调试）
cd D:\workspace\soul_knight_game
D:\flutter\bin\flutter run

# 方式二：构建 Debug APK
# 1. 创建临时 junction（避免 Windows Gradle 路径 bug）
mklink /J C:\soul_knight_game D:\workspace\soul_knight_game

# 2. 在 junction 目录构建
cmd /c "D:\flutter\bin\flutter build apk --debug"

# 3. 清理 junction
rmdir C:\soul_knight_game

# APK 输出位置
D:\workspace\soul_knight_game\build\app\outputs\flutter-apk\app-debug.apk
```

---

## 8. Flutter 镜像配置

> ⚠️ 华为云镜像（`https://repo.huaweicloud.com/flutter`）未同步部分新版 Flutter artifacts。

**正确配置**：
```powershell
# 临时设置（仅当前会话）
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"

# 永久设置（写入用户环境变量）
[Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", "https://storage.googleapis.com", "User")
```

验证：`flutter --version` 输出应显示 `Flutter assets will be downloaded from https://storage.googleapis.com`

---

## 9. 已完成功能

| 功能 | 状态 | 文件 |
|------|------|------|
| FlameGame 主循环 | ✅ | `game.dart` |
| 玩家移动（WASD/方向键） | ✅ | `game.dart` |
| 自动瞄准射击 | ✅ | `player.dart` |
| 碰撞检测（CircleHitbox + AABB） | ✅ | `player.dart` |
| 敌人生成（屏幕边缘） | ✅ | `game.dart` |
| 敌人 AI 追踪玩家 | ✅ | `player.dart` |
| 玩家/敌人/子弹可视化渲染 | ✅ | `player.dart` |
| 固定逻辑分辨率（480×720） | ✅ | `game.dart` |
| Debug APK 构建 | ✅ | `build/app/outputs/flutter-apk/` |
| Git 推送 | ✅ | GitHub repo |

---

## 10. 待实现功能（优先级排序）

1. **虚拟摇杆** — 手机端触摸控制（非键盘）
2. **地牢房间系统** — 程序化房间生成，关卡递进
3. **多种武器** — 霰弹、激光、榴弹等不同弹道
4. **装备/道具系统** — 掉落后获得属性加成
5. **HUD** — 血条、弹药、金币显示
6. **多种敌人类型** — 近战、远程、精英怪、BOSS
7. **商店系统** — 击杀金币 → 购买武器/血量
8. **音效与特效** — 射击火花、击中反馈、背景音乐
9. **存档系统** — shared_preferences 持久化
10. **永久升级** — 天赋树/局外成长

---

## 11. 踩坑记录

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 黑屏（无渲染） | 组件只有 `CircleHitbox`，没有可视化 | 给 Player/Enemy/Bullet 添加 `RectangleComponent` |
| `camera.viewfinder.size` 不存在 | Flame 1.37 中无此 API | 使用 `camera.viewport = FixedSizeViewport(w, h)` |
| 华为镜像 404 | 华为云未同步 425cfb54 版本的 artifacts | 改用 `FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com` |
| Gradle 路径跨盘符错误 | Kotlin 增量编译在 C:\（缓存）和 D:\（项目）跨盘符 | 创建 `mklink /J C:\soul_knight_game D:\workspace\soul_knight_game` 在 C:\ 下构建 |
| `flutter run` 提示找不到 `pubspec.yaml` | 在错误目录执行 | 切换到 `D:\workspace\soul_knight_game` 再执行 |
| `onKeyEvent` 未覆盖 super | `HasKeyboardHandlerComponents` 要求调用 super | 在 `onKeyEvent` 末尾添加 `return super.onKeyEvent(...)` |

---

## 12. 代码风格

- **组件文件**：`player.dart` 内含 Player / Enemy / Bullet 三个类（避免循环 import）
- **常量管理**：所有数值常量集中在 `game_constants.dart`，不硬编码
- **提交规范**：`feat:` 新功能 / `fix:` 修复 / `docs:` 文档 / `refactor:` 重构

---

## 13. 联系方式

- GitHub: https://github.com/ANewName-1024
- 仓库: https://github.com/ANewName-1024/soul_knight_game