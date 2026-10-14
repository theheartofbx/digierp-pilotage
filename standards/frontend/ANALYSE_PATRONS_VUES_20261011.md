# ANALYSE — PATRONS DE VUES DigiERP (vues standard consommées par tous les modules)
# Version du 11/10/2026 (soir). Statut : DÉCIDÉ le 11/10/2026 à 20 h 03 (recommandations V1 à V7
#   adoptées par l'utilisateur, §7). Devient standard à l'étape 6 du plan (§6).
# Origine : demande de l'utilisateur après le prototype « Fiche Employé » (canvas Design) :
#   1. analyser les modules actuels et futurs pour définir des vues standard ;
#   2. les réaliser comme des patrons consommés par tous les modules, sans réflexion à refaire ;
#   3. s'appuyer sur les meilleures pratiques du design web ; icônes illustratives, icône seule
#      quand elle est assez parlante.
# Sources lues : code poussé (rh-frontend : navigation.js, EmployeForm, EmployeDetailModal,
#   useEmployesList…), HLD RH / STOCK / ACHAT / BUDGET (Project), STANDARDS_FRONTEND §25-§54,
#   références web citées en fin de document. Noms d'icônes VÉRIFIÉS dans lucide-static 0.460.0
#   (1 539 icônes, licence ISC) le 11/10.

---

## 1. CONSTAT : MÊMES BESOINS, ÉCRANS REFAITS À LA MAIN

Chaque module a écrit ses propres écrans (liste, formulaire, détail, modales) en copiant le
précédent. Les standards (§25 « deux patterns d'administration », §27 « modal de détail +
formulaire autonome », §39 actions, §41 pile de fenêtres…) disent COMMENT écrire un écran, mais
chaque écran reste écrit à la main. Conséquences observées :
- incohérences entre écrans d'un même objet (Employés : création ≠ modification ≠ détail,
  analyse du 11/10) ;
- incohérences entre modules (trois manières de supprimer une sous-information, trois
  mécanismes de mise en forme des dates : dette 27) ;
- coût : chaque nouveau module (Stock, Achats, Budget, inventoriés au §2) répéterait tout.
Ce que font les ERP et design systems de référence : un **petit catalogue de types de pages**
(« floorplans » chez SAP Fiori, « view types » chez Odoo), et chaque objet métier DÉCRIT ses
champs, ses colonnes, ses actions ; la page est ASSEMBLÉE à partir de la description.
- SAP Fiori elements : « build enterprise apps quickly using proven page types known as
  floorplans… you assemble an app from standardized pages that are automatically filled with
  your business data and actions » (List Report, Object Page, Worklist, Overview Page,
  Analytical List Page).
- Odoo : les vues (form, list, kanban, calendar, pivot, graph, gantt…) sont des
  enregistrements `ir.ui.view` liés à un modèle, décrits en XML (`arch`) et héritables.
- **Parallèle iDempiere (que tu connais)** : le Dictionnaire applicatif (AD_Window, AD_Tab,
  AD_Field, AD_Process) génère TOUTES les fenêtres à partir de métadonnées. C'est exactement
  l'idée, avec une interface moderne et sans perdre la main sur les écrans particuliers.
- Parallèle Laravel : Filament / Nova — une classe `Resource` déclare `form()`, `table()`,
  `actions()`, et le panneau d'administration est généré.

---

## 2. INVENTAIRE DES BESOINS DE VUES (modules actuels et futurs)

Lecture : pour chaque écran connu ou prévu, le ou les patrons qui le servent (codes au §3).

