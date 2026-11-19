import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_theme.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/pending_email_verification.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.pending,
    required this.onVerify,
    required this.onResend,
  });

  final PendingEmailVerification pending;
  final Future<void> Function(String email, String code) onVerify;
  final Future<void> Function(String email) onResend;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  Timer? _timer;
  late int _seconds = widget.pending.emailSent ? 60 : 0;
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (_seconds > 0) _startCountdown();
    if (!widget.pending.emailSent) {
      _error =
          'No pudimos enviar el primer código. Puedes solicitar uno nuevo.';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_verifying || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.onVerify(widget.pending.email, _code.text.trim());
    } catch (failure) {
      if (mounted) setState(() => _error = userErrorMessage(failure));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _seconds > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.onResend(widget.pending.email);
      if (!mounted) return;
      setState(() {
        _seconds = 60;
        _message =
            'Enviamos un código nuevo. Revisa también el correo no deseado.';
      });
      _startCountdown();
    } catch (failure) {
      if (mounted) setState(() => _error = userErrorMessage(failure));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_verifying && !_resending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.mint,
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 34,
                        color: Color(0xFF008F73),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Revisa tu bandeja de entrada',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Escribe el código de 6 dígitos que enviamos a ${widget.pending.maskedEmail}. Vence en 10 minutos.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      key: const ValueKey('verification-code'),
                      controller: _code,
                      enabled: !_verifying,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Código de verificación',
                        counterText: '',
                      ),
                      maxLength: 6,
                      onFieldSubmitted: (_) => _verify(),
                      validator: (value) =>
                          value == null || !RegExp(r'^\d{6}$').hasMatch(value)
                          ? 'Ingresa los 6 dígitos del correo.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      InlineMessage(_error!),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      InlineMessage(_message!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _verifying ? null : _verify,
                      child: _verifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Verificar y continuar'),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resending || _seconds > 0 ? null : _resend,
                      child: Text(
                        _resending
                            ? 'Enviando…'
                            : _seconds > 0
                            ? 'Reenviar en ${_seconds}s'
                            : 'Enviar otro código',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Al verificar tu correo recibirás una bienvenida con los enlaces a Términos y Privacidad.',
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
