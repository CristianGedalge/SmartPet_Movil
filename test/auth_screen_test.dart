import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/auth/screens/auth_screen.dart';
import 'package:smartpet_movil/features/auth/models/pending_email_verification.dart';
import 'package:smartpet_movil/features/auth/screens/email_verification_screen.dart';
import 'package:smartpet_movil/features/legal/screens/legal_screen.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required Future<PendingEmailVerification?> Function(Map<String, dynamic>)
    submit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AuthScreen(
          onLogin: submit,
          onRegister: submit,
          onVerifyEmail: (_, _) async {},
          onResendCode: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('formulario no envía credenciales vacías ni correo inválido', (
    tester,
  ) async {
    var calls = 0;
    await open(
      tester,
      submit: (_) async {
        calls++;
        return null;
      },
    );
    await tapSubmit(tester, 'Iniciar sesión');
    expect(calls, 0);
    await tester.enterText(find.byKey(const ValueKey('email')), 'invalid');
    await tester.enterText(find.byKey(const ValueKey('password')), 'password');
    await tapSubmit(tester, 'Iniciar sesión');
    expect(calls, 0);
    expect(find.text('Escribe un correo electrónico válido.'), findsOneWidget);
  });

  testWidgets(
    'registro envía únicamente datos de ciudadano, sin rol ni establecimiento',
    (tester) async {
      Map<String, dynamic>? sent;
      await open(
        tester,
        submit: (value) async {
          sent = value;
          return null;
        },
      );
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      for (final entry in {
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'email': 'ANA@example.com',
        'password': '  Password123  ',
      }.entries) {
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await tapSubmit(tester, 'Crear mi cuenta');
      expect(sent, isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Crear mi cuenta'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('accept-terms')));
      await tester.tap(find.byKey(const ValueKey('accept-terms')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Crear mi cuenta'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Política de privacidad'),
      );
      await tester.tap(
        find.widgetWithText(TextButton, 'Política de privacidad'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LegalScreen), findsOneWidget);
      expect(find.textContaining('Versión $legalVersion'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('accept-terms')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('accept-privacy')),
            )
            .value,
        isFalse,
      );
      expect(find.text('ANA@example.com'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('accept-privacy')));
      await tester.tap(find.byKey(const ValueKey('accept-privacy')));
      await tester.pumpAndSettle();
      await tapSubmit(tester, 'Crear mi cuenta');
      expect(sent, {
        'aceptaTerminos': true,
        'aceptaPrivacidad': true,
        'versionLegal': legalVersion,
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'email': 'ana@example.com',
        'password': '  Password123  ',
      });
      expect(sent!.containsKey('rol'), isFalse);
      expect(sent!.containsKey('establecimiento'), isFalse);
    },
  );

  testWidgets('error conserva entradas y bloqueo evita enviar dos veces', (
    tester,
  ) async {
    final pending = Completer<PendingEmailVerification?>();
    var calls = 0;
    await open(
      tester,
      submit: (_) {
        calls++;
        return pending.future;
      },
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password')),
      'Password123',
    );
    await tapSubmit(tester, 'Iniciar sesión');
    expect(calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    pending.completeError('Credenciales inválidas.');
    await tester.pumpAndSettle();
    expect(
      find.text('Ocurrió un problema. Intenta nuevamente.'),
      findsOneWidget,
    );
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('una autenticación pendiente abre la pantalla de código', (
    tester,
  ) async {
    await open(
      tester,
      submit: (_) async => const PendingEmailVerification(
        email: 'ana@example.com',
        maskedEmail: 'an*@example.com',
        emailSent: false,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password')),
      'Password123',
    );
    await tapSubmit(tester, 'Iniciar sesión');
    await tester.pumpAndSettle();
    expect(find.byType(EmailVerificationScreen), findsOneWidget);
    expect(find.textContaining('an*@example.com'), findsOneWidget);
  });

  testWidgets('el formulario admite pantalla estrecha y texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AuthScreen(
            onLogin: (_) async => null,
            onRegister: (_) async => null,
            onVerifyEmail: (_, _) async {},
            onResendCode: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
