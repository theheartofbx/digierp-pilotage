# FIL CONDUCTEUR DigiERP - revision 15 du 16/10/2026 (par Project Pilote)
# Lu au debut de chaque conversation, dans chaque Project. Modifie par script uniquement
# (revision + 1 a chaque modification). Regles : section 7. Format : LISEZMOI.md.
# Vit dans le depot de PILOTAGE (digierp-pilotage, origin GitHub seul), distinct du depot de code.
# Les libelles de la colonne "Element" de la section 1 sont lus par
# commun/controle_reprise.sh : ne jamais les renommer.

## 1. Etat commun

| Element | Valeur |
|---|---|
| Dernier commit du depot de code | 116a4964a981fc8659cc2ebe45e9ca2b22a0ca4d |
| Branche | DigiErp-Spring-React (origin GitHub + biapay GitLab) |
| Depot de pilotage | digierp-pilotage, branche main (origin GitHub SEUL ; jamais de remote biapay : R16) |
| Tag de reference de la garde des migrations | recette-20261011 (-> 7e861563) |
| Recette deployee sur | 5cd225ca (fondations 1.1, 1.2, 1.4, etape 1.7 (1.7b, 1.7c), DC1 (db314b41), 1.3a (5e6c682d) et 1.3b (116a4964) non deployees : partent a la fin des patrons, etapes 1 a 4 et 6 (etape 5 apres), decisions DR1 et DR3) |
| Migrations dev / recette | 45 / 39 ; derniere 20261011.3 |
| Tables sous RLS (dev) | 16 |
| Non-regression de reference | 18 controles (verte le 12/10 : echecs=0, ok=18) |
| Qui tient le depot (arbre de travail du PC) | Pilote - consignation apres OT-010 (1.3b ACCEPTE), decisions W1-W6, dette 51 ; prochaine etape OT-011 (code mort : theme.js, forms.styles.js, App.css si sans usage ; Project Frontend) ; aucun travail non commite |

## 2. Compteurs partages (prochain numero libre)

| Compteur | Prochain |
|---|---|
| Lecon apprise | 290 (288 : claude/LECONS_APPRISES_FRONTEND.md, Project Frontend, demande par. 5 ; 289 : SUITE_15 et 287 : SUITE_14, Project Pilote ; 283, 284 et 286 : claude/LECONS_APPRISES_FRONTEND.md, Project Frontend ; 285 : SUITE_13, 281 et 282 : SUITE_12, 275 a 280 : SUITE_11, Project Pilote) |
| Dette technique | 52 (51 = cles de styles referencees mais inexistantes, 17 occurrences, Frontend ; 50 = bouton fermer de NotificationsPanel sans nom accessible, Frontend ; 49 = emojis hors navigation, Frontend, avec les etapes 2 a 4 des patrons ; 47 a moitie soldee par 3a1b0dfa, etendue le 15/10 aux fichiers morts de la racine et de rh-api ; 48 = secrets de developpement en dur, etendue le 15/10 au depot de pilotage, Plateforme) |
| Erreur frequente | 153 |
| Ordre de travail | OT-011 |

## 3. Projects

