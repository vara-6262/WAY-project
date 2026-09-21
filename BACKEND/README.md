# Sabus hub (server.js)

Ponte di sincronizzazione tra Sabus desktop e telefono. Node.js, **zero
dipendenze** (solo moduli built-in): lo lanci senza `npm install`.

## Avvio
```bash
SABUS_TOKEN="una-stringa-segreta-lunga" node server.js
# opzionali: PORT=8787  DATA_DIR=./data
```
I dati sono file JSON dentro `DATA_DIR` (`today.json`, `calendar.json`, ecc.):
puoi aprirli/modificarli a mano con qualsiasi editor quando il server è fermo.

## Modello
Local-first: i client (desktop = autorità, telefono) tengono il loro stato e lo
mandano al server. Il server fa da **archivio condiviso** con concorrenza sicura.
- **`today`** (stato del giorno): scrittura tramite **merge atomico lato server**
  (LWW per-campo con timestamp), quindi niente race né 409: due dispositivi che
  scrivono task diverse convivono sempre.
- **`calendar`** e documenti generici: **PUT versionato** con `If-Match` (409 se
  la versione non combacia), per l'autorità che pubblica.

## Endpoint
Tutti richiedono l'header `Authorization: Bearer <SABUS_TOKEN>` (tranne `/health`).

| Metodo | Rotta            | Uso |
|-------:|------------------|-----|
| GET    | `/health`        | stato del server (senza token) |
| GET    | `/today`         | `{ version, updatedAt, data }` dello stato del giorno |
| POST   | `/today/merge`   | invia il tuo stato/parziale → il server lo **fonde** e ritorna il risultato |
| GET    | `/calendar`      | il calendario pubblicato |
| PUT    | `/calendar`      | pubblica il calendario (opz. `If-Match: <version>`) |
| GET    | `/doc/<nome>`    | documento generico versionato (backup di tasks/history…) |
| PUT    | `/doc/<nome>`    | scrive un documento generico (opz. `If-Match`) |

`ETag` nella risposta = versione corrente; usalo come `If-Match` nel PUT successivo.

### Schema di `today`
```json
{ "date":"AAAA-MM-GG",
  "completions": { "taskId": { "count":0, "reqs":[true], "done":false, "ts":1737000000000, "dev":"phone" } },
  "flessioni": 100, "flexTs": 1737000000000 }
```
`ts` = millisecondi epoch dell'ultima modifica; `dev` = id dispositivo (tie-break).

## Integrazione con i client Flutter
È quasi identico al client GitHub che hai già:
- **push dei completamenti**: `POST /today/merge` con il tuo `today` (o il solo
  parziale modificato). Il server risponde con lo stato fuso → applicalo in locale.
  Niente più gestione di sha/409 per lo stato del giorno.
- **calendario**: il desktop fa `PUT /calendar`; il telefono `GET /calendar` e
  riprogramma le notifiche.
Sostituisci l'URL base e il token GitHub con l'URL del server e `SABUS_TOKEN`.

## Hosting a basso costo
- **Casa + Tailscale** (consigliato, gratis e privato): fai girare `server.js` sul
  PC o su un Raspberry; installa Tailscale su PC e telefono; i client usano l'IP
  Tailscale del server. Funziona anche fuori casa, cifrato, senza aprire porte.
- **Fly.io / Render / Railway** (tier gratuiti): semplici ma possono "dormire" e —
  attenzione — su alcuni il filesystem è **effimero**: monta un **volume
  persistente** e punta `DATA_DIR` lì, altrimenti i dati si perdono al redeploy.
- **VPS piccolo** (~pochi €/mese): sempre acceso, `DATA_DIR` su disco. Metti il
  server dietro HTTPS (reverse proxy) se lo esponi pubblicamente.

## Note / prossimi passi
- Le **flessioni** qui sono LWW sul timestamp: per renderle davvero incrollabili
  (somme concorrenti) passa al **registro di delta** (già in FIXLIST): il merge
  diventerebbe l'unione di transazioni con id.
- Autenticazione: singolo token condiviso (uso personale). Per più utenti serve
  un token per dispositivo e uno spazio-dati per utente.
