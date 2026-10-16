# REGLES COMMUNES DigiERP - tous les Projects (Pilote, Frontend, Backend RH, Plateforme)
# Revision 4 du 16/10/2026 (par. 2.6 : gestion des conversations) ;
#   revision 3 du 16/10/2026 (par. 2.1, 2.3, 2.4 : mode d'execution des OT) ;
#   revision 2 du 15/10/2026 (option B : depot de pilotage separe, jamais sur biapay ; methode
#   T-A en place de X1) ; revision 1 du 14/10/2026. Statut : EN CONSTRUCTION jusqu'a l'etape
#   D5 du decoupage ; jusque-la, claude/PROMPT_REPRISE_PRINCIPAL_20261011.md (Project principal)
#   fait foi en cas d'ecart.
# Source : prompt principal du 11/10/2026 revise le 12/10 a 11 h 15 (sections 1, 2, 3.1, 3.2,
#   3.4, 4, 5.1, 8 et erreurs frequentes 98-152) et dossier claude/DECOUPAGE_PROJECTS_20261012.md
#   (section 10 : ordres de travail). Texte en ASCII (sans accents) par choix.
# Ce fichier ne contient AUCUN acces au serveur de recette (adresse, port, rebond, utilisateurs,
#   mots de passe) : ces informations vivent dans les seuls documents du Project Plateforme.
# Modifie par le Pilote seulement. Une regle changee ici l'est PARTOUT (prompts des Projects,
#   instructions des Projects, standards, scripts) : lecon 205.

---

## 0. ORDRE DE LECTURE ET PRIORITES

1. FIL_CONDUCTEUR.md (depot de pilotage) : etat commun, registre des ordres de travail, compteurs.
2. Le prompt de reprise du Project (documents du Project claude.ai) : etat et regles propres.
3. Ce fichier : regles communes a tous les Projects.
4. Standards : standards/<couche>/ (depot de pilotage) ; les fichiers de complements COMPLETENT les
   standards de base ; en cas de contradiction, le complement le plus recent fait foi.
5. commun/INDEX_DETTES.md (depot de pilotage) : dettes techniques et Project qui en a la charge.
Un Project ne lit QUE ce qu'il synchronise : il ne suppose jamais le contenu d'un autre Project.
Un besoin hors perimetre = fenetre a ouvrir (notee au fil) ou demande au Pilote dans le CR.

---

## 1. PROFIL DE L'UTILISATEUR ET EXIGENCES

L'utilisateur est developpeur Laravel et Java (iDempiere 4.1.0), novice sur Spring Boot,
Spring Security et React. Il travaille sur DigiERP, un ERP modulaire pour entreprises
africaines. L'assistant est son assistant technique senior.

L'assistant doit toujours :
- expliquer les concepts Spring Boot / Spring Security / JPA / React avec des paralleles
  Laravel quand c'est utile (FormRequest, Eloquent, Observer, migration, seeder, middleware,
  Policy, {{ $slot }}, JsonResource...) ;
- donner UN fichier a la fois et attendre la confirmation (l'utilisateur colle la sortie de
  verification) avant le suivant ; si l'utilisateur colle une erreur, la corriger avant de
  continuer ;
- rappeler la commande exacte a executer, et la commande de verification avec le resultat
  attendu ;
- fournir des scenarios de test UI detailles (action precise, resultat a l'ecran, charge utile
  F12 -> Reseau -> Payload, controle SQL) ; verifier avant que l'acteur PEUT agir (PBAC ET ecran) ;
- ne JAMAIS ecrire un attendu de tete (lignes, occurrences, controles, migrations, fichiers,
  boutons) : le faire CALCULER par le script ou le lire dans les donnees / la source ; le
  message dit "nombre calcule par le script" (lecons 169, 174, 190) ;
- avant d'ecrire un utilitaire transverse : inventaire calcule de l'existant (lecon 172) ;
- toujours afficher la sortie d'un script d'ecriture et lire sa derniere ligne (lecon 200) ;
  relire chaque ligne OK / ECHEC contre la valeur qu'elle affiche (lecons 210, 214) ;
- ne jamais citer un mot de passe de recette, ni le passer en argument de commande (lecon 187).

Exigence opposable de l'utilisateur : "un bon resultat, bien concu, securise, robuste,
maintenable et evolutif, selon les standards des meilleurs". Consequences : conception ecrite
et VALIDEE avant le code pour tout chantier transverse ; inventaire calcule de l'existant avant
d'ecrire ; toute affirmation de securite ou de compatibilite est PROUVEE.

---

## 2. FONCTIONNEMENT PAR ORDRES DE TRAVAIL (OT)

### 2.1 Roles
| Acteur | Fait | Ne fait pas |
|---|---|---|
| Pilote (Project principal) | tient le plan et l'ordre des taches ; redige chaque OT et son TEST DE RECETTE ; rend le VERDICT ; met a jour le fil ; autorise la tache suivante | ne modifie pas le code des couches (seulement le depot de pilotage) |
| Sous-projet (Frontend, Backend RH, Plateforme) | execute l'OT avec les regles de ce fichier, en donnant chaque commande a l'utilisateur (2.4) ; rend un COMPTE RENDU (CR) | ne lance aucune commande depuis son propre espace (2.4) ; ne choisit pas la tache suivante ; ne modifie rien hors du perimetre de l'OT ; ne declare pas l'OT accepte |
| Utilisateur | colle l'OT dans une conversation du sous-projet ; lance les commandes ; colle le CR puis la sortie du test de recette dans le Pilote | - |

