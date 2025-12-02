Application SaaS de Gestion Hôtelière
Hôtels, Maisons de Passage & Chambres d'Hôtes
Architecture Multi-Plateforme (Web + Mobile + Desktop)
 
🏗️ Architecture Technique
Stack Technologique
Backend (API REST/GraphQL)
•	Framework : Node.js + Express / NestJS
•	Base de données : PostgreSQL (données relationnelles) + Redis (cache)
•	Authentification : JWT + OAuth2
•	Storage : AWS S3 / MinIO (documents, photos)
•	Queue : Redis Bull (tâches asynchrones)
Frontend Multi-Plateforme
├── 📱 Mobile : Flutter (iOS + Android)
├── 💻 Web : React + Next.js (responsive)
├── 🖥️ Desktop : Electron / Flutter Desktop
└── 🏪 Kiosque : PWA tactile pour réception
Base de Données PostgreSQL
-- Tables principales
- tenants (multi-tenant architecture)
- etablissements
- chambres
- categories_chambres
- clients
- reservations
- check_ins
- check_outs
- transactions_financieres
- factures
- services_additionnels
- consommations
- employes
- planning_personnel
- taches_menage
- inventaire
- tarifs_dynamiques
- logs_activites
- parametres_etablissement
Architecture Multi-Tenant
Tenant 1 (Hôtel A)  ─┐
Tenant 2 (Hôtel B)  ─┼─→ API Gateway → Backend → Base données isolée
Tenant 3 (Hôtel C)  ─┘
Isolation des données :
•	Schéma séparé par tenant
•	Sécurité au niveau rang (Row-Level Security)
•	Backup indépendant par établissement
 
📱 Modules & Écrans Détaillés
🔹 1. TABLEAU DE BORD
Vue d'ensemble temps réel
Widgets principaux :
•	Occupation actuelle : Taux d'occupation (jauge animée), chambres disponibles/occupées
•	Revenue du jour : CA actuel vs prévisionnel, RevPAR, ADR
•	Graphiques : 
o	Courbe d'occupation sur 30 jours
o	CA par catégorie de chambre
o	Top services additionnels
•	Alertes prioritaires : 
o	Arrivées du jour non check-in
o	Départs non check-out
o	Chambres en maintenance
o	Paiements en attente
o	Stock bas (minibar, linge)
Actions rapides :
•	Bouton FAB : "Nouvelle réservation"
•	Quick check-in/check-out
•	Recherche globale (client, réservation, chambre)
•	Notification center (temps réel)
Tableau synoptique chambres :
Disponible | Occupée | Sale | En nettoyage | Maintenance | Réservée
   🟢          🔴       🟡        🔵           🟠           🟣
 
🔹 2. GESTION DES RÉSERVATIONS
Écran principal : Planning visuel
Vue calendrier/Timeline :
•	Affichage Gantt par chambre
•	Drag & drop pour modifier réservations
•	Color-coding par statut : Confirmée, Provisoire, Annulée, No-show
•	Filtres : Dates, type chambre, statut, source réservation
Channels de réservation :
•	Directe (téléphone, walk-in)
•	Site web (moteur de réservation intégré)
•	OTA (Booking.com, Airbnb, Expedia via API)
•	Agences de voyage
•	Corporate (entreprises partenaires)
Écran détail réservation
Tabs:
├── 📋 Informations réservation
│   ├── Dates (arrivée/départ, durée)
│   ├── Type chambre demandé
│   ├── Nombre de personnes (adultes/enfants)
│   ├── Préférences (lit, étage, vue)
│   └── Statut et source
├── 👤 Informations client
│   ├── Données personnelles
│   ├── Historique séjours
│   ├── Préférences enregistrées
│   └── Programme fidélité
├── 💰 Détails tarifaires
│   ├── Tarif par nuit (dynamique)
│   ├── Services inclus
│   ├── Taxes et frais
│   ├── Remises/Promotions appliquées
│   └── Total et acompte
├── 💳 Paiements
│   ├── Acompte versé
│   ├── Solde restant
│   ├── Garantie bancaire
│   └── Historique transactions
└── 📝 Notes & Demandes spéciales
    ├── Demandes client
    ├── Notes internes
    └── Communications
