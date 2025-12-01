import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:afroforma/services/database_service.dart';

class PayrollSettingsScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const PayrollSettingsScreen({super.key, required this.fadeAnimation, required this.gradient});

  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  final _cnssEmpCtrl = TextEditingController();
  final _cnssErCtrl = TextEditingController();
  final _cnssCeilingCtrl = TextEditingController();

  final List<TextEditingController> _irppThresholdCtrls =
      List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _irppRateCtrls =
      List.generate(5, (_) => TextEditingController());

  bool _mutuelleEnabled = false;
  final _mutuelleRateCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final raw = await DatabaseService().getPref('payroll_tg_settings');
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data = json.decode(raw);
        final cnss = (data['cnss'] as Map?) ?? {};
        _cnssEmpCtrl.text = (cnss['employeeRate'] ?? '').toString();
        _cnssErCtrl.text = (cnss['employerRate'] ?? '').toString();
        _cnssCeilingCtrl.text = (cnss['ceiling'] ?? '').toString();

        final irpp = (data['irpp'] as List?) ?? [];
        for (int i = 0; i < _irppThresholdCtrls.length; i++) {
          _irppThresholdCtrls[i].text = i < irpp.length ? (irpp[i]['threshold'] ?? '').toString() : '';
          _irppRateCtrls[i].text = i < irpp.length ? (irpp[i]['rate'] ?? '').toString() : '';
        }

        final mut = (data['mutuelle'] as Map?) ?? {};
        _mutuelleEnabled = (mut['enabled'] ?? false) == true;
        _mutuelleRateCtrl.text = (mut['rate'] ?? '').toString();
      } catch (_) {
        // ignore parsing errors, keep defaults
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final cnss = {
      'employeeRate': double.tryParse(_cnssEmpCtrl.text) ?? 0.0,
      'employerRate': double.tryParse(_cnssErCtrl.text) ?? 0.0,
      'ceiling': double.tryParse(_cnssCeilingCtrl.text) ?? 0.0,
    };
    final irpp = <Map<String, double>>[];
    for (int i = 0; i < _irppThresholdCtrls.length; i++) {
      final th = double.tryParse(_irppThresholdCtrls[i].text);
      final rt = double.tryParse(_irppRateCtrls[i].text);
      if (th != null && rt != null) irpp.add({'threshold': th, 'rate': rt});
    }
    final mutuelle = {
      'enabled': _mutuelleEnabled,
      'rate': double.tryParse(_mutuelleRateCtrl.text) ?? 0.0,
    };
    final data = json.encode({'cnss': cnss, 'irpp': irpp, 'mutuelle': mutuelle});
    await DatabaseService().setPref('payroll_tg_settings', data);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres paie (Togo) enregistrés')),
    );
  }

  @override
  void dispose() {
    _cnssEmpCtrl.dispose();
    _cnssErCtrl.dispose();
    _cnssCeilingCtrl.dispose();
    for (final c in _irppThresholdCtrls) c.dispose();
    for (final c in _irppRateCtrls) c.dispose();
    _mutuelleRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, Icons.flag, 'Paramétrage Paie — Togo'),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _card(
                context,
                title: 'CNSS',
                child: Column(
                  children: [
                    _numberField(context, label: 'Taux salarié (%)', controller: _cnssEmpCtrl),
                    const SizedBox(height: 10),
                    _numberField(context, label: 'Taux employeur (%)', controller: _cnssErCtrl),
                    const SizedBox(height: 10),
                    _numberField(context, label: 'Plafond base (FCFA)', controller: _cnssCeilingCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                context,
                title: 'IRPP (OTR) — Tranches',
                child: Column(
                  children: List.generate(_irppThresholdCtrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _numberField(context, label: 'Seuil ${i + 1} (FCFA)', controller: _irppThresholdCtrls[i]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _numberField(context, label: 'Taux ${i + 1} (%)', controller: _irppRateCtrls[i]),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              _card(
                context,
                title: 'Mutuelle',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      value: _mutuelleEnabled,
                      onChanged: (v) => setState(() => _mutuelleEnabled = v),
                      title: const Text('Activer la mutuelle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_mutuelleEnabled)
                      _numberField(context, label: 'Taux mutuelle (%)', controller: _mutuelleRateCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _numberField(BuildContext context, {required String label, required TextEditingController controller}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
