import 'dart:convert';
import 'dart:io'; // gzip；Web 端请换成 package:archive 或去掉压缩
import 'package:flutter/material.dart';
import '../all_template/base/template_document.dart';

/// 模板导入/导出编解码（分享链路唯一编解码器）
/// 导出格式：'GKT1.' + base64Url(gzip(json))，比明文 JSON 短 60%+；
/// 导入时校验前缀，失败回退尝试纯 JSON（调试友好）。
///
/// ★ 分享不携带图片：
///   背景图字段 bgImg / bgOpacity、组件图字段 img / imgOp / imgDx / imgDy / imgSc
///   存的都是**导出方本机的绝对路径**，换设备后一定失效（还会指向别人的目录）。
///   所以导出与导入两侧统一剥离，分享码只传几何、按键、颜色、联立链等纯数据。
///   本地存档仍走 TemplateDraft.toJson()，图片配置不受影响。
class TemplateCodec {
  static const prefix = 'GKT1.';

  static String export(TemplateDraft t) =>
      prefix + base64Url.encode(gzip.encode(utf8.encode(jsonEncode(_stripImages(t.toJson())))));

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
      // 旧版分享码可能带图片路径，导入侧也剥掉，避免落一堆失效引用
      return TemplateDraft.fromMap(_stripImages(m)); // fromMap 内建钳制（sanitize）
    } catch (e) {
      debugPrint('[codec] 导入失败: $e');
      return null;
    }
  }

  /// 剥离图片相关字段（原地修改并返回，调用方传入的都是刚构造/刚解析的可变 Map）
  static Map<String, dynamic> _stripImages(Map<String, dynamic> m) {
    m.remove('bgImg');
    m.remove('bgOpacity');
    final ws = m['ws'];
    if (ws is List) {
      for (final w in ws) {
        if (w is Map) {
          w.remove('img');
          w.remove('imgOp');
          w.remove('imgDx');
          w.remove('imgDy');
          w.remove('imgSc');
        }
      }
    }
    return m;
  }
}
