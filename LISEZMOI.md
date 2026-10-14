# digierp-pilotage - depot de pilotage de DigiERP
# Cree le 12/10/2026 ; revision 3 du 15/10/2026 (option B : depot separe du depot de code, remote
# origin GitHub seul, jamais biapay). Revision 2 du 14/10 : methode T-A, ecart declare des
# standards de base, controle de reprise unique. Statut : EN CONSTRUCTION jusqu'a l'etape D5 du
# decoupage. Conception : claude/DECOUPAGE_PROJECTS_20261012.md ; option B :
# claude/PROMPT_REPRISE_DECOUPAGE_20261014.md (Project Pilote).
# Texte en ASCII (sans accents) par choix, comme tout ce depot.

## A quoi sert ce depot

Le developpement est suivi dans plusieurs Projects claude.ai : le **Pilote** (le Project
principal), **Frontend**, **Backend RH** et **Plateforme** (et, plus tard, un Project par module
long : Stock, Achats, Budget...). Chaque Project ne voit QUE les fichiers qu'il synchronise depuis
GitHub. Ce depot contient ce que tous doivent partager, en UN seul exemplaire versionne : le
fil conducteur, les regles communes, l'index des dettes, le controle de reprise et les standards.

Deux depots depuis le 14/10/2026 (option B) :
- depot de CODE : theheartofbx/digierp-spring-react, branche DigiErp-Spring-React, remotes origin
  (GitHub) et biapay (GitLab) ; il ne contient plus aucun document (README.md seul, commit 3a1b0dfa) ;
