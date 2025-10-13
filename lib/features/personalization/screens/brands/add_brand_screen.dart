import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../controllers/user_controller.dart';

class AddEtablissementScreen extends StatefulWidget {
  const AddEtablissementScreen({super.key});

  @override
  State<AddEtablissementScreen> createState() => _AddEtablissementScreenState();
}

class _AddEtablissementScreenState extends State<AddEtablissementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final EtablissementController _controller =
      EtablissementController(EtablissementRepository());
  final UserController userController = Get.find<UserController>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    final user = userController.user.value;
    if (user.role != 'Gérant') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        TLoaders.errorSnackBar(
            message: 'Seuls les Gérants peuvent créer des établissements');

        Get.back();
      });
    }
  }

  void _addEtablissement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = userController.user.value;

    final etab = Etablissement(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _latitudeController.text.isNotEmpty
          ? double.tryParse(_latitudeController.text)
          : null,
      longitude: _longitudeController.text.isNotEmpty
          ? double.tryParse(_longitudeController.text)
          : null,
      idOwner: user.id,
    );

    try {
      // CORRECTION : Créer l'établissement SANS horaires
      final id = await _controller.createEtablissement(etab); // Sans horaires

      if (id != null) {
        TLoaders.successSnackBar(
            message:
                'Établissement créé avec succès. Vous pourrez ajouter les horaires plus tard.');
        _formKey.currentState!.reset();
        Get.back(result: true);
      } else {
        TLoaders.errorSnackBar(
            message: 'Erreur lors de la création de l\'établissement');
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = userController.user.value;

    if (user.role != 'Gérant') {
      return Scaffold(
        appBar: TAppBar(
          title: const Text('Accès refusé'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Accès réservé aux Gérants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Seuls les utilisateurs avec le rôle "Gérant" peuvent créer des établissements.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Ajouter un établissement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Carte rôle utilisateur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connecté en tant que :',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Gérant',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Champs du formulaire
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer le nom' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty
                    ? 'Veuillez entrer l\'adresse'
                    : null,
              ),
              const SizedBox(height: 16),

              // Information sur les horaires
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horaires d\'ouverture',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vous pourrez configurer les horaires après la création de l\'établissement',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Coordonnées GPS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Les coordonnées GPS sont optionnelles',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Bouton de soumission
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addEtablissement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Créer l\'établissement',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
