/// 加载骨架屏：替代裸 CircularProgressIndicator，减少内容跳动。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// 单个骨架块（呼吸动画）。
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = AppMotion.reduced(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = reduce ? 0.5 : 0.35 + _ctrl.value * 0.35;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.06 + t * 0.06),
            borderRadius: widget.radius ?? AppRadius.rSm,
          ),
        );
      },
    );
  }
}

/// 列表骨架（头像 + 两行文字）。
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 5,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2 + 2),
      itemBuilder: (_, __) => Row(
        children: [
          const SkeletonBox(width: 46, height: 46, radius: AppRadius.rMd),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 180),
                SizedBox(height: AppSpacing.x2),
                SkeletonBox(width: 110, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 表格骨架。
class SkeletonTable extends StatelessWidget {
  final int rows;
  final int columns;

  const SkeletonTable({super.key, this.rows = 6, this.columns = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            child: Row(
              children: [
                for (var c = 0; c < columns; c++) ...[
                  Expanded(
                    child: SkeletonBox(
                      height: 12,
                      width: c == 0 ? 90 : double.infinity,
                    ),
                  ),
                  if (c != columns - 1) const SizedBox(width: AppSpacing.x3),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
