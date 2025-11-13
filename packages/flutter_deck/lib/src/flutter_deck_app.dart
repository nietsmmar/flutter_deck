import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deck/src/configuration/configuration.dart';
import 'package:flutter_deck/src/controls/controls.dart';
import 'package:flutter_deck/src/controls/fullscreen/window_proxy/window_proxy.dart';
import 'package:flutter_deck/src/flutter_deck.dart';
import 'package:flutter_deck/src/flutter_deck_router.dart';
import 'package:flutter_deck/src/flutter_deck_slide.dart';
import 'package:flutter_deck/src/flutter_deck_speaker_info.dart';
import 'package:flutter_deck/src/presenter/presenter.dart';
import 'package:flutter_deck/src/theme/flutter_deck_theme.dart';
import 'package:flutter_deck/src/theme/flutter_deck_theme_notifier.dart';
import 'package:flutter_deck/src/widgets/internal/internal.dart';
import 'package:flutter_deck_client/flutter_deck_client.dart';
import 'package:go_router/go_router.dart';

const _defaultLocale = Locale('en');

/// The main widget of a slide deck.
///
/// This widget is an entry point to the slide deck. It is responsible for
/// displaying the slides, and handling the navigation between them.
///
/// It is recommended to use the [FlutterDeckApp] as the root widget of your
/// app. This widget will create a [MaterialApp] with the correct theme, will
/// build the router, keyboard shortcuts, and will provide the [FlutterDeck] to
/// all the widgets in the tree.
class FlutterDeckApp extends StatefulWidget {
  /// Creates a new slide deck.
  ///
  /// The [slides] argument must not be null, and must contain at least one
  /// slide.
  ///
  /// The [configuration] argument can be used to provide a global configuration
  /// for the slide deck. This configuration will be used for all slides, unless
  /// a slide has its own configuration.
  ///
  /// The [speakerInfo] argument can be used to provide information about the
  /// speaker. This information will be displayed in the title slide as well as
  /// the footer of all slides.
  ///
  /// The [locale], [localizationsDelegates] and [supportedLocales] arguments
  /// are equivalent to those of [MaterialApp]'s.
  ///
  /// The [client] argument provides a client to use for the presenter view. The
  /// [isPresenterView] argument is used to determine if the app should run
  /// as a presenter view. If this argument is provided, the [client] argument
  /// must also be provided.
  ///
  /// See also:
  ///
  /// * [FlutterDeckSlide], which represents a single slide.
  /// * [FlutterDeckConfiguration], which represents a global configuration for
  /// the slide deck.
  /// * [FlutterDeckSlideConfiguration], which represents a configuration for a
  /// single slide.
  /// * [FlutterDeckThemeData], which represents a theme for the slide deck.
  /// * [FlutterDeckSpeakerInfo], which represents information about the
  /// speaker.
  const FlutterDeckApp({
    required this.slides,
    required this.materialTheme,
    this.client,
    this.configuration = const FlutterDeckConfiguration(),
    this.speakerInfo,
    this.locale = _defaultLocale,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[_defaultLocale],
    bool? isPresenterView,
    this.navigatorObservers,
    super.key,
  }) : assert(slides.length > 0, 'You must provide at least one slide'),
       assert(isPresenterView == null || client != null, 'You must provide a client when providing isPresenterView'),
       isPresenterView = !kIsWeb ? isPresenterView : null;

  /// The client to use for the presenter view.
  final FlutterDeckClient? client;

  /// A global configuration for the slide deck.
  ///
  /// This configuration will be used for all slides, unless a slide has its own
  /// configuration.
  ///
  /// If not provided, the default [FlutterDeckConfiguration] is used.
  ///
  /// See also:
  ///
  /// * [FlutterDeckSlideConfiguration], which can be used to override the
  ///  global configuration for a specific slide.
  final FlutterDeckConfiguration configuration;

  /// The slides to use in the slide deck.
  ///
  /// The order of the slides determines the order in which they will be
  /// displayed. The first slide will be displayed when the app is first opened.
  final List<Widget> slides;

  /// Information about the speaker.
  final FlutterDeckSpeakerInfo? speakerInfo;

  /// The initial locale for the slide deck. Defaults to English (Locale('en')).
  ///
  /// See also:
  /// * [MaterialApp.locale], which is equivalent to this argument.
  final Locale locale;

  /// The delegates for the slide deck's localization.
  ///
  /// See also:
  /// * [MaterialApp.localizationsDelegates], which is equivalent to this
  /// argument.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// The list of locales that the slide deck has been localized for. Defaults
  /// to English ([Locale('en')]).
  ///
  /// See also:
  /// * [MaterialApp.supportedLocales], which is equivalent to this argument.
  final Iterable<Locale> supportedLocales;

  /// A material theme to use for the slide deck.
  ///
  /// If not provided, the default light and dark themes will be used.
  final ThemeData materialTheme;

