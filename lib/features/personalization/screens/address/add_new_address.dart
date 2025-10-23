import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/validators/validation.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    final userController = UserController.instance;

    // Prefill user info once
    controller.name.text = userController.user.value.fullName ?? '';
    controller.phoneNumber.text = userController.user.value.phone ?? '';

    return Scaffold(
      appBar: const TAppBar(title: Text("Ajouter une adresse")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Form(
          key: controller.addressFormKey,
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Toggle Map / Manual Entry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sélectionner sur la carte",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: controller.useMap.value,
                        onChanged: (v) => controller.useMap.value = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// --- MAP MODE ---
                  if (controller.useMap.value) ...[
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(36.8065, 10.1815), // Tunis default
                          zoom: 12,
                        ),
                        onTap: controller.setMapAddress,
                        markers: controller.selectedLocation.value != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: controller.selectedLocation.value!,
                                )
                              }
                            : {},
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (controller.selectedLocation.value != null)
                      Text(
                        "Position sélectionnée: ${controller.selectedLocation.value!.latitude.toStringAsFixed(5)}, ${controller.selectedLocation.value!.longitude.toStringAsFixed(5)}",
                        style:
                            const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    if (controller.isLoadingAddress.value)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: AppSizes.spaceBtwInputFields),
                  ],

                  /// --- MANUAL FIELDS (ALSO FILLED AUTOMATICALLY BY MAP) ---
                  TextFormField(
                    controller: controller.street,
                    validator: (value) =>
                        TValidator.validateEmptyText("Rue", value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.building_31),
                        labelText: 'Rue'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.postalCode,
                          validator: (value) => TValidator.validateEmptyText(
                              'Code Postal', value),
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.activity),
                              labelText: 'Code Postal'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          controller: controller.city,
                          validator: (value) =>
                              TValidator.validateEmptyText('Cité', value),
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.building),
                              labelText: 'Cité'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.state,
                    validator: (value) =>
                        TValidator.validateEmptyText('Gouvernorat', value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.activity),
                        labelText: 'Gouvernorat'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.country,
                    validator: (value) =>
                        TValidator.validateEmptyText('Pays', value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.global), labelText: 'Pays'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),

                  /// --- USER INFO (AUTO-FILLED) ---
                  TextFormField(
                    controller: controller.name,
                    validator: (value) =>
                        TValidator.validateEmptyText("Nom", value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.user), labelText: 'Nom'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.phoneNumber,
                    validator: (value) =>
                        TValidator.validatePhoneNumber(value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.mobile),
                        labelText: 'Numéro de téléphone'),
                  ),

                  const SizedBox(height: AppSizes.defaultSpace),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.addNewAddress,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
