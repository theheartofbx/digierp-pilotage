# STANDARDS — COMPLÉMENTS FRONTEND DU 11/10/2026
# STANDARDS_FRONTEND Rev 10 (§51 à §54)
#
# Suite de claude/STANDARDS_COMPLEMENTS_20261010.md (Frontend Rev 9 §47-50), inchangé. Même
# statut : ce fichier COMPLÈTE STANDARDS_FRONTEND.md (Rev 8) et le complément du 10/10 ; en cas
# de contradiction, il fait foi. Nouveau fichier plutôt que recopie (leçon §173).
# Commits de référence : 7e861563 (photo et avatar), 108a2073 (navigation fluide), 1785d183
# (session), 16a4707f (barre latérale extraite).
# Sources de vérité (le code fait foi sur ce texte) : rh-frontend/src/layouts/AppLayout.jsx,
# src/main.jsx, src/shared/ui/Spinner.jsx, src/shared/utils/session.js, src/context/AuthContext.jsx,
# src/modules/employes/components/CadragePhotoModal.jsx, src/hooks/usePhotoEmploye.js,
# rh-frontend/nginx/nginx.conf, rh-api …/shared/util/TraitementImage.java.
# Leçons associées : claude/LECONS_APPRISES_SUITE_4.md §196-§198, §201-§204.

---

## RÈGLES ANCIENNES DEVENUES FAUSSES (à ne plus appliquer)

| Où | Règle ancienne | Remplacée par |
|---|---|---|
| Code d'avant 108a2073 (`Spinner size="full"`, 9 tableaux) | Voile de chargement plein écran pour une liste | Indicateur LOCAL ; le mode `full` n'existe plus (§51) |
| Code d'avant 1785d183 | Minuteries de session propres à chaque chemin | Règle pure `etatSession` + UNE vérification périodique (§54) |

---

# STANDARDS FRONTEND — REV 10

## 51. CHARGEMENT : TOUJOURS LOCAL, SUSPENSE AU PLUS PRÈS DU CONTENU (108a2073)

