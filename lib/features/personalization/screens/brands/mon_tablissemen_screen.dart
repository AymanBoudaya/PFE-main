import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../../../features/personalization/controllers/user_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../../shop/models/statut_etablissement_model.dart';
import 'edit_brand_screen.dart';
import 'add_brand_screen.dart';

class MonEtablissementScreen extends StatefulWidget {
  const MonEtablissementScreen({super.key});

  @override
  State<MonEtablissementScreen> createState() => _MonEtablissementScreenState();
}

class _MonEtablissementScreenState extends State<MonEtablissementScreen> {
  late final EtablissementController _controller;
  late final UserController _userController;
  String _userRole = '';
  bool _chargement = true;
  List<Etablissement> _etablissements = []; // ✅ Stockage local

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _chargerEtablissements();
  }

  void _initializeControllers() {
    try {
      _controller = Get.find<EtablissementController>();
    } catch (e) {
      _controller = Get.put(EtablissementController(EtablissementRepository()));
    }

    try {
      _userController = Get.find<UserController>();
    } catch (e) {
      _userController = Get.put(UserController());
    }

    _userRole = _userController.userRole;
  }

  void _chargerEtablissements() async {
    setState(() {
      _chargement = true;
    });

    try {
      final user = _userController.user.value;
      if (_userRole == 'Gérant' && user.id.isNotEmpty) {
        final data = await _controller.fetchEtablissementsByOwner(user.id);
        setState(() {
          _etablissements = data ?? [];
        });
      } else if (_userRole == 'Admin') {
        final data = await _controller.getTousEtablissements();
        setState(() {
          _etablissements = data;
        });
      }
    } catch (e) {
      // print('Erreur chargement établissements: $e');
      Get.snackbar('Erreur', 'Impossible de charger les établissements');
      setState(() {
        _etablissements = [];
      });
    } finally {
      setState(() {
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return TAppBar(
      title: Text(
        _userRole == 'Admin'
            ? "Gestion des établissements"
            : "Mon établissement",
      ),
    );
  }

  Widget _buildBody() {
    if (_chargement) return _buildLoadingState();

    if (_userRole != 'Admin' && _userRole != 'Gérant')
      return _buildAccesRefuse();

    if (_etablissements.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () async => _chargerEtablissements(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _etablissements.length,
        itemBuilder: (context, index) {
          final e = _etablissements[index];
          return _buildEtablissementCard(e, index);
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return _userRole == 'Gérant' && _etablissements.isEmpty
        ? FloatingActionButton(
            onPressed: () async {
              final result = await Get.to(() => AddEtablissementScreen());
              if (result == true) _chargerEtablissements();
            },
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, size: 28),
          )
        : const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Chargement des établissements...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesRefuse() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Accès refusé",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Cette fonctionnalité est réservée aux Gérants et Administrateurs",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            "Votre rôle: $_userRole",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _userRole == 'Admin'
                ? "Aucun établissement trouvé"
                : "Vous n'avez pas d'établissement",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'Admin'
                ? "Les établissements apparaîtront ici une fois créés"
                : "Commencez par créer votre premier établissement",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (_userRole == 'Gérant') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Get.to(() => AddEtablissementScreen());
                if (result == true) _chargerEtablissements();
              },
              icon: const Icon(Icons.add),
              label: const Text("Créer mon établissement"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEtablissementCard(Etablissement etablissement, int index) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: _buildEtablissementImage(etablissement),
        title: Text(etablissement.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: _buildEtablissementSubtitle(etablissement),
        trailing: _buildStatutBadge(etablissement.statut),
        onTap: () => _showEtablissementOptions(etablissement),
      ),
    );
  }

  Widget _buildEtablissementImage(Etablissement etablissement) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: Colors.blue.shade50),
      child: Icon(Icons.business, color: Colors.blue.shade600, size: 24),
    );
  }

  Widget _buildEtablissementSubtitle(Etablissement etablissement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etablissement.address,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (_userRole == 'Admin') ...[
          const SizedBox(height: 4),
          Text("Propriétaire: ${etablissement.idOwner}",
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ],
    );
  }

  Widget _buildStatutBadge(StatutEtablissement statut) {
    final (color, text) = _getStatutInfo(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  (Color, String) _getStatutInfo(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.enAttente:
        return (Colors.orange, "En attente");
      case StatutEtablissement.approuve:
        return (Colors.green, "Approuvé");
      case StatutEtablissement.rejete:
        return (Colors.red, "Rejeté");
    }
  }

  void _showEtablissementOptions(Etablissement etablissement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(etablissement),
    );
  }

  Widget _buildBottomSheetContent(Etablissement etablissement) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(etablissement),
          const SizedBox(height: 16),
          _buildActionButtons(etablissement),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Annuler"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader(Etablissement etablissement) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildEtablissementImage(etablissement),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etablissement.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(etablissement.address,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildStatutBadge(etablissement.statut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Etablissement etablissement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Get.to(() =>
                      EditEtablissementScreen(etablissement: etablissement));
                  if (result == true) _chargerEtablissements();
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text("Éditer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          if (_userRole == 'Admin' || _userRole == 'Gérant')
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(etablissement),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text("Supprimer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Etablissement etablissement) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Text("Confirmer la suppression")
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Êtes-vous sûr de vouloir supprimer l'établissement \"${etablissement.name}\" ?",
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                "Cette action est irréversible.",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Annuler"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEtablissement(etablissement);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Supprimer"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _deleteEtablissement(Etablissement etablissement) {
    if (etablissement.id == null) {
      TLoaders.errorSnackBar(
        message: 'Impossible de supprimer l\'établissement : ID manquant',
      );
      return;
    }

    _controller.deleteEtablissement(etablissement.id!);
    _chargerEtablissements();
  }
}
