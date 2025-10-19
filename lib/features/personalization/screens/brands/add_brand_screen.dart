import 'dart:typed_data';

import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../controllers/user_controller.dart';
import '../categories/widgets/category_form_widgets.dart';
import 'map_picker_screen.dart';

class AddEtablissementScreen extends StatefulWidget {
  const AddEtablissementScreen({super.key});

  @override
  State<AddEtablissementScreen> createState() => _AddEtablissementScreenState();
}

class _AddEtablissementScreenState extends State<AddEtablissementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final EtablissementController _controller =
      EtablissementController(EtablissementRepository());
  final UserController userController = Get.find<UserController>();
// Add these variables
  String _selectedAddressFromMap = '';

// Add these methods
  Future<void> _selectLocationFromMap() async {
    try {
      final double? currentLat = _latitudeController.text.isNotEmpty
          ? double.tryParse(_latitudeController.text)
          : null;
      final double? currentLng = _longitudeController.text.isNotEmpty
          ? double.tryParse(_longitudeController.text)
          : null;

      final result = await Get.to(() => MapPickerScreen(
            initialLatitude: currentLat,
            initialLongitude: currentLng,
          ));

      if (result != null) {
        setState(() {
          _latitudeController.text = result['latitude'].toStringAsFixed(6);
          _longitudeController.text = result['longitude'].toStringAsFixed(6);
          _selectedAddressFromMap = result['address'] ?? '';

          // Also update the address field if it's empty
          if (_addressController.text.isEmpty &&
              _selectedAddressFromMap.isNotEmpty) {
            _addressController.text = _selectedAddressFromMap;
          }
        });
      }
    } catch (e) {
      print('Error selecting location from map: $e');
      TLoaders.errorSnackBar(
          message: 'Erreur lors de la sélection sur la carte: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      TLoaders.infoSnackBar(message: 'Obtention de votre position...');

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          TLoaders.errorSnackBar(
              message: 'Permissions de localisation refusées');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        TLoaders.errorSnackBar(
          message:
              'Permissions de localisation définitivement refusées. Activez-les dans les paramètres.',
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _selectedAddressFromMap =
              '${place.street ?? ''}, ${place.postalCode ?? ''} ${place.locality ?? ''}, ${place.country ?? ''}';

          // Update address field
          if (_addressController.text.isEmpty) {
            _addressController.text = _selectedAddressFromMap;
          }
        }
      });

      TLoaders.successSnackBar(message: 'Localisation actuelle récupérée');
    } catch (e) {
      print('Error getting current location: $e');
      TLoaders.errorSnackBar(
          message: 'Erreur lors de l\'obtention de la localisation: $e');
    }
  }

  bool _isLoading = false;
  XFile? _selectedImage;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);
    _animationController!.forward();
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

  // Upload d'image
  Future<void> _pickMainImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = picked);
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur sélection image: $e');
    }
  }

  // Création avec upload d'image
  void _addEtablissement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = userController.user.value;

    // Upload de l'image si sélectionnée
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _controller.uploadEtablissementImage(_selectedImage!);
      if (imageUrl == null) {
        TLoaders.errorSnackBar(message: 'Erreur lors de l\'upload de l\'image');
        setState(() => _isLoading = false);
        return;
      }
    }

    final etab = Etablissement(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      imageUrl: imageUrl,
      latitude: _latitudeController.text.isNotEmpty
          ? double.tryParse(_latitudeController.text)
          : null,
      longitude: _longitudeController.text.isNotEmpty
          ? double.tryParse(_longitudeController.text)
          : null,
      idOwner: user.id,
    );

    try {
      final id = await _controller.createEtablissement(etab);

      if (id != null) {
        TLoaders.successSnackBar(message: 'Établissement créé avec succès');
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

  // Section image
  Widget _buildImageSection(double width) {
    final previewHeight =
        (width >= 900) ? 220.0 : (width >= 600 ? 200.0 : 160.0);
    final previewWidth = double.infinity;
    final borderRadius = BorderRadius.circular(12.0);

    Widget mainImageWidget() {
      if (_selectedImage != null) {
        return FutureBuilder<Uint8List?>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: borderRadius,
                child: Image.memory(snapshot.data!,
                    fit: BoxFit.cover,
                    width: previewWidth,
                    height: previewHeight),
              );
            } else {
              return SizedBox(
                height: previewHeight,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        );
      } else {
        return SizedBox(
          height: previewHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.grey, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Ajouter une image',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
    }

    return CategoryFormCard(
      children: [
        const Text('Image de l\'établissement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickMainImage,
          child: Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: borderRadius,
            ),
            child: mainImageWidget(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cliquez pour sélectionner une image (optionnel)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Section informations de base
  Widget _buildBasicInfoSection(double width) {
    final isWide = width >= 900;

    return CategoryFormCard(children: [
      const Text('Informations de base',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
            labelText: 'Nom de l\'établissement *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_outlined)),
        validator: (v) =>
            v == null || v.isEmpty ? 'Veuillez entrer le nom' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
            labelText: 'Adresse complète *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined)),
        maxLines: isWide ? 4 : 3,
        validator: (v) =>
            v == null || v.isEmpty ? 'Veuillez entrer l\'adresse' : null,
      ),
      const SizedBox(height: 16),

      // Information sur les horaires
      Card(
        color: THelperFunctions.isDarkMode(context)
            ? AppColors.eerieBlack
            : Colors.white,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    ]);
  }

  // Section coordonnées GPS
  // Widget _buildCoordinatesSection(double width) {
  //   final isWide = width >= 900;

  //   return CategoryFormCard(children: [
  //     const Text('Coordonnées GPS',
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //     const SizedBox(height: 12),
  //     Row(
  //       children: [
  //         Expanded(
  //           child: TextFormField(
  //             controller: _latitudeController,
  //             decoration: const InputDecoration(
  //               labelText: 'Latitude',
  //               border: OutlineInputBorder(),
  //               prefixIcon: Icon(Icons.explore_outlined),
  //             ),
  //             keyboardType: TextInputType.numberWithOptions(decimal: true),
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: TextFormField(
  //             controller: _longitudeController,
  //             decoration: const InputDecoration(
  //               labelText: 'Longitude',
  //               border: OutlineInputBorder(),
  //               prefixIcon: Icon(Icons.explore_outlined),
  //             ),
  //             keyboardType: TextInputType.numberWithOptions(decimal: true),
  //           ),
  //         ),
  //       ],
  //     ),
  //     const SizedBox(height: 8),
  //     Text(
  //       'Les coordonnées GPS sont optionnelles - utilisées pour la géolocalisation',
  //       style: Theme.of(context).textTheme.bodySmall,
  //     ),
  //   ]);
  // }

  Widget _buildCoordinatesSection(double width) {
    final isWide = width >= 900;

    return CategoryFormCard(children: [
      const Text('Coordonnées GPS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),

      // Location selection buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectLocationFromMap,
              icon: const Icon(Icons.map),
              label: const Text('Sélectionner sur la carte'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Ma position'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Coordinates display (read-only)
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.explore_outlined),
                suffixIcon: Icon(Icons.lock), // Show it's read-only
              ),
              readOnly: true, // Make it read-only
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.explore_outlined),
                suffixIcon: Icon(Icons.lock), // Show it's read-only
              ),
              readOnly: true, // Make it read-only
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Selected address display
      if (_selectedAddressFromMap.isNotEmpty) ...[
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAddressFromMap,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],

      Text(
        'Utilisez les boutons ci-dessus pour sélectionner la localisation',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }

  // Section rôle utilisateur
  Widget _buildUserRoleSection() {
    final user = userController.user.value;

    return CategoryFormCard(
      children: [
        const Text('Rôle utilisateur',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
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
                    user.role,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = userController.user.value;

    if (user.role != 'Admin' && user.role != 'Gérant') {
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
                'Accès réservé aux Administrateurs et Gérants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Seuls les utilisateurs avec le rôle "Admin" ou "Gérant" peuvent créer des établissements.',
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
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 900;
          final isDesktop = width >= 900;

          // On large screens, show a centered column with max width
          final content = ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth:
                    isDesktop ? 1100 : (isTablet ? 760 : double.infinity)),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Responsive two-column layout for tablet/desktop
                    if (isDesktop || isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: image + user role
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildImageSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildUserRoleSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right column: basic info + coordinates + submit
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBasicInfoSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildCoordinatesSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                // Submit area
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _addEtablissement,
                                        icon: const Icon(Iconsax.add_circle),
                                        label: const Text(
                                            'Créer l\'établissement'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(55),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Small helper text
                                Text(
                                  'Les champs marqués d\'un * sont requis.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Mobile single-column layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildUserRoleSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildBasicInfoSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildCoordinatesSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addEtablissement,
                            icon: const Icon(Iconsax.add_circle),
                            label: const Text('Créer l\'établissement'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20, vertical: 16),
              child: content,
            ),
          );
        }),
      ),
    );
  }
}
