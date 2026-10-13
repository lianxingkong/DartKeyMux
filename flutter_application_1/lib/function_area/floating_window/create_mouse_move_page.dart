import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../all_template/base/template_document.dart';
import '../all_template/base/mouse_touch_core.dart';

/// 鼠标触控模板创建 / 编辑页
///
/// 全屏触控区 + 顶栏（名称输入） + 右侧隐藏式侧边栏（参数调节）。
/// 侧边栏通过屏幕右边缘的微小把手唤出，常态隐藏防误触。
///
/// ★ 纯播放模式已拆分到 all_template/player_template/custom_mouse_play_page.dart
class CreateMouseMovePage extends StatefulWidget {
  const CreateMouseMovePage({
    super.key,
    this.initial, // 编辑已有模板时传入
  });

  final TemplateDraft? initial;

  @override
  State<CreateMouseMovePage> createState() => _CreateMouseMovePageState();
}

class _CreateMouseMovePageState extends State<CreateMouseMovePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── 触摸引擎（共享逻辑）──
  late final MouseTouchEngine _engine;

  // ── 模板相关 ──
  late String _name;
  late final TextEditingController _nameCtrl;

  // ════════════════════════════════════════════
  //  初始化
  // ════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky);
    final ini = widget.initial;
    _name = ini?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);
    _engine = MouseTouchEngine(
      sensitivity: ini?.sensitivity ?? 1.0,
      mouseMode: ini?.mouseMode ?? 0,
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    _nameCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  // ════════════════════════════════════════════
  //  保存
  // ════════════════════════════════════════════

  void _save() {
    final name = _name.trim().isEmpty ? '未命名鼠标模板' : _name.trim();
    Navigator.pop(
      context,
      TemplateDraft(
        name: name,
        widgets: [],
        type: 'mouse',
        sensitivity: _engine.sensitivity,
        mouseMode: _engine.mouseMode,
      ),
    );
  }

  // ════════════════════════════════════════════
  //  界面
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFECEFF1),
      // ★ 隐藏式右侧侧边栏（来自引擎共享，含保存按钮）
      endDrawer: _engine.buildSettingsDrawer(
        context,
        () => setState(() {}),
        showSave: true,
        onSave: _save,
      ),
      // ★ 禁止滑动手势打开侧边栏（只能通过把手按钮打开）
      drawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          // ── 全屏触控层（圆点 + Listener）──
          ..._engine.buildTouchLayers(),

          // ── 顶栏 ──
          Positioned(
            top: 16,
            left: 12,
            right: 44, // 右侧留出把手空间
            child: _topBar(),
          ),

          // ── 右侧把手（打开侧边栏）──
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _engine.buildSidebarHandle(
              () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  // ──── 顶栏（仅创建/编辑页有名称输入）────

  Widget _topBar() => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const BackButton(),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                onChanged: (v) => _name = v,
                decoration: const InputDecoration(
                  hintText: '模板名称',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ),
      );
}