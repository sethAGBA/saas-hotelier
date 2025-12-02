
import 'package:flutter/material.dart';
import '../models/personnel.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({Key? key}) : super(key: key);

  @override
  _PersonnelScreenState createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  // Dummy data - replace with actual data from a database
  final List<Personnel> _personnelList = [
    Personnel(id: 'p1', nom: 'Koffi', prenom: 'Akossiwa', poste: 'Professeur de Mathématiques', photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg'),
    Personnel(id: 'p2', nom: 'Abalo', prenom: 'Kodjo', poste: 'Professeur de Physique', statut: 'Inactif', photoUrl: 'https://randomuser.me/api/portraits/men/43.jpg'),
    Personnel(id: 'p3', nom: 'Dosseh', prenom: 'Yawa', poste: 'Surveillante Générale', photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg'),
    Personnel(id: 'p4', nom: 'Lawson', prenom: 'Komi', poste: 'Professeur d\'Histoire', photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg'),
  ];

  late List<Personnel> _filteredPersonnelList;
  String _filtreStatut = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPersonnelList = _personnelList;
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    setState(() {
      _filteredPersonnelList = _personnelList.where((p) {
        final searchLower = _searchController.text.toLowerCase();
        final nameMatch = p.nomComplet.toLowerCase().contains(searchLower);
        final posteMatch = p.poste.toLowerCase().contains(searchLower);
        
        final statutMatch = (_filtreStatut == 'Tous') || (p.statut == _filtreStatut);

        return (nameMatch || posteMatch) && statutMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: _buildPersonnelTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Gestion du Personnel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou poste...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterDropdown(),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add new personnel dialog/screen
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtreStatut,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _filtreStatut = newValue;
                _filterList();
              });
            }
          },
          items: <String>['Tous', 'Actif', 'Inactif']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPersonnelTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Photo')),
          DataColumn(label: Text('Nom Complet')),
          DataColumn(label: Text('Poste')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _filteredPersonnelList.map((personnel) {
          return DataRow(cells: [
            DataCell(
              CircleAvatar(
                backgroundImage: personnel.photoUrl != null
                    ? NetworkImage(personnel.photoUrl!)
                    : null,
                child: personnel.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            DataCell(Text(personnel.nomComplet)),
            DataCell(Text(personnel.poste)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: personnel.statut == 'Actif' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  personnel.statut,
                  style: TextStyle(color: personnel.statut == 'Actif' ? Colors.green.shade800 : Colors.red.shade800),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      // TODO: Implement edit functionality
                    },
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      // TODO: Implement delete functionality
                    },
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
