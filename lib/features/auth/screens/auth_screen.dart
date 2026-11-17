import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    this.logo,
  });
  final Future<void> Function(Map<String, dynamic> credentials) onLogin;
  final Future<void> Function(Map<String, dynamic> registration) onRegister;
  final Widget? logo;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _hidden = true;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _apellido,
      _email,
      _telefono,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _requiredName(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este campo.' : null;

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final credentials = <String, dynamic>{
      'email': _email.text.trim().toLowerCase(),
      'password': _password.text,
    };
    try {
      if (_register) {
        await widget.onRegister({
          ...credentials,
          'nombre': _nombre.text.trim(),
          'apellido': _apellido.text.trim(),
          if (_telefono.text.trim().isNotEmpty)
            'telefono': _telefono.text.trim(),
        });
      } else {
        await widget.onLogin(credentials);
      }
    } catch (failure) {
      if (mounted) setState(() => _error = failure.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.logo != null) ...[
                          SizedBox(width: 44, height: 44, child: widget.logo),
                          const SizedBox(width: 10),
                        ],
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'SmartPet',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'CERCA DE SUS HUELLAS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF008F73),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _register
                          ? 'Un nuevo comienzo,\njuntos.'
                          : 'Su hogar empieza\ncontigo.',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _register
                          ? 'Crea tu cuenta para cuidar a tus mascotas y acompañar a tu comunidad.'
                          : 'Tus mascotas, sus historias y una comunidad que las cuida.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (final register in [false, true])
                          ChoiceChip(
                            label: Text(register ? 'Crear cuenta' : 'Ingresar'),
                            selected: _register == register,
                            selectedColor: AppColors.mint,
                            shape: const StadiumBorder(),
                            onSelected: _busy
                                ? null
                                : (_) => setState(() {
                                    _register = register;
                                    _error = null;
                                    _form.currentState?.reset();
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_register) ...[
                            TextFormField(
                              key: const ValueKey('nombre'),
                              controller: _nombre,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                              ),
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.givenName],
                              maxLength: 100,
                              validator: _requiredName,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const ValueKey('apellido'),
                              controller: _apellido,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                              ),
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.familyName],
                              maxLength: 100,
                              validator: _requiredName,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            key: const ValueKey('email'),
                            controller: _email,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            maxLength: 150,
                            validator: (value) =>
                                value == null ||
                                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(value.trim())
                                ? 'Escribe un correo electrónico válido.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (_register) ...[
                            TextFormField(
                              key: const ValueKey('telefono'),
                              controller: _telefono,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono (opcional)',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              maxLength: 20,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            key: const ValueKey('password'),
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _hidden,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _hidden
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                                icon: Icon(
                                  _hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            autofillHints: [
                              _register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            maxLength: 72,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Escribe tu contraseña.'
                                : _register && value.length < 8
                                ? 'Usa al menos 8 caracteres.'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            InlineMessage(_error!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      _register
                                          ? 'Crear mi cuenta'
                                          : 'Iniciar sesión',
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pequeñas huellas. Grandes historias.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
