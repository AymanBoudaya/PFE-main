import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/personalization/screens/profile/profile.dart';
import 'package:caferesto/features/shop/screens/order/order.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/list_tiles/settings_menu_tile.dart';
import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../shop/screens/product_reviews/list_produit_screen.dart';
import '../../controllers/user_controller.dart';
import '../address/address.dart';
import '../brands/mon_tablissemen_screen.dart';
import '../categories/category_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());

    bool canAddCategory() {
      final role = userController.user.value.role;
      return role == 'Admin';
    }

    bool canAddEtablissement() {
      final role = userController.user.value.role;
      return role == 'Gérant' || role == 'Admin';
    }

    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
        children: [
          /// En tete
          TPrimaryHeaderContainer(
            child: Column(
              children: [
                TAppBar(
                    showBackArrow: false,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Compte',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .apply(color: AppColors.white)),
                        Text(
                          userController.user.value.role,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .headlineSmall!
                              .apply(color: AppColors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )),

                /// Carte du profil avec nom et email
                TUserProfileTile(
                    onPressed: () => Get.to(() => const ProfileScreen())),
                const SizedBox(height: AppSizes.spaceBtwSections),
              ],
            ),
          ),

          Padding(
              padding: EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(children: [
                /// Paramètres du compte
                TSectionHeading(
                  title: "Réglages du compte",
                  showActionButton: false,
                ),
                SizedBox(height: AppSizes.spaceBtwItems),

                TSettingsMenuTile(
                    title: "Mes Adresses",
                    subTitle: "Mes adresses de livraison",
                    icon: Iconsax.safe_home,
                    onTap: () => Get.to(() => const UserAddressScreen())),
                TSettingsMenuTile(
                    title: "Mon Panier",
                    subTitle: "Ajouter, modifier ou supprimer des articles",
                    icon: Iconsax.shopping_cart,
                    onTap: () {}),
                TSettingsMenuTile(
                    title: "Mes Commandes",
                    subTitle: "Commandes passées et en cours",
                    icon: Iconsax.bag_tick,
                    onTap: () => Get.to(() => const OrderScreen())),
                TSettingsMenuTile(
                    title: "Notifications",
                    subTitle: "Notifications de l'application",
                    icon: Iconsax.notification,
                    onTap: () {}),
                TSettingsMenuTile(
                    title: "Sécurité du Compte",
                    subTitle: "Sécuriser mon compte",
                    icon: Iconsax.security_card,
                    onTap: () {}),

                /// Paramètres de l'app
                SizedBox(height: AppSizes.spaceBtwSections),
                TSectionHeading(title: "Paramètres", showActionButton: false),
                SizedBox(height: AppSizes.spaceBtwItems),
                TSettingsMenuTile(
                    icon: Iconsax.location,
                    title: "Géolocalisation",
                    subTitle:
                        "Définir une recommandation à partir de ma position",
                    trailing: Switch(value: true, onChanged: (value) {})),

                /// Développeur , upload
                SizedBox(height: AppSizes.spaceBtwSections),
                TSectionHeading(
                    title: "Développement", showActionButton: false),
                SizedBox(height: AppSizes.spaceBtwItems),
                SizedBox(height: AppSizes.spaceBtwItems),
                if (canAddCategory())
                  TSettingsMenuTile(
                    icon: Iconsax.category,
                    title: "Gérer catégorie",
                    subTitle:
                        "Consulter, ajouter, modifier ou supprimer une catégorie",
                    onTap: () async {
                      final result =
                          await Get.to(() => CategoryManagementPage());
                      if (result == true) {
                        // Le formulaire a été réinitialisé
                        print("Écran fermé et formulaire réinitialisé");
                      }
                    },
                  ),
                SizedBox(height: AppSizes.spaceBtwItems),
                if (canAddEtablissement())
                  TSettingsMenuTile(
                    icon: Iconsax.home,
                    title: "Gérer  établissement",
                    subTitle:
                        "Consulter, ajouter, modifier ou supprimer un établissement",
                    onTap: () => Get.to(() => MonEtablissementScreen()),
                  ),
                SizedBox(
                  height: AppSizes.spaceBtwItems,
                ),

                if (canAddEtablissement())
                  TSettingsMenuTile(
                    icon: Iconsax.bag_tick_2,
                    title: "Gérer produit",
                    subTitle:
                        "Consulter, ajouter, modifier ou supprimer un produit",
                    onTap: () => Get.to(() => ListProduitScreen()),
                  ),
                SizedBox(
                  height: AppSizes.spaceBtwSections,
                ),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () =>
                            AuthenticationRepository.instance.logout(),
                        child: Text("Logout")))
              ]))
        ],
      )),
    );
  }
}
