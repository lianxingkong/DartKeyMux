import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../all_template/base/template_document.dart';
import '../all_template/base/mouse_touch_core.dart';
import '../all_template/custom_template/background_crop.dart';
import '../sidebar/theme_colors.dart';

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
  String? _bgImage;
  double _bgOpacity = 1.0;

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
    _bgImage = ini?.backgroundImage;
    _bgOpacity = ini?.backgroundOpacity ?? 1.0;
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

  /// ★ 打开背景图片裁剪页
  Future<void> _openBackgroundCrop() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundCropPage(
          widgets: const [], // 鼠标模板无组件
          existingPath: _bgImage,
          initialOpacity: _bgOpacity,
        ),
      ),
    );
    // null = 用户清除了背景
    setState(() {
      _bgImage = result?['path'] as String?;
      _bgOpacity = (result?['opacity'] as num?)?.toDouble() ?? 1.0;
    });
  }

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
        backgroundImage: _bgImage,
        backgroundOpacity: _bgOpacity,
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
      backgroundColor: AppTheme.scaffoldBg(context),
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
          // ★ 背景图片层
          if (_bgImage != null && File(_bgImage!).existsSync())
            Positioned.fill(
              child: Opacity(
                opacity: _bgOpacity,
                child: Image.file(File(_bgImage!), fit: BoxFit.cover),
              ),
            ),
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
            IconButton(
                icon: Icon(Icons.image,
                    size: 22,
                    color: _bgImage != null ? Colors.blue : null),
                onPressed: _openBackgroundCrop,
                tooltip: '背景图片'),
            const SizedBox(width: 4),
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