Formulaire nouvelle réservation
Wizard en étapes :
1.	Recherche disponibilité : Dates + type chambre + nb personnes
2.	Sélection chambre : Affichage chambres disponibles avec photos/tarifs
3.	Informations client : Nouveau client ou sélection existant
4.	Services additionnels : Petit-déjeuner, parking, transfert aéroport
5.	Paiement : Acompte ou paiement complet, mode de paiement
6.	Confirmation : Récapitulatif et envoi confirmation email/SMS
Fonctionnalités avancées :
•	Tarification dynamique en temps réel
•	Overbooking contrôlé avec alertes
•	Upgrade automatique si catégorie non disponible
•	Split reservation (plusieurs chambres)
•	Bloc de chambres pour groupes
 
🔹 3. GESTION DES CHAMBRES
Écran catalogue chambres
Affichage :
•	Vue grille avec photos, numéro, catégorie, statut
•	Vue liste détaillée
•	Vue plan d'étage (mapping visuel)
Informations par chambre :
•	Numéro et catégorie
•	Équipements (climatisation, TV, WiFi, minibar)
•	Capacité (lits, personnes max)
•	Statut actuel (disponible, occupée, maintenance)
•	Tarifs par saison
•	Photos (galerie)
Catégories de chambres
Types standards :
├── Économique / Standard
├── Confort / Supérieure
├── Deluxe
├── Suite Junior
├── Suite Exécutive
└── Appartement

Caractéristiques par catégorie :
├── Prix de base
├── Équipements inclus
├── Surface
├── Type de lit
├── Capacité maximale
└── Photos/Descriptions
États des chambres (Housekeeping)
Workflow statuts :
Occupée Propre → Départ Client → Sale → En Nettoyage → Inspection → Disponible Propre
                                   ↓
                               Maintenance (si problème détecté)
                                   ↓
                          Réparation → Inspection → Disponible
Écran gestion états :
•	Tableau avec toutes les chambres
•	Changement statut en un clic
•	Attribution des tâches au personnel
•	Timer par tâche
•	Photos avant/après nettoyage
•	Checklist inspection qualité
 
🔹 4. GESTION DES CLIENTS
Base de données clients (CRM)
Écran liste clients :
•	DataTable avec colonnes : Photo, Nom, Contact, Nb séjours, CA total, Dernière visite
•	Filtres : VIP, Fidélité, Nationalité, Source
•	Segmentation : Clients fréquents, Corporate, Loisirs
Fiche client détaillée
Tabs:
├── 📋 Profil
│   ├── Données personnelles (nom, contact, adresse)
│   ├── Documents (CNI, passeport, visa)
│   ├── Photo de profil
│   └── Statut fidélité
├── 🏨 Historique séjours
│   ├── Liste des réservations passées
│   ├── Préférences observées
│   ├── Feedback et notes
│   └── Incidents signalés
├── 💰 Historique financier
│   ├── Total dépenses
│   ├── Factures émises
│   ├── Paiements effectués
│   ├── Impayés éventuels
│   └── Crédits/Avoirs
├── ⭐ Programme fidélité
│   ├── Points accumulés
│   ├── Niveau actuel (Bronze, Silver, Gold)
│   ├── Avantages disponibles
│   └── Historique récompenses
└── 📞 Communications
    ├── Emails envoyés
    ├── SMS reçus/envoyés
    ├── Campagnes marketing
    └── Préférences contact
Programme de fidélité
Système de points :
•	1 point = 1 000 FCFA dépensé
•	Niveaux : Bronze (0-500), Silver (500-2000), Gold (2000+)
•	Avantages par niveau : Upgrade gratuit, late checkout, welcome drink
•	Points échangeables contre nuits gratuites
 
🔹 5. CHECK-IN / CHECK-OUT
Processus Check-In
Écran check-in (optimisé tablette) :
1.	Recherche réservation : Par nom, numéro réservation, code QR
2.	Vérification identité : Scan CNI/Passeport, photo
3.	Confirmation détails : Dates, tarif, services
4.	Attribution chambre : Si non pré-attribuée
5.	Paiement/Garantie : Empreinte CB ou acompte
6.	Signature contrat : Signature électronique
7.	Remise clés : Enregistrement avec système de clés RFID
8.	Welcome pack : Impression guide de l'hôtel
Check-in express :
•	Kiosque en libre-service
•	QR code sur mobile
•	Check-in mobile à distance
Processus Check-Out
Écran check-out :
1.	Récupération séjour : Par numéro chambre
2.	Vérification minibar : Ajout consommations non enregistrées
3.	Services additionnels : Vérification derniers services
4.	Génération facture : Facture détaillée automatique
5.	Paiement solde : Si reste à payer
6.	Retour clés : Désactivation badge
7.	Feedback : Questionnaire satisfaction rapide
8.	Invitation retour : Code promo prochain séjour
Late checkout :
•	Gestion des demandes
•	Surcharge automatique selon taux d'occupation
•	Validation instantanée
 
