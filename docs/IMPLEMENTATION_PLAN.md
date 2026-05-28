# Soul Knight Clone — 完整实施计划

## 文档信息

- **项目**：Soul Knight Clone（元气骑士复刻）
- **版本**：v1.0.0
- **创建**：2026-05-29
- **目标**：MVP → Beta → Release

---

## 实施概览

```
总周期：约 10 周（Beta）
├── Phase 1：基础完善 ............ 现在已完成 ✅
├── Phase 2：输入系统 ......... 1周
├── Phase 3：武器系统 .......... 1周
├── Phase 4：敌人与AI .......... 1周
├── Phase 5：地牢系统 .......... 1周
├── Phase 6：UI与HUD ........... 1周
├── Phase 7：音效与特效 ......... 1周
├── Phase 8：保存系统 .......... 1周
├── Phase 9：测试与调优 ......... 1周
└── Phase 10：发布准备 .......... 1周 (非并行)
```

---

## Phase 1：基础完善 ⭐ 已完成

> **状态**：✅ 完成  
> **耗时**：已投入  
> **依赖**：无

### 1.1 任务清单

| 任务 | 子任务 | 状态 |
|------|-------|------|
| [x] 修复黑屏问题 | Player/Enemy/Bullet添加可视化渲染 | ✅ |
| [x] 修复视口配置 | FixedSizeViewport替代viewfinder.size | ✅ |
| [x] 修复键盘输入 | onKeyEvent调用super | ✅ |
| [x] 修复Flutter镜像 | 切回Google Storage | ✅ |

### 1.2 验收标准

- [x] 运行`flutter run`无报错
- [x] 能看到蓝色玩家 + 红色敌人 + 黄色子弹
- [x] WASD/方向键能控制移动
- [x] 自动射击最近敌人

### 1.3 已知问题

| 问题 | 状态 |
|------|------|
| 只能在PC调试 | 待Phase 2解决 |
| 没有移动端虚拟摇杆 | 待Phase 2解决 |
| 没有地牢房间概念 | 待Phase 5解决 |

---

## Phase 2：输入系统

> **状态**：🔄 开始  
> **预计**：1周  
> **前置**：Phase 1完成

### 2.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] VirtualJoystick组件 | 触控区域检测 | 左右半屏可区分拖动 | P0 |
| [ ] 双摇杆布局 | 左摇杆移动 + 右tap射击 | 两者不冲突 | P0 |
| [ ] 自动连射 | 右键长按连发 | 可开关 | P1 |
| [ ] 技能按键 | 底部技能按钮 | 支持冷却回调 | P1 |
| [ ] PC/移动端适配 | 根据平台切换输入模式 | 自动检测 | P1 |
| [ ] 输入管理器 | InputManager统一分发 | 易于扩展 | P2 |

### 2.2 技术细节

```dart
// 左拇指区域：屏幕宽度60%，全高度
// x ∈ [0, width*0.6], y ∈ [0, height]

// 右区域：剩余40%
// tap = 射击, long press = 连射

// 实现要点：
// 1. GestureDetector 检测 onPanStart/Update/End
// 2. 计算相对起点的方向向量
// 3. normalize 后传给 Player.velocity
// 4. 结束时清零
```

---

## Phase 3：武器系统

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 2完成

### 3.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] Weapon基类 | 属性：伤害/攻速/弹量/射程 | 可实例化子类 | P0 |
| [ ] Pistol（手枪） | 单发直线 | 默认武器 | P0 |
| [ ] Shotgun（霰弹） | 5发扇形 | Angle±offsets | P0 |
| [ ] Rifle（步枪） | 3连发点射 | cooldown控制 | P1 |
| [ ] Sniper（狙击） | 蓄力高伤 | 蓄力动画 | P1 |
| [ ] MagicBall（魔法球） | AOE爆炸 | 范围检测 | P2 |
| [ ] 词缀系统 | 伤害+/攻速+/分裂 | random roll | P2 |
| [ ] 武器切换 | 拾取/购买切换 | 最多3把 | P2 |

### 3.2 接口定义

```dart
abstract class Weapon {
  final String id;
  final String name;
  final int damage;
  final double fireRate;  // 秒
  final int ammo;        // -1=无限
  final BulletType bulletType;
  
  void fire(Vector2 direction, Vector2 origin, Game game);
  
  // 工厂方法
  static Weapon fromId(String id) {...}
  static List<Weapon> allWeapons() {...}
}
```

### 3.3 子弹类型扩展

| BulletType | 行为 |
|------------|------|
| normal | 直线飞行，超界销毁 |
| missile | 追踪最近敌人 |
| explosive | 落点AOE伤害 |
| piercing | 穿透N个敌人 |
| split | 分裂成小弹 |

---

## Phase 4：敌人与AI

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 3完成