### 2.1 RH — existant
| Écran | Patrons |
|---|---|
| Employés | LISTE + FICHE (famille, contacts, coordonnées, affectations = listes rattachées) + ASSISTANT (création) |
| Postes | LISTE + FICHE |
| Contrats (avenants, échéances) | LISTE + FICHE + JOURNAL (historique des avenants) |
| Organigramme | ARBRE |
| Mes tâches / Mes demandes | FILE DE TRAVAIL (décision rapide) |
| Absences (demande, solde, circuit) | LISTE + FICHE (+ CALENDRIER à venir : planning) + ASSISTANT |
| Discipline | LISTE + FICHE + FILE DE TRAVAIL |
| Missions (création, frais, rapport) | LISTE + FICHE + DOCUMENT À LIGNES (frais) + ASSISTANT |
| Formation (catalogue, sessions, inscriptions, formateurs) | LISTE + FICHE + CALENDRIER (sessions) + GRILLE (présences) |
| Paramétrage (types, statuts, catégories…) | RÉFÉRENTIEL (déjà factorisé : « Pattern 1 », §25) |
| Organisation (organisation → sites → services) | ARBRE + FICHE |
| Modèles de workflow, Droits, Séquences, Postes-accès | FICHE spécialisée / MATRICE (écrans libres, §4.4) |
| Audit des refus | LISTE (lecture seule) / JOURNAL |
| Tableau de bord | TABLEAU DE BORD |
| Archives (dans chaque liste) | LISTE (mode archives) |

### 2.2 RH — prévu (HLD RH §2.4)
| Sous-domaine | Patrons |
|---|---|
| Médecine du travail (visites, convocations, échéances, aptitudes) | LISTE + FICHE + CALENDRIER + FILE (échéances) |
| Paie (périodes, éléments variables, bulletins, journal, déclarations) | GRILLE (éléments variables) + DOCUMENT À LIGNES (bulletin) + ASSISTANT (clôture de période) + LISTE |
| Prêts (simulation, échéancier, retenues) | FICHE + DOCUMENT À LIGNES (échéancier) + COMPARATEUR (simulation) |
| Stages (conventions, prolongations) | LISTE + FICHE + ASSISTANT |
| Recrutement (besoins, campagnes, candidats, entretiens, offres) | TABLEAU PAR ÉTAPES (pipeline des candidatures) + FICHE + CALENDRIER (entretiens) |

### 2.3 Stock (HLD STOCK)
| Écran | Patrons |
|---|---|
| Produits, catégories, unités | FICHE + LISTE / RÉFÉRENTIEL |
| Stock courant (disponible, réservé, bloqué) | LISTE analytique (+ indicateurs) |
| Mouvements (entrée, sortie, transfert, destruction) | DOCUMENT À LIGNES + FILE (validation) |
| Entrepôts, zones, emplacements | ARBRE + FICHE |
| Inventaires (comptage, écarts) | GRILLE (saisie des comptages) + COMPARATEUR (théorique / constaté) |
| Commandes clients, livraisons, retours | DOCUMENT À LIGNES + TABLEAU PAR ÉTAPES (suivi des statuts) |
| Alertes (rupture, péremption, seuil) | FILE DE TRAVAIL |
| Pilotage | TABLEAU DE BORD |

### 2.4 Achats (HLD ACHAT)
| Écran | Patrons |
|---|---|
| Fournisseurs, contrats fournisseurs, évaluation | FICHE + LISTE |
| Demandes d'achat (validation multi-niveaux) | DOCUMENT À LIGNES + FILE |
| Appels d'offres, analyse des offres | COMPARATEUR (offres côte à côte) |
| Commandes, livraisons / réceptions | DOCUMENT À LIGNES + TABLEAU PAR ÉTAPES |
| Factures (rapprochement commande / réception / facture) | COMPARATEUR + DOCUMENT À LIGNES |
| Paiements, litiges | LISTE + FICHE + FILE |
| KPI achats | TABLEAU DE BORD |

### 2.5 Budget (HLD BUDGET)
| Écran | Patrons |
|---|---|
| Centres de coût, rubriques | RÉFÉRENTIEL / ARBRE |
| Budgets (versions, révisions, gel) | FICHE + JOURNAL (versions) |
| Prévisions (saisie décentralisée) | GRILLE (type tableur) |
| Consolidation multi-niveaux | ARBRE avec agrégats |
| Simulation, scénarios | COMPARATEUR |
| Exécution (engagement, liquidation), écarts | LISTE analytique + FILE + TABLEAU DE BORD |

