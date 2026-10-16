/// 列表 / 卡片入场 stagger：逐项淡入 + 轻微上移。
///
/// 设计约束（见 v1.3.1 计划 M4）：
/// - 相邻项延迟固定 [AppDur.staggerStep]（24ms）；
/// - 整段动效（含最后一项自身时长）不超过 [AppDur.staggerMax]（300ms），
///   所以延迟会被截断，长列表不会让最后一项等很久；
/// - 不引入 `Timer` / `Future.delayed`：延迟由单个 controller 的
///   [Interval] 表达，避免测试里出现「仍有计时器」；
/// - 系统开启 reduced-motion 时直接落到终态，不做任何动画。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// 单项入场包装：把它套在列表项外面，并传入该项在列表中的 [index]。
///
/// 惰性列表（`ListView.builder` / `SliverList`）可以直接在 builder 里使用，
/// 每项自带一个 controller，只对已构建的项生效。
class StaggeredItem extends StatefulWidget {
  /// 在列表中的序号（决定延迟）。
  final int index;

  /// 相邻项之间的延迟。
  final Duration interval;

  /// 单项动效时长。
  final Duration duration;

  /// 起始纵向偏移（向上归位）。
  final double offset;

  final Widget child;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.interval = AppDur.staggerStep,
    this.duration = AppDur.fast,
    this.offset = 8,
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  bool _started = false;

  /// 本项延迟：受总时长上限约束，且不为负。
  Duration get _delay {
    final raw = widget.interval * widget.index;
    final maxDelay = AppDur.staggerMax - widget.duration;
    if (maxDelay <= Duration.zero) return Duration.zero;
    return raw > maxDelay ? maxDelay : raw;
  }

  @override
  void initState() {
    super.initState();
    final total = _delay + widget.duration;
    _c = AnimationController(vsync: this, duration: total);
    final begin = total.inMicroseconds == 0
        ? 0.0
        : _delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(begin.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // reduced-motion：直接落到终态
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value.clamp(0.0, 1.0);
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}

/// 固定一组子项的便捷包装：按顺序逐项入场。
///
/// 只适用于已经拿到全部子节点、且愿意用 [Column] 排布的场景；
/// sliver / builder 列表请直接在 builder 里用 [StaggeredItem]。
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration interval;
  final Duration duration;
  final double offset;

  const StaggeredList({
    super.key,
    required this.children,
    this.interval = AppDur.staggerStep,
    this.duration = AppDur.fast,
    this.offset = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          StaggeredItem(
            index: i,
            interval: interval,
            duration: duration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}
