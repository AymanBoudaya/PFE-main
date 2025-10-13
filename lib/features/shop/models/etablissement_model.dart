
import 'statut_etablissement_model.dart';

import 'horaire_model.dart';

class Etablissement {
  final String? id;
  final String name;
  final String address;
  final String? imageUrl;
  final StatutEtablissement statut;
  final double? latitude;
  final double? longitude;
  final String idOwner;
  final DateTime? createdAt;
  final List<Horaire>? horaires;

  Etablissement({
    this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.statut = StatutEtablissement.enAttente,
    this.latitude,
    this.longitude,
    required this.idOwner,
    this.createdAt,
    this.horaires,
  });

  factory Etablissement.fromJson(Map<String, dynamic> json) {
    List<Horaire>? horaires;
    if (json['horaires'] != null && json['horaires'] is List) {
      horaires = (json['horaires'] as List).map((e) => Horaire.fromJson(e)).toList();
    }

    return Etablissement(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      imageUrl: json['image_url'],
      statut: StatutEtablissementExt.fromString(json['statut']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      idOwner: json['id_owner'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      horaires: horaires,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'image_url': imageUrl,
      'statut': statut.value,
      'latitude': latitude,
      'longitude': longitude,
      'id_owner': idOwner,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}