### 2.6 Conclusion de l'inventaire
Les 41 lignes d'écrans inventoriées ci-dessus (actuels et prévus, compte calculé) se ramènent à **12 patrons**. Les trois premiers (LISTE,
FICHE, ASSISTANT) couvrent à eux seuls la grande majorité des écrans ; les autres apparaissent
dans plusieurs modules chacun (DOCUMENT À LIGNES : Missions, Paie, Prêts, Stock, Achats ;
GRILLE : Formation, Paie, Stock, Budget ; COMPARATEUR : Prêts, Stock, Achats, Budget…).

---

## 3. LE CATALOGUE DES 12 PATRONS

| # | Patron | Icône (Lucide) | Rôle | Équivalents |
|---|---|---|---|---|
| P1 | **LISTE** | `list` | trouver, filtrer, trier, agir sur beaucoup d'éléments ; mode archives ; export | Fiori List Report, Odoo list |
| P2 | **FICHE** | `id-card` | consulter / modifier UN objet : en-tête, onglets, sections éditables, listes rattachées, actions, historique ; 3 cadres (fenêtre, panneau, page) | Fiori Object Page, Odoo form |
| P3 | **ASSISTANT** | `wand-sparkles` | créer en quelques étapes le minimum obligatoire, puis ouvrir la fiche | Fiori Wizard |
| P4 | **FILE DE TRAVAIL** | `inbox` | traiter des éléments en attente (tâches, alertes, échéances) avec décision rapide | Fiori Worklist |
| P5 | **RÉFÉRENTIEL** | `settings` | listes code / libellé éditables sur place (paramétrage) | « Pattern 1 » actuel (§25) |
| P6 | **DOCUMENT À LIGNES** | `file-text` | FICHE dont une section est une grille de lignes éditable avec totaux (commande, mouvement, bulletin, frais) | Odoo form + one2many |
| P7 | **ARBRE** | `folder-tree` | hiérarchie (organisation, entrepôts, centres de coût), agrégats par niveau | — |
| P8 | **TABLEAU PAR ÉTAPES** | `kanban` | cartes rangées par statut, glisser pour avancer (pipeline) | Odoo kanban |
| P9 | **CALENDRIER / PLANNING** | `calendar-days` | éléments datés : jour / semaine / mois, planning par personne | Odoo calendar / gantt |
| P10 | **GRILLE DE SAISIE** | `sheet` | saisie en masse façon tableur (comptages, prévisions, éléments variables) | Odoo grid |
| P11 | **COMPARATEUR** | `git-compare` | objets côte à côte, écarts mis en évidence (offres, scénarios, rapprochements) | — |
| P12 | **TABLEAU DE BORD** | `layout-dashboard` | cartes d'indicateurs par rôle, chaque carte mène à la liste filtrée | Fiori Overview Page |

Plus un élément transverse, utilisé DANS les patrons : **JOURNAL** (`history`) — fil
chronologique (historique des statuts, audit, versions), section standard de toute FICHE.

### 3.1 Anatomie commune (ce qui est identique dans tous les patrons)
- **En-tête de page** : icône de l'objet, titre, sous-titre (compte, filtre actif), action
  principale (une seule en bouton plein), actions secondaires (icônes), menu « Plus » (`ellipsis`).
- **Badge de statut** : couleur + icône + texte (jamais la couleur seule), une table de
  correspondance statut → couleur → icône par module, déclarée une fois.
- **États** : chargement LOCAL (§51), liste vide utile (« Aucun conjoint — Ajouter »), erreur
  avec action (« Réessayer »), absence de droit expliquée.
- **Actions** : une seule source de vérité des actions permises (le serveur : `actionsPermises`,
  déjà en place pour les absences, §39) ; un motif obligatoire se saisit dans le même composant
  partout ; toute action destructive confirme.
- **Fenêtres** : jamais de fenêtre ouverte depuis une autre fenêtre (Carbon) ; les ajouts dans
  une liste rattachée se font sur place.
