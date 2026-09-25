import 'package:flutter/material.dart';

import '../base/key_widget.dart';

const _palette = <int>[
  0xFF5C7CFA, 0xFF26A69A, 0xFFFF7043, 0xFFFFCA28,
  0xFFEC407A, 0xFF8D6E63, 0xFF78909C, 0xFFFFFFFF, 0xFF263238,
];

/// 属性面板：实时应用（改一个属性立刻反映到画布上，用户利好）
Future<void> showWidgetPropertySheet({
  required BuildContext context,
  required KeyWidget w,
  required ValueChanged<KeyWidget> onChanged,
  required ValueChanged<int> onReorder, // +1/-1 移一层，±999 置顶/置底
  required VoidCallback onDuplicate,
  required VoidCallback onDelete,
}) {
  var cur = w;

  // ✅ TextField 没有 initialValue 参数（那是 TextFormField 的），
  //    用 controller 携带初始值；关闭弹层时释放，防止泄漏。
  final keyCtrl = TextEditingController(text: cur.key);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: 12 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('组件属性',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ]),

              _label('映射按键'),
              TextField(
                controller: keyCtrl,               // ✅ 修正点
                maxLength: 4,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder()),
                onChanged: (v) {
                  // ★ 面板内没有任何随按键文本变化的 UI，
                  //   不需要 setSheet 整个底栏重建（旧写法每敲一个字符
                  //   就重建整张面板 + 整个编辑器画布，长按/连续输入卡顿）
                  onChanged(cur = cur.copyWith(key: v));
                },
              ),

              _label('形状'),
              SegmentedButton<KShape>(
                segments: const [
                  ButtonSegment(
                      value: KShape.square,
                      label: Text('方形'),
                      icon: Icon(Icons.crop_square)),
                  ButtonSegment(
                      value: KShape.circle,
                      label: Text('圆形'),
                      icon: Icon(Icons.circle_outlined)),
                ],
                selected: {cur.shape},
                onSelectionChanged: (s) {
                  setSheet(() {});
                  onChanged(cur = cur.copyWith(shape: s.first));
                },
              ),

              _label('大小（可超过屏幕 → 分割线玩法）'),
              Row(children: [
                Expanded(
                  child: Slider(
                    min: .05,
                    max: 2.2,
                    divisions: 43,
                    value: cur.size.clamp(.05, 2.2).toDouble(),
                    label: '${(cur.size * 100).round()}%',
                    onChanged: (v) {
                      setSheet(() {});
                      onChanged(cur = cur.copyWith(size: v));
                    },
                  ),
                ),
                Text('${(cur.size * 100).round()}%'),
              ]),

              _label('旋转'),
              Row(children: [
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 360,
                    divisions: 72,
                    value: cur.rotation,
                    label: '${cur.rotation.round()}°',
                    onChanged: (v) {
                      setSheet(() {});
                      onChanged(cur = cur.copyWith(rotation: v));
                    },
                  ),
                ),
                Text('${cur.rotation.round()}°'),
              ]),
              Wrap(spacing: 6, children: [
                for (final a in const [0, 45, 90, 135, 180, 225, 270, 315])
                  ActionChip(
                    label: Text('$a°'),
                    onPressed: () {
                      setSheet(() {});
                      onChanged(cur = cur.copyWith(rotation: a.toDouble()));
                    },
                  ),
              ]),

              _swatches('松开颜色（不填用默认）', cur.idleColor, (c) {
                setSheet(() {});
                onChanged(cur = c == null
                    ? cur.copyWith(clearIdle: true)
                    : cur.copyWith(idleColor: c));
              }),
              _swatches('按下颜色（不填自动派生）', cur.pressedColor, (c) {
                setSheet(() {});
                onChanged(cur = c == null
                    ? cur.copyWith(clearPressed: true)
                    : cur.copyWith(pressedColor: c));
              }),

              _label('层级（后创建在上；可手动调整）'),
              Wrap(spacing: 6, children: [
                OutlinedButton(
                    onPressed: () => onReorder(999), child: const Text('置顶')),
                OutlinedButton(
                    onPressed: () => onReorder(1), child: const Text('上移')),
                OutlinedButton(
                    onPressed: () => onReorder(-1), child: const Text('下移')),
                OutlinedButton(
                    onPressed: () => onReorder(-999), child: const Text('置底')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDuplicate();
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('复制组件'),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(() => keyCtrl.dispose()); // ✅ 关闭弹层后释放 controller
}

Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

Widget _swatches(String title, Color? value, ValueChanged<Color?> onPick) {
  Widget chip(Color? c, bool sel, String label) => GestureDetector(
        onTap: () => onPick(c),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c ?? Colors.transparent,
            border: Border.all(
              color: sel ? Colors.deepOrange : Colors.blueGrey.shade200,
              width: sel ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              label.isEmpty ? null : Text(label, style: const TextStyle(fontSize: 12)),
        ),
      );
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(title),
    Wrap(spacing: 8, runSpacing: 8, children: [
      chip(null, value == null, '默认'),
      for (final p in _palette) chip(Color(p), value?.toARGB32() == p, ''),
    ]),
  ]);
}
