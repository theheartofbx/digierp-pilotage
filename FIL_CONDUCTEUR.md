# FIL CONDUCTEUR DigiERP - revision 14 du 16/10/2026 (par Project Pilote)
# Lu au debut de chaque conversation, dans chaque Project. Modifie par script uniquement
# (revision + 1 a chaque modification). Regles : section 7. Format : LISEZMOI.md.
# Vit dans le depot de PILOTAGE (digierp-pilotage, origin GitHub seul), distinct du depot de code.
# Les libelles de la colonne "Element" de la section 1 sont lus par
# commun/controle_reprise.sh : ne jamais les renommer.

## 1. Etat commun

| Element | Valeur |
|---|---|
| Dernier commit du depot de code | 5e6c682dc81e5cc7f617831de8860479a2a7016f |
| Branche | DigiErp-Spring-React (origin GitHub + biapay GitLab) |
| Depot de pilotage | digierp-pilotage, branche main (origin GitHub SEUL ; jamais de remote biapay : R16) |
| Tag de reference de la garde des migrations | recette-20261011 (-> 7e861563) |
| Recette deployee sur | 5cd225ca (fondations 1.1, 1.2, 1.4, etape 1.7 (1.7b, 1.7c), DC1 (db314b41) et 1.3a (5e6c682d) non deployees : partent a la fin des patrons, etapes 1 a 4 et 6 (etape 5 apres), decisions DR1 et DR3) |
| Migrations dev / recette | 45 / 39 ; derniere 20261011.3 |
| Tables sous RLS (dev) | 16 |
| Non-regression de reference | 18 controles (verte le 12/10 : echecs=0, ok=18) |
| Qui tient le depot (arbre de travail du PC) | Pilote - consignation apres OT-009 (1.3a ACCEPTE), decisions M1 (REGLES_COMMUNES rev. 3) et DR3 ; prochaine etape OT-010 (etape 1.3b : *.styles.js sur les jetons, Project Frontend) ; aucun travail non commite |

## 2. Compteurs partages (prochain numero libre)

| Compteur | Prochain |
|---|---|
| Lecon apprise | 288 (287 : SUITE_14, Project Pilote ; 283, 284 et 286 : claude/LECONS_APPRISES_FRONTEND.md, Project Frontend ; 285 : SUITE_13, 281 et 282 : SUITE_12, 275 a 280 : SUITE_11, Project Pilote) |
| Dette technique | 51 (50 = bouton fermer de NotificationsPanel sans nom accessible, Frontend ; 49 = emojis hors navigation, Frontend, avec les etapes 2 a 4 des patrons ; 47 a moitie soldee par 3a1b0dfa, etendue le 15/10 aux fichiers morts de la racine et de rh-api ; 48 = secrets de developpement en dur, etendue le 15/10 au depot de pilotage, Plateforme) |
| Erreur frequente | 153 |
| Ordre de travail | OT-010 |

## 3. Projects

| Project | Etat | Prochaine etape | Fenetres ouvertes | Derniere conversation |
|---|---|---|---|---|
| Pilote (actuel DigiERP, non renomme) | decoupage termine (D4.1, D4.2, D4.3, E1) ; ne synchronise que README.md du code + le depot de pilotage ; jauge 640 619 (32 %) ; patrons repris par OT (OT-004 a OT-009 ACCEPTE) ; REGLES_COMMUNES rev. 3 (mode d'execution, M1) | emettre OT-010 (etape 1.3b : *.styles.js sur les jetons, Frontend ; precondition : mode de lancement des 3 controles d'enums i18n mesure) ; D5 en temps masque (renommage, instructions des 4 Projects : un fichier synchronise se lit par project_search, REGLES_COMMUNES rev. 4, PROMPT_REPRISE_PILOTE) | - | 16/10/2026 |
| Frontend | prouve (OT-001) ; etape 1.7 terminee (1.7a OT-004, 1.7b OT-005 2a30d7c7, 1.7c OT-006 33cf81dd) ACCEPTE ; inventaire 1.3 (OT-007) et DC1 (OT-008 db314b41) ACCEPTE ; 1.3a (OT-009 5e6c682d : jetons de couleur en variables CSS branchees dans theme.extend, polices IBM Plex Sans/Mono latin+latin-ext, index.css sur IBM Plex Sans ; tests 92/92, ancien lint 1604/55 ; palette.test.ts) ACCEPTE, non deployee (DR1) ; prompt rev. 8 ; jauge 625 157 (31 %, mesure OT-001) | OT-010 : 1.3b (*.styles.js sur les jetons, rendu identique) ; puis OT-011 (code mort) | - | 16/10/2026 (OT-009) |
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