- **Adresse** : toute fiche a une adresse (`?fiche=` ou `/module/:id`) ; Retour fonctionne.
- **Clavier** : Échap ferme (pile, §41) ; Entrée valide un formulaire ; ↑ ↓ dans le panneau.
### 3.2 La FICHE en détail (patron le plus utilisé)
- **Cadres** : fenêtre (défaut actuel, appréciée), panneau latéral (traitement en série), page
  (« Agrandir », partage, impression, mobile). Le CONTENU est le même composant dans les 3.
- **En-tête** : photo ou icône, titre, code métier, statut, 3 ou 4 attributs clés, barre de
  complétude (optionnelle, par objet), actions.
- **Onglets** : UN niveau ; chaque onglet = sections empilées.
- **Section de champs** : lecture ↔ édition sur place (crayon), Enregistrer / Annuler, garde
  « modifications non enregistrées ».
- **Section liste rattachée** : lignes + « Ajouter » sur place, Modifier / Retirer avec motif.
- **Champs non modifiables** : étiquette explicative (« par affectation », « calculé »).
- **Menu Actions** : actions sensibles (corriger un code métier, changer de statut, archiver),
  chacune avec son droit, son motif, sa trace d'audit.
- **Onglet ou section JOURNAL** : historique daté (qui, quoi, quand, motif).

---

## 4. COMMENT LES RENDRE « CONSOMMABLES » PAR TOUS LES MODULES

### 4.1 Le principe : décrire l'objet, pas l'écran
Chaque module fournit un **descripteur** (un fichier de configuration) par objet métier ; les
patrons lisent le descripteur et construisent l'écran. Exemple (forme cible, à affiner) :

```js
// modules/employes/employe.objet.js — descripteur de l'objet Employé
export default definirObjet({
  code: 'employe', icone: 'user-round', libelle: 'employes:objet',
  api: '/rh/employes', permission: 'RH.EMPLOYE',
  entete: { titre: ['nom', 'prenom'], code: 'matricule', statut: 'statut',
            attributs: ['poste', 'service', 'site'], photo: true, completude: true },
  liste:  { colonnes: ['matricule', 'nomComplet', 'poste', 'site', 'statut'],
            filtres: ['statut', 'site'], recherche: true, archives: true, export: true },
  onglets: [
    { code: 'identite', icone: 'id-card', sections: [
      { code: 'etatcivil', champs: ['nom', 'prenom', 'sexe', 'dateNaissance', 'lieuNaissance',
        'nationalite', 'situationMatrimoniale', 'groupeSanguin'] } ] },
    { code: 'emploi', icone: 'briefcase', sections: [
      { code: 'rattachement', champs: ['site', { cle: 'poste', lectureSeule: 'par affectation' }] },
      { code: 'identifiants', champs: ['numeroCnps', 'niu'] } ] },
    { code: 'famille', icone: 'users', sections: [
      { code: 'famille', type: 'liste', api: '{id}/famille' } ] },
  ],
  actions: [
    { code: 'corriger-matricule', icone: 'pen-line', motif: true, champs: ['matricule'] },
    { code: 'archiver', icone: 'archive', motif: true, danger: true },
  ],
  creation: { etapes: [['nom', 'prenom', 'dateNaissance', 'sexe'],
                       ['site', 'matricule'], ['email', 'telephone']] },
})
```
Et la page du module se réduit à :
```jsx
export default function EmployesPage() { return <PatronListeFiche objet={employe} /> }
```
Un **type de champ** décide de son affichage, de sa saisie et de sa mise en forme (une fois,
pour tous les modules) : texte, nombre, montant (XAF), date, période, booléen, énuméré,
référence (liste déroulante sur un endpoint de liste complète, §48), statut, identifiant à
masque (CNPS, NIU), email, téléphone, fichier / photo, calculé (lecture seule + étiquette).
La dette 27 (mise en forme selon la langue) se règle ICI : une seule fonction par type.

