import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartpet_movil/shared/widgets/location_button.dart';

class FakeLocation extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requested = LocationPermission.whileInUse;
  int requests = 0, positions = 0, appSettings = 0, locationSettings = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positions++;
    return Position(
      longitude: -63.18,
      latitude: -17.78,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    appSettings++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettings++;
    return true;
  }
}

void main() {
  late GeolocatorPlatform original;
  late FakeLocation gps;
  setUp(() {
    original = GeolocatorPlatform.instance;
    gps = FakeLocation();
    GeolocatorPlatform.instance = gps;
  });
  tearDown(() => GeolocatorPlatform.instance = original);
  Future<void> mount(
    WidgetTester tester, {
    ValueChanged<Position>? onLocated,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: LocationButton(onLocated: onLocated ?? (_) {})),
    ),
  );
  Future<void> locate(WidgetTester tester) async {
    await tester.tap(find.text('Usar mi ubicación'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'solo solicita permiso al pulsar y entrega la posición concedida',
    (tester) async {
      Position? result;
      await mount(tester, onLocated: (value) => result = value);
      expect(gps.requests, 0);
      expect(gps.positions, 0);
      await locate(tester);
      expect(gps.requests, 1);
      expect(result?.latitude, -17.78);
      expect(find.textContaining('-17.78'), findsNothing);
    },
  );
  testWidgets('permiso bloqueado ofrece ajustes sin solicitar GPS', (
    tester,
  ) async {
    gps.permission = LocationPermission.deniedForever;
    await mount(tester);
    await locate(tester);
    expect(gps.requests, 0);
    expect(gps.positions, 0);
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(gps.appSettings, 1);
    gps.permission = LocationPermission.whileInUse;
    await locate(tester);
    expect(gps.positions, 1);
  });
  testWidgets('GPS apagado abre ajustes de ubicación y no pide permiso', (
    tester,
  ) async {
    gps.enabled = false;
    await mount(tester);
    await locate(tester);
    expect(gps.requests, 0);
    expect(gps.positions, 0);
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(gps.locationSettings, 1);
  });
  testWidgets('denegar permiso permite reintentar sin obtener posición', (
    tester,
  ) async {
    gps.requested = LocationPermission.denied;
    await mount(tester);
    await locate(tester);
    expect(gps.positions, 0);
    expect(find.textContaining('No se concedió'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsNothing);
    gps.requested = LocationPermission.whileInUse;
    await locate(tester);
    expect(gps.positions, 1);
  });
}
