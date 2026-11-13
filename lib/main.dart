
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native/canaux.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PageAlertes(),
  ),
);

class PageAlertes extends StatefulWidget {

  const PageAlertes({super.key});

  @override
  State<PageAlertes> createState() => _PageAlertesState();
}

class _PageAlertesState extends State<PageAlertes>
    with WidgetsBindingObserver {

  String _derniereAction = 'aucune';

  double _seuilBatterie = 20;

  double _seuilTemp = 40;

  bool _surveillance = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Ecouter les actions reçues lorsque l'application est ouverte
    CanauxNatifs.ecouterActions(_traiterAction);

    // Récupérer une action au démarrage à froid
    CanauxNatifs.actionInitiale().then((a) {

      if (!mounted) return;

      if (a != null) {
        _traiterAction(a);
      }
    });

    // Exercice 2 : récupérer l'état réel du service
    _actualiserSurveillance();
  }

  // Vérifier l'état du service
  Future<void> _actualiserSurveillance() async {

    try {

      final actif =
          await CanauxNatifs.estSurveillanceActive();

      if (!mounted) return;

      setState(() {
        _surveillance = actif;
      });

    } on PlatformException catch (e) {

      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // Exercice 2 : actualiser l'état au retour dans l'application
  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state
  ) {

    if (state == AppLifecycleState.resumed) {
      _actualiserSurveillance();
    }
  }

  // Traiter une action venant d'une notification
  void _traiterAction(Map<String, dynamic> a) {

    if (!mounted) return;

    setState(() {

      _derniereAction =
          '${a['action']} : ${a['titre']} (id ${a['id']})';
    });
  }

  void _message(String texte) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  // Demander la permission
  Future<void> _autoriser() async {

    try {

      final ok =
          await CanauxNatifs.demanderPermissionNotif();

      _message(
        ok
            ? 'Notifications autorisées'
            : 'Notifications refusées'
      );

    } on PlatformException catch (e) {

      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // Envoyer une notification
  Future<void> _envoyerAlerte() async {

    try {

      final id = await CanauxNatifs.notifier(
        'Patient critique',
        'Fréquence cardiaque : 142 bpm',
      );

      _message('Alerte envoyée (id $id)');

    } on PlatformException catch (e) {

      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // Activer ou désactiver le service
  Future<void> _basculerSurveillance(bool actif) async {

    try {

      if (actif) {

        await CanauxNatifs.demarrerSurveillance(
          _seuilTemp
        );

      } else {

        await CanauxNatifs.arreterSurveillance();
      }

      setState(() {
        _surveillance = actif;
      });

    } on PlatformException catch (e) {

      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // Planifier le Worker
  Future<void> _planifier() async {

    await CanauxNatifs.planifier(
      _seuilBatterie.round()
    );

    _message('Vérification toutes les 15 min');
  }

  // Vérifier immédiatement
  Future<void> _verifierMaintenant() async {

    await CanauxNatifs.verifierMaintenant(
      _seuilBatterie.round()
    );

    _message('Vérification demandée');
  }

  // Annuler la planification
  Future<void> _annulerPlanification() async {

    await CanauxNatifs.annulerPlanification();

    _message('Planification annulée');
  }

  // Construction d'une carte
  Widget _carte(
    String titre,
    List<Widget> contenu
  ) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              titre,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            ...contenu,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('TP 4 – Alertes natives'),
      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          // Carte 1 : notification native
          _carte(
            '1. Notification native',
            [

              Wrap(
                spacing: 8,
                children: [

                  OutlinedButton(
                    onPressed: _autoriser,
                    child: const Text('Autoriser'),
                  ),

                  FilledButton(
                    onPressed: _envoyerAlerte,
                    child: const Text('Envoyer une alerte'),
                  ),
                ],
              ),
            ],
          ),

          // Carte 2 : dernière action reçue
          _carte(
            '2. Dernière action reçue de la notification',
            [
              Text(_derniereAction),
            ],
          ),

          // Carte 3 : WorkManager
          _carte(
            '3. Vérification périodique (WorkManager)',
            [

              Text(
                'Alerte si batterie ≤ ${_seuilBatterie.round()} %'
              ),

              Slider(
                value: _seuilBatterie,
                min: 5,
                max: 100,
                divisions: 19,
                label: '${_seuilBatterie.round()} %',

                onChanged: (v) {

                  setState(() {
                    _seuilBatterie = v;
                  });
                },
              ),

              Wrap(
                spacing: 8,
                children: [

                  FilledButton(
                    onPressed: _planifier,
                    child: const Text('Planifier'),
                  ),

                  OutlinedButton(
                    onPressed: _verifierMaintenant,
                    child: const Text('Vérifier maintenant'),
                  ),

                  TextButton(
                    onPressed: _annulerPlanification,
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ],
          ),

          // Carte 4 : service au premier plan
          _carte(
            '4. Surveillance continue (service au premier plan)',
            [

              Text(
                'Alerte si température ≥ ${_seuilTemp.round()} °C'
              ),

              Slider(
                value: _seuilTemp,
                min: 20,
                max: 50,
                divisions: 30,
                label: '${_seuilTemp.round()} °C',

                onChanged: (v) {

                  setState(() {
                    _seuilTemp = v;
                  });
                },

                onChangeEnd: (v) async {

                  if (_surveillance) {

                    await CanauxNatifs.demarrerSurveillance(v);
                  }
                },
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Surveillance'),
                value: _surveillance,
                onChanged: _basculerSurveillance,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }
}
