import 'package:flutter/widgets.dart';

/// Connects an embedded router to its in-memory route information while
/// preventing it from consuming or publishing the host application's URL.
class NonReportingRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  /// Creates an adapter around the nested router's route information source.
  NonReportingRouteInformationProvider(this._source) : _value = _source.value {
    _source.addListener(_handleSourceChanged);

    // The wrapped GoRouter provider registers as a WidgetsBindingObserver while it has
    // listeners. Remove it so only the host router consumes platform URL changes.
    if (_source case final WidgetsBindingObserver observer) {
      WidgetsBinding.instance.removeObserver(observer);
    }
  }

  final RouteInformationProvider _source;
  RouteInformation _value;

  @override
  RouteInformation get value => _value;

  void _handleSourceChanged() {
    _value = _source.value;
    notifyListeners();
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _value = routeInformation;
  }

  @override
  void dispose() {
    _source.removeListener(_handleSourceChanged);
    super.dispose();
  }
}
