import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/function_area/setting/basic_setting_page.dart';
import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/sidebar/theme_colors.dart';

/// ─────────────────────────────────────────────
/// 主侧边栏菜单
/// ─────────────────────────────────────────────
class MainSidebarMenu extends StatefulWidget {
  const MainSidebarMenu({super.key});

  @override
  State<MainSidebarMenu> createState() => _MainSidebarMenuState();
}

class _MainSidebarMenuState extends State<MainSidebarMenu> {
  static const _prefAvatarPath = 'avatar_path';
  static const _prefUserName = 'user_name';

  String? _avatarPath;
  String _userName = '用户名';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ── 读取本地保存 ──
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString(_prefAvatarPath);
      _userName = prefs.getString(_prefUserName) ?? '用户名';
    });
  }

  // ── 写入本地保存 ──
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      await prefs.setString(_prefAvatarPath, _avatarPath!);
    } else {
      await prefs.remove(_prefAvatarPath);
    }
    await prefs.setString(_prefUserName, _userName);
  }

  // ─────────────────────────────────────────────
  /// 点击头像：打开系统相册选图
  // ─────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return; // 用户取消

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // ★ 先删除旧头像文件（现在是 await 异步调用）
      await _deleteOldAvatarFile(appDir.path);

      final newFile = await File(picked.path).copy(
        '${appDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      setState(() => _avatarPath = newFile.path);
      await _savePrefs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存头像失败: $e')),
        );
      }
    }
  }

  /// 删除旧的头像文件（仅删除应用私有目录内的，防止误删其他文件）
  Future<void> _deleteOldAvatarFile(String appDirPath) async {
    if (_avatarPath == null || _avatarPath!.isEmpty) return;
    try {
      final f = File(_avatarPath!);
      // 确认文件在应用目录内才删除
      if (f.existsSync() && f.path.startsWith(appDirPath)) {
        await f.delete();
      }
    } catch (_) {
      // 删除失败不影响主流程
    }
  }

  // ─────────────────────────────────────────────
  /// 编辑用户名
  // ─────────────────────────────────────────────
  Future<void> _editUserName() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '输入用户名'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    setState(() => _userName = result);
    await _savePrefs();
  }

  // ─────────────────────────────────────────────
  /// 头像（无图时显示占位图标）
  // ─────────────────────────────────────────────
  Widget _buildAvatar() {
    if (_avatarPath != null &&
        _avatarPath!.isNotEmpty &&
        File(_avatarPath!).existsSync()) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: FileImage(File(_avatarPath!)),
      );
    }
    return const CircleAvatar(
      radius: 36,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, size: 36, color: Colors.white),
    );
  }

  /// 头像 + 右下角编辑徽标
  Widget _buildAvatarWithBadge() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildAvatar(),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 13, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark.value;
    final sidebarBg = AppTheme.sidebarBg(context);
    // 侧边栏文字颜色：亮色模式用深绿，暗色模式用浅灰白
    final sidebarText = dark ? const Color(0xFFC8E6C9) : const Color.fromARGB(255, 27, 94, 32);

    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDark,
      builder: (context, darkVal, _) {
        final bg = AppTheme.sidebarBg(context);
        final txt = darkVal
            ? const Color(0xFFC8E6C9)
            : const Color.fromARGB(255, 27, 94, 32);
        return Drawer(
          backgroundColor: bg,
          child: SingleChildScrollView(
        child: Column(
          children: [
            // ─────────────────────────────────────────────
            // ★ 自绘头部：高度自己说了算，彻底解决溢出问题
            // （原 DrawerHeader 高度固定 168dp，内容刚好超 1px 导致溢出）
            // ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 180,
              // 与 Drawer 背景同色，视觉上无缝衔接
              color: bg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatarWithBadge(),
                  const SizedBox(height: 14),
                  // 用户名可点击修改
                  GestureDetector(
                    onTap: _editUserName,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: txt,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: txt),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── 暗色模式开关 ──
            ValueListenableBuilder<bool>(
              valueListenable: AppTheme.isDark,
              builder: (context, darkVal, _) => SwitchListTile(
                secondary: Icon(darkVal ? Icons.dark_mode : Icons.light_mode),
                title: Text(darkVal ? '暗色模式' : '亮色模式'),
                value: darkVal,
                onChanged: (v) => AppTheme.isDark.value = v,
              ),
            ),
            // ── 强制屏幕方向 ──
            const _OrientationButtons(),
            const Divider(indent: 16, endIndent: 16),
            // ── 自启动模板开关 ──
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text("自启动指定模板"),
              trailing: ListenableBuilder(
                listenable: TemplateService.instance,
                builder: (context, _) {
                  final masterOn =
                      TemplateService.instance.autoStartMasterEnabled;
                  final hasTarget =
                      TemplateService.instance.autoStartIndex != null;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasTarget)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            TemplateService.instance
                                .draftAt(
                                    TemplateService.instance.autoStartIndex!)
                                .name,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Switch(
                        value: masterOn,
                        onChanged: (value) {
                          TemplateService.instance.setAutoStartMaster(value);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── 设置入口 ──
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingPage()),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.settings),
                title: Text("设置"),
              ),
            ),
          ],
        ),
      ),
    );
      },  // ValueListenableBuilder builder
    );    // ValueListenableBuilder
  }
}

// ─────────────────────────────────────────────
//  强制屏幕方向按钮组
// ─────────────────────────────────────────────
class _OrientationButtons extends StatelessWidget {
  const _OrientationButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.screen_rotation, size: 18),
          const SizedBox(width: 8),
          const Text('屏幕方向', style: TextStyle(fontSize: 14)),
          const Spacer(),
          _btn(Icons.stay_primary_portrait, '竖屏',
              [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]),
          const SizedBox(width: 6),
          _btn(Icons.stay_primary_landscape, '横屏',
              [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String tooltip, List<DeviceOrientation> orientations) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: () => SystemChrome.setPreferredOrientations(orientations),
    );
  }
}
