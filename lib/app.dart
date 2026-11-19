import 'features/avistamientos/screens/sightings_screen.dart';
import 'features/avistamientos/services/sightings_service.dart';
import 'features/adopciones/screens/adoptions_screen.dart';
import 'features/adopciones/services/adoptions_service.dart';
import 'features/chat/services/chat_service.dart';
import 'features/chat/screens/chat_inbox_screen.dart';
import 'features/busqueda_visual/screens/visual_search_screen.dart';
import 'features/busqueda_visual/services/visual_search_service.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/auth/services/session.dart';
import 'features/inicio/screens/home_screen.dart';
import 'features/mascotas/screens/pets_screen.dart';
import 'features/mascotas/services/pets_service.dart';
import 'features/alertas/screens/alerts_screen.dart';
import 'features/alertas/screens/alert_detail_screen.dart';
import 'features/alertas/services/alerts_service.dart';
import 'shared/widgets/app_widgets.dart';

class SmartPetApp extends StatefulWidget {
  const SmartPetApp({super.key, required this.config, required this.session});
  final ApiConfig config;
  final Session session;
  @override
  State<SmartPetApp> createState() => _SmartPetAppState();
}

class _SmartPetAppState extends State<SmartPetApp> {
  final _privateNavigator = GlobalKey<NavigatorState>();
  @override
  void dispose() {
    widget.session.dispose();
    widget.session.api.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(widget.session.restore());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SmartPet',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        if (session.restoring) {
          return const Scaffold(
            body: LoadingPanel(message: 'Preparando tu espacio…'),
          );
        }
        if (session.restoreError != null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ErrorPanel(
                        message: session.restoreError!,
                        onRetry: session.restore,
                      ),
                      TextButton(
                        onPressed: session.logout,
                        child: const Text('Volver a ingresar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (session.user == null) {
          return AuthScreen(
            logo: SvgPicture.asset('assets/smartpet-icon.svg'),
            onLogin: session.authenticate,
            onRegister: (data) => session.authenticate(data, register: true),
          );
        }
        // Replacing this Navigator discards every private route/dialog on logout.
        return NavigatorPopHandler<Object?>(
          onPopWithResult: (result) {
            _privateNavigator.currentState?.maybePop(result);
          },
          child: Navigator(
            key: _privateNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) =>
                  _CitizenShell(session: session, config: widget.config),
            ),
          ),
        );
      },
    ),
  );
}

class _CitizenShell extends StatefulWidget {
  const _CitizenShell({required this.session, required this.config});
  final Session session;
  final ApiConfig config;
  @override
  State<_CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<_CitizenShell> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    super.dispose();
  }

  int _index = 0;
  late final _pets = PetsService(widget.session.api);
  late final _alerts = AlertsService(widget.session.api);
  late final _sightings = SightingsService(widget.session.api);
  late final _adoptions = AdoptionsService(widget.session.api);
  void _go(int index) => setState(() => _index = index);
  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    if (user == null) return const SizedBox.shrink();
    final pages = [
      HomeScreen(
        user: user,
        alerts: _alerts,
        onPets: () => _go(1),
        onAlerts: () => _go(2),
        onAdoptions: () => _go(4),
        onAlert: (alert) => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => AlertDetailScreen(
              id: alert.id,
              mine: false,
              service: _alerts,
              pets: _pets,
              styleUrl: widget.config.mapStyleUrl,
            ),
          ),
        ),
      ),
      PetsScreen(service: _pets),
      AlertsScreen(
        service: _alerts,
        pets: _pets,
        styleUrl: widget.config.mapStyleUrl,
      ),
      SightingsScreen(service: _sightings, styleUrl: widget.config.mapStyleUrl),
      AdoptionsScreen(service: _adoptions),
    ];
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _go(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/smartpet-icon.svg',
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'SmartPet',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Buscar por foto',
              icon: const Icon(Icons.image_search_rounded),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => VisualSearchScreen(
                    service: VisualSearchService(widget.session.api),
                    sightings: _sightings,
                    styleUrl: widget.config.mapStyleUrl,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mensajes',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatInboxScreen(service: ChatService(widget.session.api)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                tooltip: 'Mi perfil',
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Mi perfil')),
                      body: SafeArea(
                        child: ProfileScreen(session: widget.session),
                      ),
                    ),
                  ),
                ),
                icon: CircleAvatar(
                  backgroundColor: AppColors.mint,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Color(0xFF008F73),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(index: _index, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded),
              label: 'Mascotas',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Alertas',
            ),
            NavigationDestination(
              icon: Icon(Icons.visibility_outlined),
              selectedIcon: Icon(Icons.visibility),
              label: 'Avistamientos',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Adopciones',
            ),
          ],
        ),
      ),
    );
  }
}
