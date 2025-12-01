import 'package:flutter/material.dart';
import 'package:afroforma/services/database_service.dart';
import 'package:afroforma/models/student.dart';
import 'package:intl/intl.dart';
import 'package:afroforma/services/sync_service.dart';
import 'package:afroforma/services/notification_service.dart';
import 'package:afroforma/screen/parametres/models.dart';
import 'package:afroforma/screen/parametres/dialogs.dart';

class ComptabiliteTab extends StatefulWidget {
  const ComptabiliteTab({Key? key}) : super(key: key);

  @override
  State<ComptabiliteTab> createState() => _ComptabiliteTabState();
}

class _ComptabiliteTabState extends State<ComptabiliteTab> {
  final _formKey = GlobalKey<FormState>();
  int _missingClientAccounts = 0;


  // Accounts
  final _revenueCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _vatCollectedCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _tmoneyCtrl = TextEditingController();
  final _floozCtrl = TextEditingController();
  final _chequeCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _transferCtrl = TextEditingController();
  final _advanceClientCtrl = TextEditingController();

  // Journals
  String? _salesJournalId;
  String? _bankJournalId;
  String? _cashJournalId;
  String? _advanceJournalId;

  // Flags
  bool _autoPostSale = false;
  bool _autoPostPayment = true;
  bool _vatEnabled = true;
  double _vatRate = 18.0;

  bool _loading = true;
  List<Map<String, Object?>> _accounts = [];
  List<Map<String, Object?>> _journaux = [];
  bool _syncing = false;
  String _lastSyncLabel = '';

