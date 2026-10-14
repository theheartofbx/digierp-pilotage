# STANDARDS — COMPLÉMENTS FRONTEND « PATRONS DE VUES ET FONDATIONS » DU 11/10/2026
# STANDARDS_FRONTEND Rev 11 (§55 à §60) + §61 scripts de test et de preuve
# Révision du 11/10 (22 h 20) : §57.7 (DOMPurify retiré), §58.4 (chiffres réels de S1, `88807add`),
#   §58.5 (cartes de source), §61 (tests), checklist 56-57.
#
# Suite de claude/STANDARDS_COMPLEMENTS_FRONTEND_20261011.md (Rev 10, §51-54), inchangé.
# Ce fichier COMPLÈTE STANDARDS_FRONTEND.md (Rev 8) et les compléments antérieurs ; en cas de
# contradiction, il fait foi. Nouveau fichier plutôt que recopie (leçon §173).
# Décisions sources (Project) : claude/ANALYSE_PATRONS_VUES_20261011.md (V1-V7, décidées le 11/10
# à 20 h 03) ; claude/CONCEPTION_PATRONS_ETAPE1_20261011.md (C1-C4, validées le 11/10 à 20 h 20).
# Statut des paragraphes : « RÈGLE » = applicable dès maintenant à tout nouveau code ;
# « CIBLE » = décidé, en cours de construction (étapes du plan) — ne pas l'appliquer avant que
# le composant existe, mais ne rien écrire qui le contredise.

---

## RÈGLES ANCIENNES DEVENUES FAUSSES (à ne plus appliquer)

