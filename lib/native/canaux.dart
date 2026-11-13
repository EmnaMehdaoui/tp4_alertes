
import 'package:flutter/services.dart';

class CanauxNatifs {

  // Etapes 1 et 2 : notifications
  static const _alerte =
      MethodChannel('alerte/notifier');

  static Future<bool> demanderPermissionNotif() async =>
      await _alerte.invokeMethod<bool>(
        'demanderPermission'
      ) ?? false;

  static Future<int?> notifier(
    String titre,
    String texte
  ) =>
      _alerte.invokeMethod<int>(
        'notifier',
        {
          'titre': titre,
          'texte': texte,
        },
      );

  // Récupérer une action au démarrage à froid
  static Future<Map<String, dynamic>?> actionInitiale() =>
      _alerte.invokeMapMethod<String, dynamic>(
        'actionInitiale'
      );

  // Ecouter les actions lorsque l'application est ouverte
  static void ecouterActions(
    void Function(Map<String, dynamic>) traiter
  ) {

    _alerte.setMethodCallHandler((call) async {

      if (call.method == 'surAction') {

        traiter(
          Map<String, dynamic>.from(
            call.arguments as Map
          ),
        );
      }
    });
  }

  // Etape 3 : WorkManager
  static const _sync =
      MethodChannel('sync/planifier');

  static Future<void> planifier(int seuil) =>
      _sync.invokeMethod(
        'planifier',
        {'seuil': seuil},
      );

  static Future<void> verifierMaintenant(int seuil) =>
      _sync.invokeMethod(
        'maintenant',
        {'seuil': seuil},
      );

  static Future<void> annulerPlanification() =>
      _sync.invokeMethod('annuler');

  // Etape 4 : service au premier plan
  static const _service =
      MethodChannel('service/surveillance');

  static Future<void> demarrerSurveillance(
    double seuil
  ) =>
      _service.invokeMethod(
        'demarrer',
        {'seuil': seuil},
      );

  static Future<void> arreterSurveillance() =>
      _service.invokeMethod('arreter');

  // Exercice 2 : vérifier si le service tourne
  static Future<bool> estSurveillanceActive() async =>
      await _service.invokeMethod<bool>(
        'estActif'
      ) ?? false;
}