🔹 6. FACTURATION & CAISSE
Génération automatique factures
Types de factures :
•	Facture séjour (hébergement + services)
•	Facture services uniquement (restaurant, bar)
•	Facture groupée (événements, séminaires)
•	Facture pro-forma (devis)
Template personnalisable :
•	Logo et infos établissement
•	Détail journalier ou global
•	Taxes (TVA, taxe séjour)
•	Conditions de paiement
•	Mentions légales
•	QR code pour paiement mobile
Système de caisse intégré
Écran encaissement :
•	Saisie montant ou scan facture
•	Modes de paiement : 
o	Espèces (calcul monnaie automatique)
o	Carte bancaire (TPE intégré)
o	Mobile Money (API MTN, Moov, Orange)
o	Virement bancaire
o	Chèque
o	Paiement différé (entreprises)
o	Mixte (plusieurs moyens)
Gestion de caisse :
•	Ouverture/Fermeture caisse
•	Fond de caisse
•	Dépôts intermédiaires
•	Rapport de caisse (attendu vs réel)
•	Gestion des écarts
•	Historique des transactions
Facture folio (note de frais)
Suivi en temps réel :
•	Affichage folio par chambre
•	Ajout services pendant séjour
•	Consommations minibar
•	Room service
•	Pressing, téléphone, spa
•	Split billing (partage entre personnes/entreprises)
 
🔹 7. SERVICES ADDITIONNELS
Catalogue services
Services proposés :
•	Restauration (petit-déjeuner, restaurant, room service)
•	Bar et minibar
•	Spa et bien-être
•	Blanchisserie/Pressing
•	Transfert aéroport
•	Location véhicules
•	Excursions touristiques
•	Salle de réunion/séminaire
•	Parking
Gestion par service :
•	Tarification
•	Disponibilité/Horaires
•	Personnel assigné
•	Stock (si applicable)
•	Commissions (partenaires externes)
Point de vente (POS) intégré
Module restaurant/bar :
•	Menu digital
•	Prise de commande tablette
•	Envoi cuisine/bar automatique
•	Facturation sur chambre ou directe
•	Gestion tables
•	Split check
 
🔹 8. HOUSEKEEPING (Entretien)
Gestion du personnel d'entretien
Écran planning ménage :
•	Liste des chambres à nettoyer
•	Priorités : Départs, VIP, longue attente
•	Attribution aux femmes de chambre
•	Tracking temps réel
•	Validation qualité
Application mobile pour femmes de chambre :
•	Liste des chambres assignées
•	Checklist par chambre (30+ points)
•	Signalement problèmes (ampoule, robinet...)
•	Photos avant/après
•	Changement statut chambre
•	Relevé minibar consommé
Inventaire linge
Gestion stock :
•	Draps, serviettes, peignoirs
•	Entrées/Sorties quotidiennes
•	Blanchisserie interne/externe
•	Alertes stock minimum
•	Calcul usure et remplacement
 
🔹 9. PERSONNEL & PLANNING
Gestion employés
Base de données RH :
•	Informations personnelles
•	Contrats et documents
•	Planning de travail (shifts)
•	Heures travaillées/supplémentaires
•	Congés et absences
•	Salaires et primes
•	Évaluations performance
Rôles et permissions :
├── 👔 Directeur (accès total)
├── 🧑‍💼 Manager (gestion opérationnelle)
├── 🏨 Réceptionniste (check-in/out, réservations)
├── 💰 Caissier (paiements, facturation)
├── 🧹 Femme de chambre (housekeeping)
├── 👨‍🍳 Restauration (POS restaurant/bar)
├── 🔧 Maintenance (tickets, réparations)
└── 📊 Comptable (reporting, finances)
Planning de travail
Écran planning :
•	Calendrier hebdomadaire/mensuel
•	Gestion des shifts (matin, soir, nuit)
•	Pointage entrée/sortie
•	Demandes de congés
•	Remplacement automatique
•	Export paie
 