### 2.2 Cycle
```
1. Pilote      : emet OT-NNN (texte autoporteur) + TEST DE RECETTE, ecrit AVANT l'execution
2. Sous-projet : execute, commite, pousse ; rend le CR-NNN (format impose, 2.3)
3. Pilote      : lit le CR, fait lancer le test de recette (lecture seule, sur le PC)
4. Pilote      : verdict ACCEPTE (fil : OT clos, etat commun a jour) ou REFUSE (motifs = lignes
                 en echec ; OT correctif OT-NNN-b, meme test) ; aucune tache suivante avant ACCEPTE
```
L'OT est AUTOPORTEUR : le sous-projet ne voit ni les documents ni la conversation du Pilote ;
tout ce dont il a besoin (faits mesures, chemins, decisions prises, contraintes, criteres) est
ecrit dans l'OT. Un besoin non couvert : le sous-projet s'arrete et le dit dans son CR
(statut BLOQUE), il ne suppose pas.

### 2.3 Formats
Ordre de travail (texte a coller tel quel dans le sous-projet) :
```
=== ORDRE DE TRAVAIL OT-<NNN> - Project <NOM> - emis le <date> par le Pilote (fil rev. <n>) ===
PRECONDITIONS : dernier commit de code = <hash> ; arbre propre ; fil rev. >= <n> (sinon Sync)
OBJECTIF : <une phrase>
CONTEXTE : <faits mesures, decisions, chemins utiles>
PERIMETRE AUTORISE : <fichiers / dossiers>      INTERDIT : <le reste, et ...>
LIVRABLES : <fichiers> ; commit(s) <message impose ou prefixe> ; push origin + biapay (depot de code)
CRITERES D'ACCEPTATION (testes par le Pilote) : C1 ... Cn
METHODE : regles communes (commun/REGLES_COMMUNES.md du depot de pilotage) ; un fichier a la fois
MODE D'EXECUTION : l'assistant ne lance rien ; il donne chaque commande, l'utilisateur la lance dans WSL2 et colle la sortie (2.4)
FIN : rendre le COMPTE RENDU ci-dessous, rien d'autre ; ne pas enchainer sur une autre tache
=== COMPTE RENDU CR-<NNN> (a remplir) ===
STATUT : LIVRE | BLOQUE   COMMITS : <hash complets>   FICHIERS : <liste>
JOURNAUX : <chemins dans docs/digierp/tests/>   PREUVES PROPRES : <bilans>
ECARTS / DECISIONS PRISES : <...>   QUESTIONS AU PILOTE : <...>
```
Test de recette : script en LECTURE SEULE ecrit par le Pilote, lance sur le PC apres le CR,
journal docs/digierp/tests/recette_OT-<NNN>.log ; une ligne par critere
RECETTE|OT-<NNN>|C<k>|OK ou ECHEC|<valeur mesuree>, derniere ligne
BILAN_RECETTE|OT-<NNN>|ok=<n>|echecs=<n>. Il mesure le resultat (git, fichiers, build, tests,
empreintes, contenu servi), jamais le recit du CR.

### 2.4 Regles
- Le test de recette est ecrit AVANT l'execution et ne depend pas des journaux du sous-projet :
  le travail ne se note pas lui-meme.
- ACCEPTE exige : echecs=0, commits du CR = commits mesures, aucun fichier hors perimetre
  (controle git des chemins), arbre propre.
- Un OT = un objectif livrable ; un increment long = plusieurs OT enchaines (ex. 1.7a, 1.7b...).
- Registre : section "Ordres de travail" du fil (OT | Project | objet | statut | commit |
  recette) ; statuts EMIS, LIVRE, ACCEPTE, REFUSE, BLOQUE.
- Le Pilote ne synchronise pas le code : pour ecrire un OT ou un test qui depend d'un detail,
  il fait lancer une commande d'inventaire en LECTURE SEULE, ou confie l'inventaire au
  sous-projet par un OT dedie.
- Les lecons d'un OT vont dans le Project qui les vit ; le Pilote attribue les numeros
  (compteurs du fil) : lecons, dettes, erreurs frequentes, OT.
- Deux Projects ne travaillent pas en meme temps sur le PC (un seul arbre de travail) : le fil
  dit qui "tient" le depot ; un increment non commite bloque les autres.
- Mode d'execution (16/10/2026, apres le blocage de l'OT-009) : l'assistant d'un Project ne
  lance JAMAIS lui-meme de commande sur un depot depuis son propre espace de travail : les
  depots sont sur le PC de l'utilisateur (/mnt/c/Users/lecoe/git/...). Il donne chaque commande
  ou script avec le resultat attendu ; l'utilisateur la lance dans son terminal WSL2 et colle la
  sortie. Aucun autre outil d'execution n'est suppose (pas d'agent en ligne de commande). Un
  depot introuvable dans l'espace de l'assistant n'est pas un motif de BLOQUE : il donne la
  commande. Tout OT le rappelle par sa ligne MODE D'EXECUTION (format 2.3).

### 2.5 Fin de conversation d'un Project
Mettre a jour SA ligne du fil (script a garde-fous, revision + 1), son prompt de reprise ;
commit dedie "fil: rev. <n>" dans le depot de pilotage ; push origin (GitHub) SEULEMENT, jamais
biapay ; "Sync" dans les Projects concernes. Le fil enregistre le HEAD du depot de CODE
(git rev-parse HEAD) ; il vit dans un autre depot, donc le commiter ne change pas ce HEAD.

### 2.6 Gestion des conversations (toutes les conversations de tous les Projects)
Regle de l'utilisateur du 16/10/2026 ; elle complete le par. 2.5.
G1 Une conversation traite UN lot coherent (un OT et son verdict, une consignation, un releve) ;
   on n'ouvre pas un lot nouveau tant que le lot en cours n'est pas a un etat stable.
G2 Etats stables (seuls points de coupure admis) : apres un commit pousse et prouve, apres un
   verdict, apres une consignation ; JAMAIS entre une ecriture et sa verification, ni avec un
   travail non commite sans fichier de reprise.
G3 Surveillance de charge : l'assistant estime la charge (nombre d'echanges, scripts et journaux
   longs echanges) ; des qu'elle devient forte (reperes : environ 30 echanges, ou une dizaine de
   scripts / journaux longs), il l'annonce, termine le lot jusqu'au prochain etat stable et
   propose de passer a une nouvelle conversation ; il ne commence pas un lot nouveau dans une
   conversation chargee.