### 4.2 Le contrat serveur que les patrons supposent (uniforme pour tout module)
| Besoin du patron | Endpoint standard | État aujourd'hui |
|---|---|---|
| liste paginée, triée, filtrée | `GET /{objet}?page&taille&tri&q&filtres` → `PageResponse` | en place (forme `contenu`) |
| liste complète pour une référence | `GET /{objet}/tous` | partiel (§48) |
| fiche complète | `GET /{objet}/{id}` avec `actionsPermises` | partiel (absences) |
| modifier une section | `PUT /{objet}/{id}/sections/{code}` (seuls les champs de la section) | à créer |
| action métier | `POST /{objet}/{id}/actions/{code}` `{motif, …}` | partiel (soumettre, annuler…) |
| liste rattachée | `GET/POST/PUT/DELETE /{objet}/{id}/{liste}[/{ligneId}]` | en place (famille, contacts) |
| journal | `GET /{objet}/{id}/historique` | à créer (audit existe) |
| archives, restauration, purge | `GET /{objet}/archives`, `POST …/restaurer`, `DELETE …/purger` | en place |
| export | `GET /{objet}/export/excel` | partiel (dette 31) |
Parallèle Laravel : une `Route::apiResource` + des routes d'action nommées, identiques pour
toutes les ressources.

### 4.3 Où vivent les descripteurs — trois options
- **D1 — Descripteurs dans le frontend (fichiers JS par module).** Simple, versionné avec le
  code, typé par des contrôles au build. Les libellés restent dans l'i18n. Limite : la
  cohérence avec le DTO Java se contrôle par un test (comme `controle_cles_resume.py`).
- **D2 — Dictionnaire applicatif en base, servi par le backend** (comme iDempiere AD ou Odoo
  `ir.ui.view`). Personnalisable sans déploiement (colonnes, ordre, champs visibles par
  client). Limite : lourd à construire (écrans d'administration du dictionnaire, migrations,
  sécurité), et une erreur de paramétrage casse un écran en production.
- **D3 (recommandée) — D1 maintenant, avec un format pensé pour D2 plus tard.** Les
  descripteurs sont des données pures (aucune fonction dedans, sérialisables en JSON) ; le
  backend pourra un jour en servir une partie (personnalisation par client : colonnes, filtres
  sauvegardés) sans réécrire les patrons. Contrôle au build : chaque champ cité existe dans le
  DTO (outil de contrôle, comme pour les clés de résumé).
### 4.4 Ce qui reste écrit à la main (et c'est normal)
Les écrans vraiment singuliers : éditeur de modèles de workflow, matrice des droits,
organigramme graphique, calcul de paie. Règle : ils utilisent les COMPOSANTS de base (en-tête,
boutons, badges, champs, icônes) même s'ils n'utilisent pas un patron complet. Fiori fait de
même (« freestyle » à côté des « elements »).