🔹 10. MAINTENANCE & INVENTAIRE
Gestion maintenance
Tickets de maintenance :
•	Création ticket (chambre, équipement, urgence)
•	Attribution technicien
•	Suivi statut (ouvert, en cours, résolu)
•	Photos du problème
•	Pièces utilisées
•	Temps de résolution
•	Validation qualité
Maintenance préventive :
•	Planning entretien équipements (clim, chaudière, ascenseur)
•	Rappels automatiques
•	Historique interventions
•	Coûts de maintenance
Inventaire général
Gestion stock :
•	Minibar (boissons, snacks)
•	Linge (draps, serviettes)
•	Produits d'entretien
•	Amenities (savons, shampooings)
•	Fournitures bureau
•	Pièces détachées
Fonctionnalités :
•	Entrées/Sorties
•	Inventaire physique périodique
•	Alertes réapprovisionnement
•	Gestion fournisseurs
•	Coûts moyens et valorisation stock
 
🔹 11. TARIFICATION DYNAMIQUE
Yield Management
Stratégies tarifaires :
•	Tarifs de base par catégorie
•	Tarifs par saison (haute, moyenne, basse)
•	Tarifs par jour de la semaine
•	Tarifs événements spéciaux
•	Tarifs last minute
•	Tarifs early booking
Moteur de tarification dynamique :
•	Ajustement automatique selon taux d'occupation
•	Analyse concurrence (si API disponibles)
•	Prévisions occupancy
•	Optimisation RevPAR
Promotions et packages
Types de promotions :
•	Code promo (réduction %)
•	Offres spéciales (2 nuits = 3ème offerte)
•	Packages (chambre + petit-déj + spa)
•	Tarifs groupes
•	Tarifs corporate (entreprises partenaires)
•	Programme fidélité
 
🔹 12. CHANNEL MANAGER
Intégration OTA (Online Travel Agencies)
Connexion API :
•	Booking.com
•	Expedia
•	Airbnb
•	Hotels.com
•	Agoda
•	TripAdvisor
Synchronisation bidirectionnelle :
•	Disponibilités en temps réel
•	Tarifs mis à jour automatiquement
•	Réservations importées automatiquement
•	Inventaire unifié (évite overbooking)
Moteur de réservation propre
Site web intégré :
•	Widget de recherche
•	Affichage disponibilités
•	Réservation en ligne sécurisée
•	Paiement en ligne (Stripe, PayPal, Mobile Money)
•	Confirmation automatique email/SMS
 
🔹 13. REPORTING & ANALYTICS
Tableau de bord financier
KPIs principaux :
├── 💰 Indicateurs revenus
│   ├── RevPAR (Revenue Per Available Room)
│   ├── ADR (Average Daily Rate)
│   ├── Chiffre d'affaires total
│   ├── CA par département (hébergement, restaurant, services)
│   └── Évolution MoM et YoY
├── 📊 Indicateurs occupation
│   ├── Taux d'occupation (%)
│   ├── Durée moyenne de séjour
│   ├── Chambres vendues vs disponibles
│   └── Prévisions occupation
├── 👥 Indicateurs clients
│   ├── Nombre de clients
│   ├── Taux de retour
│   ├── Score satisfaction
│   └── Source de réservation
└── 💸 Indicateurs financiers
    ├── Taux de no-show
    ├── Taux d'annulation
    ├── Délai moyen de paiement
    └── Impayés
Rapports standards
Rapports quotidiens :
•	Rapport d'occupation
•	Arrivées/Départs du jour
•	Rapport de caisse
•	Liste chambres hors service
Rapports mensuels :
•	Compte de résultat
•	Bilan occupation
•	Analyse revenus par segment
•	Performance vs budget
•	Top clients
•	Statistiques housekeeping
Rapports personnalisés :
•	Générateur de requêtes visuelles
•	Filtres multiples
•	Export Excel/PDF
•	Envoi automatique programmé
Business Intelligence
Analyses avancées :
•	Prévisions occupation (Machine Learning)
•	Segmentation clientèle
•	Analyse saisonnalité
•	Benchmark concurrence
•	Optimisation pricing
•	Analyse rentabilité par canal
 
