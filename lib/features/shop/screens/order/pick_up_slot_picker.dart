import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product/horaire_controller.dart';
import '../../models/jour_semaine.dart';

class PickUpSlotPicker extends StatelessWidget {
  final HoraireController horaireController = Get.find();
  final Function(DateTime pickupDateTime, String dayLabel, String timeRange)
      onSlotSelected;

  PickUpSlotPicker({required this.onSlotSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horaires = horaireController.horaires;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choisir un créneau de retrait', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: horaires.length,
              itemBuilder: (ctx, index) {
                final h = horaires[index];
                final dayLabel = h.jour.valeur;
                if (!h.isValid) {
                  return ListTile(
                    title: Text(dayLabel),
                    subtitle: Text('Fermé'),
                    enabled: false,
                  );
                }
                final timeRange = '${h.ouverture} - ${h.fermeture}';
                return ListTile(
                  title: Text(dayLabel),
                  subtitle: Text(timeRange),
                  onTap: () {
                    // Choix: par défaut prendre aujourd'hui + ouverture comme heure de pickup
                    // Ou déterminer date future correspondant à ce jour de la semaine.
                    final now = DateTime.now();
                    // Trouver prochaine date correspondant à ce jour
                    final targetWeekday = _weekdayFromJour(h.jour);
                    final daysToAdd =
                        (targetWeekday - now.weekday + 7) % 7; // 0..6
                    final chosenDate = now.add(Duration(days: daysToAdd));
                    // convertir ouverture (HH:mm) en heure
                    final parts = h.ouverture!.split(':');
                    final pickupDateTime = DateTime(chosenDate.year,
                        chosenDate.month, chosenDate.day, int.parse(parts[0]), int.parse(parts[1]));

                    onSlotSelected(pickupDateTime, dayLabel, timeRange);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _weekdayFromJour(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
        return 1;
      case JourSemaine.mardi:
        return 2;
      case JourSemaine.mercredi:
        return 3;
      case JourSemaine.jeudi:
        return 4;
      case JourSemaine.vendredi:
        return 5;
      case JourSemaine.samedi:
        return 6;
      case JourSemaine.dimanche:
        return 7;
    }
  }
}