### 4.5 Règle de construction
Un patron est construit **au premier module qui en a besoin**, à partir du catalogue (pas
d'invention locale), et n'est déclaré « standard » qu'après un **second usage réel** qui le
valide sans modification de fond. LISTE, FICHE, ASSISTANT : pilote Employés (cas le plus
riche), validation Postes.

---

## 5. ICÔNES : RÈGLES D'USAGE

### 5.1 Bibliothèque
**Lucide** (`lucide-react`) : 1 539 icônes au trait homogène, licence ISC (libre, compatible
avec un ERP open source), composants React importés un par un (seules les icônes utilisées
entrent dans le build). Remplace les émojis actuels de la navigation (`👤`, `💼`…), dont le
rendu change selon le système (Windows, Android, macOS), qui ne prennent pas la couleur du
thème et que les lecteurs d'écran lisent mal.

### 5.2 Un lexique unique : une notion = une icône, partout
Fichier unique `shared/ui/icones.js` (nom métier → composant Lucide). Aucun composant
n'importe Lucide directement : il demande l'icône de la notion (`icone('employe')`). Un
changement d'icône se fait une fois.

**Objets métier**
| Notion | Icône | Notion | Icône |
|---|---|---|---|
| Tableau de bord | `layout-dashboard` | Produit | `package` |
| Employé | `user-round` | Stock | `boxes` |
| Employés (groupe RH) | `users` | Mouvement de stock | `arrow-left-right` |
| Poste | `briefcase` | Entrepôt | `warehouse` |
| Contrat | `file-pen-line` | Inventaire | `clipboard-list` |
| Organigramme | `network` | Commande | `shopping-cart` |
| Organisation, site | `building-2` | Livraison | `truck` |
| Mes tâches | `list-checks` | Retour | `undo-2` |
| Absence | `calendar-off` | Fournisseur | `store` |
| Mission | `plane` | Facture | `receipt` |
| Formation | `graduation-cap` | Paiement | `credit-card` |
| Discipline | `gavel` | Litige | `message-square-warning` |
| Paie | `wallet` | Budget | `piggy-bank` |
| Prêt | `hand-coins` | Centre de coût | `target` |
| Recrutement | `user-search` | Paramétrage | `settings` |
| Médecine du travail | `stethoscope` | Droits | `key-round` |
| Stage | `backpack` | Séquences | `hash` |
| Famille | `users` | Audit, journal | `scroll-text` / `history` |

**Actions**
| Action | Icône | Icône seule ? |
|---|---|---|
| Rechercher | `search` | oui (universelle) |
| Fermer | `x` | oui (universelle) |
| Imprimer | `printer` | oui (universelle) |
| Plus d'actions | `ellipsis` | oui |
| Agrandir / réduire | `maximize-2` / `minimize-2` | oui, avec info-bulle |
| Précédent / suivant | `chevron-up` / `chevron-down` | oui, avec info-bulle |
| Voir (dans une ligne) | `eye` | oui dans une ligne de tableau, avec info-bulle |
| Modifier (dans une ligne) | `pencil` | oui dans une ligne de tableau, avec info-bulle |
| Filtrer, trier | `list-filter`, `arrow-up-down` | oui dans un en-tête de colonne / barre d'outils |
| Exporter | `download` | icône + texte en en-tête de page |
| Créer | `plus` | **icône + texte** (« Nouvel employé ») |
| Enregistrer | `check` | **texte** (+ icône facultative) |
| Valider (décision) | `circle-check` | **icône + texte** |
| Rejeter | `circle-x` | **icône + texte** |
| Soumettre | `send` | **icône + texte** |
| Annuler (une demande) | `ban` | **icône + texte** |
| Archiver | `archive` | **icône + texte** (action sensible) |
| Restaurer | `archive-restore` | icône + texte |
| Purger | `trash-2` | **icône + texte** (destructif) |
| Joindre un fichier | `paperclip` | oui, avec info-bulle |
| Commenter | `message-square` | oui, avec info-bulle |
| Historique | `history` | icône + texte (onglet) |

### 5.3 Quand l'icône peut rester seule (règle de décision)
Nielsen Norman Group : « a text label must be present alongside an icon to clarify its
meaning », sauf pour les très rares icônes universelles (accueil, imprimer, loupe de
recherche) ; ne pas compter sur le survol pour révéler le libellé ; si l'on ne trouve pas
d'icône parlante en 5 secondes, il n'y en a pas. D'où la règle DigiERP :

**Icône seule autorisée** si au moins UNE condition est vraie, ET toujours avec `aria-label`
+ info-bulle (même texte, issu de l'i18n) :
1. icône universelle : rechercher, fermer, imprimer, plus d'actions, menu ;
2. action répétée dans une ligne de tableau ou une carte (voir, modifier, joindre) : le
   contexte et la répétition l'apprennent, et le texte encombrerait chaque ligne ;
3. barre latérale réduite (déjà en place) ou barre d'outils dense, quand le même libellé est
   visible ailleurs sur l'écran (version étendue, en-tête de colonne).
**Icône + texte obligatoires** :
- action principale de la page (une par page) ; décisions (valider, rejeter, soumettre) ;
- actions sensibles ou destructives (archiver, purger, corriger un code métier) ;
- onglets et navigation principale étendue ;
- toute notion qui échoue au test des 5 secondes.
**Statuts** : badge = icône + texte + couleur (jamais la couleur seule, jamais l'icône seule).

Contrôle automatique proposé : un `BoutonIcone` sans `libelle` ne compile pas (prop
obligatoire, utilisée pour `aria-label` et l'info-bulle) ; un contrôle au build vérifie que
chaque icône citée existe dans le lexique.

---

## 6. PLAN D'ADOPTION (incréments livrables, chacun déployable en recette)

| Étape | Contenu | Valide |
|---|---|---|
| 0 | Décisions (§7) | — |
| 1 | **Fondations** : `lucide-react`, lexique `icones.js`, jetons de design (couleurs, espacements, rayons, statuts), composants de base (`Bouton`, `BoutonIcone` à libellé obligatoire, `BadgeStatut`, champs par type, en-tête de page) ; navigation passée des émojis aux icônes | écran de démonstration interne + navigation |
| 2 | **FICHE + LISTE pilotées par descripteur**, pilote **Employés** (3 cadres : fenêtre par défaut, « Agrandir » → page ; panneau ensuite) ; endpoints par section et actions ; contrôle « champs du descripteur = DTO » | non-régression + tests UI Employés |
| 3 | **ASSISTANT** (création employé), **FILE DE TRAVAIL** (migration de « Mes tâches »), **RÉFÉRENTIEL** (migration du Pattern 1) | Postes migré sans écrire d'écran |
| 4 | Migration des modules RH existants un par un (Postes, Contrats, Absences, Missions, Discipline, Formation) | suppression des anciens composants |
| 5 | Patrons suivants au premier besoin réel : DOCUMENT À LIGNES (frais de mission), CALENDRIER (planning des absences), GRILLE (présences formation), ARBRE (organisation), TABLEAU PAR ÉTAPES (recrutement), COMPARATEUR (achats), TABLEAU DE BORD | 2ᵉ usage = standard |
| 6 | Standard écrit (STANDARDS_FRONTEND, nouvelle section « Patrons de vues ») et checklist : un nouvel écran = un descripteur, sauf exception motivée (§4.4) | — |

Les modules Stock, Achats et Budget démarrent ensuite DIRECTEMENT sur les patrons.

---

## 7. DÉCISIONS (adoptées le 11/10/2026 : colonne « Recommandation »)

| # | Question | Options | Recommandation |
|---|---|---|---|
| V1 | Catalogue | les 12 patrons du §3 (ajouts / retraits ?) | adopter, extensible |
| V2 | Cadre par défaut de la FICHE | fenêtre / panneau / page | **fenêtre** (continuité), « Agrandir » vers la page, panneau en option |
| V3 | Où vivent les descripteurs | D1 / D2 / D3 (§4.3) | **D3** |
| V4 | Bibliothèque d'icônes | Lucide / autre / émojis | **Lucide** |
| V5 | Règle icône seule | §5.3 | adopter |
| V6 | Pilote | Employés / un objet plus simple | **Employés** (cas le plus riche ; valide tout le modèle) |
| V7 | Calendrier | avant / après Phase B des migrations et dettes 37, 38, 28 | **patrons d'abord** (frontend), Phase B ensuite ; dette 37 (Famille) traitée à l'étape 2, dette 27 (mise en forme) absorbée par les types de champs de l'étape 1 |

---

## 8. SOURCES
- SAP Fiori elements — https://www.sap.com/design-system/fiori-design-web/v1-139/discover/frameworks/sap-fiori-elements
- SAP Learning — templates Fiori elements — https://learning.sap.com/learning-journeys/develop-sapui5-applications/explaining-templates-for-fiori-elements_dec74b06-8f9c-404d-922d-0f5faafcd289
- Odoo 18 — View records — https://www.odoo.com/documentation/18.0/developer/reference/user_interface/view_records.html
- Nielsen Norman Group — Icon Usability — https://www.nngroup.com/articles/icon-usability/
- Carbon Design System — Dialog pattern — https://carbondesignsystem.com/patterns/dialog-pattern
- GitLab Pajamas — Modal — https://design.gitlab.com/components/modal
- Notion — side peek / center peek / full page — https://www.notion.com/releases/2022-07-20
- HubSpot — Preview a record — https://knowledge.hubspot.com/records/preview-a-record
- Lucide — paquet lucide-static 0.460.0 (licence ISC), noms vérifiés localement le 11/10