🔹 14. COMMUNICATION CLIENT
Messagerie automatisée
Email automatique :
•	Confirmation réservation
•	Rappel arrivée (J-3, J-1)
•	Instructions check-in
•	Welcome email post check-in
•	Questionnaire satisfaction post-départ
•	Offres promotionnelles ciblées
SMS automatique :
•	Code d'accès chambre
•	Rappels
•	Promotions flash
•	Alertes importantes
CRM Marketing
Campagnes ciblées :
•	Segmentation clients (loisirs, affaires, familles)
•	Newsletters
•	Offres anniversaire
•	Réactivation clients inactifs
•	Programme parrainage
Feedback management :
•	Questionnaires satisfaction
•	Collecte avis (Google, TripAdvisor)
•	Réponse avis automatisée
•	Analyse sentiment
 
🔹 15. SÉCURITÉ & CONFORMITÉ
Registre de police
Déclaration obligatoire :
•	Enregistrement identité clients
•	Transmission automatique autorités (si API gouvernementale)
•	Archivage sécurisé
•	Export format requis
Protection données (RGPD)
Conformité :
•	Consentement explicite collecte données
•	Droit à l'oubli
•	Portabilité des données
•	Registre des traitements
•	Chiffrement base de données
•	Logs d'accès
Contrôle d'accès
Système de badges/clés :
•	Intégration serrures électroniques (API)
•	Gestion clés RFID/NFC
•	Activation/Désactivation à distance
•	Historique accès chambres
•	Clés temporaires personnel
 
