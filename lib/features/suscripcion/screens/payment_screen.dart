import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_theme.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/plan_offer.dart';
import '../services/subscription_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.plan,
    required this.service,
    required this.defaultHolder,
  });

  final PlanOffer plan;
  final SubscriptionService service;
  final String defaultHolder;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _form = GlobalKey<FormState>();
  late final _holder = TextEditingController(text: widget.defaultHolder);
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _useTestCard() {
    final nextYear = DateTime.now().year + 2;
    setState(() {
      _number.text = '4242 4242 4242 4242';
      _expiry.text = '12/${nextYear.toString().substring(2)}';
      _cvv.text = '123';
      _error = null;
    });
  }

  (int, int)? _expiryValue() {
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(_expiry.text);
    if (match == null) return null;
    return (int.parse(match.group(1)!), 2000 + int.parse(match.group(2)!));
  }

  String? _validateExpiry(String? value) {
    final expiry = _expiryValue();
    if (expiry == null) return 'Usa el formato MM/AA.';
    final now = DateTime.now();
    if (expiry.$2 < now.year ||
        (expiry.$2 == now.year && expiry.$1 < now.month)) {
      return 'La tarjeta está vencida.';
    }
    return null;
  }

  Future<void> _pay() async {
    if (_busy || !_form.currentState!.validate()) return;
    final expiry = _expiryValue()!;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.simulatePayment(
        plan: widget.plan,
        holder: _holder.text,
        cardNumber: _number.text,
        expiryMonth: expiry.$1,
        expiryYear: expiry.$2,
        cvv: _cvv.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userErrorMessage(
            error,
            fallback: 'No pudimos completar la demostración del pago.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Pago de demostración')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.science_outlined, color: Color(0xFF008F73)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modo demostración: no se cobrará dinero real. Usa únicamente las tarjetas de prueba mostradas aquí.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.mint,
                        child: Icon(Icons.workspace_premium_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan ${widget.plan.nombre}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Acceso durante 30 días · sin renovación automática',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.plan.precioTexto,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 185,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006E59), Color(0xFF00B894)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29008F73),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SmartPet Demo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Icon(Icons.contactless, color: Colors.white),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _number.text.isEmpty
                            ? '••••  ••••  ••••  ••••'
                            : _number.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _holder.text.isEmpty
                                  ? 'NOMBRE DEL TITULAR'
                                  : _holder.text.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _expiry.text.isEmpty ? 'MM/AA' : _expiry.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('use-test-card'),
                  onPressed: _busy ? null : _useTestCard,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Usar tarjeta aprobada de prueba'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aprobada: 4242 4242 4242 4242 · Rechazada: 4000 0000 0000 0002',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('card-holder'),
                  controller: _holder,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del titular',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().length < 3
                      ? 'Escribe el nombre del titular.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('card-number'),
                  controller: _number,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                  ),
                  inputFormatters: [_CardNumberFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      value == null || value.replaceAll(' ', '').length != 16
                      ? 'Ingresa los 16 dígitos.'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('card-expiry'),
                        controller: _expiry,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Vencimiento',
                          hintText: 'MM/AA',
                        ),
                        inputFormatters: [_ExpiryFormatter()],
                        onChanged: (_) => setState(() {}),
                        validator: _validateExpiry,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('card-cvv'),
                        controller: _cvv,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) =>
                            value == null ||
                                !RegExp(r'^\d{3,4}$').hasMatch(value)
                            ? 'Usa 3 o 4 dígitos.'
                            : null,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  InlineMessage(_error!),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('simulate-payment'),
                  onPressed: _busy ? null : _pay,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_outline_rounded),
                  label: Text(
                    _busy
                        ? 'Procesando demostración…'
                        : 'Simular pago de ${widget.plan.precioTexto}',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SmartPet no guarda el número, el vencimiento ni el CVV.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CardNumberFormatter extends TextInputFormatter {
  const _CardNumberFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 16));
    final groups = <String>[];
    for (var index = 0; index < limited.length; index += 4) {
      groups.add(
        limited.substring(index, (index + 4).clamp(0, limited.length)),
      );
    }
    final text = groups.join(' ');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  const _ExpiryFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 4));
    final text = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