| Project | Etat | Prochaine etape | Fenetres ouvertes | Derniere conversation |
|---|---|---|---|---|
| Pilote (actuel DigiERP, non renomme) | decoupage termine (D4.1, D4.2, D4.3, E1) ; ne synchronise que README.md du code + le depot de pilotage ; jauge 640 619 (32 %) ; patrons repris par OT (OT-004 a OT-010 ACCEPTE) ; REGLES_COMMUNES rev. 3 (mode d'execution, M1) | preparer OT-011 (code mort : theme.js, forms.styles.js, App.css si sans usage ; build identique ; dette 9 ; Frontend) ; correctif de la dette 51 a planifier ; D5 en temps masque (renommage, instructions des 4 Projects : un fichier synchronise se lit par project_search, REGLES_COMMUNES rev. 4, PROMPT_REPRISE_PILOTE) | - | 16/10/2026 |
| Frontend | prouve (OT-001) ; etape 1.7 terminee (1.7a OT-004, 1.7b OT-005 2a30d7c7, 1.7c OT-006 33cf81dd) ACCEPTE ; inventaire 1.3 (OT-007) et DC1 (OT-008 db314b41) ACCEPTE ; 1.3a (OT-009 5e6c682d : jetons de couleur en variables CSS branchees dans theme.extend, polices IBM Plex Sans/Mono latin+latin-ext, index.css sur IBM Plex Sans ; tests 92/92, ancien lint 1604/55 ; palette.test.ts) ACCEPTE, non deployee (DR1) ; 1.3b (OT-010 116a4964 : 65 substitutions de la table W1 dans les 4 *.styles.js, rendu identique prouve (0 conflit d'ordre CSS), cliquet du reliquat 22/38/15/29 dans palette.test.ts ; tests 97/97, ancien lint 1604/55) ACCEPTE, non deployee (DR1, DR3) ; prompt rev. 9 ; jauge 625 157 (31 %, mesure OT-001) | OT-011 (code mort) ; inscrire la lecon 288 (demande par. 5) | - | 16/10/2026 (OT-010) |
| Backend RH | prouve (OT-002 ACCEPTE : controle 26 OK, prompt rev. 2 relu identique) ; jauge 876 438 (44 %) | sur OT du Pilote | - | 15/10/2026 (OT-002) |
| Plateforme | prouve (OT-003 ACCEPTE : controle 25 OK, prompt rev. 1 relu identique, aucun acces serveur dans le CR) ; jauge 101 254 (5 %) | sur OT du Pilote ; dettes 42 (avant le deploiement des patrons, DR1), 47 (reste), 48 | - | 15/10/2026 (OT-003) |

## 4. Ordres de travail

| OT | Project | Objet | Statut | Commit(s) | Recette |
|---|---|---|---|---|---|
| OT-001 | Frontend | preuve du Project (lecture seule) | ACCEPTE | aucun | recette_OT-001.log : ok=6 echecs=0 |
| OT-002 | Backend RH | preuve du Project (lecture seule) | ACCEPTE | aucun | recette_OT-002.log : ok=6 echecs=0 |
| OT-003 | Plateforme | preuve du Project (lecture seule) | ACCEPTE | aucun | recette_OT-003.log : ok=6 echecs=0 |
| OT-004 | Frontend | etape 1.7a des patrons : inventaire (lecture seule) | ACCEPTE | aucun | recette_OT-004.log : ok=7 echecs=0 |
| OT-005 | Frontend | etape 1.7b des patrons : navigation sur le lexique d'icones | ACCEPTE | 2a30d7c7 | recette_OT-005.log : ok=8 echecs=0 |
| OT-006 | Frontend | etape 1.7c des patrons : NotificationsPanel sur le lexique, mecanisme d'exception retire | ACCEPTE | 33cf81dd | recette_OT-006.log : ok=10 echecs=0 |
| OT-007 | Frontend | etape 1.3 des patrons : inventaire (lecture seule) | ACCEPTE | aucun | recette_OT-007.log : ok=4 echecs=0 |
| OT-008 | Frontend | DC1 : cible de build et browserslist = socle (J6) | ACCEPTE | db314b41 | recette_OT-008.log : ok=9 echecs=0 |
| OT-009 | Frontend | etape 1.3a des patrons : jetons de couleur (variables CSS en canaux RGB, theme.extend) et polices IBM Plex | ACCEPTE | 5e6c682d | recette_OT-009.log : ok=12 echecs=0 |
| OT-010 | Frontend | etape 1.3b des patrons : 4 *.styles.js sur les jetons (table W1, 65 substitutions, rendu identique) et cliquet du reliquat de palette | ACCEPTE | 116a4964 | recette_OT-010.log : ok=12 echecs=0 |

Statuts : EMIS, LIVRE, ACCEPTE, REFUSE, BLOQUE. Un OT n'est clos qu'ACCEPTE, apres
BILAN_RECETTE|OT-NNN|...|echecs=0.

## 5. Demandes entre Projects

| Date | De | A | Objet | Statut |
|---|---|---|---|---|
| 16/10/2026 | Pilote | Frontend | inscrire la lecon 288 dans claude/LECONS_APPRISES_FRONTEND.md (constat du CR-010) : une contre-epreuve par injection vise une ligne de CODE et non un commentaire quand le test retire les commentaires avant de compter, sinon elle echoue a rougir sans rien prouver | ouverte |

## 6. Decisions transverses recentes (les 5 dernieres ; historique dans Git)

| Date | Decision |
|---|---|
| 16/10/2026 | W1-W6 (OT-010) : W1 en 1.3b, une classe de palette d'un *.styles.js n'est remplacee que par un jeton de MEME VALEUR et de MEME ROLE, aucun jeton nouveau (65 sur 188 ; le reliquat part avec les composants des etapes 2 a 4) ; W2 rendu identique prouve par l'arbre syntaxique (docs/digierp/tests/analyse_ordre_css.mjs : ordre reel du CSS Tailwind, toutes les branches ?:, ??, tables et fonctions) ; W3 cles inexistantes hors OT (dette 51) ; W4 sans objet (0 conflit) ; W5 une analyse de combinaisons de classes se fait sur l'arbre syntaxique avec temoins, jamais sur le texte (lecon 289) ; W6 cliquet du reliquat dans palette.test.ts (plafonds par fichier, qui ne se relevent jamais) |
| 16/10/2026 | DR3 (precise DR1) : la fin des patrons qui libere le deploiement en recette = etapes 1 a 4 et 6 ; l'etape 5 (patrons suivants au premier besoin reel, sans fin definie) se fait apres, au fil des besoins ; exception de DR1 (correctif impose) et DR2 (demonstration du pilote Employes avant l'etape 3) inchangees |
| 16/10/2026 | M1 (blocage de l'OT-009) : mode d'execution des OT - l'assistant d'un Project ne lance aucune commande depuis son propre espace ; il donne chaque commande, l'utilisateur la lance dans WSL2 et colle la sortie ; tout OT porte la ligne MODE D'EXECUTION (REGLES_COMMUNES rev. 3, par. 2.1, 2.3, 2.4) ; piste Claude Code ecartee (outil non utilise) |
| 15/10/2026 | K1 (CR-008) : KaiOS hors socle DC1 (KaiOS 2.5, moteur Gecko 48, ne chargeait deja pas l'application : modules ES natifs exiges par la cible de Vite ; ergonomie clavier incompatible avec un ERP) ; KaiOS 3 a mesurer avec la preuve au plancher du socle (dette 39) |
| 15/10/2026 | J1-J7 (OT-007) : J1 jetons en un niveau semantique, variables CSS en canaux RGB dans src/styles/jetons.css (V1) ; J2 branchement theme.extend, palette Tailwind conservee, classes de palette interdites dans le nouveau code .ts/.tsx (B1) ; J3 neutre unique slate ; J4 primaire blue-600 ; J5 polices IBM Plex Sans 400-700 et Mono 400, latin + latin-ext (P-b) ; J6 socle DC1 releve (R1) a Chrome 88, Edge 88, Firefox 78, Safari 14.1 / iOS 14.5 (exige par Tailwind 3.4 : :where du preflight, gap en flex) ; J7 ordre : OT-008 DC1 + browserslist, OT-009 1.3a, OT-010 1.3b, OT-011 code mort |

## 7. Regles du fil

1. Chaque Project ne modifie QUE sa ligne (section 3) et les compteurs qu'il consomme ; le Pilote
   tient l'etat commun, le registre des OT et les decisions.
2. Toute modification = script a garde-fous (empreinte de la revision precedente, revision + 1,
   controle), commit dedie "fil: rev. <n>" dans le depot de pilotage, push origin (GitHub)
   SEULEMENT, puis "Sync" dans les Projects concernes.
3. Le fil enregistre le HEAD du depot de CODE ; il vit dans un autre depot, donc le commiter ne
   change pas ce HEAD. Le controle de reprise le compare a git rev-parse HEAD du depot de code (R2).
4. Au debut de chaque conversation : la revision lue dans le Project (synchronise) doit egaler
   celle du depot (controle R0) ; sinon "Sync" avant toute chose.
5. Deux Projects ne travaillent pas en meme temps sur le PC : la ligne "Qui tient le depot" dit
   qui l'utilise ; un increment non commite bloque les autres.
6. Le depot de pilotage n'a JAMAIS de remote biapay ; ni documentation ni pilotage n'y sont
   pousses (controle R16 : remote origin seul, URL ecrite et effective = digierp-pilotage).
