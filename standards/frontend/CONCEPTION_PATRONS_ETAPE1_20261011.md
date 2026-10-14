# CONCEPTION DÉTAILLÉE — PATRONS DE VUES, ÉTAPE 1 : FONDATIONS
# Version du 11/10/2026 (20 h 15). Statut : VALIDÉE le 11/10 (20 h 20) : C1-a TypeScript, C2-a types +
#   test + contrôle DTO, C3-a Vitest + Testing Library, C4-a variables CSS + C4-p1 IBM Plex embarquée.
# Cadre : claude/ANALYSE_PATRONS_VUES_20261011.md (décisions V1-V7 du 11/10).
# Exigence de l'utilisateur (11/10, 20 h 09) : « robuste, sécurisée, pas faite à l'arrache ;
#   un bon résultat, bien conçu, sécurisé, robuste, maintenable et évolutif, selon les standards
#   des meilleurs ». Elle s'applique à tout le chantier et prime sur la vitesse.

---

## 1. FAITS DE DÉPART (inventaires calculés du 11/10, lecture seule)

| Fait | Source | Conséquence |
|---|---|---|
| React 18.2, Vite 6.4, Tailwind 3.4, Node 18.20, npm 10.8 | `package.json`, `node -v` | socle moderne, aucune montée de version nécessaire |
| `lucide-react` 1.16.0 déjà installé (ISC) ; les 70 icônes du lexique existent | `node_modules`, import testé | aucune installation ; noms PascalCase vérifiés |
| 1 seul importeur direct de Lucide : `NotificationsPanel.jsx` (Bell, X, Check, CheckCheck, Loader2, Wifi, WifiOff) | grep | à migrer vers le lexique (même rendu) |
| 455 occurrences d'émojis dans 88 fichiers, 96 émojis distincts | script | migration progressive, module par module ; jamais en masse aveugle |
| `Button`, `Badge`, `EmptyState`, `PageHeader`, `Alert` : 0 importeur (forme `import X from '…/ui/X'`) ; `Spinner` 8, `Pagination` 9 | grep | à CONFIRMER par un inventaire sans filtre de forme ; si confirmé : refonte sans coût de migration |
| `config/theme.js` (jetons en hex) non relié à Tailwind (`extend: {}`) ; STANDARDS §3 recommande des classes construites (`bg-${c}-600`) | lecture | **défaut** : Tailwind ne génère que les classes écrites en entier ; une classe construite peut ne pas exister à l'exécution |
| `index.css` déclare la police `Inter` sans la charger | lecture | rendu réel = Segoe UI ; à décider (C4) |
| Pas d'outil de test de composants (Playwright en devDependency, non utilisé) | `package.json` | à décider (C3) |
| Projet en JavaScript (pas de TypeScript) | arbre | à décider (C1) |
| Stash `dette27-wip` : `config/locales.js`, `format.js`, `LocaleContext.jsx` | `git stash show` | relu avant d'écrire les types de champs (étape 1.6) |

---

## 2. QUALITÉS EXIGÉES ET COMMENT ELLES SONT GARANTIES