  /// Whether the app should run as a presenter view.
  ///
  /// This argument is only used on non-web platforms. On the web, the app will
  /// automatically determine if it should run as a presenter view based on the
  /// URL.
  final bool? isPresenterView;

  /// An optional list of [NavigatorObserver]s that will be added to the router.
  final List<NavigatorObserver>? navigatorObservers;

  @override
  State<FlutterDeckApp> createState() => _FlutterDeckAppState();
}

class _FlutterDeckAppState extends State<FlutterDeckApp> {
  late FlutterDeckRouter _flutterDeckRouter;
  late GoRouter _router;

  late FlutterDeckAutoplayNotifier _autoplayNotifier;
  late FlutterDeckControlsNotifier _controlsNotifier;
  late FlutterDeckDrawerNotifier _drawerNotifier;
  late FlutterDeckLocalizationNotifier _localizationNotifier;
  late FlutterDeckMarkerNotifier _markerNotifier;
  late FlutterDeckPresenterController _presenterController;
  late FlutterDeckThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();

    _buildRouter();

    _autoplayNotifier = FlutterDeckAutoplayNotifier(router: _flutterDeckRouter);
    _drawerNotifier = FlutterDeckDrawerNotifier();
    _markerNotifier = FlutterDeckMarkerNotifier();
    _controlsNotifier = FlutterDeckControlsNotifier(
      autoplayNotifier: _autoplayNotifier,
      drawerNotifier: _drawerNotifier,
      markerNotifier: _markerNotifier,
      fullscreenManager: FlutterDeckFullscreenManager(WindowProxy()),
      router: _flutterDeckRouter,
    );
    _localizationNotifier = FlutterDeckLocalizationNotifier(
      locale: widget.locale,
      supportedLocales: widget.supportedLocales,
    );
    _themeNotifier = FlutterDeckThemeNotifier(ThemeMode.system);
    _presenterController = FlutterDeckPresenterController(
      client: widget.client,
      controlsNotifier: _controlsNotifier,
      localizationNotifier: _localizationNotifier,
      markerNotifier: _markerNotifier,
      themeNotifier: _themeNotifier,
      router: _flutterDeckRouter,
    );

    if (widget.client != null && !(widget.isPresenterView ?? true)) {
      _presenterController.init();
    }
  }

  @override
  void didUpdateWidget(covariant FlutterDeckApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.slides, widget.slides)) {
      final slides = widget.slides.where(_filterHidden).indexed.map(_buildRouterSlide).toList();
      _flutterDeckRouter.updateSlides(slides);
      _router = _flutterDeckRouter.build(
        isPresenterView: widget.isPresenterView,
        navigatorObservers: widget.navigatorObservers,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _presenterController.dispose();

    super.dispose();
  }

  bool _filterHidden(Widget slide) => slide is! FlutterDeckSlideWidget || !(slide.configuration?.hidden ?? false);

  FlutterDeckRouterSlide _buildRouterSlide((int, Widget) indexedSlide) {
    final (index, slide) = indexedSlide;
    final defaultConfiguration = FlutterDeckSlideConfiguration(route: '/slide-${index + 1}');

    var slideWidget = slide;

    if (slideWidget is! FlutterDeckSlideWidget) {
      slideWidget = slide.withSlideConfiguration(defaultConfiguration);
    }

    final configuration = slideWidget.configuration ?? defaultConfiguration;

    return FlutterDeckRouterSlide(
      configuration: configuration.mergeWithGlobal(widget.configuration),
      route: configuration.route,
      widget: slideWidget,
    );
  }

  void _buildRouter() {
    final slides = widget.slides.where(_filterHidden).indexed.map(_buildRouterSlide).toList();

    _flutterDeckRouter = FlutterDeckRouter(slides: slides);
    _router = _flutterDeckRouter.build(
      isPresenterView: widget.isPresenterView,
      navigatorObservers: widget.navigatorObservers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _localizationNotifier,
      builder: (context, locale, _) => ValueListenableBuilder(
        valueListenable: _themeNotifier,
        builder: (context, themeMode, _) => MaterialApp.router(
          routerConfig: _router,
          theme: widget.materialTheme,
          builder: (context, child) => FlutterDeck(
            configuration: widget.configuration,
            router: _flutterDeckRouter,
            speakerInfo: widget.speakerInfo,
            autoplayNotifier: _autoplayNotifier,
            controlsNotifier: _controlsNotifier,
            drawerNotifier: _drawerNotifier,
            localizationNotifier: _localizationNotifier,
            markerNotifier: _markerNotifier,
            presenterController: _presenterController,
            themeNotifier: _themeNotifier,
            child: FlutterDeckControlsListener(
              controlsNotifier: _controlsNotifier,
              markerNotifier: _markerNotifier,
              child: FlutterDeckTheme(data: FlutterDeckThemeData.fromTheme(widget.materialTheme), child: child!),
            ),
          ),
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: widget.localizationsDelegates,
          supportedLocales: widget.supportedLocales,
        ),
      ),
    );
  }
}
