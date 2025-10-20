import 'package:flutter/widgets.dart';

/// An inherited widget that provides a preview context to its descendants.
///
/// This widget is used to signal to the slide that it is being rendered in a
/// preview context, and that it should hide its controls.
class FlutterDeckPreviewContext extends InheritedWidget {
  /// Creates a new [FlutterDeckPreviewContext].
  const FlutterDeckPreviewContext({
    required super.child,
    this.isPreview = false,
    super.key,
  });

  /// Whether the slide is being rendered in a preview context.
  final bool isPreview;

  /// Returns the [FlutterDeckPreviewContext] from the given [context].
  static FlutterDeckPreviewContext? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlutterDeckPreviewContext>();

  @override
  bool updateShouldNotify(FlutterDeckPreviewContext oldWidget) =>
      oldWidget.isPreview != isPreview;
}
