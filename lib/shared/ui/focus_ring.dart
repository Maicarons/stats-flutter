/// 键盘焦点环：把「是否应显示焦点环」交给 [FocusRing.builder]。
///
/// 为什么不用 `FocusableActionDetector` 自己包一层：它默认
/// `canRequestFocus: enabled`，会在子树里多插一个 Tab 停靠点，
/// 于是卡片 / 列表项会被 Tab 访问两次。这里用 `canRequestFocus: false`
/// + `skipTraversal: true` 的 [Focus]，只**观察**子树焦点、不参与遍历；
/// 真正的焦点与回车/空格激活仍然由内部 `InkWell` 负责。
///
/// 只在「传统导航模式」（键盘 / 遥控器）下报 `true`：鼠标与触摸点击
/// 不会留下常驻焦点环，同时焦点环与 hover 态视觉可区分。
library;

import 'package:flutter/material.dart';

class FocusRing extends StatefulWidget {
  /// [focused] 为 true 时调用方应画出焦点环。
  final Widget Function(BuildContext context, bool focused) builder;

  const FocusRing({super.key, required this.builder});

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _hasFocus = false;
  bool _traditional =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  bool get _show => _hasFocus && _traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    if (hasFocus == _hasFocus) return;
    setState(() => _hasFocus = hasFocus);
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    final traditional = mode == FocusHighlightMode.traditional;
    if (traditional == _traditional) return;
    setState(() => _traditional = traditional);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      child: widget.builder(context, _show),
    );
  }
}
