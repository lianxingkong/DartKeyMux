import 'package:flutter/material.dart';

import './mapping_key_page.dart';
import './change_host.dart';
import '../../app_config.dart';
import '../sidebar/theme_colors.dart';

/// ── 设置页 ──
/// 分区卡片式布局，自适应横竖屏。
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  // ── 实验性功能上次弹窗标志 ──
  bool _disclaimerShown = false;

  // ── 开启实验性功能前的免责弹窗 ──
  Future<bool> _showDisclaimer() async {
    if (_disclaimerShown) return true;
    _disclaimerShown = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('实验性功能'),
        ]),
        content: const Text(
          '你即将开启实验性功能（摇杆组件、按键映射表等）。\n\n'
          '这些功能仍在测试阶段，可能存在不稳定或未预期的行为。\n'
          '开发者不对此造成的任何后果负责。\n\n'
          '确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定开启'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// ── 构建带圆角的卡片容器 ──
  Widget _card(String title, IconData icon, List<Widget> children) {
    final dark = AppTheme.isDark.value;
    return Card(
      color: AppTheme.settingsCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: AppTheme.accent(context)),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context))),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("设 置")),
      body: ValueListenableBuilder<bool>(
        valueListenable: AppTheme.isDark,
        builder: (context, dark, _) {
          final experimentalOn = AppConfig.experimentalMode.value;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // ═══════════ 连接设置 ═══════════
              ChangeHost(
                valueHost: AppConfig.grpcHost,
                valuePort: AppConfig.grpcPort,
                valueUpdateHost: (host) {
                  AppConfig.grpcHost.value = host;
                },
                valueUpdatePort: (port) {
                  AppConfig.grpcPort.value = port;
                },
              ),
              const SizedBox(height: 10),

              // ═══════════ 实验性功能 ═══════════
              Card(
                color: AppTheme.settingsCardBg(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ValueListenableBuilder<bool>(
                  valueListenable: AppConfig.experimentalMode,
                  builder: (context, expOn, _) => Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          expOn ? Icons.science : Icons.science_outlined,
                          color: expOn ? Colors.orange : null,
                        ),
                        title: const Text("实验性功能"),
                        subtitle: Text(expOn ? '已开启（风险自负）' : '关闭（推荐）',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context))),
                        value: expOn,
                        onChanged: (v) async {
                          if (v) {
                            final ok = await _showDisclaimer();
                            if (!ok) return;
                          }
                          AppConfig.experimentalMode.value = v;
                        },
                      ),
                      // ★ 实验性功能开启后才显示以下项目
                      if (expOn) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.keyboard_alt_outlined,
                              size: 20),
                          title: const Text("按键映射表"),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          dense: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const KeyMapPage()),
                            );
                          },
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.games_outlined, size: 20),
                          title: const Text("摇杆组件（编辑器内可选）"),
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}