### 4.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] Enemy基类扩展 | 添加type/hp/speed/attack | 向下兼容 | P0 |
| [ ] Chaser（小怪） | 向玩家冲撞 | 基础AI | P0 |
| [ ] Shooter（枪兵） | 定时射击 | 预判弹道 | P1 |
| [ ] EliteEnemy（精英） | 双倍属性+特殊技 | 血条外观 | P1 |
| [ ] Boss基类 | 多阶段+全屏技能 | 阶段转换 | P1 |
| [ ] SlimeKing（Boss） | 吞噬/跳跃 | 3阶段 | P1 |
| [ ] 掉落系统 | 武器/金币/宝石 | 随机roll | P2 |

### 4.2 AI状态机

```dart
enum EnemyState {
  idle,     // 待机
  chasing,  // 追击
  attacking,// 攻击中
  retreating,// 撤退
  stunned, // 眩晕
  dead,    // 死亡
}

// 状态转换
idle → chasing：玩家进入感知范围
chasing → attacking：进入攻击范围
attacking → retreating：攻击后短暂后退
任意 → stunned：受击硬直
```

### 4.3 数值配置

| EnemyType | HP | Speed | Attack | XP |
|----------|-----|------|--------|-----|
| Chaser | 1 | 80 | 1 | 1 |
| Shooter | 2 | 60 | 1 | 2 |
| Elite | 5 | 100 | 2 | 5 |
| Boss | 20 | 50 | 3 | 10 |

---

## Phase 5：地牢系统

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 4完成

### 5.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] Room组件 | 类型/敌人生成/清理状态 | UI渲染 | P0 |
| [ ] RoomGenerator | 连线算法+随机房间 | 生成关卡 | P0 |
| [ ] Door（门） | 通向下一个房间 | 点击进入 | P0 |
| [ ] Wave系统 | 波次配置+生成 | 刷怪节奏 | P1 |
| [ ] TreasureRoom | 宝箱+武器 | 随机奖励 | P1 |
| [ ] ShopRoom | 商人NPC | 买卖UI | P2 |
| [ ] BossRoom | Boss刷新 | 过门触发 | P1 |

### 5.2 房间类型定义

```dart
enum RoomType {
  normal,   // 普通房，1-3波
  elite,    // 精英房，固定精英
  treasure,// 宝箱房
  shop,    // 商人房
  portal,   // 传送房
  boss,    // Boss房
}

class Room {
  final String id;
  final RoomType type;
  List<Wave> waves;
  bool cleared = false;
  bool unlocked = false;
  Map<String, Room> doors = {};  // north/south/east/west
}
```

### 5.3 关卡生成算法

```
生成规则（floor=N）：
1. 房间数 = 3 + N (最多8)
2. 普通房 = 总数 - 2
3. 奖励房 = 1 (第N-1间)
4. Boss房 = 1 (最后一间)

连接规则：
- 每个房至少1个门
- 不超过3个门
- 避免死路
```

---

## Phase 6：UI与HUD

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 5完成

### 6.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] HP条 | 左上角心形图标 | 实时更新 | P0 |
| [ ] 武器显示 | 图标+弹药数 | 切换同步 | P0 |
| [ ] 金币计数 | 无间数字 | 增加动画 | P1 |
| [ ] 技能冷却 | 底部按钮遮罩 | 倒计时 | P1 |
| [ ] 暂停菜单 | 继续/退出/重试 | 回调 | P1 |
| [ ] 结算界面 | 通关/死亡弹窗 | 显示数据 | P1 |
| [ ] 开始菜单 | 角色选择/开始 | 进入游戏 | P1 |
| [ ] 商店UI | 商品列表+购买 | 货币检查 | P2 |

### 6.2 HUD布局

```
┌─────────────────────────────────────┐
│ ♥♥♥♡♡    🔫12/∞    ����999        │  <- 顶部30px
│                                     │
│                                     │
│           游戏区域                   │  <- 480×660
│                                     │
│                                     │
├─────────────────────────────────────┤
│ [Q][W][E][必杀]                    │  <- 底部30px
└─────────────────────────────────────┘
```

---

## Phase 7：音效与特效

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 6完成

### 7.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] 射击音效 | 不同武器不同 | audio播放 | P1 |
| [ ] 击中音效 | 伤害反馈音 | audio播放 | P1 |
| [ ] 背景音乐 | 地牢氛围loop | audio播放 | P2 |
| [ ] 击中火花 | ParticleEmitter | 粒子效果 | P1 |
| [ ] 暴击闪光 | 屏幕闪烁 | blink动画 | P1 |
| [ ] 子弹拖尾 | SparkEmitter | 拖尾效果 | P2 |
| [ ] 武器发光 | Shader效果 | 传说词缀 | P2 |

### 7.2 粒子系统（Flame）

```dart
// 使用 flame_particles
// 示例：击中火花
final particles = ParticlesComponent(
  particle: Particle.png('spark.png'),
  lifespan: 0.3,
  emissionFrequency: 100,
  count: 5,
  speed: 100,
  angleSpread: pi / 2,
);
// 在 bullet.hit() 时 add(particles)
```

---

## Phase 8：保存系统

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：无依赖

