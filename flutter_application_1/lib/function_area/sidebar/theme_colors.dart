import 'package:flutter/material.dart';

/// 中央颜色词典 —— 通过 AppTheme.isDark 全局切换。
/// 所有硬编码颜色应逐步迁移至此，保证暗色模式一致性。
class AppTheme {
  AppTheme._();

  /// 全局暗色模式开关
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  // ═══════════════ 背景 ═══════════════
  static Color scaffoldBg(BuildContext context) =>
      isDark.value ? const Color(0xFF1A1A2E) : const Color(0xFFECEFF1);

  static Color cardBg(BuildContext context) =>
      isDark.value ? const Color(0xFF252540) : Colors.white;

  static Color sidebarBg(BuildContext context) =>
      isDark.value ? const Color(0xFF152238) : const Color.fromARGB(255, 210, 243, 210);

  static Color? appBarBg(BuildContext context) =>
      isDark.value ? const Color(0xFF252540) : null; // null = 用默认   // 承认 Color 可空即可？

  // ═══════════════ 文字 ═══════════════
  static Color textPrimary(BuildContext context) =>
      isDark.value ? const Color(0xFFE0E0E0) : Colors.black87;

  static Color textSecondary(BuildContext context) =>
      isDark.value ? const Color(0xFFA0A0B0) : Colors.black54;

  static Color textHint(BuildContext context) =>
      isDark.value ? const Color(0xFF707088) : Colors.grey;

  // ═══════════════ 强调 / 交互 ═══════════════
  static Color accent(BuildContext context) =>
      isDark.value ? const Color(0xFF7C8FFF) : const Color(0xFF5C7CFA);

  static Color divider(BuildContext context) =>
      isDark.value ? const Color(0xFF2A2A45) : Colors.grey.shade300;

  // ═══════════════ 模板卡片（不受暗色影响） ═══════════════
  static const Color keyboardCard = Color.fromARGB(255, 202, 225, 243);
  static const Color mouseCard = Color.fromARGB(255, 243, 225, 202);

  // ═══════════════ 设置页卡片 ═══════════════
  static Color settingsCardBg(BuildContext context) =>
      isDark.value ? const Color(0xFF2A2A45) : Colors.grey.shade50;

  // ═══════════════ 弹窗 ═══════════════
  static Color dialogBg(BuildContext context) =>
      isDark.value ? const Color(0xFF252540) : Colors.white;

  // ═══════════════ 输入框 ═══════════════
  static Color inputFill(BuildContext context) =>
      isDark.value ? const Color(0xFF1A1A35) : Colors.white;
}