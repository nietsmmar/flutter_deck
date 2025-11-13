import 'package:flutter/material.dart';
import 'package:flutter_deck/src/flutter_deck.dart';
import 'package:flutter_deck/src/flutter_deck_router.dart';
import 'package:flutter_deck/src/widgets/internal/flutter_deck_preview_context.dart';

/// Renders the preview of the current and next slide.
///
/// This widget is used in the presenter view to display the current slide and
/// the next slide.
class FlutterDeckPresenterSlidePreview extends StatelessWidget {
  /// Creates a [FlutterDeckPresenterSlidePreview] widget.
  const FlutterDeckPresenterSlidePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.flutterDeck.router;

    return ListenableBuilder(
      listenable: router,
      builder: (context, child) {
        final FlutterDeckRouter(:currentSlideConfiguration, :currentSlideIndex, :currentStep) = router;
        final slideSteps = currentSlideConfiguration.steps;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: FlutterDeckPreviewContext(
            isPreview: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _SlidePreview(index: currentSlideIndex, step: currentStep, steps: slideSteps),
                ),
                const SizedBox(width: 16),
                Flexible(child: _SlidePreview(index: currentSlideIndex + 1, next: true)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlidePreview extends StatelessWidget {
  const _SlidePreview({required this.index, this.next = false, this.step, this.steps});

  final int index;
  final bool next;
  final int? step;
  final int? steps;

  String _getHeader(int slideCount) {
    var slideInfo = 'Slide ${index + 1} of $slideCount';

    if (step != null && (steps ?? 1) > 1) {
      slideInfo += ' (step $step of $steps)';
    }

    return next ? 'Next: $slideInfo' : 'Current: $slideInfo';
  }

  @override
  Widget build(BuildContext context) {
    final flutterDeck = context.flutterDeck;
    final slideSize = flutterDeck.globalConfiguration.slideSize;
    final slides = flutterDeck.router.slides;
    final aspectRatio = slideSize.isResponsive ? 16 / 9 : slideSize.width! / slideSize.height!;
    final isLastSlide = index >= slides.length;

    final slide = isLastSlide ? null : slides[index];
    final configuration = slide?.configuration;
    final previewBuilder = configuration?.previewBuilder;

    return Column(
      children: [
        Text(isLastSlide ? '' : _getHeader(slides.length)),
        const SizedBox(height: 8),
        Expanded(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: isLastSlide
                ? const Center(child: Text('End of presentation'))
                : previewBuilder != null
                ? previewBuilder(context)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (slideSize.isResponsive) {
                        return slide!.widget;
                      }

                      final scale = constraints.maxWidth / slideSize.width!;

                      return ClipRect(
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: SizedBox(width: slideSize.width, height: slideSize.height, child: slide!.widget),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
