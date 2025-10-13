import 'package:caferesto/features/personalization/screens/categories/widgets/category_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../shop/controllers/category_controller.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final CategoryController _categoryController = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    _categoryController.clearForm();
    return Scaffold(
      appBar: TAppBar(
        title: const Text("Ajouter Catégorie"),
      ),
      body: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _categoryController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              CategoryImageSection(
                onPickImage: _categoryController.pickImage,
                pickedImage: _categoryController.pickedImage.value,
              ),
              const SizedBox(height: 40),

              // Formulaire
              CategoryFormCard(
                children: [
                  CategoryNameField(
                    controller: _categoryController.nameController,
                  ),
                  const SizedBox(height: 24),
                  CategoryParentDropdown(
                    selectedParentId:
                        _categoryController.selectedParentId.value,
                    categories: _categoryController.allCategories,
                    onChanged: (value) {
                      _categoryController.selectedParentId.value = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CategoryFeaturedSwitch(
                        value: _categoryController.isFeatured.value,
                        onChanged: (value) {
                          _categoryController.isFeatured.value = value;
                        },
                      )),
                ],
              ),
              const SizedBox(height: 32),

              // Bouton Ajouter
              Obx(() => CategorySubmitButton(
                    isLoading: _categoryController.isLoading.value,
                    onPressed: () async {
                      await _categoryController.addCategory();
                    },
                    text: "Ajouter la catégorie",
                    icon: Icons.add_circle_outline,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/*import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../shop/controllers/category_controller.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final CategoryController _categoryController = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text('Ajouter catégorie'),
        showBackArrow: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _categoryController.formKey,
          child: Column(
            children: [
              // Section Image
              Obx(() {
                final imageFile = _categoryController.pickedImage.value;
                return GestureDetector(
                  onTap: _categoryController.pickImage,
                  child: CircleAvatar(
                    radius: 60, // Rayon du cercle (60 => diamètre 120)
                    backgroundColor: Colors.white, // fond gris clair
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile) as ImageProvider
                        : AssetImage(TImages.pasdimage),
                  ),
                );
              }),

              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _categoryController.pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Choisir une image'),
              ),

              const SizedBox(height: 16),

              // Champ nom de la catégorie
              TextFormField(
                controller: _categoryController.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Dropdown catégorie parente
              Obx(() {
                return DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: "Catégorie parente (optionnel)",
                    border: OutlineInputBorder(),
                  ),
                  value: _categoryController.selectedParentId.value,
                  items: _categoryController.allCategories.map((cat) {
                    return DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    _categoryController.selectedParentId.value = val;
                  },
                );
              }),


              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Checkbox catégorie en vedette
              Obx(() => CheckboxListTile(
                title: const Text('Catégorie en vedette'),
                value: _categoryController.isFeatured.value,
                onChanged: (val) {
                  _categoryController.isFeatured.value = val ?? false;
                },
              )),

              const SizedBox(height: 20),

              // Bouton Ajouter
              Obx(() => _categoryController.isLoading.value
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _categoryController.addCategory();
                  },
                  child: const Text('Ajouter'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
 MODIFIER LE CODE DE import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../shop/controllers/category_controller.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final CategoryController _categoryController = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text('Ajouter catégorie'),
        showBackArrow: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _categoryController.formKey,
          child: Column(
            children: [
              // Section Image
              Obx(() {
                final imageFile = _categoryController.pickedImage.value;
                return GestureDetector(
                  onTap: _categoryController.pickImage,
                  child: CircleAvatar(
                    radius: 60, // Rayon du cercle (60 => diamètre 120)
                    backgroundColor: Colors.white, // fond gris clair
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile) as ImageProvider
                        : AssetImage(TImages.pasdimage),
                  ),
                );
              }),

              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _categoryController.pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Choisir une image'),
              ),

              const SizedBox(height: 16),

              // Champ nom de la catégorie
              TextFormField(
                controller: _categoryController.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Dropdown catégorie parente
              Obx(() {
                return DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: "Catégorie parente (optionnel)",
                    border: OutlineInputBorder(),
                  ),
                  value: _categoryController.selectedParentId.value,
                  items: _categoryController.allCategories.map((cat) {
                    return DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    _categoryController.selectedParentId.value = val;
                  },
                );
              }),


              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Checkbox catégorie en vedette
              Obx(() => CheckboxListTile(
                title: const Text('Catégorie en vedette'),
                value: _categoryController.isFeatured.value,
                onChanged: (val) {
                  _categoryController.isFeatured.value = val ?? false;
                },
              )),

              const SizedBox(height: 20),

              // Bouton Ajouter
              Obx(() => _categoryController.isLoading.value
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _categoryController.addCategory();
                  },
                  child: const Text('Ajouter'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}*/
