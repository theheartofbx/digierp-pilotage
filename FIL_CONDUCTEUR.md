# FIL CONDUCTEUR DigiERP - revision 7 du 15/10/2026 (par Project Pilote)
# Lu au debut de chaque conversation, dans chaque Project. Modifie par script uniquement
# (revision + 1 a chaque modification). Regles : section 7. Format : LISEZMOI.md.
# Vit dans le depot de PILOTAGE (digierp-pilotage, origin GitHub seul), distinct du depot de code.
# Les libelles de la colonne "Element" de la section 1 sont lus par
# commun/controle_reprise.sh : ne jamais les renommer.

## 1. Etat commun

| Element | Valeur |
|---|---|
| Dernier commit du depot de code | 2a30d7c7709e1d27c5228bdb79a004fe738e34f5 |
| Branche | DigiErp-Spring-React (origin GitHub + biapay GitLab) |
| Depot de pilotage | digierp-pilotage, branche main (origin GitHub SEUL ; jamais de remote biapay : R16) |
| Tag de reference de la garde des migrations | recette-20261011 (-> 7e861563) |
| Recette deployee sur | 5cd225ca (fondations 1.1, 1.2, 1.4 et etape 1.7b non deployees : partent a la fin des patrons, etapes 1 a 6, decision DR1) |
| Migrations dev / recette | 45 / 39 ; derniere 20261011.3 |
| Tables sous RLS (dev) | 16 |
| Non-regression de reference | 18 controles (verte le 12/10 : echecs=0, ok=18) |
| Qui tient le depot (arbre de travail du PC) | Pilote - consignation apres OT-004 et OT-005 (etapes 1.7a et 1.7b des patrons ACCEPTE) ; prochaine etape OT-006 (etape 1.7c, NotificationsPanel, Project Frontend) ; aucun travail non commite |

## 2. Compteurs partages (prochain numero libre)

| Compteur | Prochain |
|---|---|
| Lecon apprise | 283 (281 et 282 : LECONS_APPRISES_SUITE_12, Project Pilote ; 275 a 280 : LECONS_APPRISES_SUITE_11) |
| Dette technique | 50 (49 = emojis hors navigation, Frontend, avec les etapes 2 a 4 des patrons ; 47 a moitie soldee par 3a1b0dfa, etendue le 15/10 aux fichiers morts de la racine et de rh-api ; 48 = secrets de developpement en dur, etendue le 15/10 au depot de pilotage, Plateforme) |
| Erreur frequente | 153 |
| Ordre de travail | OT-006 |

## 3. Projects

| Project | Etat | Prochaine etape | Fenetres ouvertes | Derniere conversation |
|---|---|---|---|---|
| Pilote (actuel DigiERP, non renomme) | decoupage termine (D4.1, D4.2, D4.3, E1) ; ne synchronise que README.md du code + le depot de pilotage ; jauge 640 619 (32 %) ; patrons repris par OT (OT-004, OT-005 ACCEPTE) | emettre OT-006 (etape 1.7c des patrons, Frontend) ; D5 en temps masque (renommage, instructions des 4 Projects : un fichier synchronise se lit par project_search, REGLES_COMMUNES rev. 3, PROMPT_REPRISE_PILOTE) | - | 15/10/2026 |
| Frontend | prouve (OT-001) ; etapes 1.7a (OT-004, inventaire) et 1.7b (OT-005, commit 2a30d7c7 : navigation sur le lexique, 96 cles, tests 73/73) ACCEPTE, 1.7b non deployee (DR1) ; prompt rev. 2 (rev. 3 a livrer) ; jauge 625 157 (31 %, mesure OT-001) | OT-006 : etape 1.7c (NotificationsPanel sur le lexique, retrait de son exception du test d'architecture) | - | 15/10/2026 (OT-005) |
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

Statuts : EMIS, LIVRE, ACCEPTE, REFUSE, BLOQUE. Un OT n'est clos qu'ACCEPTE, apres
BILAN_RECETTE|OT-NNN|...|echecs=0.

## 5. Demandes entre Projects

| Date | De | A | Objet | Statut |
|---|---|---|---|---|
| (aucune) | | | | |

## 6. Decisions transverses recentes (les 5 dernieres ; historique dans Git)

| Date | Decision |
|---|---|
| 15/10/2026 | DR1 : aucun deploiement en recette avant la fin des patrons (etapes 1 a 6) ; l'etape 1.9 ne deploie plus ; exception : correctif impose, deploye depuis un commit de fin d'etape (OT ACCEPTE, non-regression verte). DR2 : demonstration du pilote Employes (etape 2) au responsable sur le PC avant d'emettre l'etape 3 |
| 15/10/2026 | P1-P5 (OT-004) : nouvelle cle groupeRecrutement ; nav:workflow -> workflow ; pas de chunk separe du lexique (reexamen en 1.9) ; emojis hors navigation (43 tables) hors 1.7 -> dette 49 ; 1.7b = navigation.js + AppLayout.jsx, 1.7c = NotificationsPanel |
| 15/10/2026 | D4.3 : les 3 sous-projets sont prouves par OT (controle de reprise vert, prompt relu a l'identique, jauge <= 70 %) ; un fichier SYNCHRONISE ne se lit pas par project_read, seulement par project_search |
| 15/10/2026 | E1 : le Pilote ne synchronise plus le code (README.md seul) mais le depot de pilotage entier ; ses instructions sont a reecrire en D5 (elles citent encore la lecture du code) |
| 15/10/2026 | F1 : le filtre du Project Plateforme recoit l'outillage de build (.gitignore, .gitlab-ci.yml, mvnw, .mvn, fichiers de rh-api) ; les fichiers morts ne sont dans aucun filtre (dette 47) |

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