### 8.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] GameProgress类 | 存档结构体 | 序列化 | P0 |
| [ ] 本地存档 | SharedPreferences | 保存/读取 | P0 |
| [ ] 高分记录 | topScore | 持久化 | P1 |
| [ ] 金币积累 | totalCoins | 跨局累加 | P1 |
| [ ] 已解锁角色 | unlockedChars | JSON数组 | P1 |
| [ ] 已解锁武器 | unlockedWeapons | JSON数组 | P1 |
| [ ] 每日签到 | streak+reward | 日期检查 | P2 |
| [ ] 云存档 | Firebase | 可选 | P3 |

### 8.2 存储Key定义

```dart
class StorageKeys {
  static const HIGH_SCORE = 'high_score';
  static const TOTAL_COINS = 'total_coins';
  static const UNLOCKED_CHARS = 'unlocked_chars';
  static const UNLOCKED_WEAPONS = 'unlocked_weapons';
  static const UPGRADES = 'upgrades';
  static const STREAK_DAYS = 'streak_days';
  static const LAST_LOGIN = 'last_login';
}
```

---

## Phase 9：测试与调优

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 1-8完成

### 9.1 测试计划

| 测试类型 | 覆盖 | 工具 |
|---------|------|------|
| 单元测试 | 数值计算/AI状态 | flutter test |
| 组件测试 | Player/Enemy/Bullet | golden测试 |
| 集成测试 | 完整游戏流程 | 自动化脚本 |
| 压力测试 | 100+敌人同屏 | perf工具 |
| 兼容性测试 | Android 8-14 | 真机矩阵 |

### 9.2 性能目标

| 指标 | 目标 |
|------|------|
| FPS | ≥55（60为满） |
| 加载时间 | ≤3秒 |
| 包体大小 | ≤200MB |
| 内存峰值 | ≤500MB |
| 发热 | 适度（不烫手） |

---

## Phase 10：发布准备

> **状态**：⏳ 待开始  
> **预计**：1周  
> **前置**：Phase 9完成

### 10.1 任务清单

| 任务 | 子任务 | 验收 | 优先级 |
|------|-------|------|--------|
| [ ] Release构建 | `flutter build apk --release` | 签名APK | P0 |
| [ ] 应用图标 | 替换默认图标 | 设计稿 | P1 |
| [ ] 应用名称 | "Soul Knight Clone" | 配置 | P1 |
| [ ] 包名 | com.soulknight.clone | 配置 | P1 |
| [ ] 版本号 | 1.0.0 | pubspec.yaml | P1 |
| [ ] 隐私政策 | Google Play合规 | 法律 | P1 |
| [ ] 商店截图 | 5张截图+视频 | 运营素材 | P2 |
| [ ] 商��描�� | 中文+英文 | 运营素材 | P2 |

### 10.2 发布检查表

```
□ 代码无 analyze 警告
□ 无硬编码敏感信息
□ ProGuard 已配置
□ 签名密钥已备份
□ 应用图标已替换
□ 版本号已更新
□ CHANGELOG.md 已写
□ Tag 已打 v1.0.0
□ Alpha测试包已分发
□ Beta测试完成
□ 商店素材已准备
□ 隐私政策已上传
```

---

## 人力安排

### 开发者角色（1人）

| 角色 | 职责 |
|------|------|
| 全栈开发 | 全部任务 |
| QA | 自测 |
| 运营 | 上架 |

> 💡 MVP阶段建议专注核心玩法，打磨射击手感，地牢和UI可简化

---

## 风险与预案

| 风险 | 影响 | 预案 |
|------|------|------|
| 性能不足 | 50+敌人卡顿 | 启用四叉树剔除 |
| 内存泄漏 | 长时间闪退 | 对象池+dispose |
| 审核拒绝 | Google Play驳回 | 提前阅读政策 |
| 功能蔓延 | 延期 | 砍非必要功能 |

---

## 进度看板

```
Phase  ▓▓▓▓▓▓▓▓░░░░░░  60%  ← 当前
████  ██████████████████  100%
████████████████████████████████████████  100%

Phase 1 ✅ 完成
Phase 2 🔄 进行中
Phase 3 ⏳ 待开始
Phase 4 ⏳ 待开始
Phase 5 ⏳ 待开始
Phase 6 ⏳ 待开始
Phase 7 ⏳ 待开始
Phase 8 ⏳ 待开始
Phase 9 ⏳ 待开始
Phase 10 ⏳ 待开始
```

---

## 术语表

| 术语 | 定义 |
|------|------|
| MVP | Minimum Viable Product，最小可行产品 |
| AOE | Area of Effect，范围效果 |
| Buff/Debuff | 增益/减益效果 |
| HP | Health Points，生命值 |
| Cooldown | 冷却时间 |
| DPS | Damage Per Second，秒伤害 |
| Aggro | 仇恨值（怪物攻击目标） |
| Spawn | 生成（敌人生成） |
| Drop | 掉落（击杀掉落） |

---

*本计划会随开发进展持续更新。*