  // Company-level accounting parameters
  CompanyInfo? _company;
  final TextEditingController _exerciceCtrl = TextEditingController();
  String _planComptable = 'SYSCOHADA';
  String _monnaie = 'FCFA';
  int _startMonth = DateTime.now().month;
  int _startYear = DateTime.now().year;
  int _endMonth = 12;
  int _endYear = DateTime.now().year;
  bool _exerciceValid = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSyncInfo();
    _computeMissingClientAccounts();
  }

  Future<void> _load() async {
    final db = DatabaseService();
    // Ensure default journals exist to avoid empty dropdown
    await db.insertDefaultJournauxIfMissing();
    final accs = await db.getPlanComptable();
    final journaux = await db.getJournaux();

    String rev = await db.getPref('acc.revenue') ?? '706'; // Services vendus (SYSCOHADA)
    String cli = await db.getPref('acc.client') ?? '411'; // Clients
    String vat = await db.getPref('acc.vat_collected') ?? '4432'; // TVA facturée sur prestations (SYSCOHADA)
    String bank = await db.getPref('acc.bank') ?? '5211'; // Banque locale monnaie nationale (SYSCOHADA)
    String cash = await db.getPref('acc.cash') ?? '5711'; // Caisse monnaie nationale (SYSCOHADA)
    String tmoney = await db.getPref('acc.tmoney') ?? '';
    String flooz = await db.getPref('acc.flooz') ?? '';
    String cheque = await db.getPref('acc.cheque') ?? '';
    String card = await db.getPref('acc.card') ?? '';
    String transfer = await db.getPref('acc.transfer') ?? '';
    String advClient = await db.getPref('acc.advance_client') ?? '4191';

    String sj = await db.getPref('journal.sales') ?? 'VE';
    String bj = await db.getPref('journal.bank') ?? 'BQ';
    String cj = await db.getPref('journal.cash') ?? 'CA';
    String aj = await db.getPref('journal.advance') ?? 'AV';

    bool autoSale = (await db.getPref('auto.post.sale')) == '1';
    bool autoPay = (await db.getPref('auto.post.payment')) != '0';
    bool vatEnabled = (await db.getPref('vat.enabled')) == '1';
    double vatRate = double.tryParse((await db.getPref('vat.rate')) ?? '') ?? 18.0;
    final company = await db.getCompanyInfo();

    setState(() {
      _accounts = accs;
      _journaux = journaux;
      _revenueCtrl.text = rev;
      _clientCtrl.text = cli;
      _vatCollectedCtrl.text = vat;
      _bankCtrl.text = bank;
      _cashCtrl.text = cash;
      _tmoneyCtrl.text = tmoney;
      _floozCtrl.text = flooz;
      _chequeCtrl.text = cheque;
      _cardCtrl.text = card;
      _transferCtrl.text = transfer;
      _advanceClientCtrl.text = advClient;
      _salesJournalId = sj;
      _bankJournalId = bj;
      _cashJournalId = cj;
      _autoPostSale = autoSale;
      _autoPostPayment = autoPay;
      _vatEnabled = vatEnabled;
      _vatRate = vatRate;
      _advanceJournalId = aj;
      _loading = false;
      _company = company;
      _exerciceCtrl.text = company?.exercice ?? '';
      _planComptable = company?.planComptable ?? 'SYSCOHADA';
      _monnaie = company?.monnaie ?? 'FCFA';
      // Parse exercice like "MM/YYYY - MM/YYYY"
      final ex = (company?.exercice ?? '').trim();
      final reg = RegExp(r'^(\d{2})\/(\d{4})\s*-\s*(\d{2})\/(\d{4})$');
      final m = reg.firstMatch(ex);
      if (m != null) {
        _startMonth = int.tryParse(m.group(1)!) ?? _startMonth;
        _startYear = int.tryParse(m.group(2)!) ?? _startYear;
        _endMonth = int.tryParse(m.group(3)!) ?? _endMonth;
        _endYear = int.tryParse(m.group(4)!) ?? _endYear;
      } else {
        // default to current calendar year
        _startMonth = 1;
        _startYear = DateTime.now().year;
        _endMonth = 12;
        _endYear = DateTime.now().year;
      }
      _exerciceCtrl.text = _formatExercice();
      _exerciceValid = _checkExerciceValid();
    });
  }

  Future<void> _computeMissingClientAccounts() async {
    try {
      final db = DatabaseService();
      final students = await db.getStudents();
      final plan = await db.getPlanComptable();
      final codes = plan.map((r) => (r['code'] ?? '').toString()).toSet();
      int missing = 0;
      for (final s in students) {
        final code = (s as Student).clientAccountCode;
        if (code.isEmpty || !codes.contains(code)) missing++;
      }
      if (mounted) setState(() => _missingClientAccounts = missing);
    } catch (_) {}
  }

  Future<void> _loadSyncInfo() async {
    try {
      final db = DatabaseService();
      final val = await db.getPref('lastSyncAt');
      if (val != null && val.isNotEmpty) {
        final ms = int.tryParse(val) ?? 0;
        if (ms > 0) {
          final d = DateTime.fromMillisecondsSinceEpoch(ms);
          setState(() => _lastSyncLabel = 'Dernière sync: ${DateFormat('dd/MM/yyyy HH:mm').format(d)}');
          return;
        }
      }
      setState(() => _lastSyncLabel = 'Jamais synchronisé');
    } catch (_) {
      setState(() => _lastSyncLabel = 'Statut sync indisponible');
    }
  }

  Future<void> _runSyncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await SyncService().runOnce();
      await _loadSyncInfo();
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Synchronisation terminée'));
    } catch (e) {
      NotificationService().showNotification(NotificationItem(id: DateTime.now().toString(), message: 'Erreur de synchronisation', backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }


  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final db = DatabaseService();
    await db.setPref('acc.revenue', _revenueCtrl.text.trim());
    await db.setPref('acc.client', _clientCtrl.text.trim());
    await db.setPref('acc.vat_collected', _vatCollectedCtrl.text.trim());
    await db.setPref('acc.bank', _bankCtrl.text.trim());
    await db.setPref('acc.cash', _cashCtrl.text.trim());
    await db.setPref('acc.tmoney', _tmoneyCtrl.text.trim());
    await db.setPref('acc.flooz', _floozCtrl.text.trim());
    await db.setPref('acc.cheque', _chequeCtrl.text.trim());
    await db.setPref('acc.card', _cardCtrl.text.trim());
    await db.setPref('acc.transfer', _transferCtrl.text.trim());
    await db.setPref('acc.advance_client', _advanceClientCtrl.text.trim());
    await db.setPref('journal.sales', _salesJournalId ?? 'VE');
    await db.setPref('journal.bank', _bankJournalId ?? 'BQ');
    await db.setPref('journal.cash', _cashJournalId ?? 'CA');
    await db.setPref('journal.advance', _advanceJournalId ?? 'AV');
    await db.setPref('auto.post.sale', _autoPostSale ? '1' : '0');
    await db.setPref('auto.post.payment', _autoPostPayment ? '1' : '0');
    await db.setPref('vat.enabled', _vatEnabled ? '1' : '0');
    await db.setPref('vat.rate', _vatRate.toString());
    // Save company-level accounting params
    try {
      final base = await db.getCompanyInfo() ?? CompanyInfo(
        name: '', address: '', phone: '', email: '', rccm: '', nif: '', website: '', logoPath: '',
      );
      // Validate exercice before saving
      if (!_checkExerciceValid()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercice invalide: la fin doit être postérieure au début'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }
      base.exercice = _formatExercice();
      base.planComptable = _planComptable;
      base.monnaie = _monnaie;
      await db.saveCompanyInfo(base);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres comptables enregistrés')));
  }

  String _monthLabel(int m) {
    const months = ['01','02','03','04','05','06','07','08','09','10','11','12'];
    if (m < 1 || m > 12) return m.toString().padLeft(2,'0');
    return months[m-1];
  }

  String _formatExercice() {
    final sm = _monthLabel(_startMonth);
    final em = _monthLabel(_endMonth);
    return '$sm/${_startYear} - $em/${_endYear}';
  }

  bool _checkExerciceValid() {
    if (_endYear < _startYear) return false;
    if (_endYear == _startYear && _endMonth < _startMonth) return false;
    return true;
  }

  void _updateExerciceAndValidate() {
    // Auto-correct: if fin < début, aligne la fin sur le début
    if (_endYear < _startYear || (_endYear == _startYear && _endMonth < _startMonth)) {
      _endYear = _startYear;
      _endMonth = _startMonth;
    }
    _exerciceCtrl.text = _formatExercice();
    _exerciceValid = _checkExerciceValid();
  }

  void _applyFiscalStart(int startMonth) {
    _startMonth = startMonth;
    // Si début = Janvier, fin = Décembre même année, sinon fin = mois précédent et année +1
    if (startMonth == 1) {
      _endMonth = 12;
      _endYear = _startYear;
    } else {
      _endMonth = startMonth - 1;
      _endYear = _startYear + 1;
    }
    _updateExerciceAndValidate();
  }

  String _exercisePreview() {
    try {
      final start = DateTime(_startYear, _startMonth, 1);
      // last day of month trick: day 0 of next month
      final end = DateTime(_endYear, _endMonth + 1, 0);
      final df = DateFormat('dd MMMM yyyy', 'fr_FR');
      return '${df.format(start)} → ${df.format(end)}';
    } catch (_) {
      return _formatExercice();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercices
            const Text('Exercices', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, Object?>>>(
              future: DatabaseService().getExercices(),
              builder: (ctx, snap) {
                final list = snap.data ?? const [];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, Object?>?>(
                        future: DatabaseService().getActiveExercice(),
                        builder: (ctx2, act) {
                          final active = act.data;
                          final label = active == null ? '(Aucun)' : (active['label']?.toString() ?? '(Exercice)');
                          final isClosed = (active?['isClosed'] as int?) == 1;
                          return Row(children: [
                            Expanded(child: Text('Actif: $label ${isClosed ? '(clos)' : ''}', style: const TextStyle(color: Colors.white))),
                            if (active != null && !isClosed)
                              OutlinedButton.icon(onPressed: () async {
                                final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Clôturer l\'exercice ?'), content: const Text('Aucune écriture ne pourra être saisie sur cet exercice.'), actions: [TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Annuler')), ElevatedButton(onPressed: ()=>Navigator.pop(d,true), child: const Text('Clôturer'))]));
                                if (ok == true) { await DatabaseService().closeExercice(active['id']!.toString()); setState(() {}); }
                              }, icon: const Icon(Icons.lock), label: const Text('Clôturer')),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(onPressed: () async {
                              // créer nouvel exercice à partir des sélecteurs d'exercice
                              final start = DateTime(_startYear, _startMonth, 1).millisecondsSinceEpoch;
                              final end = DateTime(_endYear, _endMonth + 1, 0).millisecondsSinceEpoch;
                              final id = await DatabaseService().createExercice(startMs: start, endMs: end, makeActive: true);
                              await DatabaseService().setActiveExercice(id);
                              setState(() {});
                            }, icon: const Icon(Icons.add), label: const Text('Nouveau exercice')),
                          ]);
                        }
                      ),
                      const SizedBox(height: 8),
                      if (list.isEmpty) const Text('Aucun exercice créé', style: TextStyle(color: Colors.white70)) else DropdownButtonFormField<String>(
                        value: null,
                        items: list.map((e) => DropdownMenuItem(value: e['id']!.toString(), child: Text(e['label']?.toString() ?? e['id']!.toString()))).toList(),
                        onChanged: (v) async {
                          if (v==null) return;
                          // Option: consulter totals pour l'exercice sélectionné
                          final ex = (list.firstWhere((e) => e['id']!.toString() == v));
                          final sm = DateTime.fromMillisecondsSinceEpoch((ex['startMs'] as int?) ?? 0);
                          final em = DateTime.fromMillisecondsSinceEpoch((ex['endMs'] as int?) ?? 0);
                          setState(() { _startMonth = sm.month; _startYear = sm.year; _endMonth = em.month; _endYear = em.year; _updateExerciceAndValidate(); });
                        },
                        decoration: const InputDecoration(labelText: 'Consulter un exercice'),
                      ),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            // Company-level settings
            const Text('Paramètres généraux', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _planComptable,
                      items: [
                        DropdownMenuItem(value: 'SYSCOHADA', child: Text('SYSCOHADA')),
                        DropdownMenuItem(value: 'PCG', child: Text('PCG')),
                        DropdownMenuItem(value: 'PERSONNALISE', child: Text('Personnalisé')),
                      ],
                      onChanged: (v) => setState(() => _planComptable = v ?? _planComptable),
                      decoration: const InputDecoration(labelText: 'Plan Comptable'),
                    )),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => PlanComptableDialog()),
                      icon: const Icon(Icons.settings),
                      label: const Text('Configurer Plan Comptable'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Exercice Comptable', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                value: _startMonth,
                                items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthLabel(i+1)))).toList(),
                                onChanged: (v) { setState(() { _startMonth = v ?? _startMonth; _updateExerciceAndValidate(); }); },
                                decoration: const InputDecoration(labelText: 'Mois début'),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                value: _startYear,
                                items: List.generate(7, (k) { final y = DateTime.now().year - 3 + k; return DropdownMenuItem(value: y, child: Text(y.toString())); }).toList(),
                                onChanged: (v) { setState(() { _startYear = v ?? _startYear; _updateExerciceAndValidate(); }); },
                                decoration: const InputDecoration(labelText: 'Année début'),
                              ),
                            ),
                            const Text('→', style: TextStyle(color: Colors.white70)),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                value: _endMonth,
                                items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthLabel(i+1)))).toList(),
                                onChanged: (v) { setState(() { _endMonth = v ?? _endMonth; _updateExerciceAndValidate(); }); },
                                decoration: const InputDecoration(labelText: 'Mois fin'),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                value: _endYear,
                                items: List.generate(7, (k) { final y = DateTime.now().year - 3 + k; return DropdownMenuItem(value: y, child: Text(y.toString())); }).toList(),
                                onChanged: (v) { setState(() { _endYear = v ?? _endYear; _updateExerciceAndValidate(); }); },
                                decoration: const InputDecoration(labelText: 'Année fin'),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () { setState(() { _startMonth = 1; _startYear = DateTime.now().year; _endMonth = 12; _endYear = DateTime.now().year; _updateExerciceAndValidate(); }); },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Année en cours'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                setState(() {
                                  _startMonth = 4; // Avril
                                  _startYear = now.year;
                                  _endMonth = 3; // Mars
                                  _endYear = _startYear + 1;
                                  _updateExerciceAndValidate();
                                });
                              },
                              icon: const Icon(Icons.event_repeat),
                              label: const Text('Exercice fiscal (Avr → Mar)'),
                            ),
                            SizedBox(
                              width: 220,
                              child: DropdownButtonFormField<int>(
                                value: _startMonth,
                                items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text('Début fiscal: ${_monthLabel(i+1)}'))).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _applyFiscalStart(v);
                                  });
                                },
                                decoration: const InputDecoration(labelText: 'Début exercice fiscal'),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          TextField(controller: _exerciceCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Format'), style: const TextStyle(color: Colors.white)),
                          if (!_exerciceValid)
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Text('La fin doit être postérieure au début', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text('Aperçu: ' + _exercisePreview(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _monnaie,
                      items: [
                        DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (v) => setState(() => _monnaie = v ?? _monnaie),
                      decoration: const InputDecoration(labelText: 'Monnaie'),
                    )),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(_lastSyncLabel.isEmpty ? ' ' : _lastSyncLabel, style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
            
            const Text('Automatisation comptable', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Comptabiliser la vente à l\'inscription', style: TextStyle(color: Colors.white)),
                    value: _autoPostSale,
                    onChanged: (v) => setState(() => _autoPostSale = v),
                  ),
                  SwitchListTile(
                    title: const Text('Comptabiliser l\'encaissement au paiement', style: TextStyle(color: Colors.white)),
                    value: _autoPostPayment,
                    onChanged: (v) => setState(() => _autoPostPayment = v),
                  ),
                  SwitchListTile(
                    title: const Text('Appliquer la TVA aux inscriptions', style: TextStyle(color: Colors.white)),
                    value: _vatEnabled,
                    onChanged: (v) => setState(() => _vatEnabled = v),
                  ),
                  if (_vatEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _vatRate.toString(),
                            decoration: const InputDecoration(labelText: 'Taux TVA (%)'),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                              if (d == null || d < 0) return 'TVA invalide';
                              return null;
                            },
                            onChanged: (v) => _vatRate = double.tryParse(v.replaceAll(',', '.')) ?? _vatRate,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Journaux', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _buildJournalPicker('Ventes', _salesJournalId, (v) => setState(() => _salesJournalId = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildJournalPicker('Banque', _bankJournalId, (v) => setState(() => _bankJournalId = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildJournalPicker('Caisse', _cashJournalId, (v) => setState(() => _cashJournalId = v))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _buildJournalPicker('Avances', _advanceJournalId, (v) => setState(() => _advanceJournalId = v))),
                    Expanded(child: SizedBox()),
                    Expanded(child: SizedBox()),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Comptes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  Row(children: [Expanded(child: _buildAccountField('Produit (inscriptions)', _revenueCtrl)), const SizedBox(width: 12), Expanded(child: _buildAccountField('Client (411)', _clientCtrl))]),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _buildAccountField('TVA collectée', _vatCollectedCtrl)), const SizedBox(width: 12), Expanded(child: _buildAccountField('Banque', _bankCtrl))]),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _buildAccountField('Caisse', _cashCtrl)), const SizedBox(width: 12), Expanded(child: _buildAccountField('Avances clients (4191)', _advanceClientCtrl))]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Modes de paiement (comptes de trésorerie)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  Row(children: [Expanded(child: _buildAccountField('TMoney (Togocom)', _tmoneyCtrl)), const SizedBox(width: 12), Expanded(child: _buildAccountField('Flooz (Moov)', _floozCtrl))]),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _buildAccountField('Chèque', _chequeCtrl)), const SizedBox(width: 12), Expanded(child: _buildAccountField('Carte bancaire (POS)', _cardCtrl))]),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _buildAccountField('Virement', _transferCtrl)), const SizedBox(width: 12), const Expanded(child: SizedBox())]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalPicker(String label, String? selectedId, ValueChanged<String?> onChanged) {
    // De-duplicate by id and ensure current value exists
    final byId = <String, Map<String, Object?>>{};
    for (final j in _journaux) {
      final id = (j['id'] ?? '').toString();
      if (id.isEmpty) continue;
      byId.putIfAbsent(id, () => j);
    }
    final items = byId.values
        .map((j) => DropdownMenuItem<String>(
              value: (j['id'] ?? '').toString(),
              child: Text('${j['code']} - ${j['name']}', style: const TextStyle(color: Colors.white)),
            ))
        .toList();
    final availableIds = byId.keys.toSet();
    final value = (selectedId != null && availableIds.contains(selectedId)) ? selectedId : null;

    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildAccountField(String label, TextEditingController ctrl) {
    return Autocomplete<Map<String, Object?>>(
      displayStringForOption: (opt) => '${opt['code']} - ${opt['title']}',
      optionsBuilder: (TextEditingValue tev) {
        final q = tev.text.toLowerCase();
        Iterable<Map<String, Object?>> base = _accounts;
        if (q.isNotEmpty) {
          base = base.where((a) {
            final code = (a['code'] ?? '').toString().toLowerCase();
            final title = (a['title'] ?? '').toString().toLowerCase();
            return code.contains(q) || title.contains(q);
          });
        }
        return base.take(200);
      },
      onSelected: (opt) => ctrl.text = (opt['code'] ?? '').toString(),
      fieldViewBuilder: (context, textCtrl, focus, onSubmit) {
        if (ctrl.text.isNotEmpty && ctrl.text != textCtrl.text) textCtrl.text = ctrl.text;
        textCtrl.addListener(() {
          if (ctrl.text != textCtrl.text) ctrl.text = textCtrl.text;
        });
        return TextField(controller: textCtrl, focusNode: focus, decoration: InputDecoration(labelText: label));
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (_, idx) {
                final opt = options.elementAt(idx);
                return ListTile(
                  title: Text('${opt['code']} - ${opt['title']}'),
                  onTap: () => onSelected(opt),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
