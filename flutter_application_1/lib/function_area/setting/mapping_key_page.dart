import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

// ==================== 数据定义（要改名/加键只改这里） ====================

class KeyMapEntry {
  final String pc;     // PC 端名称
  final String mobile; // 移动端名称
  const KeyMapEntry(this.pc, this.mobile);
}

class KeyCategory {
  final String title;
  final List<KeyMapEntry> entries;
  const KeyCategory(this.title, this.entries);
}

const List<KeyCategory> keyCategories = [
  KeyCategory('基础控制键', [
    KeyMapEntry('Enter', 'return'),
    KeyMapEntry('Escape', 'esc'),
    KeyMapEntry('Backspace', 'backspace'),
    KeyMapEntry('Tab', 'tab'),
    KeyMapEntry('Space', 'space'),
    KeyMapEntry('CapsLock', 'capslock'),
  ]),
  KeyCategory('功能键', [
    KeyMapEntry('F1', 'f1'),
    KeyMapEntry('F2', 'f2'),
    KeyMapEntry('F3', 'f3'),
    KeyMapEntry('F4', 'f4'),
    KeyMapEntry('F5', 'f5'),
    KeyMapEntry('F6', 'f6'),
    KeyMapEntry('F7', 'f7'),
    KeyMapEntry('F8', 'f8'),
    KeyMapEntry('F9', 'f9'),
    KeyMapEntry('F10', 'f10'),
    KeyMapEntry('F11', 'f11'),
    KeyMapEntry('F12', 'f12'),
  ]),
  KeyCategory('方向键', [
    KeyMapEntry('Up', 'up'),
    KeyMapEntry('Down', 'down'),
    KeyMapEntry('Left', 'left'),
    KeyMapEntry('Right', 'right'),
  ]),
  KeyCategory('导航 / 编辑键', [
    KeyMapEntry('Home', 'home'),
    KeyMapEntry('End', 'end'),
    KeyMapEntry('PageUp', 'pgup'),
    KeyMapEntry('PageDown', 'pgdn'),
    KeyMapEntry('Insert', 'ins'),
    KeyMapEntry('Delete', 'del'),
  ]),
  KeyCategory('锁定键', [
    KeyMapEntry('NumLock', 'numlock'),
    KeyMapEntry('ScrollLock', 'scrolllock'),
  ]),
  KeyCategory('修饰键', [
    KeyMapEntry('Ctrl', 'ctrl'),
    KeyMapEntry('LCtrl', 'lctrl'),
    KeyMapEntry('RCtrl', 'rctrl'),
    KeyMapEntry('Shift', 'shift'),
    KeyMapEntry('LShift', 'lshift'),
    KeyMapEntry('RShift', 'rshift'),
    KeyMapEntry('Alt', 'alt'),
    KeyMapEntry('LAlt', 'lalt'),
    KeyMapEntry('RAlt', 'ralt'),
    KeyMapEntry('GUI', 'gui'),
  ]),
];

// ═══════════════════════════════════════════════════════════
//  按键传输模式判定（供 custom_play_page 等调用）
// ═══════════════════════════════════════════════════════════

/// 命名键集合（isRune=false），大小写不敏感。
///
/// 包含上表中所有移动端键名，以及用户指定的等价别名：
/// - enter / return   escape / esc   backspace   tab   space   capslock
/// - f1 … f12
/// - up / down / left / right
/// - home / end   pageup / pgup / pagedown / pgdn   insert / ins   delete / del
/// - numlock   scrolllock
/// - ctrl / lctrl / rctrl   shift / lshift / rshift   alt / lalt / ralt
/// - gui / win / windows / super / meta
const _namedKeys = {
  // 基础控制键
  'enter', 'return',
  'escape', 'esc',
  'backspace',
  'tab',
  'space',
  'capslock',
  // 功能键
  'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
  // 方向键
  'up', 'down', 'left', 'right',
  // 导航 / 编辑键
  'home', 'end',
  'pageup', 'pgup', 'pagedown', 'pgdn',
  'insert', 'ins',
  'delete', 'del',
  // 锁定键
  'numlock', 'scrolllock',
  // 修饰键（含左右变体）
  'ctrl', 'lctrl', 'rctrl',
  'shift', 'lshift', 'rshift',
  'alt', 'lalt', 'ralt',
  // GUI 键别名
  'gui', 'win', 'windows', 'super', 'meta',
};

/// 判断 [key] 是否为命名键（→ isRune=false）。
///
/// 规则：trim 后转为小写，与上表中的键名精确匹配。
/// 不在表中的一律视为 rune 模式（isRune=true），由后端按 rune / chord 处理。
bool isNamedKey(String key) => _namedKeys.contains(key.trim().toLowerCase());

// ==================== 页面 ====================

class KeyMapPage extends StatelessWidget {
  const KeyMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    // 字号缩放：手机竖屏 ≈ 0.9，横屏 ≈ 1.1，平板/PC ≈ 1.3（封顶）
    final double scale = (width / 480).clamp(0.85, 1.3);

    return Scaffold(
      appBar: AppBar(
        title: Text('按键映射表', style: TextStyle(fontSize: 18 * scale)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 卡片最大宽度：窄屏 240，宽屏 260
            final double maxCardWidth = constraints.maxWidth > 700 ? 300 : 240;

            return CustomScrollView(
              slivers: [
                for (final cat in keyCategories) ...[
                  _SectionHeader(title: cat.title, scale: scale),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    sliver: SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxCardWidth, // 自动决定每行几列
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 62 * scale,       // 卡片高度随字号缩放
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _KeyCard(entry: cat.entries[i], scale: scale),
                        childCount: cat.entries.length,
                      ),
                    ),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==================== 分组标题 ====================

class _SectionHeader extends StatelessWidget {
  final String title;
  final double scale;
  const _SectionHeader({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16 * scale,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 单个按键卡片 ====================

class _KeyCard extends StatelessWidget {
  final KeyMapEntry entry;
  final double scale;
  const _KeyCard({required this.entry, required this.scale});

  // ===== 复制方法 =====
  void _copyKey(BuildContext context) {
    Clipboard.setData(ClipboardData(text: entry.mobile));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制：${entry.mobile}'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        width: 160,                              // 小尺寸提示，不占满屏
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      child: Row(
        children: [
          // 左：PC 端（保持不变）
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PC端',
                    style: TextStyle(
                        fontSize: 10 * scale, color: cs.onSurfaceVariant)),
                Text(entry.pc,
                    style: TextStyle(
                        fontSize: 15 * scale, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Icon(Icons.swap_horiz, size: 16 * scale, color: cs.primary),
          SizedBox(width: 6 * scale),

          // ===== 右：移动端（改成可点击复制）=====
          Expanded(
            child: GestureDetector(              // 包一层点击
              onTap: () => _copyKey(context),
              child: Container(                  // 撑满区域，点哪儿都有效
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('移动端 (点击复制)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10 * scale,
                                  color: cs.primary)),  // 用主题色提示可点
                          Text(entry.mobile,
                              style: TextStyle(
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(width: 4 * scale),
                    Icon(Icons.copy,                            // 复制小图标
                        size: 13 * scale,
                        color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
