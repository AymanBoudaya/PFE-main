import 'package:caferesto/features/authentication/controllers/signup/signup_controller.dart';
import 'package:get/get.dart';

import '../data/repositories/etablissement/etablissement_repository.dart';
import '../data/repositories/product/produit_repository.dart';
import '../data/repositories/user/user_repository.dart';
import '../features/authentication/controllers/signup/verify_otp_controller.dart';
import '../features/personalization/controllers/address_controller.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../features/shop/controllers/etablissement_controller.dart';
import '../features/shop/controllers/product/checkout_controller.dart';
import '../features/shop/controllers/product/variation_controller.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProduitRepository());
    Get.lazyPut(() => UserRepository());
    Get.lazyPut(() => EtablissementRepository());

    Get.lazyPut(() => SignupController());
    Get.lazyPut(() => OTPVerificationController());
    Get.lazyPut(() => UserController());
    Get.lazyPut(() => VariationController());
    Get.lazyPut(() => AddressController());
    Get.lazyPut(() => CheckoutController());
    Get.lazyPut(
        () => EtablissementController(Get.find<EtablissementRepository>()));

    Get.put(NetworkManager(), permanent: true);
  }
}
