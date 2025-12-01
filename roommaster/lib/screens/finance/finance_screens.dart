import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_template.dart';
import '../../models/ecriture_comptable.dart';

class FacturationScreen extends StatefulWidget {
  const FacturationScreen({super.key});

  @override
  State<FacturationScreen> createState() => _FacturationScreenState();
}

class _FacturationScreenState extends State<FacturationScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  _DateRange _range = _DateRange.last30;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Facturation',
      subtitle: 'Folio & soldes par réservation',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _filterReservations(snapshot.data ?? [], _range);
          final total = data.fold<double>(
            0,
            (sum, r) => sum + (r['amount'] as num? ?? 0).toDouble(),
          );
          final deposits = data.fold<double>(
            0,
            (sum, r) => sum + (r['deposit'] as num? ?? 0).toDouble(),
          );
          final outstanding = total - deposits;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeSelector(
                current: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 8),
              _FinanceHeaderRow(
                total: total,
                deposits: deposits,
                outstanding: outstanding,
                money: _money,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _ReservationPaymentsList(
                  reservations: data,
                  money: _money,
                  emptyLabel: 'Aucune réservation à facturer',
                  onUpdated: () {
                    _future = LocalDatabase.instance.fetchReservations();
                    setState(() {});
                  },
                  enablePaymentActions: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  _DateRange _range = _DateRange.last30;
  String? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Caisse',
      subtitle: 'Entrées / soldes en attente',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _filterReservations(snapshot.data ?? [], _range);
          final paid = data.where(
            (r) =>
                (r['paymentStatus'] as String? ?? '').toLowerCase() == 'payé',
          );
          final pending = data.where(
            (r) =>
                (r['paymentStatus'] as String? ?? '').toLowerCase() != 'payé',
          );
          final paidTotal = paid.fold<double>(
            0,
            (sum, r) => sum + (r['amount'] as num? ?? 0).toDouble(),
          );
          final pendingTotal = pending.fold<double>(0, (sum, r) {
            final amount = (r['amount'] as num? ?? 0).toDouble();
            final deposit = (r['deposit'] as num? ?? 0).toDouble();
            return sum + (amount - deposit);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeSelector(
                current: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 8),
              _PaymentFilter(
                current: _paymentFilter,
                onChanged: (v) => setState(() => _paymentFilter = v),
              ),
              const SizedBox(height: 8),
              _StatRow(
                items: [
                  _StatItem(
                    label: 'Payé',
                    value: _money.format(paidTotal),
                    color: Colors.greenAccent,
                  ),
                  _StatItem(
                    label: 'En attente',
                    value: _money.format(pendingTotal),
                    color: Colors.orangeAccent,
                  ),
                  _StatItem(
                    label: 'Réservations',
                    value: '${data.length}',
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PaymentSummaryRow(data: data, money: _money),
              const SizedBox(height: 16),
              Expanded(
                child: _ReservationPaymentsList(
                  reservations: _filterByPayment(data, _paymentFilter),
                  money: _money,
                  emptyLabel: 'Aucune donnée caisse',
                  onUpdated: () {
                    _future = LocalDatabase.instance.fetchReservations();
                    setState(() {});
                  },
                  enablePaymentActions: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EncaissementsScreen extends StatefulWidget {
  const EncaissementsScreen({super.key});

  @override
  State<EncaissementsScreen> createState() => _EncaissementsScreenState();
}

class _EncaissementsScreenState extends State<EncaissementsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  _DateRange _range = _DateRange.last30;
  String? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Encaissements',
      subtitle: 'Détails des paiements enregistrés',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _filterReservations(snapshot.data ?? [], _range);
          final payments = data
              .where(
                (r) =>
                    (r['deposit'] as num? ?? 0) > 0 ||
                    (r['paymentStatus'] as String? ?? '').isNotEmpty,
              )
              .toList();
          payments.sort((a, b) {
            final aDep = (a['deposit'] as num? ?? 0).toDouble();
            final bDep = (b['deposit'] as num? ?? 0).toDouble();
            return bDep.compareTo(aDep);
          });

          return Column(
            children: [
              _RangeSelector(
                current: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 8),
              _PaymentFilter(
                current: _paymentFilter,
                onChanged: (v) => setState(() => _paymentFilter = v),
              ),
              const SizedBox(height: 8),
              _PaymentSummaryRow(data: payments, money: _money),
              const SizedBox(height: 8),
              Expanded(
                child: _ReservationPaymentsList(
                  reservations: _filterByPayment(payments, _paymentFilter),
                  money: _money,
                  emptyLabel: 'Aucun encaissement',
                  onUpdated: () {
                    _future = LocalDatabase.instance.fetchReservations();
                    setState(() {});
                  },
                  enablePaymentActions: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ImpayesScreen extends StatefulWidget {
  const ImpayesScreen({super.key});

  @override
  State<ImpayesScreen> createState() => _ImpayesScreenState();
}

class _ImpayesScreenState extends State<ImpayesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  _DateRange _range = _DateRange.last30;
  String? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Impayés',
      subtitle: 'Soldes restants par client',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _filterReservations(snapshot.data ?? [], _range);
          final due = data.where((r) {
            final amount = (r['amount'] as num? ?? 0).toDouble();
            final deposit = (r['deposit'] as num? ?? 0).toDouble();
            return amount - deposit > 0;
          }).toList();
          due.sort((a, b) {
            final aDue =
                (a['amount'] as num? ?? 0).toDouble() -
                (a['deposit'] as num? ?? 0).toDouble();
            final bDue =
                (b['amount'] as num? ?? 0).toDouble() -
                (b['deposit'] as num? ?? 0).toDouble();
            return bDue.compareTo(aDue);
          });

          return _ReservationPaymentsList(
            reservations: _filterByPayment(due, _paymentFilter),
            money: _money,
            emptyLabel: 'Aucun impayé',
            highlightOutstanding: true,
            onUpdated: () {
              _future = LocalDatabase.instance.fetchReservations();
              setState(() {});
            },
            enablePaymentActions: true,
          );
        },
      ),
    );
  }
}

class ComptabiliteScreen extends StatefulWidget {
  const ComptabiliteScreen({super.key});

  @override
  State<ComptabiliteScreen> createState() => _ComptabiliteScreenState();
}

class _ComptabiliteScreenState extends State<ComptabiliteScreen> {
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final List<CompteComptable> _accounts = [];
  final List<EcritureComptable> _entries = [];
  final List<Map<String, dynamic>> _journaux = [];
  final List<EcritureTemplate> _templates = [];
  String _journalFilter = 'Tous';
  String? _templatesJournal;
  DateTimeRange? _range;
  String? _selectedAccountCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = LocalDatabase.instance;
    final plan = await db.getPlanComptable();
    final entries = await db.getEcritures();
    final journaux = await db.getJournaux();
    final tplRows = await db.getEcritureTemplates();
    if (!mounted) return;
    setState(() {
      _accounts
        ..clear()
        ..addAll(plan.map(CompteComptable.fromMap));
      _entries
        ..clear()
        ..addAll(entries.map(EcritureComptable.fromMap));
      _journaux
        ..clear()
        ..addAll(journaux);
      _templates
        ..clear()
        ..addAll(tplRows.map(EcritureTemplate.fromMap));
    });
  }

  List<EcritureComptable> get _filteredEntries {
    return _entries.where((e) {
      if (_range != null) {
        if (e.date.isBefore(_range!.start)) return false;
        if (e.date.isAfter(_range!.end)) return false;
      }
      if (_journalFilter != 'Tous' && e.journalId != _journalFilter) {
        return false;
      }
      if (_selectedAccountCode != null &&
          _selectedAccountCode!.isNotEmpty &&
          e.accountCode != _selectedAccountCode) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _totalDebit => _filteredEntries.fold(0, (sum, e) => sum + e.debit);
  double get _totalCredit =>
      _filteredEntries.fold(0, (sum, e) => sum + e.credit);

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Comptabilité',
      subtitle: 'Plan comptable et journal',
      child: DefaultTabController(
        length: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.account_tree), text: 'Plan comptable'),
                  Tab(icon: Icon(Icons.book), text: 'Journal'),
                  Tab(icon: Icon(Icons.view_list_outlined), text: 'Modèles'),
                  Tab(
                    icon: Icon(Icons.insert_chart_outlined),
                    text: 'Rapports',
                  ),
                  Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatRow(
              items: [
                _StatItem(
                  label: 'Débit',
                  value: _money.format(_totalDebit),
                  color: Colors.blueAccent,
                ),
                _StatItem(
                  label: 'Crédit',
                  value: _money.format(_totalCredit),
                  color: Colors.greenAccent,
                ),
                _StatItem(
                  label: 'Balance',
                  value: _money.format(_totalDebit - _totalCredit),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlanTab(),
                  _buildJournalTab(),
                  _buildTemplatesTab(),
                  _buildReportsTab(),
                  _buildComptaSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalTab() {
    final entries = _filteredEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2100),
                  initialDateRange:
                      _range ??
                      DateTimeRange(
                        start: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        end: DateTime.now(),
                      ),
                );
                if (picked != null) {
                  setState(() => _range = picked);
                }
              },
              icon: const Icon(Icons.date_range, color: Colors.white),
              label: Text(
                _range == null
                    ? 'Plage de dates'
                    : '${DateFormat('dd/MM/yyyy').format(_range!.start)} - ${DateFormat('dd/MM/yyyy').format(_range!.end)}',
                style: const TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _journalFilter,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              items: [
                const DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                ..._journaux.map(
                  (j) => DropdownMenuItem(
                    value: j['id'] as String,
                    child: Text('${j['code']} - ${j['name']}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _journalFilter = v ?? 'Tous'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showEntryDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouvelle écriture',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune écriture',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final acc = _accounts.firstWhere(
                        (a) => a.code == e.accountCode,
                        orElse: () => CompteComptable(
                          id: '',
                          code: e.accountCode,
                          title: '',
                        ),
                      );
                      final journalLabel = _journaux.firstWhere(
                        (j) => j['id'] == e.journalId,
                        orElse: () => {'code': e.journalId, 'name': ''},
                      );
                      return ListTile(
                        title: Text(
                          e.label,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(e.date)} • ${journalLabel['code']} • ${acc.code} ${acc.title}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Débit: ${_money.format(e.debit)}',
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                            Text(
                              'Crédit: ${_money.format(e.credit)}',
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTab() {
    final sorted = [..._accounts]..sort((a, b) => a.code.compareTo(b.code));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showAccountDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouveau compte',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await LocalDatabase.instance.resetPlanComptable();
                await _loadData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan comptable réinitialisé')),
                );
              },
              child: const Text('Plan par défaut'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final acc = sorted[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${acc.code} - ${acc.title}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _showAccountDialog(existing: acc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteAccount(acc),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.all(8),
      children: [
        _reportCard(
          title: 'Balance générale',
          description: 'Synthèse débits / crédits',
          icon: Icons.grid_view,
          onTap: () => _showReportDialog('Balance générale'),
          color: Colors.purpleAccent,
        ),
        _reportCard(
          title: 'Grand livre',
          description: 'Détail par compte',
          icon: Icons.menu_book_outlined,
          onTap: () => _showReportDialog('Grand livre'),
          color: Colors.tealAccent,
        ),
        _reportCard(
          title: 'Compte de résultat',
          description: 'Charges / Produits',
          icon: Icons.show_chart,
          onTap: () => _showReportDialog('Compte de résultat'),
          color: Colors.orangeAccent,
        ),
        _reportCard(
          title: 'Bilan comptable',
          description: 'Actif / Passif',
          icon: Icons.account_balance,
          onTap: () => _showReportDialog('Bilan comptable'),
          color: Colors.lightBlueAccent,
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modèles d\'écriture',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Journal par défaut',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        DropdownButtonFormField<String?>(
                          value:
                              _journaux.any((j) => j['id'] == _templatesJournal)
                              ? _templatesJournal
                              : null,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(isDense: true),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Aucun'),
                            ),
                            ..._journaux.map(
                              (j) => DropdownMenuItem(
                                value: j['id'] as String,
                                child: Text('${j['code']} - ${j['name']}'),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _templatesJournal = v),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showTemplateDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Nouveau modèle',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: _templates.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun modèle pour le moment.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final t = _templates[index];
                        final linesPreview = t.lines
                            .map(
                              (l) =>
                                  '${l.account}: ${l.label} (D ${l.debit}, C ${l.credit})',
                            )
                            .join('\n');
                        return ListTile(
                          title: Text(
                            t.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            linesPreview,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                ),
                                onPressed: () =>
                                    _showTemplateDialog(existing: t),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteTemplate(t),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComptaSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paramètres comptables',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _journalFilter == 'Tous' && _journaux.isNotEmpty
                          ? _journaux.first['id'] as String?
                          : _journalFilter == 'Tous'
                          ? null
                          : _journalFilter,
                      decoration: const InputDecoration(
                        labelText: 'Journal par défaut (paiements)',
                      ),
                      items: _journaux
                          .map(
                            (j) => DropdownMenuItem(
                              value: j['id'] as String,
                              child: Text('${j['code']} - ${j['name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (_) {},
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // placeholder for exercice picker
                      },
                      icon: const Icon(Icons.date_range, color: Colors.white),
                      label: const Text(
                        'Exercice comptable',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // placeholder import plan
                    },
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'Importer plan',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // placeholder export plan
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'Exporter plan',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await LocalDatabase.instance.resetPlanComptable();
                      await _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan comptable réinitialisé'),
                        ),
                      );
                    },
                    child: const Text('Reset plan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Lettrage & journaux spéciaux',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilterChip(
                    selected: true,
                    onSelected: (_) {},
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    label: const Text(
                      'Activer lettrage',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  FilterChip(
                    selected: true,
                    onSelected: (_) {},
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                    label: const Text(
                      'Journal avances',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  FilterChip(
                    selected: true,
                    onSelected: (_) {},
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFFEAB308).withOpacity(0.2),
                    label: const Text(
                      'Journal OD',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Ces options serviront à connecter import/export et lettrage comme sur Afroforma (placeholder pour l’instant).',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            TextButton(
              onPressed: onTap,
              child: const Text(
                'Ouvrir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Vue détaillée sera ajoutée (balance, grand livre, résultat, bilan) comme dans Afroforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTemplateDialog({EcritureTemplate? existing}) async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord un compte.')),
      );
      return;
    }
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    String? journal = existing?.defaultJournalId ?? _templatesJournal;
    final lines = <TemplateLine>[
      if (existing != null) ...existing.lines,
      if (existing == null)
        TemplateLine(
          account: _accounts.first.code,
          label: '',
          debit: 0,
          credit: 0,
        ),
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nouveau modèle' : 'Modifier le modèle'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              void addLine() => setState(() {
                lines.add(
                  TemplateLine(
                    account: _accounts.first.code,
                    label: '',
                    debit: 0,
                    credit: 0,
                  ),
                );
              });
              void removeLine(int i) => setState(() => lines.removeAt(i));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Intitulé'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: journal,
                    decoration: const InputDecoration(
                      labelText: 'Journal par défaut',
                    ),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucun'),
                      ),
                      ..._journaux.map(
                        (j) => DropdownMenuItem<String?>(
                          value: j['id'] as String,
                          child: Text('${j['code']} - ${j['name']}'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => journal = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: Text('Compte')),
                      SizedBox(width: 8),
                      Expanded(child: Text('Libellé')),
                      SizedBox(width: 8),
                      SizedBox(width: 80, child: Text('Débit')),
                      SizedBox(width: 8),
                      SizedBox(width: 80, child: Text('Crédit')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 720,
                    height: 300,
                    child: ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (context, i) {
                        final l = lines[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      _accounts.any((a) => a.code == l.account)
                                      ? l.account
                                      : null,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                  items: _accounts
                                      .map(
                                        (a) => DropdownMenuItem(
                                          value: a.code,
                                          child: Text('${a.code} - ${a.title}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => lines[i] = TemplateLine(
                                      account: v ?? '',
                                      label: l.label,
                                      debit: l.debit,
                                      credit: l.credit,
                                    ),
                                  ),
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: l.label,
                                  onChanged: (v) => lines[i] = TemplateLine(
                                    account: l.account,
                                    label: v,
                                    debit: l.debit,
                                    credit: l.credit,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Libellé',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: l.debit.toString(),
                                  onChanged: (v) => lines[i] = TemplateLine(
                                    account: l.account,
                                    label: l.label,
                                    debit:
                                        double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ) ??
                                        0.0,
                                    credit: l.credit,
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: l.credit.toString(),
                                  onChanged: (v) => lines[i] = TemplateLine(
                                    account: l.account,
                                    label: l.label,
                                    debit: l.debit,
                                    credit:
                                        double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ) ??
                                        0.0,
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: lines.length > 1
                                    ? () => removeLine(i)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: addLine,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une ligne'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final tpl = EcritureTemplate(
        id: existing?.id ?? 'tpl_${DateTime.now().millisecondsSinceEpoch}',
        label: labelCtrl.text.trim(),
        defaultJournalId: journal,
        lines: lines,
      );
      await LocalDatabase.instance.saveEcritureTemplate(tpl.toMap());
      await _loadData();
    }
  }

  Future<void> _deleteTemplate(EcritureTemplate tpl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le modèle ?'),
        content: Text(tpl.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LocalDatabase.instance.deleteEcritureTemplate(tpl.id);
      await _loadData();
    }
  }

  Future<void> _showAccountDialog({CompteComptable? existing}) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    String? parent = existing?.parentId;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nouveau compte' : 'Modifier le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Intitulé'),
            ),
            DropdownButtonFormField<String?>(
              value: parent,
              decoration: const InputDecoration(
                labelText: 'Parent (optionnel)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Aucun')),
                ..._accounts.map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.code} - ${a.title}'),
                  ),
                ),
              ],
              onChanged: (v) => parent = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == true) {
      final id = existing?.id ?? codeCtrl.text.trim();
      final compte = CompteComptable(
        id: id,
        code: codeCtrl.text.trim(),
        title: titleCtrl.text.trim(),
        parentId: parent,
      );
      await LocalDatabase.instance.insertCompte(compte.toMap());
      await _loadData();
    }
  }

  Future<void> _deleteAccount(CompteComptable account) async {
    final hasChild = await LocalDatabase.instance.hasChildAccounts(account.id);
    final used = await LocalDatabase.instance.countEcrituresForAccountCode(
      account.code,
    );
    if (hasChild || used > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasChild
                ? 'Impossible de supprimer: des sous-comptes existent.'
                : 'Impossible de supprimer: des écritures utilisent ce compte.',
          ),
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Text('${account.code} - ${account.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LocalDatabase.instance.deleteCompte(account.id);
      await _loadData();
    }
  }

  Future<void> _showEntryDialog() async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord un compte.')),
      );
      return;
    }
    final labelCtrl = TextEditingController();
    final debitCtrl = TextEditingController();
    final creditCtrl = TextEditingController();
    DateTime date = DateTime.now();
    String journal = _journaux.isNotEmpty
        ? _journaux.first['id'] as String
        : 'j_od';
    String account = _accounts.first.code;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle écriture'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Libellé'),
              ),
              DropdownButtonFormField<String>(
                value: journal,
                decoration: const InputDecoration(labelText: 'Journal'),
                items: _journaux
                    .map(
                      (j) => DropdownMenuItem(
                        value: j['id'] as String,
                        child: Text('${j['code']} - ${j['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => journal = v ?? journal,
              ),
              DropdownButtonFormField<String>(
                value: account,
                decoration: const InputDecoration(labelText: 'Compte'),
                items: _accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.code,
                        child: Text('${a.code} - ${a.title}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => account = v ?? account,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: debitCtrl,
                decoration: const InputDecoration(labelText: 'Débit'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: creditCtrl,
                decoration: const InputDecoration(labelText: 'Crédit'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    date = picked;
                  }
                },
                icon: const Icon(Icons.event),
                label: const Text('Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final debit = double.tryParse(debitCtrl.text.replaceAll(',', '.')) ?? 0;
      final credit = double.tryParse(creditCtrl.text.replaceAll(',', '.')) ?? 0;
      final entry = EcritureComptable(
        id: 'ec_${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        label: labelCtrl.text.trim().isEmpty
            ? 'Sans libellé'
            : labelCtrl.text.trim(),
        journalId: journal,
        accountCode: account,
        debit: debit,
        credit: credit,
      );
      await LocalDatabase.instance.insertEcriture(entry.toMap());
      await _loadData();
    }
  }
}

class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  _DateRange _range = _DateRange.last30;

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchExpenses();
  }

  void _addExpense() {
    final label = _labelController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (label.isEmpty || amount <= 0) return;
    LocalDatabase.instance.insertExpense(label: label, amount: amount).then((
      _,
    ) {
      setState(() {
        _future = LocalDatabase.instance.fetchExpenses();
        _labelController.clear();
        _amountController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceScaffold(
      title: 'Dépenses',
      subtitle: 'Saisie locale (persistée)',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final expenses = _filterExpenses(snapshot.data ?? [], _range);
          final total = expenses.fold<double>(
            0,
            (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble(),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeSelector(
                current: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 12),
              _StatRow(
                items: [
                  _StatItem(
                    label: 'Total',
                    value: _money.format(total),
                    color: Colors.orangeAccent,
                  ),
                  _StatItem(
                    label: 'Entrées',
                    value: '${expenses.length}',
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ExpenseForm(
                labelController: _labelController,
                amountController: _amountController,
                onAdd: _addExpense,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : expenses.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune dépense saisie',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final e = expenses[index];
                          final createdAt =
                              DateTime.tryParse(
                                e['createdAt'] as String? ?? '',
                              ) ??
                              DateTime.now();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e['label'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _money.format(
                                    (e['amount'] as num? ?? 0).toDouble(),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceScaffold extends StatelessWidget {
  const _FinanceScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceHeaderRow extends StatelessWidget {
  const _FinanceHeaderRow({
    required this.total,
    required this.deposits,
    required this.outstanding,
    required this.money,
  });

  final double total;
  final double deposits;
  final double outstanding;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return _StatRow(
      items: [
        _StatItem(
          label: 'Total',
          value: money.format(total),
          color: Colors.greenAccent,
        ),
        _StatItem(
          label: 'Encaissements',
          value: money.format(deposits),
          color: Colors.blueAccent,
        ),
        _StatItem(
          label: 'Restant',
          value: money.format(outstanding),
          color: Colors.orangeAccent,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
}

class _ReservationPaymentsList extends StatelessWidget {
  const _ReservationPaymentsList({
    required this.reservations,
    required this.money,
    required this.emptyLabel,
    this.highlightOutstanding = false,
    this.onUpdated,
    this.enablePaymentActions = false,
  });

  final List<Map<String, dynamic>> reservations;
  final NumberFormat money;
  final String emptyLabel;
  final bool highlightOutstanding;
  final VoidCallback? onUpdated;
  final bool enablePaymentActions;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: const TextStyle(color: Colors.white70)),
      );
    }

    return ListView.separated(
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = reservations[index];
        final amount = (r['amount'] as num? ?? 0).toDouble();
        final deposit = (r['deposit'] as num? ?? 0).toDouble();
        final outstanding = amount - deposit;
        final paymentStatus = (r['paymentStatus'] as String? ?? '').isEmpty
            ? (outstanding <= 0 ? 'Payé' : 'En attente')
            : r['paymentStatus'] as String;
        final paymentMethod = (r['paymentMethod'] as String? ?? '').trim();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['guestName'] as String? ?? 'Client',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ch. ${r['roomNumber'] ?? '?'} • ${r['roomType'] ?? 'Type'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Statut paiement : $paymentStatus',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (paymentMethod.isNotEmpty)
                      Text(
                        'Mode : $paymentMethod',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money.format(amount),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acompte : ${money.format(deposit)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (highlightOutstanding || outstanding > 0)
                    Text(
                      'Reste : ${money.format(outstanding)}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  if (enablePaymentActions)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _openPaymentSheet(context, r),
                        icon: const Icon(Icons.point_of_sale, size: 16),
                        label: const Text('Encaisser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPaymentSheet(
    BuildContext context,
    Map<String, dynamic> reservation,
  ) {
    final amountController = TextEditingController(
      text: ((reservation['deposit'] as num?) ?? 0).toString(),
    );
    String method = (reservation['paymentMethod'] as String? ?? '').trim();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.point_of_sale, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Encaisser / mettre à jour',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Acompte / paiement',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mode de paiement',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentMethods
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m),
                        selected: method == m,
                        onSelected: (_) => method = m,
                        selectedColor: const Color(0xFF6C63FF),
                        labelStyle: TextStyle(
                          color: method == m ? Colors.white : Colors.white70,
                        ),
                        backgroundColor: const Color(0xFF1B1B2F),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final deposit =
                        double.tryParse(
                          amountController.text.replaceAll(',', '.'),
                        ) ??
                        0;
                    await LocalDatabase.instance.updateReservationPayment(
                      reservation['id'] as int,
                      deposit: deposit,
                      paymentMethod: method.isEmpty ? null : method,
                    );
                    onUpdated?.call();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    required this.labelController,
    required this.amountController,
    required this.onAdd,
  });

  final TextEditingController labelController;
  final TextEditingController amountController;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter une dépense (session locale)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Libellé',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Montant',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _DateRange { today, last7, last30, all }

const List<String> _paymentMethods = [
  'Espèces',
  'Carte bancaire',
  'Mobile Money',
  'Virement bancaire',
  'Chèque',
  'Différé',
  'Mixte',
];

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.current, required this.onChanged});

  final _DateRange current;
  final ValueChanged<_DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = _DateRange.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (r) => ChoiceChip(
              label: Text(_label(r)),
              selected: current == r,
              onSelected: (_) => onChanged(r),
              selectedColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(
                color: current == r ? Colors.white : Colors.white70,
              ),
              backgroundColor: const Color(0xFF1B1B2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
          .toList(),
    );
  }

  String _label(_DateRange r) {
    switch (r) {
      case _DateRange.today:
        return 'Aujourd\'hui';
      case _DateRange.last7:
        return '7 jours';
      case _DateRange.last30:
        return '30 jours';
      case _DateRange.all:
        return 'Tout';
    }
  }
}

List<Map<String, dynamic>> _filterReservations(
  List<Map<String, dynamic>> items,
  _DateRange range,
) {
  if (range == _DateRange.all) return items;
  final now = DateTime.now();
  DateTime? start;
  switch (range) {
    case _DateRange.today:
      start = DateTime(now.year, now.month, now.day);
      break;
    case _DateRange.last7:
      start = now.subtract(const Duration(days: 7));
      break;
    case _DateRange.last30:
      start = now.subtract(const Duration(days: 30));
      break;
    case _DateRange.all:
      break;
  }
  final startDate = start;
  if (startDate == null) return items;
  return items.where((r) {
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    if (checkIn == null) return true;
    return !checkIn.isBefore(startDate);
  }).toList();
}

List<Map<String, dynamic>> _filterExpenses(
  List<Map<String, dynamic>> items,
  _DateRange range,
) {
  if (range == _DateRange.all) return items;
  final now = DateTime.now();
  DateTime? start;
  switch (range) {
    case _DateRange.today:
      start = DateTime(now.year, now.month, now.day);
      break;
    case _DateRange.last7:
      start = now.subtract(const Duration(days: 7));
      break;
    case _DateRange.last30:
      start = now.subtract(const Duration(days: 30));
      break;
    case _DateRange.all:
      break;
  }
  final startDate = start;
  if (startDate == null) return items;
  return items.where((e) {
    final created = DateTime.tryParse(e['createdAt'] as String? ?? '');
    if (created == null) return true;
    return !created.isBefore(startDate);
  }).toList();
}

class _PaymentFilter extends StatelessWidget {
  const _PaymentFilter({required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Tous'),
          selected: current == null,
          onSelected: (_) => onChanged(null),
          selectedColor: const Color(0xFF6C63FF),
          labelStyle: TextStyle(
            color: current == null ? Colors.white : Colors.white70,
          ),
          backgroundColor: const Color(0xFF1B1B2F),
        ),
        ..._paymentMethods.map(
          (m) => ChoiceChip(
            label: Text(m),
            selected: current == m,
            onSelected: (_) => onChanged(m),
            selectedColor: const Color(0xFF6C63FF),
            labelStyle: TextStyle(
              color: current == m ? Colors.white : Colors.white70,
            ),
            backgroundColor: const Color(0xFF1B1B2F),
          ),
        ),
      ],
    );
  }
}

List<Map<String, dynamic>> _filterByPayment(
  List<Map<String, dynamic>> reservations,
  String? method,
) {
  if (method == null) return reservations;
  return reservations.where((r) {
    final m = (r['paymentMethod'] as String? ?? '').toLowerCase();
    return m == method.toLowerCase();
  }).toList();
}

class _PaymentSummaryRow extends StatelessWidget {
  const _PaymentSummaryRow({required this.data, required this.money});

  final List<Map<String, dynamic>> data;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (final r in data) {
      final method = (r['paymentMethod'] as String? ?? 'Inconnu').trim();
      final deposit = (r['deposit'] as num? ?? 0).toDouble();
      totals[method.isEmpty ? 'Inconnu' : method] =
          (totals[method.isEmpty ? 'Inconnu' : method] ?? 0) + deposit;
    }
    if (totals.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: totals.entries
            .map(
              (e) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money.format(e.value),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