| Qualité | Garantie (vérifiable, pas déclarative) |
|---|---|
| **Robustesse** | contrats typés (C1) ; descripteur validé au build ET au chargement en dev (C2) ; valeur inconnue = erreur visible en dev, repli sûr en prod ; aucune classe CSS construite ; tests automatiques (C3) |
| **Sécurité** | §6 : aucune donnée exécutable dans un descripteur, aucun HTML injecté, droits décidés par le serveur, dépendances auditées et figées, aucune ressource externe chargée à l'exécution |
| **Accessibilité** | WCAG 2.2 niveau AA : contrastes ≥ 4,5:1, focus visible, tout au clavier, `aria-label` obligatoire pour une icône seule (contrôlé par le typage), `prefers-reduced-motion` ; contrôle `eslint-plugin-jsx-a11y` |
| **Maintenabilité** | une notion = un endroit (jetons, lexique, types de champs, statuts) ; API de composants documentées et stables ; couches strictes (§3) ; aucun composant déclaré dans un composant (§52) |
| **Évolutivité** | descripteurs = données pures sérialisables (passage au dictionnaire serveur possible, D3) ; jetons en variables CSS (thème sombre, marque client) ; patrons ajoutés sans toucher aux modules |
| **Performance** | imports Lucide statiques nommés (seules les icônes utilisées entrent dans le build) ; patrons chargés avec les pages (lazy existant) ; aucune dépendance lourde ajoutée sans mesure de la taille du bundle avant / après |
| **Testabilité** | règles en fonctions pures (`shared/utils`, `shared/patrons/regles`) testées sans navigateur ; composants testés en isolation (C3) ; page de démonstration interne (§5.8) |

---

## 3. ARCHITECTURE EN COUCHES (dépendances autorisées : de haut en bas uniquement)

```
modules/{module}/{objet}.objet.(ts|js)   ← DESCRIPTEURS (données pures, par module)
        │ consommés par
shared/patrons/                         ← PATRONS (Liste, Fiche, Assistant… étapes 2+)
        │ assemblent
shared/champs/                          ← TYPES DE CHAMPS (lecture + saisie + mise en forme)
shared/ui/                              ← COMPOSANTS DE BASE (Bouton, BoutonIcone, BadgeStatut,
        │                                  EnTetePage, EtatVide, Icone…)
shared/ui/icones.(ts|js)                ← LEXIQUE D'ICÔNES (seul importeur de lucide-react)
styles/jetons.css + tailwind.config.js  ← JETONS (variables CSS → classes Tailwind)
```
Règles :
- une couche n'importe jamais une couche au-dessus d'elle (contrôlé par un test d'architecture
  qui lit les imports, comme `controle_cles_resume.py`) ;
- **seul `icones` importe `lucide-react`** (contrôle au build) ;
- `shared/ui` ne connaît aucun module métier ni aucun endpoint ;
- un patron ne connaît aucun module : il ne reçoit qu'un descripteur.
Parallèle Laravel : `resources/views/components` (composants Blade) ← utilisés par des vues
générées depuis une `Resource` Filament ; le modèle Eloquent ne connaît pas la vue.

---

## 4. DÉCISIONS TECHNIQUES À VALIDER

### C1 — Typage
- **C1-a (recommandée) : TypeScript pour les NOUVEAUX dossiers transverses** (`shared/ui`,
  `shared/champs`, `shared/patrons`, descripteurs), le reste du projet restant en JavaScript.
  Vite compile `.ts/.tsx` sans configuration ; vérification par `tsc --noEmit` ajoutée à la
  chaîne frontend (règle 22). Un descripteur mal formé (champ inconnu, icône inexistante,
  icône seule sans libellé) devient une ERREUR DE COMPILATION, pas un écran cassé en recette.
  Parallèle Laravel : PHP typé + PHPStan niveau max sur le nouveau code.
- C1-b : JavaScript + JSDoc + `// @ts-check` (même contrôle, syntaxe plus lourde, moins outillé).
- C1-c : JavaScript seul + tests (contrôle seulement à l'exécution des tests).
### C2 — Validation des descripteurs
- **C2-a (recommandée)** : types TypeScript (C1) + **un test** qui charge TOUS les descripteurs et
  vérifie leur cohérence (clés i18n présentes en fr ET en en, icônes du lexique, champs connus) +
  un **contrôle au build** qui compare chaque champ du descripteur au DTO Java (comme
  `controle_cles_resume.py`). Aucune bibliothèque de validation embarquée dans le bundle.
- C2-b : schéma Zod validé à l'exécution (≈ 12 Ko de plus ; utile si un jour les descripteurs
  viennent du serveur — D2 — et pourra être ajouté à ce moment-là).
