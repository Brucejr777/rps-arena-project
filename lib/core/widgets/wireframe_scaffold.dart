import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Common scaffold wrapper matching the wireframe layout:
/// - SafeArea with consistent padding
/// - Bottom frame indicator (pill bar)
/// - Screen title with back button
class WireframeScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showFrameIndicator;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool useSafeArea;

  const WireframeScaffold({
    super.key,
    this.title,
    required this.child,
    this.floatingActionButton,
    this.backgroundColor = AppColors.background,
    this.showFrameIndicator = true,
    this.bottomNavigationBar,
    this.appBar,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar ?? (title != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _WireframeTopNav(title: title!),
            )
          : null),
      body: Column(
        children: [
          Expanded(
            child: useSafeArea
                ? SafeArea(
                    top: false,
                    bottom: false,
                    child: child,
                  )
                : child,
          ),
          if (showFrameIndicator) const _WireframeFrameIndicator(),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Top navigation bar matching wireframe design
class _WireframeTopNav extends StatelessWidget {
  final String title;

  const _WireframeTopNav({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          children: [
            // Blue circle back button matching wireframe
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.5,
                    color: AppColors.blue,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// Bottom frame indicator (pill bar) from wireframes
class _WireframeFrameIndicator extends StatelessWidget {
  const _WireframeFrameIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}
