enum StatutEtablissement { enAttente, approuve, rejete }

extension StatutEtablissementExt on StatutEtablissement {
  String get value {
    switch (this) {
      case StatutEtablissement.approuve:
        return 'approuve';
      case StatutEtablissement.rejete:
        return 'rejete';
      default:
        return 'en_attente';
    }
  }

  static StatutEtablissement fromString(String? s) {
    switch (s) {
      case 'approuve':
        return StatutEtablissement.approuve;
      case 'rejete':
        return StatutEtablissement.rejete;
      default:
        return StatutEtablissement.enAttente;
    }
  }
}