### 51.1 Constat
Le « flash blanc » entre deux pages avait deux causes : un `Suspense` placé au-dessus de la mise
en page (toute la page, barre latérale comprise, remplacée par un écran de chargement pendant
le téléchargement d'une page paresseuse), et 9 tableaux qui affichaient `Spinner size="full"`,
un voile sur toute la fenêtre.

### 51.2 Règles
```
✅ Le Suspense des pages privées entoure l'<Outlet /> DANS AppLayout (zone <main>) :
     <Suspense fallback={<ChargementPage />}><Outlet /></Suspense>
   la barre latérale et l'en-tête ne sont jamais démontés pendant une navigation
✅ BrowserRouter future={{ v7_startTransition: true }} (main.jsx) : chaque navigation est une
   transition React ; l'ancienne page reste affichée pendant le chargement de la nouvelle
✅ Un chargement de DONNÉES s'affiche là où les données s'afficheront :
     Spinner (shared/ui/Spinner.jsx), tailles sm | md | lg seulement, dans le tableau ou la fiche
✅ Le Suspense racine d'App.jsx (Spinner plein écran) ne sert qu'au premier chargement de
   l'application et aux routes publiques (login), avant que la mise en page existe
❌ Un voile plein écran pour un chargement de données (le mode `full` a été RETIRÉ : il ne
   peut plus revenir par erreur)
❌ Un Suspense au-dessus de la mise en page pour les pages privées
```
Dette (39) : pendant un RECHARGEMENT, les tableaux remplacent encore leurs lignes par l'indicateur
(`if (loading) return <Spinner … />`) ; cible : garder les lignes et superposer un indicateur.

Parallèle Laravel / Livewire : `wire:loading` posé sur le bloc qui se recharge, jamais sur
`<body>`.

## 52. AUCUN COMPOSANT DÉCLARÉ DANS UN COMPOSANT (16a4707f)

### 52.1 Constat (mesuré dans le navigateur le 11/10)
`BarreLaterale` était une fonction déclarée DANS `AppLayout`. À chaque rendu d'AppLayout, c'était
un NOUVEAU type de composant : React détruisait puis recréait toute la barre (menu remis en haut
puis redescendu jusqu'à l'élément actif, état local perdu).

### 52.2 Règles
```
✅ Tout composant est déclaré au niveau du MODULE (fichier), jamais dans le corps d'un autre
   composant ; ses dépendances arrivent en PROPS (BarreLaterale, NavGroupe, ChargementPage)
✅ Plusieurs petits composants dans un même fichier sont permis, tous au niveau du module ;
   un composant réutilisé ailleurs a son propre fichier (dette 39 : BarreLaterale et NavGroupe
   à sortir d'AppLayout.jsx)
✅ Une fonction qui RETOURNE du JSX et qui est appelée comme fonction (`{rendreLigne(x)}`) n'est
   pas un composant : elle est permise dans un composant (pas de type, pas de démontage) ;
   dès qu'elle est utilisée comme balise (`<RendreLigne />`), elle sort au niveau du module
❌ const Sous = () => (...) dans le corps d'un composant, puis <Sous />
```
Parallèle Blade : un composant se déclare une fois (`resources/views/components/…`), jamais
dans le corps d'une vue.

## 53. ENVOI ET LECTURE DE FICHIERS (7e861563)

### 53.1 Envoi multipart : en-tête EXPLICITE
L'instance `api` (services/api.js) impose `Content-Type: application/json` par défaut ; avec cet
en-tête, axios 1.x SÉRIALISE un `FormData` en JSON : le fichier est perdu sans erreur.
```jsx
const donnees = new FormData()
donnees.append('fichier', jpeg, 'photo.jpg')       // nom de champ = @RequestParam du contrôleur
await api.put(chemin, donnees, { headers: { 'Content-Type': 'multipart/form-data' } })
// axios garde le FormData ; le navigateur complète la frontière (boundary)
```
```
✅ Tout envoi de fichier passe par l'instance api (cookie, CSRF, renouvellement) avec cet en-tête
✅ Contrôleur : @PutMapping/@PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
✅ Preuve : F12 → Réseau → la requête montre « multipart/form-data; boundary=… » et une partie
   « fichier »
❌ FormData envoyé sans l'en-tête ; fetch() à côté de l'instance api
```

### 53.2 Limite de taille : alignée sur TOUTE la chaîne
```
nginx (rh-frontend/nginx/nginx.conf, location /api/) : client_max_body_size 50m
  → aligné sur spring.servlet.multipart.max-request-size (rh-api, application.yaml)
  → la règle métier (TraitementImage.OCTETS_MAX, 2 Mo pour une photo) est la plus basse
     et la seule que voit l'utilisateur, avec un message clair (422)
```
```
✅ Toute nouvelle limite se règle sur nginx, la gateway et Spring, puis se MESURE couche par
   couche (8090 / 8082 / 5173 : complément du 10/10 §55.4)
❌ Directive absente : nginx refuse en 413 tout corps de plus de 1 Mo, avant la gateway
```

### 53.3 Le navigateur prépare, le serveur fait foi
```
✅ Navigateur (confort) : cadrage react-easy-crop, orientation, réduction, JPEG
   (modules/employes/utils/preparerPhoto) — erreurs locales traduites (PHOTO_ILLISIBLE,
   PHOTO_TROP_PETITE)
✅ Serveur (règle) : TraitementImage — taille, format par octets magiques, dimensions lues dans
   l'en-tête avant décodage, décodage réel, carré, réduction, réencodage JPEG sans métadonnées,
   empreinte SHA-256 (ETag) ; refus = 422 avec message
❌ Une validation qui n'existe que dans le navigateur
Dette 40 : le seuil de 128 px est écrit des deux côtés (à exposer par le serveur)
```

### 53.4 Lecture d'une image protégée : par l'API, en blob
`usePhotoEmploye(chemin, version)` (hooks/) :
```
✅ api.get(chemin, { responseType: 'blob' }) puis URL.createObjectURL ; URL révoquée au
   démontage et au changement ; 204 = pas de photo = null (initiales affichées)
✅ Jamais <img src="/api/…"> pour une ressource protégée : VITE_API_URL peut être une autre
   origine, où le cookie de session (SameSite=Lax) ne suivrait pas une balise <img>
✅ Cache : ETag / 304 du serveur ; `version` (l'empreinte) force le rechargement après une
   modification
✅ Échec silencieux ASSUMÉ pour un avatar (pas une action de l'utilisateur) ; toute action
   de l'utilisateur garde son toast d'erreur
```
Parallèle Laravel : une route `Storage::download` derrière le middleware `auth`, lue en `fetch`
plutôt qu'en URL publique.

## 54. SESSION : UNE RÈGLE PURE, UNE VÉRIFICATION PÉRIODIQUE (1785d183)

### 54.1 Constat
L'avertissement de fin de session apparaissait à un utilisateur en plein travail : l'état de la
session était décidé à plusieurs endroits, sans relire l'état partagé.

### 54.2 Règle unique : `shared/utils/session.js`
```js
etatSession({ maintenant, derniereActivite, dernierRenouvellement })
  → ACTION.DECONNECTER  inactif ≥ DELAI_INACTIVITE_MS (15 min)
  → ACTION.AVERTIR      inactif ≥ DELAI_INACTIVITE_MS − AVERTISSEMENT_AVANT_MS (13 min)
  → ACTION.RENOUVELER   jeton âgé ≥ DUREE_JETON_MS − MARGE_RENOUVELLEMENT_MS ET activité
                        depuis le dernier renouvellement (silencieux)
  → ACTION.RIEN
```
Fonction PURE (ni React, ni minuterie, ni stockage), testée par Node (`test_session.mjs`, 9 OK).

### 54.3 Utilisation (AuthContext)
```
✅ UNE minuterie (VERIFICATION_MS = 15 s) appelle etatSession et applique l'action
✅ dernierRenouvellement = sessionStorage.login_at, RELU à chaque passage ; écrit par TOUS les
   chemins de renouvellement (connexion, renouveler(), intercepteur d'api.js) : rien à
   synchroniser
✅ Activité = événements mousemove, keydown, click, scroll, touchstart (refs, aucun rendu)
✅ Un seul renouvellement à la fois (renouvellementEnCoursRef) ; « Rester connecté » =
   prolongerSession()
✅ Un utilisateur qui travaille n'est JAMAIS averti : avertissement et déconnexion ne
   dépendent que de l'inactivité
❌ Une minuterie par chemin (connexion, renouvellement, intercepteur) ; une copie de l'état de
   session dans un état React relancé à chaque changement
```
Test réel de l'avertissement après 13 min d'inactivité : À FAIRE (prompt principal §9).

Parallèle Laravel : `SESSION_LIFETIME` décidé par un seul middleware qui relit `last_activity`,
pas par chaque contrôleur.

---

## CHECKLIST (à ajouter à STANDARDS_FRONTEND §46 lors de la prochaine fusion)
```
[ ] 46. Chargement de données : indicateur local, jamais plein écran ; Suspense des pages dans AppLayout (§51)
[ ] 47. Aucun composant déclaré dans le corps d'un autre composant (§52)
[ ] 48. Envoi de fichier : api + en-tête multipart explicite ; limites alignées nginx / Spring ; serveur fait foi (§53)
[ ] 49. Ressource protégée affichée : chargée par l'API en blob, jamais <img src="/api/…"> (§53.4)
[ ] 50. État de session : décidé par etatSession seulement (§54)
```