| Où | Règle ancienne | Remplacée par |
|---|---|---|
| STANDARDS_FRONTEND §3 « Utilisation dans les styles centralisés » | classes construites par concaténation (`` `bg-${c.primary}-600` ``) | **interdit** : Tailwind ne génère que les classes écrites EN ENTIER dans le code (§57.3) |
| STANDARDS_FRONTEND §3 « Fichier src/config/theme.js » | `theme.js` = source des jetons | `theme.js` n'a AUCUN importeur (inventaire du 11/10) : code mort, retiré ; jetons = variables CSS branchées dans Tailwind (§57.3, CIBLE étape 1.3) |
| STANDARDS_FRONTEND §11 (Button, Badge, EmptyState, PageHeader de `shared/ui`) | composants atomiques « utilisés par toutes les pages » | AUCUN importeur (inventaire du 11/10, toutes formes d'import) : code mort ; remplacés par les composants de base §57.5 (CIBLE) |
| STANDARDS_FRONTEND §13, §11 EmptyState | émojis comme icônes (`✏️`, `🗑️`, `📭`) | icônes du lexique Lucide (§56) ; les émojis existants migrent module par module |
| STANDARDS_FRONTEND §11 Spinner | taille `full` | retirée (Rev 10 §51) |
| Prompts, `package.json` | versions en plage (`^x.y.z`) | versions EXACTES pour toute dépendance directe (§58) |
| §57.7 de ce fichier (version de 20 h 28) | HTML éventuel passé par `shared/utils/sanitize.js` (DOMPurify) | **aucun HTML injecté** ; DOMPurify et `sanitize.js` retirés (S1, `88807add`) |
| §58.4 de ce fichier (version de 20 h 28) | S1 : « dompurify 3.4.16 », cible 9 / 2 | dompurify RETIRÉ ; réel 10 / 3 (§58.4) |
| Écran = composants écrits à la main par module | — | écran = descripteur consommé par un patron (§55, CIBLE à partir de l'étape 2) |

---

# STANDARDS FRONTEND — REV 11

## 55. PATRONS DE VUES ET DESCRIPTEURS (décisions V1-V7) — CIBLE

### 55.1 Principe
Un écran n'est plus écrit à la main : chaque module DÉCRIT ses objets métier dans un
**descripteur** (données pures) et un **patron** générique construit l'écran.
Parallèles : SAP Fiori elements (floorplans), Odoo (`ir.ui.view`), **iDempiere Dictionnaire
applicatif** (AD_Window / AD_Tab / AD_Field), Laravel Filament (`Resource::form()/table()`).

### 55.2 Catalogue (V1) — 12 patrons, extensible
| Code | Patron | Icône | Rôle |
|---|---|---|---|
| P1 | Liste | `list` | trouver, filtrer, trier, agir ; archives ; export |
| P2 | Fiche | `id-card` | un objet : en-tête, onglets, sections modifiables sur place, listes rattachées, actions, journal |
| P3 | Assistant | `wand-sparkles` | créer le minimum en étapes, puis ouvrir la fiche |
| P4 | File de travail | `inbox` | traiter ce qui attend (tâches, alertes, échéances) |
| P5 | Référentiel | `settings` | paramétrage code / libellé modifiable sur place |
| P6 | Document à lignes | `file-text` | fiche + grille de lignes + totaux |
| P7 | Arbre | `folder-tree` | hiérarchies, agrégats par niveau |
| P8 | Tableau par étapes | `kanban` | cartes par statut (pipeline) |
| P9 | Calendrier / planning | `calendar-days` | éléments datés |
| P10 | Grille de saisie | `sheet` | saisie en masse façon tableur |
| P11 | Comparateur | `git-compare` | objets côte à côte, écarts |
| P12 | Tableau de bord | `layout-dashboard` | indicateurs par rôle |
Élément transverse : JOURNAL (`history`), section standard de toute FICHE.
Inventaire de référence (41 lignes d'écrans actuels et prévus → patrons) : analyse §2.

### 55.3 La FICHE (V2)
```
✅ Un seul composant de contenu, affiché dans 3 cadres : FENÊTRE (défaut), PANNEAU latéral,
   PAGE (« Agrandir », adresse /module/:id) ; toute fiche a une adresse (?fiche= ou route)
✅ En-tête : photo / icône, titre, code métier, statut, attributs clés, complétude (option)
✅ UN niveau d'onglets ; sections empilées ; édition PAR SECTION sur place (crayon,
   Enregistrer / Annuler, garde « modifications non enregistrées »)
✅ Listes rattachées : ajout / modification sur place, retrait avec motif
✅ Champ non modifiable : étiquette qui dit pourquoi (« par affectation », « calculé »)
✅ Menu Actions : actions sensibles (code métier, statut, archivage) avec droit, motif, audit
❌ Formulaire de modification séparé qui montre d'autres champs que la fiche
❌ Fenêtre ouverte depuis une autre fenêtre (Carbon : « One modal should never trigger another »)
❌ Sous-onglets dans des onglets
```
Prototype de référence : artefact « Fiche Employé — prototype » (canvas Design, 11/10).

### 55.4 Descripteurs (V3 = D3)
```
✅ Fichier par objet : modules/{module}/{objet}.objet.ts (TypeScript, §57.1)
✅ DONNÉES PURES sérialisables en JSON : aucune fonction, aucune chaîne évaluée (condition pour
   les servir un jour depuis la base sans faille, et pour les valider)
✅ Contenu : code, icône (lexique), libellé i18n, api, permission, en-tête, liste (colonnes,
   filtres, recherche, archives, export), onglets → sections → champs, listes rattachées,
   actions (icône, motif, danger, champs), création (étapes)
✅ Validés par le TYPAGE (compilation) + un TEST qui charge tous les descripteurs (clés i18n fr
   ET en, icônes du lexique, champs connus) + un CONTRÔLE AU BUILD champ ↔ DTO Java (C2-a)
✅ Écrans singuliers (éditeur de workflow, matrice des droits, calcul de paie) : écrits à la main
   MAIS avec les composants de base (§57.5)
❌ Bibliothèque de validation embarquée dans le bundle (Zod) tant que les descripteurs sont
   dans le code (à reconsidérer si le serveur les sert : D2)
```

### 55.5 Types de champs (un type = affichage + saisie + mise en forme, une fois)
texte, nombre, montant (XAF), date, période, booléen, énuméré, référence (endpoint de liste
complète, Rev 9 §48), statut, identifiant à masque (CNPS, NIU), email, téléphone, fichier /
photo, calculé (lecture seule + étiquette). La mise en forme selon la langue (dette 27) est
réglée ICI : une seule fonction par type, testée en fr ET en en.

### 55.6 Contrat serveur supposé par les patrons (uniforme)
`GET /{objet}` (PageResponse `contenu`) ; `GET /{objet}/tous` ; `GET /{objet}/{id}` avec
`actionsPermises` ; `PUT /{objet}/{id}/sections/{code}` (seuls les champs de la section) ;
`POST /{objet}/{id}/actions/{code}` `{motif,…}` ; listes rattachées
`/{objet}/{id}/{liste}[/{ligneId}]` ; `GET /{objet}/{id}/historique` ; archives / restaurer /
purger ; `GET /{objet}/export/excel`. Le serveur DÉCIDE (droits, champs renvoyés) ; masquer un
bouton n'est jamais une protection.

### 55.7 Règle de construction
Un patron est construit au PREMIER module qui en a besoin, depuis le catalogue (pas
d'invention locale) ; il devient « standard » après un SECOND usage réel sans modification de
fond. Pilote (V6) : Employés pour Liste / Fiche / Assistant, validation par Postes.

### 55.8 Plan et ordre (V7)
Étape 1 fondations → 2 Liste + Fiche (pilote Employés, dette 37 traitée) → 3 Assistant, File
de travail, Référentiel → 4 migration des modules RH → 5 autres patrons au premier besoin →
6 standard final. Patrons AVANT la Phase B des migrations. Stock, Achats, Budget démarrent
directement sur les patrons.

---

## 56. ICÔNES (décisions V4, V5) — RÈGLE

### 56.1 Bibliothèque et lexique
```
✅ Lucide (lucide-react, ISC), version figée (§58) ; noms vérifiés dans la version installée
✅ UN lexique : shared/ui/icones.ts (nom MÉTIER → composant Lucide) ; seul fichier qui importe
   lucide-react (contrôle au build) ; composant <Icone nom="employe" taille="sm|md|lg" />
✅ Une notion = une icône, partout (table complète : analyse §5.2)
✅ Imports statiques nommés uniquement (tree-shaking, aucune ressource externe)
❌ Émoji comme icône dans du nouveau code ; import direct de lucide-react hors du lexique ;
   import dynamique d'une icône par son nom
```
Existant au 11/10 : seul `NotificationsPanel.jsx` importe Lucide directement (à migrer vers le
lexique) ; 455 occurrences d'émojis dans 88 fichiers, migrées module par module (jamais en
remplacement de masse).

### 56.2 Icône seule ou icône + texte (Nielsen Norman Group, « Icon Usability »)
```
Icône SEULE autorisée — toujours avec aria-label + info-bulle (même texte i18n) — si :
  1. icône universelle : rechercher, fermer, imprimer, plus d'actions, menu ;
  2. action répétée dans chaque ligne / carte : voir, modifier, joindre ;
  3. barre latérale réduite ou barre d'outils dense, le libellé étant visible ailleurs.
Icône + TEXTE obligatoires : action principale de la page (une seule) ; décisions (valider,
  rejeter, soumettre) ; actions sensibles ou destructives (archiver, purger, corriger un code
  métier) ; onglets ; navigation étendue ; toute notion qui échoue au test des 5 secondes.
Statuts : icône + texte + couleur, jamais la couleur seule.
Garde-fou : BoutonIcone exige `libelle` (erreur de compilation sinon).
```

---

## 57. FONDATIONS TECHNIQUES (décisions C1-C4) — RÈGLE pour le nouveau code

### 57.1 Typage (C1-a)
TypeScript strict pour les NOUVEAUX dossiers transverses (`shared/ui`, `shared/champs`,
`shared/patrons`) et les descripteurs ; le code existant reste en JavaScript jusqu'à sa
migration. `tsc --noEmit` = 0 dans la chaîne frontend. Parallèle Laravel : PHP typé + PHPStan.

### 57.2 Tests (C3-a)
Vitest + Testing Library (+ jsdom) ; `npm test` = 0 dans la chaîne et la non-régression ;
tests écrits du point de vue de l'utilisateur (rôles, libellés accessibles) ; Playwright pour
les parcours de bout en bout. Toute règle pure a ses tests ; tout composant de base a les siens.

### 57.3 Jetons et classes (C4-a)
```
✅ Jetons = variables CSS (src/styles/jetons.css), branchées dans tailwind.config
   (couleurs sémantiques : primaire, danger, succes, avertissement, info, neutre, surface…)
✅ Classes ÉCRITES EN ENTIER (bg-primaire, text-danger) ; changer la valeur = un seul endroit
✅ Les fichiers shared/styles/*.styles.js (106 importeurs au 11/10 : buttons 54, table 34,
   layout 17, forms 1) adoptent les jetons EN PREMIER : les écrans en héritent sans être touchés
❌ Classe construite par concaténation ; couleur en dur dans un nouveau composant
```
Note : Tailwind 4 configure le thème directement en CSS (`@theme`, variables) ; la migration
Tailwind 4 est faite avec l'étape 1.3 (corrige aussi les vulnérabilités restantes, §58.4).

### 57.4 Police (C4-p1)
IBM Plex Sans (texte) et IBM Plex Mono (matricules, codes), licence OFL, EMBARQUÉES dans le
build (paquets @fontsource) : aucun appel à Google Fonts (confidentialité, hors ligne, CSP).
`index.css` déclarait « Inter » sans la charger (rendu réel : Segoe UI) : corrigé à l'étape 1.

### 57.5 Couches et composants de base — CIBLE étape 1
```
descripteurs → patrons → champs → composants de base (shared/ui) → lexique d'icônes → jetons
(une couche n'importe jamais une couche au-dessus : test d'architecture)
Bouton (variante, taille, icone?, chargement ; type="button" par défaut)
BoutonIcone (icone, libelle OBLIGATOIRE → aria-label + info-bulle ; cible ≥ 40 px)
InfoBulle (clavier + survol, role="tooltip") ; BadgeStatut (table de statuts du module)
EnTetePage (une seule action principale) ; EtatVide ; Icone
```
Valeur inconnue (variante, statut, icône) : erreur de compilation ; en exécution,
`console.error` citant la CLÉ (jamais la valeur, données personnelles) + repli sûr.

### 57.6 Accessibilité
WCAG 2.2 niveau AA : contrastes ≥ 4,5:1 (3:1 au-delà de 24 px), focus visible, tout au clavier,
`prefers-reduced-motion` respecté ; `eslint-plugin-jsx-a11y` dans le lint.

### 57.7 Sécurité frontend
Le serveur décide (PBAC, politique de document, RLS) ; aucune donnée exécutable dans un
descripteur ; **aucun HTML injecté** : `dangerouslySetInnerHTML` interdit partout (contrôle au
build) — React échappe tout texte affiché, c'est la protection ; DOMPurify et
`shared/utils/sanitize.js` ont été RETIRÉS le 11/10 (S1, `88807add` : 0 importeur, livrés aux
navigateurs sans être utilisés). Un besoin RÉEL de HTML riche (éditeur de texte, modèle de
courrier) = décision écrite, puis assainisseur réintroduit selon §58 (version exacte, audit,
taille) et appelé dans UN seul composant ; aucune ressource externe chargée à
l'exécution (icônes, polices dans le build : CSP stricte possible) ; aucun champ personnel
dans la console.

---

## 58. DÉPENDANCES (correctif de sécurité du 11/10, dette 39) — RÈGLE

### 58.1 Versions
```
✅ Toute dépendance directe en version EXACTE dans package.json (pas de ^ ni ~) ; le
   package-lock.json est commité ; les images Docker installent par `npm ci`
✅ Une dépendance sans importeur (inventaire calculé) est RETIRÉE, pas mise à jour
   (11/10 : i18next-http-backend, 0 importeur)
✅ Montée de version MINEURE / correctif : par lot, avec audit, build, non-régression et tests
   à l'écran ciblés sur les paquets touchés
✅ Montée de version MAJEURE : un incrément dédié par paquet, prouvé (options de compatibilité
   d'abord, puis version), jamais avec `npm audit fix --force`
❌ `npm audit fix` aveugle ; `--force` ; ajout d'une dépendance sans audit avant / après et
   sans mesure de la taille du build
```

### 58.2 Audit
`npm audit` (tout) ET `npm audit --omit=dev` (ce qui part dans les navigateurs) relevés AVANT
et APRÈS chaque changement ; le résultat cible de toute version candidate est d'abord PROUVÉ
dans un projet jetable (lock régénéré) avant d'être appliqué au dépôt.

### 58.3 Piège mesuré (11/10)
`npm install` avec un package-lock.json existant NE met PAS à jour les dépendances
indirectes qui satisfont encore leur plage : les vulnérabilités indirectes restent (S1 : 13
au lieu de 9 attendues). Les rafraîchir par `npm update` (les directes étant figées, seules
les indirectes bougent), puis réauditer.

### 58.4 État et plan (11/10)
| Étape | Contenu | Audit (tout / prod) |
|---|---|---|
| départ | — | 23 / 8 (1 critique) |
| S1 ✅ `88807add` | axios 1.20.0 ; retrait de i18next-http-backend, dompurify, @types/dompurify (0 importeur) et du chunk `vendor-security` ; vite 6.4.4, postcss 8.5.29, tailwindcss 3.4.19, autoprefixer 10.6.1, @playwright/test 1.64.0 ; versions exactes ; indirectes rafraîchies (`npm update`) | **réel : 10 / 3, critique 0** (cible d'essai : 9 / 2 ; écart d'une unité à expliquer avec l'audit de S2) |
| S2 | React Router 7.18 (majeure) + garde « chemin interne seulement » sur toute navigation dont l'adresse vient du serveur | — |
| S3 | Tailwind 4 (majeure), avec les jetons (étape 1.3) | cible prouvée : 0 / 0 |
Risque résiduel entre S1 et S3 : outils de build seulement (Tailwind 3 : braces, micromatch,
chokidar), non livrés aux navigateurs ; React Router : exposition faible (aucune adresse de
navigation saisie par un utilisateur ; la `route` des résumés est construite par le serveur).
Restent après S1 (11/10, 22 h) : livrées aux navigateurs = 3 modérées, famille React Router 6
(→ S2) ; outils seulement = 7, chaîne Tailwind 3 (→ S3). Preuves de S1 : chaîne verte, image
reconstruite, tests à l'écran (photo, notifications temps réel, navigation), non-régression
complète 17/17.

### 58.5 Cartes de source (sourcemaps) — à trancher en S2
`vite.config.js` contient `sourcemap: true` : les fichiers `.map` sont SERVIS en production, donc
le code source frontend est lisible par tout visiteur. Options : `false` (aucune carte) ou
`'hidden'` (cartes générées pour le diagnostic, jamais servies : nginx refuse `*.map`).
Recommandation : `'hidden'` + refus nginx, prouvé par un 404 sur un `.map` servi. Dette 39.

---

## 59. MÉTHODE (rappel opposable, 11/10)
Exigence de l'utilisateur : « un bon résultat, bien conçu, sécurisé, robuste, maintenable et
évolutif, selon les standards des meilleurs ». Conséquences :
- conception écrite et VALIDÉE avant le code pour tout chantier transverse ;
- inventaire calculé de l'existant avant d'écrire (composants, styles, dépendances) ;
- toute affirmation de sécurité ou de compatibilité est PROUVÉE (projet d'essai, audit, test).
## 60. CHECKLIST (à ajouter à STANDARDS_FRONTEND §46 lors de la prochaine fusion)
```
[ ] 51. Nouvel écran : un descripteur + un patron (sinon exception motivée, §55.4)
[ ] 52. Icônes : lexique uniquement ; icône seule = cas §56.2 + libellé obligatoire
[ ] 53. Nouveau code transverse en TypeScript strict, avec tests Vitest
[ ] 54. Aucune classe Tailwind construite ; couleurs par jetons sémantiques
[ ] 55. Dépendance ajoutée / montée : version exacte, audit avant / après, taille du build
[ ] 56. Aucun HTML injecté (dangerouslySetInnerHTML) ; aucune carte de source servie
[ ] 57. Script de test qui lit une liste : TOUTES les pages (outils_pagination, §61.1)
```

---

## 61. SCRIPTS DE TEST ET DE PREUVE (hors dépôt, `docs/digierp/tests/`) — RÈGLE (11/10, 22 h)

### 61.1 Listes paginées
```
✅ Une liste de l'API est TOUJOURS lue en entier : outils_pagination.lire_toutes_les_pages(lire_page),
   lire_page(n) -> (code_http, reponse) ; l'appelant exige codes == {200}
✅ Arrêt garanti : page vide, page identique à une page déjà lue (serveur qui ignorerait `page`),
   code != 200, limite de pages
❌ Supposer qu'une liste tient sur une page ; gonfler `taille` (le serveur plafonne :
   AbsDemandeController `Math.min(taille, 100)`, défaut 20) ; purger les données de dev pour
   faire passer un test
```
Constat (11/10) : `securite_rls_politiques` S3-lecture et `nonreg_rls_workflow` B1 sont tombés
quand l'employé 4 a dépassé 20 demandes et la base 100 demandes actives (données créées par les
exécutions des tests). Le serveur était correct ; les tests lisaient la seule page 0.

### 61.2 Réponses et erreurs
```
✅ Réponse 2xx : JSON lu seulement si la réponse en est (image/*, octets, corps vide = succès
   sans json.loads)
✅ Une erreur de test (ERR) garde le TYPE et le MESSAGE de l'exception ; un échec affiche ce qu'il
   a reçu (code, message, extrait) : un ECHEC sans détail ne se diagnostique pas après coup
```

### 61.3 Code commun des tests
Un utilitaire utile à deux scripts va dans un MODULE de `tests/` importé par les deux (premier :
`outils_pagination.py`, auto-testé sur une fausse API : paginé, serveur ignorant `page`, 403) ;
jamais deux boucles recopiées (dette 25 : helpers recopiés, à résorber par ce chemin). Lancement
par `python3 -B` (aucun `__pycache__`).

### 61.4 Non-régression
La commande complète (17 contrôles, attendus de référence, arrêt si un seul diffère) est écrite
dans le prompt principal §8 ; elle précède tout commit.
