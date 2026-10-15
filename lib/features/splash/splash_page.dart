/// 开屏页：品牌渐变 + Logo 入场，短时自动进入，可轻触跳过。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/app_info.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/brand_logo.dart';
import '../../shared/project_store.dart';
import '../home/home_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    unawaited(projectStore.load());
    _timer = Timer(const Duration(milliseconds: 1300), _enter);
  }

  void _enter() {
    if (!mounted || _left) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: const HomeShell(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final reduce = AppMotion.reduced(context);

    final gradientEnd = Color.lerp(scheme.primary, scheme.tertiary, 0.42)!;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // 柔光装饰
              Positioned(
                top: -80,
                right: -60,
                child: _Glow(color: Colors.white, size: 240),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: _Glow(color: Colors.white, size: 300),
              ),
              Center(
                child: FadeTransition(
                  opacity: reduce ? const AlwaysStoppedAnimation(1) : _fade,
                  child: ScaleTransition(
                    scale: reduce ? const AlwaysStoppedAnimation(1) : _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            boxShadow: context.appColors.shadowLg,
                          ),
                          child: const BrandLogo(size: 108, onPrimary: true),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        Text(
                          AppInfo.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2 + 2),
                        Text(
                          l10n.splashTagline,
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onPrimary.withValues(alpha: 0.9),
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x7),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: scheme.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x6),
                  child: Text(
                    l10n.splashSkip,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
