import 'dart:convert';
import 'dart:io'; // gzip；Web 端请换成 package:archive 或去掉压缩
import 'package:flutter/material.dart';
import '../all_template/base/template_document.dart';

/// 模板导入/导出编解码
/// 导出格式：'GKT1.' + base64Url(gzip(json))，比明文 JSON 短 60%+；
/// 导入时校验前缀，失败回退尝试纯 JSON（调试友好）。
class TemplateCodec {
  static const prefix = 'GKT1.';

  static String export(TemplateDraft t) => prefix +
      base64Url.encode(gzip.encode(utf8.encode(jsonEncode(t.toJson()))));

  /// 无效分享码返回 null（调用方负责提示）
  static TemplateDraft? import(String raw) {
    raw = raw.trim();
    try {
      Map<String, dynamic> m;
      if (raw.startsWith(prefix)) {
        m = jsonDecode(utf8.decode(
            gzip.decode(base64Url.decode(raw.substring(prefix.length)))));
      } else if (raw.startsWith('{')) {
        m = jsonDecode(raw); // 高级用户直接贴 JSON
      } else {
        return null;
      }
      return TemplateDraft.fromMap(m); // fromMap 内建钳制（sanitize）
    } catch (e) {
      debugPrint('[codec] 导入失败: $e');
      return null;
    }
  }
}
