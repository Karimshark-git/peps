import 'package:flutter/material.dart';

/// Scrollable viewport whose **child is at least as tall** as the available
/// height from [LayoutBuilder] (typically the safe area).
///
/// ### Do not combine with vertical flex inside the scroll axis
/// A [SingleChildScrollView] gives its child an **unbounded maximum height**.
/// [Spacer], [Expanded], and [Flexible] in a [Column] inside that child will
/// throw ("incoming height constraints are unbounded" / infinite flex).
///
/// **Instead:** use a [Column] with [MainAxisAlignment.spaceBetween] and
/// group content into top / middle / bottom widgets (each with
/// [MainAxisSize.min] where needed), or use fixed [SizedBox] gaps.
class PepsMinHeightScrollView extends StatelessWidget {
  const PepsMinHeightScrollView({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = child;
        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