🔹 16. PARAMÈTRES & ADMINISTRATION
Configuration établissement
Informations générales :
•	Nom, adresse, contacts
•	Logo et photos
•	Numéros administratifs (RC, NIF)
•	Réseaux sociaux
•	Langues supportées
•	Devise et taxes
Paramètres opérationnels :
•	Heures check-in/check-out standard
•	Politique annulation
•	Temps nettoyage chambre
•	Délai réservation en ligne
•	Acompte minimum
Intégrations
APIs tierces :
•	Passerelles paiement (Stripe, CinetPay, Fedapay)
•	Mobile Money (MTN, Moov, Orange)
•	Channel Manager (OTA)
•	Comptabilité (export vers logiciels)
•	Email (SendGrid, Mailgun)
•	SMS (Twilio, Africa's Talking)
Sauvegarde & Sécurité
Backup automatique :
•	Sauvegarde quotidienne base de données
•	Stockage cloud redondant
•	Rétention 30 jours
•	Test restauration mensuel
Sécurité :
•	Authentification 2FA
•	SSL/TLS encryption
•	Logs d'activité complets
•	Détection intrusion
•	Mises à jour sécurité automatiques
 
🎨 Interface Utilisateur
Design System
Framework UI :
•	Material Design 3 / Fluent Design
•	Thème personnalisable par établissement
•	Mode sombre/clair
•	Responsive (mobile, tablette, desktop)
•	Support multilingue (FR, EN, ES, AR)
Composants réutilisables :
•	DataTables avancées (tri, filtres, export)
•	Calendriers interactifs
•	Drag & drop
•	Charts dynamiques (Chart.js / Recharts)
•	Notifications push temps réel
•	Modals et wizards
•	Signature électronique
•	Scan QR/Barcode
•	Upload documents
UX optimisée par rôle
Réceptionniste :
•	Dashboard simplifié
•	Accès rapide check-in/out
•	Vue occupation en un coup d'œil
Direction :
•	KPIs en première page
•	Rapports synthétiques
•	Alertes critiques
Femme de chambre :
•	Interface mobile ultra-simple
•	Gros boutons tactiles
•	Checklist visuelle
 
⚡ Fonctionnalités Avancées
Performance & Scalabilité
Optimisations :
•	CDN pour assets statiques
•	Cache Redis pour requêtes fréquentes
•	Compression images automatique
•	Lazy loading
•	Pagination intelligente
•	Indexation base de données optimisée
•	Load balancing
Automatisations intelligentes
IA et Machine Learning :
•	Prédiction taux d'occupation
•	Optimisation pricing dynamique
•	Détection fraude paiement
•	Chatbot client 24/7
•	Reconnaissance vocale (commandes)
•	Analyse sentiment avis clients
Mode Offline
Fonctionnement hors ligne :
•	Synchronisation automatique au retour connexion
•	Cache local (SQLite mobile)
•	Queue de transactions
•	Alertes resync
Intégrations IoT
Objets connectés :
•	Serrures connectées (ouverture mobile)
•	Thermostats intelligents (économies énergie)
•	Détecteurs présence chambres
•	Gestion éclairage automatique
•	Minibar intelligent (détection consommation)
 
🔄 Workflows Types
Réservation → Séjour → Départ
Réservation en ligne
    ↓
Confirmation automatique (Email/SMS)
    ↓
Rappel J-3 avec infos pratiques
    ↓
Check-in (scan ID + paiement garantie)
    ↓
Attribution chambre + remise badge
    ↓
Séjour (consommations ajoutées au folio)
    ↓
Demande check-out
    ↓
Génération facture finale
    ↓
Paiement solde
    ↓
Check-out + retour badge
    ↓
Email satisfaction + code promo retour
Cycle de vie d'une chambre
Disponible Propre
    ↓
Réservée
    ↓
Occupée (client check-in)
    ↓
Occupée Sale (client check-out)
    ↓
Attribution femme de chambre
    ↓
En Nettoyage (30-45 min)
    ↓
Inspection Qualité
    ↓ (OK)                    ↓ (Problème)
Disponible Propre        Maintenance
                              ↓
                         Réparation
                              ↓
                    Inspection → Disponible
Gestion incident client
Signalement problème (client ou staff)
    ↓
Création ticket avec priorité
    ↓
Attribution personnel compétent
    ↓
Notification mobile technicien
    ↓
Intervention
    ↓
Clôture ticket avec commentaire
    ↓
Notification client
    ↓
Geste commercial si nécessaire (upgrade, remise)
 
📊 Modèle de Tarification SaaS
Abonnement par nombre de chambres
Plans proposés :
•	Starter (1-10 chambres) : 20 000 FCFA/mois
•	Business (11-30 chambres) : 50 000 FCFA/mois
•	Professional (31-100 chambres) : 120 000 FCFA/mois
•	Enterprise (100+ chambres) : Sur devis
Inclus dans tous les plans :
•	Hébergement cloud
•	Support technique
•	Mises à jour automatiques
•	Backup quotidien
•	SSL/Sécurité
Options additionnelles :
•	Channel Manager OTA : +15 000 FCFA/mois
•	Module POS Restaurant : +10 000 FCFA/mois
•	Kiosque check-in automatique : +20 000 FCFA/mois
•	IA Pricing dynamique : +25 000 FCFA/mois
 
🚀 Roadmap de Développement
Phase 1 (3 mois) - MVP :
•	Gestion réservations
•	Check-in/Check-out
•	Gestion chambres
•	Facturation basique
•	Caisse
Phase 2 (2 mois) - Core Features :
•	Housekeeping complet
•	CRM clients
•	Reporting avancé
•	Mobile app (Flutter)
Phase 3 (2 mois) - Advanced :
•	Channel Manager OTA
•	Pricing dynamique
•	POS Restaurant
•	Programme fidélité
Phase 4 (Continu) - Optimisation :
•	IA prédictive
•	IoT intégrations
•	Analytics avancés
•	Expansion internationale
 
📱 Applications Mobiles Spécifiques
App Client (iOS/Android)
Fonctionnalités :
•	Réservation mobile
•	Check-in mobile (QR code)
•	Clé digitale (ouverture chambre smartphone)
•	Room service commande
•	Services spa/excursions
•	Chat support 24/7
•	Facture digitale
•	Programme fidélité
App Staff (iOS/Android)
Par rôle :
•	Réception : Check-in/out rapide
•	Housekeeping : Liste tâches, checklist
•	Maintenance : Tickets, interventions
•	Management : Dashboard KPIs temps réel
 
🏆 Avantages Compétitifs
Par rapport solutions existantes :
•	✅ 100% adapté marché africain (Mobile Money, offline)
•	✅ Interface en français
•	✅ Prix abordable pour PME
•	✅ Pas de frais setup
•	✅ Support local
•	✅ Conformité réglementations locales
•	✅ Multi-plateforme (Web + Mobile + Desktop)
•	✅ Tout-en-un (pas besoin multiples logiciels)
Document v1.0 - Architecture complète prête pour développement

