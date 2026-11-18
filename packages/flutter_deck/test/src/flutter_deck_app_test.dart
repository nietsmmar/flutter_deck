import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('FlutterDeckApp', () {
    group('when slides list is empty', () {
      test('should throw [AssertionError]', () {
        expect(
          () => FlutterDeckApp(slides: const [], materialTheme: ThemeData.light()),
          throwsA(isA<AssertionError>().having((e) => e.message, 'message', 'You must provide at least one slide')),
        );
      });
    });

    group('adding NavigatorObservers', () {
      testWidgets('adds nothing by default', (tester) async {
        await tester.pumpWidget(FlutterDeckApp(slides: [Container()], materialTheme: ThemeData.light()));

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        final delegate = app.routerConfig!.routerDelegate as GoRouterDelegate;

        expect(delegate.builder.observers, isEmpty);
      });

      testWidgets('adds observer that registers slide changes', (tester) async {
        final myObserver = MyObserver();

        await tester.pumpWidget(
          FlutterDeckApp(
            slides: [Container(), Container()],
            materialTheme: ThemeData.light(),
            navigatorObservers: [myObserver],
          ),
        );

        expect(myObserver.changes, hasLength(1));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(myObserver.changes, hasLength(2));
      });
    });

    testWidgets('does not expose a platform-reporting provider when embedded', (tester) async {
      final outerRouter = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (context, state) =>
                FlutterDeckApp(slides: [Container(), Container()], materialTheme: ThemeData.light()),
          ),
        ],
      );
      addTearDown(outerRouter.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: outerRouter));
      await tester.pumpAndSettle();

      final apps = tester.widgetList<MaterialApp>(find.byType(MaterialApp)).toList();
      final embeddedApp = apps.last;

      expect(embeddedApp.routerConfig, isNull);
      expect(embeddedApp.routeInformationProvider, isNotNull);
      expect(embeddedApp.routeInformationProvider, isNot(same(outerRouter.routeInformationProvider)));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(embeddedApp.routeInformationProvider!.value.uri.path, '/slide-2');
      expect(outerRouter.routeInformationProvider.value.uri.path, '/host');
    });
  });
}

class MyObserver extends NavigatorObserver {
  final changes = <Route>[];

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    changes.add(topRoute);
  }
}