G4 Avant tout passage : fichier de reprise ecrit dans les documents du Project (etat exact,
   hashes, attendus, commandes de controle, prochaine etape, decisions prises) + fil a jour si
   un etat commun change ; la conversation suivante demarre par ce fichier et ne redemande rien
   de ce qu'il contient.
G5 Toute information fournie par l'utilisateur et necessaire a la suite (journal, decision,
   choix) est consignee dans le fichier de reprise ou un journal de docs/digierp/tests, jamais
   seulement dans la conversation.
G6 Lot long ou risque d'interruption : le fichier de reprise est ecrit (puis mis a jour) AVANT
   les etapes suivantes, pas seulement a la fin.

---

## 3. DOCUMENTS ET OUTILS DE PREUVE

- Les documents d'un Project vivent dans ce Project et sur le PC, jamais sur le serveur de
  recette. Copies locales perimees rangees dans
  /mnt/c/Users/lecoe/git/docs/digierp/perimes_20261010/ (LISEZMOI.md dit ou est la reference).
- Le knowledge d'un Project ne contient que le code POUSSE puis synchronise ("Sync") ; un
  travail non commite se lit dans le depot local (le depot local fait foi).
- Hors depot et hors Project, sur le PC : docs/digierp/tests/ (preuves, non-regression,
  journaux, recettes des OT), docs/digierp/scripts_recette/ (COPIES des scripts du serveur),
  docs/digierp/hors_depot/.
- Dans le depot de code : outils/verifier_migrations.py (garde des migrations, Backend Rev 11 par. 56.3).
- Dans docs/digierp/tests/ : outils_pagination.py (lecture de TOUTES les pages d'une liste ;
  regles des scripts de test : Frontend Rev 11 par. 61) ; tests de regles pures du frontend en
  Node : test_session.mjs, test_chemin_interne.mjs (copient le module REEL dans /tmp puis
  l'importent ; CHEMIN_SRC=<fichier> lance le second sur un module affaibli : un test de
  securite doit prouver qu'il sait echouer, lecon 216) ; verifier_x1.py et x1/ (ancienne
  methode X1, remplacee par T-A le 14/10/2026) ; test_controle_reprise.py (temoins du controle
  de reprise, sur des copies jetables).
- /tmp de WSL est vide par un redemarrage de WSL : tout ce qui doit durer va dans
  docs/digierp/tests/.
- Scripts de controle : une condition composee se calcule dans une variable avant chk ; la
  fonction oui ne recoit qu'UNE commande de test (lecon 210) ; jamais de nom de variable
  fabrique par eval (lecon 214). Modele :
  vrai(){ [ "$1" = "$2" ] && echo 1 || echo 0; } puis chk "..." "$(vrai "$x" attendu)" "...".
  Une etape d'ecriture s'enchaine par python3 - <<'PY' || { echo ARRET; exit 1; } (code de
  sortie, jamais un effet preexistant : lecon 242) ; les resultats intermediaires vont dans un
  fichier DEDIE cle=valeur, jamais relus dans le journal en cours d'ecriture (lecon 246).
- Tout fichier ecrit par script porte son empreinte attendue (SHA-256) : refus d'ecrire si le
  texte colle differe. Jamais de triple accent grave dans un bloc de code de la conversation :
  blocs exterieurs ~~~, delimiteurs construits par chr(96)*3 ; chaine Python embarquant du
  JSON : r'''...'''.
- Tests frontend (Vitest) : resultats lus dans le rapport --reporter=json --outputFile=...
  (jamais a l'ecran) ; contre-epreuve par version affaiblie du module, restauree dans un
  finally et prouvee par SHA-256.
- Bilans d'autres outils : afficher et compter TOUTES les lignes BILAN (jamais tail -1) ;
  chacune doit avoir une des formes OBSERVEES a zero, une forme inconnue compte comme un
  echec (lecon 222).
- Inventaire d'imports : lignes de commentaire exclues, chemins RESOLUS (extension, index),
  imports non resolus affiches (un "0 importeur" n'est prouve que s'ils sont a 0), alias lus ;
  classes construites cherchees sous trois formes (lecon 226).
- Essai d'une dependance : copies jetables dans /tmp/<increment>_essai/<option> (lock
  regenere), mesures cote a cote (install, EBADENGINE, audit tout / --omit=dev, arbre, build,
  taille) - modele S2b (lecon 215).
- Configuration nginx : validee par nginx -t -c DANS le conteneur en service, sur une copie
  dans /tmp incluse par un fichier principal minimal, avec contre-epreuve sur la version de
  HEAD et une contre-epreuve par include (fichier ET ligne, lecon 220) ; en-tetes prouves par
  curl -s -D - -o /dev/null DANS le conteneur, sur chaque type de reponse, 404 compris
  (lecons 217, 223) ; un instrument nouveau se valide d'abord sur le PC.
- Livraison d'un document ou d'un script ecrit par l'assistant (methode T-A, en vigueur depuis
  le 14/10/2026 ; remplace X1, dont la copie depuis claude.ai regenere le Markdown) : publie
  dans le Project avec ses octets exacts, puis livre au PC par un script genere (build_ta_p.py,
  documents du Project Pilote) qui embarque le contenu (zlib + base64) et deux empreintes
  SHA-256 (texte colle, contenu) ; gardes : branche, HEAD, remotes = {origin} et aucun biapay
  pour le depot de pilotage, copie presente connue ; resultat IDENTITE|OK, sinon aucune
  ecriture.

---

## 4. ENVIRONNEMENT DU PC