- depot de PILOTAGE (celui-ci) : theheartofbx/digierp-pilotage, branche main, remote origin
  (GitHub) SEUL. Ni documentation ni pilotage ne sont jamais pousses sur biapay (regle de
  l'utilisateur du 14/10/2026), ce que verifie le controle R16.

Le Pilote tient le plan, emet les ordres de travail (OT) avec leur test de recette ecrit AVANT
l'execution, et rend le verdict ; les sous-projets executent et rendent un compte rendu (CR).

## Cycle d'un ordre de travail

```
1. Pilote      : emet OT-NNN (texte autoporteur) + test de recette, ecrit AVANT l'execution
2. Sous-projet : execute, commite, pousse ; rend CR-NNN (format impose)
3. Pilote      : fait lancer le test de recette (lecture seule) -> BILAN_RECETTE
4. Pilote      : ACCEPTE (fil a jour, OT clos) ou REFUSE (OT correctif) ;
                 aucune tache suivante avant ACCEPTE
```
Formats de l'OT, du CR et du test : commun/REGLES_COMMUNES.md (section 2).

## Structure

```
digierp-pilotage/            racine du depot
+-- LISEZMOI.md              ce fichier
+-- FIL_CONDUCTEUR.md        etat commun, registre des OT, une ligne par Project, compteurs
+-- commun/
|   +-- REGLES_COMMUNES.md   profil, environnement, regles de travail, formats OT / CR / recette
|   +-- INDEX_DETTES.md      dettes techniques, avec le Project qui en a la charge
|   +-- controle_reprise.sh  controle de reprise unique (lance avec le nom du Project)
+-- standards/
    +-- projet/              STANDARDS_PROJET
    +-- backend/             STANDARDS_BACKEND et ses complements
    +-- frontend/            STANDARDS_FRONTEND, ses complements, patrons de vues
```

## Ou vit chaque document

| Document | Ou | Synchronise dans | Modifie par |
|---|---|---|---|
| Fil conducteur et registre des OT | FIL_CONDUCTEUR.md | tous les Projects | Pilote (verdicts, etat commun) ; chaque sous-projet sa ligne |
| Regles communes | commun/REGLES_COMMUNES.md | tous | Pilote seulement |
| Index des dettes | commun/INDEX_DETTES.md | tous | Pilote, sur proposition des CR |
| Controle de reprise | commun/controle_reprise.sh | tous | Pilote seulement |
| Standards | standards/<couche>/ | Project de la couche + Pilote | Pilote, par NOUVEAUX fichiers de complements |
| Ordres de travail, tests de recette, verdicts | conversation du Pilote ; resume dans le fil | - | Pilote |
| Prompt de reprise d'un Project | documents du Project claude.ai | ce Project | ce Project |
| Lecons apprises | documents du Project qui les vit (numero attribue par le fil) | - | ce Project |
| Acces au serveur de recette | documents du Project Plateforme UNIQUEMENT | - | Plateforme ; jamais dans ce depot |
| Preuves, journaux, recettes | PC : docs/digierp/tests/ (hors depot) | - | - |

## Synchronisation dans les Projects (a mesurer en D4)

Chaque Project doit lire DEUX sources GitHub : le depot de code (filtre de sa couche) et ce
depot (filtre du pilotage). Qu'un Project claude.ai accepte deux sources n'est PAS encore
mesure : relevage en D4 (project_info de chaque Project). Si ce n'est pas possible, les options
seront presentees a ce moment ; rien ne sera suppose d'ici la.

## Transfert d'un document du Project vers ce depot

Constat du 14/10/2026 : la seule voie de sortie d'un document de claude.ai vers le PC est la
COPIE, et elle regenere le Markdown (lignes vides changees en lignes d'une espace ou supprimees,
retour final perdu). Les lignes non vides restent intactes. Des reperes (titres, phrases) ne
voient pas cette alteration : seule l'identite SHA-256 prouve une copie.

1. **Methode T-A (en vigueur)** pour tout document ECRIT par l'assistant : publie dans le Project
   avec ses octets exacts, puis livre au PC par un script qui embarque le contenu (compresse,
   base64) et deux empreintes SHA-256 (texte colle, contenu). Le script refuse d'ecrire si l'une
   differe et affiche IDENTITE|OK. Aucune copie depuis claude.ai.
2. **Standards de base (10 fichiers transferes le 14/10, option A)** : aucun original fidele
   n'existait. Copies claude.ai normalisees : lignes d'espaces redevenues vides ; ligne vide
   retablie avant les 18 separateurs "---" qui suivaient un texte. **Ecart declare** : le TEXTE est
   conforme au Project, la position de certaines lignes vides ne l'est pas forcement (sans effet
   sur la lecture du texte brut). Ces fichiers ne sont jamais reecrits en place.
3. **Evolution d'un standard** : nouveau fichier de complements (tableau "regles devenues
   fausses"), ecrit par l'assistant et livre par T-A.

## Regles

1. Un sous-projet n'execute que l'OT recu, dans son perimetre, et ne passe pas a une autre
   tache de lui-meme.
2. Le verdict vient du test de recette du Pilote, jamais du compte rendu.
3. Un standard n'est jamais reecrit en place : toute evolution = un nouveau fichier de
   complements, avec un tableau des regles devenues fausses.
4. Aucun acces au serveur ni secret dans ce depot (adresse publique, port, rebond,
   utilisateurs, cles, mots de passe) : controle R9 de controle_reprise.sh, avant chaque commit.
5. Toute modification de ce depot = commit dedie, push origin (GitHub) SEULEMENT, puis "Sync"
   dans les Projects concernes.
6. Tout nombre ecrit dans ces documents est calcule par un script ou lu dans la source, jamais
   ecrit de tete.
7. Au debut de chaque conversation :
   bash /mnt/c/Users/lecoe/git/digierp-pilotage/commun/controle_reprise.sh <Project> ; la
   revision du fil affichee (R0) doit egaler celle du fil synchronise dans le Project.
8. Ce depot n'a JAMAIS de remote biapay, et aucun document n'est remis dans le depot de code :
   controle R16 (remote origin seul ; URL ecrite, effective et de push = digierp-pilotage).
