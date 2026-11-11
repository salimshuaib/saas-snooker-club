import 'dart:ui';

import 'package:flutter/material.dart';

class AppModal {
  static Widget _blurTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.12),
          child: child,
        ),
      ),
    );
  }

  static Future<T?> showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = const Color(0x59000000),
    bool useRootNavigator = true,
    Duration transitionDuration = const Duration(milliseconds: 220),
    Color? backgroundColor,
    double? insetPadding,
    ShapeBorder? shape,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (dialogContext, __, ___) {
        final child = builder(dialogContext);
        if (backgroundColor == null && shape == null) {
          return child;
        }
        return Center(
          child: Material(
            color: backgroundColor ?? Colors.transparent,
            shape: shape,
            clipBehavior: shape != null ? Clip.antiAlias : Clip.none,
            child: child,
          ),
        );
      },
      transitionBuilder: _blurTransitionBuilder,
    );
  }

  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = const Color(0x59000000),
    bool useRootNavigator = true,
    bool isScrollControlled = false,
    double? maxWidth,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, __, ___) {
        final bottomSheetContent = builder(dialogContext);
        final child = Material(
          color: backgroundColor ?? Colors.transparent,
          shape: shape,
          clipBehavior: shape != null ? Clip.antiAlias : Clip.none,
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isScrollControlled
                    ? MediaQuery.viewInsetsOf(context).bottom
                    : 0,
              ),
              child: bottomSheetContent,
            ),
          ),
        );
        final isDesktop = MediaQuery.sizeOf(dialogContext).width > 800;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? (isDesktop ? 680 : double.infinity),
            ),
            child: child,
          ),
        );
      },
      transitionBuilder: _blurTransitionBuilder,
    );
  }
}
