import 'package:flutter/material.dart';
import '../widgets/setting_card.dart';

class CloudTab extends StatelessWidget {
  const CloudTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingCard(
          title: 'Connexion Cloud',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // État de connexion avec badge visuel
              _CloudRow(
                label: 'État',
                value: 'Déconnecté',
                actionLabel: 'Connecter',
                onTap: () {},
                statusColor: Colors.red,
                icon: Icons.cloud_off,
              ),
              const Divider(height: 24, color: Colors.white12),
              
              // Endpoint
              _CloudRow(
                label: 'Endpoint',
                value: 'api.roommaster.app',
                icon: Icons.dns,
                isSubdued: true,
              ),
              const Divider(height: 24, color: Colors.white12),
              
              // Profil
              _CloudRow(
                label: 'Profil',
                value: 'Aucun profil cloud associé',
                actionLabel: 'Associer',
                onTap: () {},
                icon: Icons.person_outline,
              ),
              const Divider(height: 24, color: Colors.white12),
              
              // Diagnostics
              _CloudRow(
                label: 'Diagnostics',
                value: 'Ping: n/a • Sync: n/a',
                actionLabel: 'Tester',
                onTap: () {},
                icon: Icons.analytics_outlined,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card d'information supplémentaire
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connectez-vous au cloud pour synchroniser vos données',
                  style: TextStyle(color: Colors.blue[200], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloudRow extends StatelessWidget {
  const _CloudRow({
    required this.label,
    required this.value,
    this.actionLabel,
    this.onTap,
    this.statusColor,
    this.icon,
    this.isSubdued = false,
  });

  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Color? statusColor;
  final IconData? icon;
  final bool isSubdued;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône à gauche
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: statusColor ?? Colors.white60,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Contenu principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (statusColor != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor!.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: isSubdued ? Colors.white54 : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Bouton d'action
        if (actionLabel != null)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}