/// ══════════════════════════════════════════════════════════════
///  混合模板（鼠标底层 + 键盘组件）的创建 / 编辑逻辑
/// ══════════════════════════════════════════════════════════════
///
/// 设计：
///   • 编辑界面完全复用 [CreateTemplatePage]（键盘模板的一切功能都在），
///     只是通过 [CreateTemplatePage.mixLayerFactory] 注入一个鼠标底层。
///   • 本文件只负责"底层怎么响应触摸、设置抽屉长什么样、顶栏标识"，
///     编辑器的画布 / 组件 / 联立 / 属性面板等逻辑一行都不用改。
///
/// 鼠标底层语义（**只移动、不点击、无多指**）：
///   • 固定为触控板模式（mouseMode = 1）
///   • 只发送光标 MOVE，不发送任何点击 / 滚轮（`moveOnly = true`）
///   • 出现第二根手指 → 整层收回控制（配合编辑器双指缩放画布），
///     避免"缩放画布顺手给电脑发一串事件"
///   • 落在组件上的指针一律不接管，交给键盘 / 画布逻辑
library;

import 'package:flutter/material.dart';

import '../all_template/base/template_document.dart';
import '../all_template/base/mouse_touch_core.dart';
import 'create_template_page.dart';

/// 新建 / 编辑混合模板的入口页
class CreateMixTemplatePage extends StatelessWidget {
  const CreateMixTemplatePage({super.key, this.initial, this.editIndex = -1});

  /// 编辑已有模板时传入旧草稿
  final TemplateDraft? initial;

  /// index >= 0 时，调用方按"覆盖第 index 个"处理返回值
  final int editIndex;

  @override
  Widget build(BuildContext context) => CreateTemplatePage(
        initial: initial,
        editIndex: editIndex,
        // 每次进入页面新建一份底层（由编辑器负责 dispose）
        mixLayerFactory: () => MixMouseLayer.fromDraft(initial),
      );
}

/// ─────────────────────────────────────────────
///  混合模板的鼠标底层实现
/// ─────────────────────────────────────────────
class MixMouseLayer implements MixBottomLayer {
  MixMouseLayer({double sensitivity = 1.0})
      : _engine = MouseTouchEngine(
          sensitivity: sensitivity,
          mouseMode: 1,    // ★ 固定触控板逻辑
          moveOnly: true,  // ★ 只移动，不点击，无多指
        );

  /// 从旧草稿恢复灵敏度（触控模式固定为触板）
  factory MixMouseLayer.fromDraft(TemplateDraft? draft) =>
      MixMouseLayer(sensitivity: draft?.sensitivity ?? 1.0);

  final MouseTouchEngine _engine;

  /// 当前被本层接管的指针（起点不在任何组件上）
  final Set<int> _ptrs = <int>{};

  @override
  double get sensitivity => _engine.sensitivity;

  @override
  int get mouseMode => 1; // 混合模板底层恒为触控板模式

  @override
  void dispose() => _engine.dispose();

  // ════════════════════════════════════════════
  //  指针接管策略
  // ════════════════════════════════════════════

  @override
  bool onDown(PointerDownEvent e, bool hitWidget) {
    // 已有手指在拖动 → 这是第二根手指：判定为「画布双指缩放」，
    // 收回全部鼠标控制，保证缩放画布不会把事件发给电脑
    if (_ptrs.isNotEmpty) {
      _engine.releaseAll();
      _ptrs.clear();
      return false;
    }
    // 落在组件上 → 键盘 / 画布逻辑，本层不接管
    if (hitWidget) return false;

    _ptrs.add(e.pointer);
    _engine.onDown(e);
    return true;
  }

  @override
  void onMove(PointerMoveEvent e) {
    if (!_ptrs.contains(e.pointer)) return;
    _engine.onMove(e);
  }

  @override
  void onUp(PointerUpEvent e) {
    if (!_ptrs.remove(e.pointer)) return;
    _engine.onUp(e);
    _hideDotIfIdle();
  }

  @override
  void onCancel(PointerCancelEvent e) {
    if (!_ptrs.remove(e.pointer)) return;
    _engine.onCancel(e);
    _hideDotIfIdle();
  }

  /// 手指全部抬起 → 收起圆点（引擎本身只转移归属，不清除显示）
  void _hideDotIfIdle() {
    if (_ptrs.isEmpty) _engine.fingerPos.value = null;
  }

  // ════════════════════════════════════════════
  //  编辑器需要插入的 UI
  // ════════════════════════════════════════════

  /// 手指圆点：纯视觉，绝不能拦截触摸
  @override
  Widget buildOverlay() => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: FingerDotPainter(_engine.fingerPos),
          ),
        ),
      );

  /// 顶栏标识
  @override
  Widget buildBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🧩 混合 · 鼠标底层',
          style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
        ),
      );

  /// 右侧设置抽屉：仅移动模式下只有灵敏度可调
  @override
  Widget buildSettingsDrawer(BuildContext context, VoidCallback onChanged) =>
      _engine.buildSettingsDrawer(context, onChanged, showSave: false);
}
