import 'package:flutter/material.dart';

import '../../legal/screens/legal_screen.dart';

import '../../../config/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../services/session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session});
  final Session session;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre, _apellido, _telefono;
  final _password = TextEditingController();
  bool _busy = false, _changePassword = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final user = widget.session.user!;
    _nombre = TextEditingController(text: user.nombre);
    _apellido = TextEditingController(text: user.apellido);
    _telefono = TextEditingController(text: user.telefono);
  }

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.updateProfile({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'telefono': _telefono.text.trim(),
        if (_changePassword) 'password': _password.text,
      });
      if (mounted) {
        _password.clear();
        setState(() => _changePassword = false);
        showMessage(context, 'Tu perfil se actualizó.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mi espacio',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.mint,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(user.email, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    const Text(
                      'Ciudadano',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (final item in [
                (_nombre, 'Nombre'),
                (_apellido, 'Apellido'),
              ]) ...[
                TextFormField(
                  controller: item.$1,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: item.$2),
                  maxLength: 100,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Completa este campo.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _telefono,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _changePassword,
                title: const Text('Cambiar contraseña'),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _changePassword = value),
              ),
              if (_changePassword)
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 72,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                  validator: (v) => v == null || v.length < 8
                      ? 'Usa al menos 8 caracteres.'
                      : null,
                ),
              if (_error != null) InlineMessage(_error!),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_busy ? 'Guardando…' : 'Guardar cambios'),
                ),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        if (!await confirmAction(
                              context,
                              title: '¿Cerrar sesión?',
                              message: 'Podrás volver a entrar con tu correo y contraseña.',
                              confirmLabel: 'Cerrar sesión',
                            ) ||
                            !mounted) {
                          return;
                        }
                        await widget.session.logout();
                      },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
              const LegalLinks(),
            ],
          ),
        ),
      ),
    );
  }
}