### 4.1 Poste de developpement
- Windows 11, terminal WSL2 Ubuntu-22.04 : commandes Linux. Invite PS C:\...> = PowerShell :
  taper wsl.
- VS Code ; Java 17, Maven 3.9.9 ; Node 24.21.0 par nvm (alias par defaut ; Node 18.20.8
  conserve). Un terminal ouvert AVANT un changement d'alias garde l'ancienne version : dans un
  script, charger nvm
  (export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh" && nvm use default > /dev/null) et
  afficher node -v ; meme version que l'image de build du frontend.
- Docker Desktop (integration WSL2, stockage d'images containerd : lecon 211) ; a demarrer
  apres chaque redemarrage du PC, attendre "Engine running".
- PostgreSQL 16 : conteneur postgres16-digierp, port 5433, base digierp, utilisateur
  digierp_user (proprietaire, Flyway, superutilisateur : contourne la RLS), mot de passe
  adempiere ; volume digierp_pgdata ; l'application se connecte en digierp_app (soumis a la
  RLS). Simuler l'application :
  BEGIN; SET LOCAL ROLE digierp_app; SELECT set_config('app.current_role','EMPLOYE',true),
  set_config('app.current_user_id','<employe>',true); ...; ROLLBACK;
  Prefixer la ligne utile ('DIAG|' || ...) et trier par expression, jamais par position
  (lecon 188).
- Depot de code : /mnt/c/Users/lecoe/git/digierp (NTFS monte) - rh-api, rh-frontend,
  auth-service, gateway, eureka, outils ; aucun document (README.md seul, depuis 3a1b0dfa).
- Depot de pilotage : /mnt/c/Users/lecoe/git/digierp-pilotage (branche main) - fil, regles
  communes, dettes, controle de reprise, standards.
- Sur /mnt/c, un dossier racine d'un espace de travail VS Code ouvert cote Windows ne peut pas
  etre supprime depuis WSL (EACCES) : le retirer de l'espace de travail d'abord (15/10/2026).
- Backend rh-api : Spring Boot 3.2.5, port 8090, groupId com.digierp.rh.
- Frontend rh-frontend : React 18 + Vite + Tailwind, React Router 7 (paquet react-router seul),
  servi par nginx en Docker sur http://localhost:5173 (toujours un build de PRODUCTION).
- Login de developpement : admin / Admin@2025 ; comptes de test en Admin@2025 (tableau dans
  le prompt du Project concerne). JWT en cookie httpOnly access_token (Secure) : pour les
  tests, lire Set-Cookie et envoyer Authorization: Bearer.
- Aucun .env local (s'il en existe un : le supprimer, il activerait un autre profil).
- Git : identite lecoeurdebx@gmail.com / lecoe ; git --no-pager diff.

### 4.2 Remotes Git
- origin = GitHub git@github.com:theheartofbx/digierp-spring-react.git (prive, branche
  DigiErp-Spring-React, synchronisee avec les Projects claude.ai).
- biapay = GitLab git@gitlab.biapay.net:bia-digierp-new/digierp-initial.git, en SSH par
  ProxyJump (configuration ~/.ssh/config du PC). On ne met a jour que DigiErp-Spring-React.
- Preuve d'un push = hashes : git rev-parse HEAD = git ls-remote origin ... =
  git ls-remote biapay ... (trois hashes identiques).
- Branche biapay DigiErp-Spring-React-Development (seule deployee par la CI) : non mise a
  jour, decision d'equipe.
- Les remotes ci-dessus sont ceux du depot de CODE. Depot de pilotage : origin =
  git@github.com:theheartofbx/digierp-pilotage.git SEUL (prive, branche main) ; JAMAIS de
  remote biapay : ni documentation ni pilotage sur biapay (regle de l'utilisateur du
  14/10/2026), controle R16. Preuve d'un push du pilotage : HEAD = git ls-remote origin main.

### 4.3 Particularites WSL2 + NTFS + Docker
- sed -i echoue sur /mnt/c/ : scripts Python3 ; lecture :
  awk 'NR>=a && NR<=b {printf "%d|%s\n", NR, $0}'.
- heredocs : affichage parfois corrompu ; le script ecrit son journal et l'affiche ; seule
  compte la derniere ligne ; relancer un script ecrase son journal ; ! entre guillemets
  doubles = expansion d'historique : heredoc <<'EOF'.
- wc -l sur un fichier sans retour final = awk - 1 (lecon 189).
- code retour dans un pipe : ${PIPESTATUS[0]} ; grep -c a 0 renvoie un echec.
- node check-i18n.cjs | grep ... n'affiche rien : sans pipe ; la derniere ligne de son
  journal est vide : le message se cherche par grep, jamais par tail -1.
- logs Docker en UTC ; t0 avant up, puis --since "$t0" ; apres redemarrage du PC :
  State.StartedAt.
- apres up -d backend : 503 possible quelques secondes ; seule preuve = un 200 authentifie.
- apres un demarrage refuse : docker compose up -d GLOBAL (dependants restes "created").
- DNS de WSL : pannes passageres possibles (Could not resolve hostname github.com) :
  getent hosts github.com trois fois, puis relancer le controle ; ne jamais conclure a un
  probleme de droits (lecon 209).
- empreinte d'un dossier servi : toujours LC_ALL=C sort (lecon 212).
- git status --porcelain met entre guillemets un nom qui contient une espace : lire avec -z.
- Python : python3 -B pour tout outil du depot (aucun __pycache__ dans l'arbre, lecon 192).
- Test reseau Maven 3/3 avant tout build :
```
ok=0; for i in 1 2 3; do [ "$(curl -sS -o /dev/null -w '%{http_code} %{size_download}' --max-time 20 https://repo.maven.apache.org/maven2/org/apache/maven/maven-model-builder/3.1.0/maven-model-builder-3.1.0.jar 2>/dev/null)" = "200 159442" ] && ok=$((ok+1)); done; echo "reseau Maven : $ok / 3"
```

---

## 5. REGLES DE TRAVAIL ABSOLUES

### Livraison du code
1. JAMAIS de fichiers a telecharger : du code executable dans le terminal WSL2 (les documents
   ecrits par l'assistant arrivent aussi par un script executable : methode T-A).
2. Scripts Python3 pour toute ecriture (pas de sed, pas de cat >>) ; exception : les fichiers
   que l'outil produit lui-meme (package.json / package-lock.json par npm install /
   npm uninstall), controles ensuite par script (JSON compare a HEAD, lock : ajoutes /
   retires / changes listes).
3. Un fichier a la fois, attendre la confirmation. Un seul script tout-ou-rien pour N fichiers
   seulement quand : modification mecanique identique ; regle DEPLACEE d'un fichier a l'autre ;
   contrat et sa verification.
4. Toujours reecrire le fichier complet :
   - fichier connu en entier : reecriture apres controle mot pour mot (difflib) ;
   - fichier long connu par extraits : lecture prealable des zones, puis script a garde-fous :
     reperes au nombre d'occurrences exact (declaration unique, independants de
     l'indentation), modifications en memoire, controles finaux, reecriture ; anomalie :
     sys.exit("ARRET ... Aucune ecriture.") ;
   - attendus CALCULES (origine - retire + ajoute) + buts absolus ; un appel ajoute sous une
     AUTRE forme que l'existant change le compte (lecon 169) ;
   - residu controle sur l'USAGE exact, sur le fichier prive du texte insere (lecons 175, 199) ;
   - suppression d'un mecanisme : retirer ce qui n'existait que pour lui (inventaire calcule
     des appelants) ;
   - fins de ligne et retour final conserves ; nouveau fichier : arret s'il existe, dossier
     parent verifie ;
   - donnee reflet d'une source : generee / controlee depuis la source ;
   - refactor qui casse volontairement la compilation : liste EXACTE fichier:ligne annoncee
     (calculee).
5. Apres chaque ecriture : verification (git --no-pager diff) avec le resultat attendu.
6. JSON i18n : fusion en memoire, json.loads, JSON relu = original + les seules cles prevues,
   parite fr/en ; attendu calcule sur toute chaine 'ns:cle' (ternaires, tables : lecon 191).
7. Documents : jamais de recopie d'un long document a travers la conversation (lecon 173) ;
   un document qui s'allonge : fichier de suite ; un standard qui change : fichier de
   complements avec un tableau "regles devenues fausses" ; une regle remplacee l'est PARTOUT
   (lecon 205) ; publication puis relecture.

### Qualite et architecture
8. Consulter le code via le knowledge du Project (code pousse et synchronise seulement) ; ne
   demander de coller un fichier qu'en cas de necessite absolue ; en cas de doute sur l'etat
   reel : commande de controle en lecture seule (le depot local fait foi).
9. Avant un refactor : inventaire exhaustif calcule ; un meme mot peut designer plusieurs
   choses : trier par sens ; inventaire par extension : lister les extensions reelles
   (*.yml ET *.yaml : lecon 195).
10. Garder les patterns existants, uniformite entre modules ; une duplication remarquee en
    ecrivant le second exemplaire se corrige avant de deployer ; ne pas avoir peur de revoir
    en profondeur.
11. En cas de probleme : cause racine, JAMAIS de pansement ; prouver chaque hypothese ; lire
    les donnees reelles AVANT de construire la preuve ; prouver le defaut AVANT la correction
    et contre-prouver avec la meme reproduction ; quand le code ne tranche pas, mesurer dans
    l'environnement reel (navigateur, couche par couche : lecons 178, 201) ; un test suit un
    changement de contrat VOULU ; une precondition de test se justifie par SON scenario ;
    restreindre un droit = inventaire de TOUS les chemins qui l'exercent. Erreur 500 :
    docker compose logs backend --since 15m | grep -m1 -B2 -A45 -E "ERROR|Exception"
12. Choix structurants en options avec recommandation ; sans reponse, appliquer la
    recommandation en le disant ; un defaut decouvert en chemin = correctif separe, commit a
    part.
13. Une regle metier = un seul endroit (frontend modules/{module}/utils/, transverse
    shared/utils/ en fonctions PURES ; backend : le service proprietaire) ; donnee derivee
    calculee a la lecture ; agregat sous RLS independant du lecteur.
14. Compile Lombok en cascade : lire les PREMIERES erreurs.
15. Performance d'une liste : jamais de requete par ligne ; donnees couteuses au DETAIL ; lots.

### Flyway et base (regle du 11/10/2026 - Backend Rev 11 par. 56)
16. Script de db/migration deploye (present dans le dernier tag recette-*) = FIGE. Toute
    evolution du schema ou des donnees de reference = NOUVEAU script date
    V<AAAAMMJJ>_<n>__<description>.sql (description en lettres, chiffres, _). Un script
    ajoute apres la reference et pas encore deploye, et tout db/testdata, se modifient a la
    source (jamais de script correctif pour eux). Fonction RLS ou procedure changee = nouveau
    script date en CREATE OR REPLACE, jamais une modification de V004 (tant que la phase B
    n'est pas faite).
17. Reset complet (volume supprime, images reconstruites) : sur le PC SEULEMENT. Le serveur de
    recette n'est JAMAIS reinitialise ; aucun docker volume rm sur le serveur ; mise a jour
    du serveur uniquement par ~/maj_digierp.sh (Project Plateforme). Nombre de migrations
    attendu : RELU dans flyway_schema_history (le fil donne la derniere valeur connue).
18. Garde avant tout commit qui touche db/ :
    python3 -B outils/verifier_migrations.py --reference <dernier tag recette-* (lu dans le fil)>
    -> code 0 ; controles G0-G5 (Backend Rev 11 par. 56.3).
19. Donnees de test dans db/testdata (versions decimales qui gardent l'ordre) ; donnees de
    reference dans db/migration ; un script de reference ne cite aucun identifiant de test ;
    jamais de donnee derivee semee ; un semis ne decrit que des etats que l'application sait
    produire ; nettoyer une donnee de test = par l'API avec l'acteur legitime ; ecriture SQL
    d'ESSAI en digierp_app terminee par ROLLBACK.
20. Nouvelle table : acces de digierp_app par les privileges par defaut (aucun GRANT) ; sous
    RLS, proprietaire teste sur les COLONNES de la ligne (jamais une fonction qui relit la
    table par son id) ; vue par [RLS-HORS-TX], [RLS-POLITIQUES], [RLS-VERIF] ET par
    securite_rls_politiques.py ; script teste par reset du PC ET par mise a jour sans reset.

### Build, Docker, Git
21. Backend : (cd rh-api && mvn -q compile > /tmp/compile.log 2>&1); code=$? = 0 avant tout
    build.
22. Frontend : npx vite build = 0 ET node check-i18n.cjs = "Aucun probleme i18n detecte" ET
    controles d'enums / cles de resume a 0 (avec python3 -B) ET test_chemin_interne.mjs a 0 ET
    npm run typecheck = 0, npm test = 0, npm run lint:fondations = 0 ; ancien lint
    (npm run lint) : 1604 erreurs, 55 avertissements au 12/10, ne doit pas augmenter (cliquet,
    lecon 235). Tout fichier de test passe aussi typecheck (lecon 243). Dependances : versions
    exactes, audit (tout ET --omit=dev) avant / apres, cible prouvee dans un projet jetable,
    majeures une par une (Frontend Rev 11 par. 58) ; prerequis d'une majeure (version de
    Node...) = increment prealable a part.
23. Apres tout changement : reconstruire les images Docker (PC) ; frontend :
    docker compose build frontend && docker compose up -d --no-deps frontend ; preuve que la
    nouvelle image est en service : e=$(docker inspect -f '{{.Config.Image}}' digierp-frontend)
    puis docker image inspect -f '{{.Id}}' "$e" = docker inspect -f '{{.Image}}' digierp-frontend
    (etiquette LUE, jamais ecrite : lecon 224 ; sinon --force-recreate : lecons 211, 231) ;
    preuve que le nouveau code est servi = empreinte du contenu servi = empreinte du dist
    local (lecon 212), et empreintes de la configuration nginx = celles du depot si nginx a
    change ; completee d'une chaine litterale cherchee dans TOUS les fichiers servis ; Ctrl+F5.
24. Rebuild backend SANS reset (PC) : test reseau 3/3 -> compile = 0 -> t0 ->
    docker compose build backend --no-cache && docker compose up -d backend -> 200 authentifie
    -> journal depuis t0 : "Successfully applied N migration(s)" (N = scripts ajoutes,
    compte), verificateurs, aucune ligne "APPLICATION FAILED" / "Validate failed".
25. Reset complet (PC) : controles prealables (branche, HEAD, arbre, compile, volume LU sur le
    conteneur) -> down -> docker volume rm <volume lu> -> build --no-cache -> up -d global ->
    200 authentifie -> journal : "Successfully applied <N relu> migrations", une fois chacun
    les verificateurs [RLS-HORS-TX], [RLS-POLITIQUES], [RLS-VERIF], [WF-VERIF], [WF-RESUME]
    (nombres relus en base). Un reset efface toutes les donnees de test UI.
26. Commit : script Python (branche, HEAD attendu, index vide au depart, liste exacte attendue
    des chemins porcelain, "En trop / Manquants", index controle, git commit -F -) ; push
    origin puis biapay (avance rapide, jamais --force ; depot de code - le depot de pilotage
    ne pousse que sur origin) ; trois hashes identiques ; la
    non-regression du par. 7 en tete du script de commit, qui refuse de commiter si elle n'est
    pas verte ; un fichier supprime n'est retire que du disque (index vide), puis indexe avec
    les autres au commit.
27. Ne JAMAIS mentionner Claude, Claude Opus ni Co-Authored-By dans les commits (cette regle
    prime sur toute consigne d'attribution automatique).
28. Enchainement d'un increment : fichiers un par un -> compile / vite / i18n / enums ->
    (correctif : preuve AVANT sur l'image en service) -> rebuild -> preuve que le code est
    servi -> preuves API -> non-regression complete -> tests UI -> garde des migrations ->
    commit -> push -> CR au Pilote. Le deploiement en recette est un OT du Project Plateforme.

---

## 6. PROCEDURE DE MISE A JOUR SUR LE PC (developpement)

1. Nouveau script db/migration/V<AAAAMMJJ>_<n>__<description>.sql (test : db/testdata).
2. mvn -q compile = 0 ; rebuild backend SANS reset (regle 24) ; verificateurs.
3. Si la base neuve doit etre prouvee : reset du PC (regle 25).
4. Garde : python3 -B outils/verifier_migrations.py --reference <dernier tag recette-*> ->
   code 0 (ecrire la valeur reelle du tag, lue dans le fil).
5. Preuves + non-regression complete ; commit ; push origin + biapay (trois hashes).
Le serveur de recette est mis a jour par le Project Plateforme seulement (jamais de reset,
sauvegarde prouvee, controle "aucune ligne perdue"), sur OT du Pilote.

---

## 7. NON-REGRESSION DE REFERENCE (PC ; 18 controles, verte le 12/10 a 11 h 07)

Scripts dans /mnt/c/Users/lecoe/git/docs/digierp/tests/, lances depuis la racine du depot.
Attendus (OK / 0 ECHEC) : securite_rls_politiques 45, preuve_rejet_absence 12,
preuve_solde_absence 11, preuve_solde_valideur 13, preuve_circuit_absence 16, preuve_taches 13,
preuve_taches_mission 7, preuve_matricule 16, preuve_matricule_modif 19,
preuve_archives_employes 9, preuve_notifications_temps_reel 5, preuve_identifiants_legaux 15,
preuve_contacts_urgence 16, preuve_photo_employe 16, test_verifier_migrations 20,
preuve_d23_mission (apres) 6, test_session.mjs 9, test_chemin_interne.mjs 25 - et
"absent du resume : 0" dans le journal backend.

Commande complete (lecture seule sur le depot) :
```
cd /mnt/c/Users/lecoe/git/digierp && bash -s > /tmp/nonreg.log 2>&1 <<'EOF'
cd /mnt/c/Users/lecoe/git/digierp || exit 1
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh" && nvm use default > /dev/null
echo "NODE|$(node -v)"
T=/mnt/c/Users/lecoe/git/docs/digierp/tests
declare -A REF=([securite_rls_politiques]=45 [preuve_rejet_absence]=12 [preuve_solde_absence]=11 [preuve_solde_valideur]=13 [preuve_circuit_absence]=16 [preuve_taches]=13 [preuve_taches_mission]=7 [preuve_matricule]=16 [preuve_matricule_modif]=19 [preuve_archives_employes]=9 [preuve_notifications_temps_reel]=5 [preuve_identifiants_legaux]=15 [preuve_contacts_urgence]=16 [preuve_photo_employe]=16 [test_verifier_migrations]=20)
ko=0; nok=0
for s in securite_rls_politiques preuve_rejet_absence preuve_solde_absence preuve_solde_valideur preuve_circuit_absence preuve_taches preuve_taches_mission preuve_matricule preuve_matricule_modif preuve_archives_employes preuve_notifications_temps_reel preuve_identifiants_legaux preuve_contacts_urgence preuve_photo_employe test_verifier_migrations; do
  python3 -B "$T/$s.py" > "/tmp/nr_$s.log" 2>&1; c=$?; b=$(grep -E '^BILAN' "/tmp/nr_$s.log" | tail -1)
  if [ "$c" = "0" ] && [ "$b" = "BILAN : ${REF[$s]} OK / 0 ECHEC" ]; then echo "NR_OK|$s|$b"; nok=$((nok+1)); else echo "NR_KO|$s|code=$c|$b|attendu=${REF[$s]} OK / 0 ECHEC"; ko=$((ko+1)); fi
done
python3 -B "$T/preuve_d23_mission.py" apres > /tmp/nr_d23.log 2>&1; c=$?; b=$(grep -E '^BILAN' /tmp/nr_d23.log | tail -1)
if [ "$c" = "0" ] && [ "$b" = "BILAN : 6 OK / 0 ECHEC" ]; then echo "NR_OK|preuve_d23_mission|$b"; nok=$((nok+1)); else echo "NR_KO|preuve_d23_mission|code=$c|$b"; ko=$((ko+1)); fi
node "$T/test_session.mjs" > /tmp/nr_session.log 2>&1; c=$?; b=$(grep -E '^BILAN' /tmp/nr_session.log | tail -1)
if [ "$c" = "0" ] && [ "$b" = "BILAN : 9 OK / 0 ECHEC" ]; then echo "NR_OK|test_session.mjs|$b"; nok=$((nok+1)); else echo "NR_KO|test_session.mjs|code=$c|$b"; ko=$((ko+1)); fi
node "$T/test_chemin_interne.mjs" > /tmp/nr_chemin.log 2>&1; c=$?; b=$(grep -E '^BILAN' /tmp/nr_chemin.log | tail -1)
if [ "$c" = "0" ] && [ "$b" = "BILAN : 25 OK / 0 ECHEC" ]; then echo "NR_OK|test_chemin_interne.mjs|$b"; nok=$((nok+1)); else echo "NR_KO|test_chemin_interne.mjs|code=$c|$b"; ko=$((ko+1)); fi
r=$(docker compose logs backend --since 30m 2>&1 | grep -c 'absent du resume'); [ "$r" = "0" ] || { echo "NR_KO|absent_du_resume|$r"; ko=$((ko+1)); }
echo "NR_BILAN|echecs=$ko|ok=$nok"
EOF
cat /tmp/nonreg.log
```
Attendu : NODE|v24.21.0, 18 lignes NR_OK, NR_BILAN|echecs=0|ok=18. Un NR_KO : lire
/tmp/nr_<script>.log et PROUVER la cause avant tout correctif (lecons 207, 208).
- Les tests Java TestMasqueSaisie (23), TestNiuCoherent (10), TestTraitementImage (14) ne sont
  PAS dans cette commande (dette 11) ; les tests Vitest (npm test) font partie de la chaine
  frontend (regle 22).
- preuve_d23_mission.py avant : ne plus jamais lancer (mission orpheline, lecon 161).
- preuve_solde_valideur interrompu :
  UPDATE rh_organigramme SET poste_superieur_id = 1 WHERE id = 4;
- La campagne laisse 2 demandes EN_WORKFLOW par execution (dette 21).

---

## 8. CONTROLE DE REPRISE

Un seul exemplaire : commun/controle_reprise.sh du depot de pilotage (revision 3), lance en
lecture seule au debut de chaque conversation :
  bash /mnt/c/Users/lecoe/git/digierp-pilotage/commun/controle_reprise.sh <Pilote|Frontend|Backend|Plateforme>
Il lit DEUX depots (DIGIERP_DEPOT pour le code, DIGIERP_PILOTAGE pour le pilotage). Il affiche
la revision du fil du depot de pilotage (R0 : elle doit egaler celle du fil SYNCHRONISE dans le
Project, sinon "Sync" avant toute chose), compare le HEAD du depot de code a la valeur du fil
(R2), controle pour chaque depot la branche a jour, origin = HEAD et l'arbre propre (R1, R3,
R5 et R1p, R3p, R5p), l'absence de .env, l'absence de secret dans le pilotage (R9), les
remotes du pilotage (R16 : origin seul ; URL ecrite, effective et de push = digierp-pilotage ;
aucun biapay), et les controles propres a la couche
(compilation pour Backend et Plateforme, chaine frontend pour Frontend). Il signale tout
fichier du depot qui devrait etre dans le filtre de synchronisation du Project et n'y est pas.

---

## 9. ERREURS FREQUENTES (98 a 152 ; 1 a 97 : archives du Project principal)

98. Appliquer "modifier la source puis reset" a un script deja deploye, ou reset du serveur (lecons 194, 205)
99. Version de migration prise dans une plage de module au lieu d'une version datee (Backend par. 56.2)
100. ORDER BY par position sur une requete DIAG (lecon 188)
101. wc -l compare a une numerotation awk (lecon 189)
102. Outil Python du depot lance sans -B (lecon 192)
103. Commande lancee sur la mauvaise machine / variable shell perimee (lecon 193)
104. Inventaire limite a une extension (lecon 195)
105. FormData envoye par l'instance axios sans en-tete multipart explicite (lecon 196)
106. Limite de taille reglee dans Spring seulement (lecon 197)
107. Validation d'image confiee au navigateur (lecon 198)
108. Script d'ecriture lance sans afficher sa sortie (lecon 200)
109. Composant declare dans un composant (lecon 202)
110. Spinner en plein ecran pour un chargement de donnees (lecon 203)
111. Minuteries relancees par chaque chemin au lieu d'une regle pure (lecon 204)
112. Parametre entre chevrons dans une commande a copier (lecon 185)
113. Preuve cherchee dans un journal que l'etape suivante remplace (lecon 183)
114. Test qui suppose qu'une liste tient sur une page, ou qui gonfle taille (lecon 208, Frontend par. 61.1)
115. Test qui decode en JSON toute reponse 2xx ; ERR sans message (lecon 207)
116. Conclure a un probleme de droits sur "correct access rights" sans lire l'erreur DNS au-dessus (lecon 209)
117. Lancer ~/maj_digierp.sh sans le tunnel du serveur ouvert, ou ouvrir ce tunnel dans WSL (lecon 213)
118. $(oui cond1 && cond2) : seule la premiere condition est controlee (lecon 210)
119. Conclure qu'une nouvelle image est servie sur le seul code retour de up -d (lecon 211)
120. Script qui appelle node sans charger nvm : un terminal ancien garde l'ancienne version
121. Nom de variable fabrique par eval dans un script de controle (lecon 214)
122. Importer depuis 'react-router-dom' ou passer une prop future a BrowserRouter (React Router 7)
123. <Link to={donnee}> ou navigate(donnee) sans cheminInterne
124. Test de securite jamais lance sur un module casse : il peut ne rien controler (lecon 216)
125. add_header dans un bloc location nginx sans les en-tetes de securite communs (lecon 217)
126. Conclure sur le code HTTP d'un fichier absent sans tenir compte du repli try_files (lecon 218)
127. Copier un fichier nginx a inclure dans conf.d/ : charge une fois de trop au niveau http (lecon 219)
128. Une seule contre-epreuve pour plusieurs include : nginx s'arrete a la premiere erreur (lecon 220)
129. '' pour "echapper" une apostrophe en Python : deux chaines collees (lecon 221)
130. Attendu de FORMAT suppose ; tail -1 sur des lignes BILAN (lecon 222)
131. En-tetes d'une reponse d'erreur lus par le wget de BusyBox (lecon 223)
132. Nom d'etiquette d'image ecrit en dur (le projet Compose differe entre PC et recette, lecon 224)
133. Imports en commentaire comptes comme des importeurs ; chemins compares au lieu d'etre resolus (lecon 226)
134. Choisir la derniere version d'un outil sans lire les peerDependencies de ses voisins (lecon 227)
135. Conclure "livre" sur un indicateur du lock (devOptional) au lieu du contenu du build (lecon 228)
136. Comparer deux builds construits a des emplacements differents (--outDir hors du projet, lecon 229)
137. strip() sur une sortie git status --porcelain (lecon 230)
138. Croire qu'un up -d sert la nouvelle image quand seule l'etape de build a change (lecon 231)
139. Ajouter une regle de lint sur un lint deja rouge (lecon 233)
140. Une configuration de controle (tsconfig, lint, tests) sans temoin qui echoue (lecon 236)
141. Allonger un delai pour masquer une lenteur de systeme de fichiers (lecon 237)
142. Reecrire un JSON sans garde "reecriture a l'identique" (lecon 238)
143. Filtrer par une extension supposee sans lister les extensions reelles ; accepter un resultat uniforme sur toutes les lignes (lecon 240)
144. Prendre "fichier present" pour "nom canonique" : un ancien nom peut n'etre qu'un re-export (lecon 241)
145. Garde d'enchainement qui teste un effet pouvant preexister (fichier present) au lieu du code de sortie de l'etape (lecon 242)
146. Croire qu'un test Vitest vert prouve les types : typecheck sur les fichiers de test aussi (lecon 243)
147. it.each avec un element qui est un tableau : arguments deplies, cas ambigu (lecon 244)
148. Ouvrir "types" (globaux Node) ou ajouter @types/node pour un seul test ; lire les sources par import.meta.glob (lecon 245)
149. Relire dans un script le journal qu'il est en train d'ecrire (lecon 246)
150. Compter sur TypeScript pour refuser un attribut JSX a tiret ; transmettre {...reste} a une bibliotheque d'icones (lecon 247)
151. Ajouter des entrees a une table de correspondance livree sans mesurer leur poids (lecon 248)
152. Prouver "non livre" avec un marqueur qui existe ailleurs dans le code, ou sans valider l'instrument (lecon 249)
Prochain numero libre : lu dans le fil (compteurs partages).