### C3 — Tests
- **C3-a (recommandée)** : **Vitest** (natif Vite, même configuration) + **Testing Library**
  (`@testing-library/react`, tests du point de vue de l'utilisateur : « le bouton nommé
  Modifier existe ») + `jsdom` ; Playwright (déjà présent) pour les parcours de bout en bout aux
  étapes suivantes. Commande unique `npm test`, ajoutée à la chaîne (règle 22) et à la
  non-régression. Les tests Node existants (`test_session.mjs`…) migrent progressivement.
- C3-b : tests Node des seules fonctions pures (pas de test de composant).
### C4 — Jetons et police
- **C4-a (recommandée)** : jetons en **variables CSS** (`src/styles/jetons.css`, palette actuelle
  inchangée : ardoise + bleu 600), branchées dans `tailwind.config.js` (`theme.extend.colors.
  primaire = 'rgb(var(--c-primaire) / <alpha-value>)'`…) : les composants écrivent des classes
  sémantiques ENTIÈRES (`bg-primaire`, `text-danger`), changeables en un seul endroit, thème
  sombre et marque client possibles plus tard. `config/theme.js` est retiré quand plus rien ne
  le lit (inventaire calculé) ; STANDARDS §3 est corrigé (classes construites interdites).
- Police : **C4-p1 (recommandée)** `IBM Plex Sans` + `IBM Plex Mono` (matricules, codes),
  licence OFL, **embarquées dans le build** (paquet `@fontsource`, aucun appel à Google Fonts :
  confidentialité, fonctionnement hors ligne, CSP stricte possible) ; C4-p2 police système
  (aucun fichier, rendu variable selon l'OS) ; C4-p3 Inter embarquée.
### C5 — Lexique d'icônes
`shared/ui/icones.ts` : table `nom métier → composant Lucide` (imports statiques nommés) ;
type `NomIcone` = union des clés ; composant `<Icone nom="employe" taille="md" />` (tailles
16 / 20 / 24, trait 2, `aria-hidden` par défaut). Nom inconnu : erreur de compilation (C1) ;
en exécution, `console.error` + rendu vide (jamais d'exception qui casse l'écran). Aucun
import dynamique par nom (sécurité et tree-shaking).

### C6 — Contrats des composants de base (extrait ; complet dans les fichiers)
| Composant | Contrat | Garde-fous |
|---|---|---|
| `Bouton` | `variante` (principal, secondaire, danger, succes, fantome), `taille`, `icone?`, `chargement`, `desactive`, `type` | variante inconnue = erreur de type ; `type="button"` par défaut (jamais de soumission involontaire) ; désactivé pendant le chargement |
| `BoutonIcone` | `icone`, **`libelle` obligatoire** (→ `aria-label` + info-bulle), `variante`, `taille` | sans libellé : erreur de compilation ; cible tactile ≥ 40 px |
| `BadgeStatut` | `statut` + table de statuts du module (`{code → libellé i18n, ton, icône}`) | statut inconnu : badge neutre + `console.error` ; jamais couleur seule |
| `EnTetePage` | `icone`, `titre`, `sousTitre?`, `actionPrincipale?`, `actions?` | une seule action principale (typage) |
| `EtatVide` | `icone`, `titre`, `message?`, `action?` | |
| `InfoBulle` | accessible au clavier (focus) et au survol, `role="tooltip"`, `aria-describedby` | pas de dépendance externe |

### C7 — Navigation
La barre latérale passe des émojis aux icônes du lexique (première amélioration visible) ;
`navigation.js` référence des NOMS du lexique (`icone: 'employe'`), plus des émojis.

---

## 5. PLAN D'ÉCRITURE (un fichier à la fois, chacun vérifié)

| # | Fichier / action | Vérification |
|---|---|---|
| 1.0 | inventaire complémentaire (lecture seule) : importeurs de `theme.js` et de `shared/styles/*`, autres formes d'import de `shared/ui`, classes construites dynamiquement (`` `bg-${`` …), fichiers du stash `dette27-wip` affichés | sortie calculée |
| 1.1 | outillage : `typescript`, `vitest`, `@testing-library/react`, `jsdom`, `eslint-plugin-jsx-a11y`, polices — versions FIGÉES, `npm audit` avant / après, taille du bundle avant / après | `npm ci` = 0, `npx vite build` = 0, audit sans vulnérabilité haute nouvelle |
| 1.2 | `tsconfig.json` (strict) + `vitest.config` + script `npm test` + `tsc --noEmit` dans la chaîne | `npm test` = 0 (test témoin) |
| 1.3 | `src/styles/jetons.css` + `tailwind.config.js` | build = 0 ; classes sémantiques présentes dans le CSS servi |
| 1.4 | `shared/ui/icones.ts` + `Icone.tsx` + tests (nom connu / inconnu, `aria-hidden`) + contrôle « seul importeur de Lucide » | tests verts |
| 1.5 | `Bouton`, `BoutonIcone`, `InfoBulle`, `BadgeStatut`, `EnTetePage`, `EtatVide` (un par un, chacun avec ses tests) | tests verts, a11y lint = 0 |
| 1.6 | types de champs (texte, date, nombre, montant XAF, booléen, énuméré, référence, identifiant à masque, email, téléphone) : lecture + saisie + mise en forme selon la langue ; **reprend le stash `dette27-wip`** (relu, pas dépilé à l'aveugle) | tests en fr ET en en, deux fuseaux |
| 1.7 | navigation : `navigation.js` + barre latérale sur le lexique ; `NotificationsPanel` sur le lexique | test UI, marqueur servi |
| 1.8 | page interne « Composants » (route réservée ADMIN, PBAC) : galerie de tous les composants et du lexique, sert de recette visuelle | test UI |
| 1.9 | non-régression complète, commit(s), push, déploiement recette (frontend seul), STANDARDS (§3 corrigé, nouvelle section « Fondations »), leçons | règles 21-28 |

---

## 6. SÉCURITÉ (frontend)

1. **Le serveur décide** : masquer un bouton n'est jamais une protection ; toute action reste
   contrôlée par PBAC + politique de document + RLS côté serveur. Les patrons n'affichent que
   ce que le DTO renvoie ; un champ sensible absent du DTO n'existe pas pour l'écran.
2. **Aucune donnée exécutable** dans un descripteur (pas de fonction, pas de chaîne évaluée,
   pas de `new Function`, pas d'import dynamique par nom) : condition pour pouvoir un jour les
   servir depuis la base sans ouvrir une faille.
3. **Aucun HTML injecté** : interdiction de `dangerouslySetInnerHTML` dans `shared/` (contrôle
   au build) ; les textes passent par React (échappés) et l'i18n.
4. **Aucune ressource externe à l'exécution** : icônes et polices dans le build (pas de CDN),
   ce qui permet une politique CSP stricte côté nginx (à poser dans une étape ultérieure).
5. **Chaîne d'approvisionnement** : versions figées dans `package-lock.json`, `npm ci` en build,
   `npm audit` avant / après chaque ajout (dette 39), licences vérifiées (ISC, MIT, OFL).
6. **Données personnelles** : aucun champ personnel dans les journaux de la console ; les
   messages `console.error` des composants citent la clé, jamais la valeur.

---

## 7. CE QUI N'EST PAS FAIT À L'ÉTAPE 1 (pour ne pas le perdre)
- Patrons Liste / Fiche / Assistant (étape 2-3), endpoints par section et actions (étape 2).
- Migration des 455 émojis hors navigation : par module, avec la migration du module vers les
  patrons (étape 4) — jamais par remplacement en masse.
- CSP nginx (étape ultérieure, rendue possible par §6.4).
