import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/local_database.dart';
import '../widgets/action_button.dart';
import '../widgets/setting_card.dart';

class SecuriteTab extends StatefulWidget {
  const SecuriteTab({super.key});

  @override
  State<SecuriteTab> createState() => _SecuriteTabState();
}

class _SecuriteTabState extends State<SecuriteTab> {
  bool _autoBackup = true;
  String _backupFrequency = 'Quotidienne';
  int _retentionDays = 30;
  String? _lastBackupPath;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingCard(
          title: 'Sauvegarde & restauration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.backup_rounded, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SwitchListTile(
                      value: _autoBackup,
                      onChanged: (v) => setState(() => _autoBackup = v),
                      activeColor: const Color(0xFF10B981),
                      title: const Text(
                        'Sauvegarde automatique',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              if (_autoBackup) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Quotidienne', 'Hebdomadaire', 'Mensuelle']
                      .map(
                        (opt) => ChoiceChip(
                          label: Text(opt),
                          selected: _backupFrequency == opt,
                          onSelected: (_) =>
                              setState(() => _backupFrequency = opt),
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          labelStyle: TextStyle(
                            color: _backupFrequency == opt
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Rétention: $_retentionDays jours',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Expanded(
                      child: Slider(
                        value: _retentionDays.toDouble(),
                        min: 7,
                        max: 90,
                        divisions: 83,
                        onChanged: (v) =>
                            setState(() => _retentionDays = v.toInt()),
                        activeColor: const Color(0xFF10B981),
                        inactiveColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  ActionButton(
                    icon: Icons.save_alt_rounded,
                    label: 'Sauvegarder maintenant',
                    color: Color(0xFF10B981),
                    onTap: _performBackup,
                  ),
                  const SizedBox(width: 8),
                  ActionButton(
                    icon: Icons.restore_rounded,
                    label: 'Restaurer',
                    color: const Color(0xFFef4444),
                    onTap: _restoreBackup,
                  ),
                ],
              ),
              if (_lastBackupPath != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dernière sauvegarde: $_lastBackupPath',
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: _lastBackupPath!),
                      ),
                      child: const Text('Copier'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SettingCard(
          title: 'Affichage',
          child: const Text(
            'Mode sombre géré au niveau de l’app (pas de réglage ici).',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Future<void> _restoreBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choisir une sauvegarde',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (picked == null) return;
    final path = picked.files.single.path;
    if (path == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer la sauvegarde'),
        content: Text('Restaurer le fichier suivant ?\n$path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurer'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              Navigator.of(context).pop(false);
            },
            child: const Text('Copier le chemin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await LocalDatabase.instance.restoreDatabase(sourcePath: path);
        setState(() => _lastBackupPath = path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base restaurée avec succès.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de restauration: $e')));
      }
    }
  }

  Future<void> _performBackup() async {
    final target = await FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder la base de données',
      fileName: 'roommaster_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (target == null) return;
    try {
      await LocalDatabase.instance.backupDatabase(targetPath: target);
      setState(() => _lastBackupPath = target);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sauvegarde réalisée.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de sauvegarde: $e')));
    }
  }
}
