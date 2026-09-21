# WAY

App di produttività in cui il carico della giornata cambia con l'ambiente in
cui ti trovi. Porting Flutter del prototipo interattivo: stesse quattro
schermate, stesse meccaniche, stessa identità visiva.

## Avvio

```bash
flutter pub get
flutter run
```

Richiede Flutter 3.19 o superiore (usa `onAcceptWithDetails` di `DragTarget`,
`PopScope` e i pattern di Dart 3).

Se mancano le cartelle di piattaforma:

```bash
flutter create --project-name way .
flutter pub get
```

`flutter create` non tocca `lib/` né `pubspec.yaml` se già esistono.

## Struttura

```
lib/
  main.dart              avvio: legge l'archivio prima del primo frame
  app.dart               MaterialApp, tema unico
  theme/                 palette WAY come ThemeExtension + Manrope e Space Mono
  models/                Task, Place, Criterion, stato app, stato tutorial
  data/                  date, icone, demo popolata e archivio vuoto
  state/                 provider Riverpod, unico punto di scrittura
  fx/                    capsula notifiche, coriandoli, card, ancore
  onboarding/            riflettore e tappe del primo utilizzo
  screens/               Home, Tasks, Places, Trend e i tre wizard
  widgets/               anello, curva del trend, fiore dei giorni, card
  sheets/                fogli modali
```

### Stato

Un solo `NotifierProvider` tiene tutto in un `AppData` immutabile. Ogni
scrittura passa da `AppController`, che aggiorna lo stato e salva su
`shared_preferences`. Le letture derivate — punteggio del giorno, task in
carico, giorni di fila, candidata al passaggio di livello — stanno tutte
nell'extension `AppStats`: la regola del prodotto vive in un posto solo e
nessuna schermata ricalcola a modo suo.

Le due modalità del prototipo (**Proxy** e **Configura da 0**) hanno archivi
separati, quindi passare dall'una all'altra non distrugge il lavoro fatto
nell'altra. Si cambiano dal foglio del profilo, toccando l'avatar in Home.

## Cosa è stato portato

- **Quattro schermate** scorribili con swipe o barra a pillola.
- **Core Session**: si trascina una task dalla lista all'hub per metterla nel
  nucleo, e un chip fuori per toglierla. Il carico trascinato porta con sé la
  provenienza, così i due bersagli non si confondono.
- **Ambienti** con hub di attivazione, un solo ambiente per volta.
- **Home**: anello che supera il 100%, esecuzione con spunta o contatore,
  tacca della soglia sulla barra, curva del periodo a 7 / 30 giorni e 12 mesi
  con cursore per leggere il singolo valore.
- **Feedback a tre livelli**: soglia superata, task completata (coriandoli dal
  punto toccato), target del giorno (anello, coriandoli, card a fondo fluido).
  Più il passaggio di livello, con i coriandoli che scendono dalla capsula.
- **Tutorial del primo utilizzo**: riflettore a ritaglio sull'elemento vero —
  niente cloni, niente chiamate all'azione duplicate — e wizard guidato in
  **4 schermate** (6 se scegli Misura), con barra di avanzamento sempre
  visibile. L'icona della task viene indovinata dal nome mentre scrivi.

## Differenze rispetto al prototipo web

- **La Dynamic Island.** Sul telefono vero è un'area di sistema: un'app
  Flutter non può disegnarci dentro. `IslandBanner` è la sua controparte
  onesta, una capsula che nasce sotto la barra di stato con la stessa forma e
  lo stesso comportamento. Per una vera Live Activity servirebbe ActivityKit
  dietro un platform channel, solo su iOS 16.1+.
- **Il mockup dell'iPhone non c'è**, ed è giusto così: era un artefatto di
  presentazione del prototipo web. Qui l'app *è* il telefono.
- Le icone sono Material invece degli SVG disegnati a mano. La chiave finisce
  nel JSON, l'icona no: il set grafico si può cambiare senza migrare i dati.
- I font arrivano da `google_fonts`, scaricati al primo avvio. Per spedire
  l'app offline metti i .ttf in `assets/fonts/`, dichiarali nel `pubspec.yaml`
  e cambia le due funzioni in `theme/way_theme.dart`.
- I coriandoli sono un `CustomPainter` con un `Ticker` che si spegne da solo,
  al posto della canvas del web.

## Cosa manca ancora

- La banda dell'ambiente sotto la curva del trend: senza quella il rientro a
  casa continua a figurare come una settimana storta.
- Il cambio automatico o retroattivo dell'ambiente.
- La soglia minima non incide ancora sul punteggio: `AppStats.percentOf` usa
  solo il target. La regola va decisa prima di implementarla.
- La verifica dei criteri al momento di segnare "fatto".
- La sezione Trend, volutamente vuota.
