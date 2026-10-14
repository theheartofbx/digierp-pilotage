# FIL CONDUCTEUR DigiERP - revision 4 du 15/10/2026 (par Project Pilote)
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
| Qui tient le depot (arbre de travail du PC) | Pilote - decoupage ; B1 a B4 faits, prochaine etape D4 ; aucun travail non commite |

## 2. Compteurs partages (prochain numero libre)

| Compteur | Prochain |
|---|---|
| Lecon apprise | 275 (250 a 274 : LECONS_APPRISES_SUITE_10, Project Pilote) |
| Dette technique | 49 (47 a moitie soldee par 3a1b0dfa : reste migration_old ; 48 = secrets de developpement en dur, Plateforme) |
| Erreur frequente | 153 |
| Ordre de travail | OT-001 |

## 3. Projects

| Project | Etat | Prochaine etape | Fenetres ouvertes | Derniere conversation |
|---|---|---|---|---|
| Pilote (actuel DigiERP) | decoupage, option B : depot de pilotage cree, documents revises et pousses (B1 a B4, commit 16522869) | D4 : creation des Projects (mesurer d'abord : un Project claude.ai accepte-t-il deux sources GitHub ?) | - | 15/10/2026 |
| Frontend | a creer (D4) | OT-001 (preuve du Project), puis reprise de l'etape 1.7 des patrons | - | - |
| Backend RH | a creer (D4) | OT-002 (preuve du Project) | - | - |
| Plateforme | a creer (D4) | OT-003 (preuve du Project) ; dettes 47 (reste), 48 | - | - |

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
| 14/10/2026 | Option B : pilotage dans un depot separe (GitHub theheartofbx/digierp-pilotage, origin seul) ; ni documentation ni pilotage sur biapay (regle de l'utilisateur), verifie par R16 |
| 14/10/2026 | Documentation retiree du depot de code (3a1b0dfa) ; README.md conserve ; historique non reecrit |
| 14/10/2026 | T-A : tout document ecrit par l'assistant est livre au PC avec ses octets exacts (contenu embarque + empreintes SHA-256) ; la copie depuis claude.ai regenere le Markdown et n'est plus utilisee |
| 14/10/2026 | Option A : les 10 standards de base sont des copies claude.ai normalisees ; texte conforme, position de certaines lignes vides non garantie (ecart declare dans LISEZMOI) |
| 14/10/2026 | Le Project principal devient le PILOTE : ordres de travail + tests de recette ecrits avant l'execution, verdict avant toute tache suivante |

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
