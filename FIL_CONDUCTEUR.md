# FIL CONDUCTEUR DigiERP - revision 5 du 15/10/2026 (par Project Pilote)
# Lu au debut de chaque conversation, dans chaque Project. Modifie par script uniquement
# (revision + 1 a chaque modification). Regles : section 7. Format : LISEZMOI.md.
# Vit dans le depot de PILOTAGE (digierp-pilotage, origin GitHub seul), distinct du depot de code.
# Les libelles de la colonne "Element" de la section 1 sont lus par
# commun/controle_reprise.sh : ne jamais les renommer.

## 1. Etat commun

| Element | Valeur |
|---|---|
| Dernier commit du depot de code | 3a1b0dfa717f0e6a2f88004a204476fe0770ea14 |
| Branche | DigiErp-Spring-React (origin GitHub + biapay GitLab) |
| Depot de pilotage | digierp-pilotage, branche main (origin GitHub SEUL ; jamais de remote biapay : R16) |
| Tag de reference de la garde des migrations | recette-20261011 (-> 7e861563) |
| Recette deployee sur | 5cd225ca (fondations 1.1, 1.2, 1.4 non deployees : partent a l'etape 1.9) |
| Migrations dev / recette | 45 / 39 ; derniere 20261011.3 |
| Tables sous RLS (dev) | 16 |
| Non-regression de reference | 18 controles (verte le 12/10 : echecs=0, ok=18) |
| Qui tient le depot (arbre de travail du PC) | Pilote - decoupage ; D4.1, D4.2 et E1 faits le 15/10, prochaine etape D4.3 (OT-001 a OT-003) ; aucun travail non commite |

## 2. Compteurs partages (prochain numero libre)

| Compteur | Prochain |
|---|---|
| Lecon apprise | 281 (275 a 280 : LECONS_APPRISES_SUITE_11, Project Pilote) |
| Dette technique | 49 (47 a moitie soldee par 3a1b0dfa, etendue le 15/10 aux fichiers morts de la racine et de rh-api ; 48 = secrets de developpement en dur, Plateforme) |
| Erreur frequente | 153 |
| Ordre de travail | OT-001 |

## 3. Projects

| Project | Etat | Prochaine etape | Fenetres ouvertes | Derniere conversation |
|---|---|---|---|---|
| Pilote (actuel DigiERP, non renomme) | decoupage : D4.1 (3 Projects crees, filtres et jauges releves) et D4.2 (3 prompts de reprise livres et prouves) faits ; E1 : ne synchronise plus que README.md du code + le depot de pilotage (31 %) | D4.3 : emettre OT-001 a OT-003 avec leurs tests de recette ; puis D5 (renommage, instructions, PROMPT_REPRISE_PILOTE) | - | 15/10/2026 |
| Frontend | cree le 15/10 ; prompt PROMPT_REPRISE_FRONTEND rev. 2 ; jauge 31 % | OT-001 (preuve du Project), puis reprise de l'etape 1.7 des patrons | - | - |
| Backend RH | cree le 15/10 ; prompt PROMPT_REPRISE_BACKEND rev. 2 ; jauge 43 % | OT-002 (preuve du Project) | - | - |
| Plateforme | cree le 15/10 (filtre par. 3.4 + outillage de build, F1) ; prompt PROMPT_REPRISE_PLATEFORME rev. 1 (acces serveur : ce Project seulement) ; jauge 5 % | OT-003 (preuve du Project) ; dettes 42 (avant 1.9), 47 (reste), 48 | - | - |

## 4. Ordres de travail

| OT | Project | Objet | Statut | Commit(s) | Recette |
|---|---|---|---|---|---|
| (aucun emis) | | | | | |

Statuts : EMIS, LIVRE, ACCEPTE, REFUSE, BLOQUE. Un OT n'est clos qu'ACCEPTE, apres
BILAN_RECETTE|OT-NNN|...|echecs=0.

## 5. Demandes entre Projects

| Date | De | A | Objet | Statut |
|---|---|---|---|---|
| (aucune) | | | | |

## 6. Decisions transverses recentes (les 5 dernieres ; historique dans Git)

| Date | Decision |
|---|---|
| 15/10/2026 | E1 : le Pilote ne synchronise plus le code (README.md seul) mais le depot de pilotage entier ; ses instructions sont a reecrire en D5 (elles citent encore la lecture du code) |
| 15/10/2026 | F1 : le filtre du Project Plateforme recoit l'outillage de build (.gitignore, .gitlab-ci.yml, mvnw, .mvn, fichiers de rh-api) ; les fichiers morts ne sont dans aucun filtre (dette 47) |
| 15/10/2026 | Mesure D4 : un Project claude.ai accepte deux sources GitHub de depots prives differents ; chaque sous-projet synchronise le code filtre ET le depot de pilotage filtre |
| 14/10/2026 | Option B : pilotage dans un depot separe (GitHub theheartofbx/digierp-pilotage, origin seul) ; ni documentation ni pilotage sur biapay (regle de l'utilisateur), verifie par R16 |
| 14/10/2026 | Documentation retiree du depot de code (3a1b0dfa) ; README.md conserve ; historique non reecrit |

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