Statuts : EMIS, LIVRE, ACCEPTE, REFUSE, BLOQUE. Un OT n'est clos qu'ACCEPTE, apres
BILAN_RECETTE|OT-NNN|...|echecs=0.

## 5. Demandes entre Projects

| Date | De | A | Objet | Statut |
|---|---|---|---|---|
| (aucune) | | | | |

## 6. Decisions transverses recentes (les 5 dernieres ; historique dans Git)

| Date | Decision |
|---|---|
| 16/10/2026 | DR3 (precise DR1) : la fin des patrons qui libere le deploiement en recette = etapes 1 a 4 et 6 ; l'etape 5 (patrons suivants au premier besoin reel, sans fin definie) se fait apres, au fil des besoins ; exception de DR1 (correctif impose) et DR2 (demonstration du pilote Employes avant l'etape 3) inchangees |
| 16/10/2026 | M1 (blocage de l'OT-009) : mode d'execution des OT - l'assistant d'un Project ne lance aucune commande depuis son propre espace ; il donne chaque commande, l'utilisateur la lance dans WSL2 et colle la sortie ; tout OT porte la ligne MODE D'EXECUTION (REGLES_COMMUNES rev. 3, par. 2.1, 2.3, 2.4) ; piste Claude Code ecartee (outil non utilise) |
| 15/10/2026 | K1 (CR-008) : KaiOS hors socle DC1 (KaiOS 2.5, moteur Gecko 48, ne chargeait deja pas l'application : modules ES natifs exiges par la cible de Vite ; ergonomie clavier incompatible avec un ERP) ; KaiOS 3 a mesurer avec la preuve au plancher du socle (dette 39) |
| 15/10/2026 | J1-J7 (OT-007) : J1 jetons en un niveau semantique, variables CSS en canaux RGB dans src/styles/jetons.css (V1) ; J2 branchement theme.extend, palette Tailwind conservee, classes de palette interdites dans le nouveau code .ts/.tsx (B1) ; J3 neutre unique slate ; J4 primaire blue-600 ; J5 polices IBM Plex Sans 400-700 et Mono 400, latin + latin-ext (P-b) ; J6 socle DC1 releve (R1) a Chrome 88, Edge 88, Firefox 78, Safari 14.1 / iOS 14.5 (exige par Tailwind 3.4 : :where du preflight, gap en flex) ; J7 ordre : OT-008 DC1 + browserslist, OT-009 1.3a, OT-010 1.3b, OT-011 code mort |
| 15/10/2026 | T2 : Tailwind 3 conserve (deploiement prevu dans plusieurs structures d'Afrique centrale ; Tailwind 4 exige Chrome 111, Safari 16.4, Firefox 128) ; S3 abandonnee ; jetons de 1.3 en variables CSS branchees dans tailwind.config.js. DC1 : socle de compatibilite navigateur = cible actuelle de Vite 6 (es2020, Chrome 87, Edge 88, Firefox 78, Safari 14), ecrite explicitement dans vite.config.js (build.target, build.cssTarget) ; toute dependance ou montee de version prouve qu'elle le respecte |

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
