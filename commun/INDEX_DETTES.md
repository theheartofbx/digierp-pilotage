# INDEX DES DETTES TECHNIQUES DigiERP
# Revision 3 du 15/10/2026 (dette 47 etendue aux fichiers morts releves en D4.1) ; revision 2
#   du 15/10/2026 (dette 47 a moitie soldee par 3a1b0dfa ; dette 48 nouvelle) ;
#   revision 1 du 14/10/2026. Source : prompt principal du 11/10/2026 revise le 12/10 (section 10),
#   plus les dettes 47 (decoupage, 12/10) et 48 (14/10). Texte en ASCII (sans accents) par choix.
# Tenu par le Pilote seulement, sur proposition des comptes rendus (CR) des sous-projets.
# Colonne "Project" : Project qui en a la charge (Frontend, Backend RH, Plateforme, Pilote).
# Colonne "Detail" : document ou se trouve la description complete. Les prompts dates (05/10,
#   09/10, 10/10, 11/10, 12/10) sont des ARCHIVES du Project Pilote : un sous-projet ne les voit
#   pas ; tout ce dont il a besoin pour traiter une dette est recopie dans l'ordre de travail (OT).
# Prochain numero libre : lu dans FIL_CONDUCTEUR.md du depot de pilotage (compteurs partages).

---

## 1. DETTES OUVERTES

| # | Objet | Project | Detail | Etat |
|---|---|---|---|---|
| 1 | Delegations et moteur de workflow | Backend RH | prompt du 05/10 | ouverte |
| 2 | Discipline (increment 4) | Backend RH | prompt du 05/10 | ouverte |
| 3 | Droits / RLS divers (dont rls_proprietaire_mission dans V219) | Backend RH | prompt du 05/10 | ouverte |
| 4 | Controllers qui lisent des repositories | Backend RH | prompt du 05/10 | ouverte |
| 5 | /perimetres/conflits en 500 (vue absente) ; /employes/archives | Backend RH | prompts du 05/10 et du 10/10 | ouverte |
| 6 | Absences (dont type AUTRE inexistant : Detail obligatoire non testable) | Backend RH | prompts du 05/10 et du 10/10 soir | ouverte |
| 7 | Jobs Missions | Backend RH | prompt du 05/10 | ouverte |
| 8 | Deploiement : index.html sans Cache-Control (no-cache a poser) ; attribut version de docker-compose (avertissement vu le 12/10 en recette) ; FROM nginx:alpine non fige dans le Dockerfile frontend (curl present au 12/10, non garanti) ; /vite.svg (nom sans empreinte) mis en cache un an immutable ; aucune CSP servie (conception des patrons par. 6.4) | Plateforme | prompts du 05/10 et du 12/10 | ouverte |
| 9 | Code mort frontend : config/theme.js et shared/styles/forms.styles.js a 0 importeur (retires quand les jetons les remplacent, etape 1.3) ; Button, Badge, EmptyState, PageHeader, Alert a 0 importeur (remplaces en 1.5) | Frontend | prompts du 05/10 et du 12/10 | ouverte |
| 10 | Relance STAGE, placeholder en dur | Backend RH | prompt du 05/10 | ouverte |
| 11 | Campagne de tests a etendre ; commande unique de non-regression (18 controles au 12/10, sans les tests Java TestMasqueSaisie, TestNiuCoherent, TestTraitementImage) ; inventaire S3 limite | Pilote | prompts du 05/10 et du 11/10 ; REGLES_COMMUNES par. 7 | ouverte |
| 12 | Reprises anterieures | Pilote | prompt du 05/10 | ouverte |
| 13 | Motif obligatoire a l'ecran, facultatif au serveur | Backend RH | prompt du 05/10 | ouverte |
| 14 | Cles i18n (inutilisees, dynamiques, .js non lus) | Frontend | prompt du 05/10, lecon 191 | ouverte |
| 15 | Verificateurs [RLS-VERIF], [RLS-POLITIQUES], [WF-VERIF] encore en ApplicationRunner (apres l'ouverture de Tomcat) | Backend RH | prompt du 05/10 ; STANDARDS_BACKEND par. 51.2 | ouverte |
| 16 | Couleurs de statut dans AbsencesTable | Frontend | prompt du 05/10 | ouverte |
| 17 | Semis disc_demande_explication sans instance de workflow | Backend RH | prompt du 05/10 ; STANDARDS_BACKEND par. 51.3 | ouverte |
| 19 | Fenetres "maison" hors pile | Frontend | prompt du 05/10 | ouverte |
| 20 | ConfirmModal monte ferme | Frontend | prompt du 05/10 | ouverte |
| 21 | La campagne laisse 2 demandes EN_WORKFLOW par execution | Backend RH | prompt du 05/10 | ouverte |
| 22 | Erreurs rendues en 500 (route inconnue, violation de RLS d'ecriture : 403 attendu) | Backend RH | prompt du 05/10 ; STANDARDS_BACKEND par. 45 | ouverte, pressante avant l'increment 5 |
| 24 | Build --no-cache expose au reseau | Plateforme | prompt du 05/10 | ouverte |
| 25 | Helpers recopies dans les scripts de preuve (premier module commun : outils_pagination.py ; Frontend Rev 11 par. 61.3) | Pilote | prompts du 05/10 et du 11/10 | ouverte |
| 26 | Missions : constats non prouves (missionnaire principal sans resolveEmployeId, participants, pas de MisMissionPolitique ni d'actionsPermises) | Backend RH | prompt du 05/10 ; STANDARDS_BACKEND par. 42, 51.6 | ouverte |
| 27 | Mise en forme selon la langue (option F-a) ; travail en reserve dans le stash dette27-wip ; absorbee par les types de champs de l'etape 1.6 des patrons | Frontend | prompt du 05/10 ; stash dette27-wip | ouverte, travail en reserve |
| 28 | Suppression logique d'un employe : rh_employe.actif non ecrit (prouvee le 11/10 : 8 archives) | Backend RH | prompt du 09/10 | ouverte |
| 29 | remplirDepuisRequest recopie dateEmbauche (ecrasement a null ?) | Backend RH | prompt du 10/10 | a prouver |
| 31 | Exports Absences / Contrats / Missions sans endpoint | Backend RH | prompt du 10/10 soir | ouverte |
| 32 | Bareme per diem : 2 combinaisons inserees sur 9 ; V224_1 recale le compteur en dur | Backend RH | prompt du 10/10 soir | a prouver |
| 33 | Profil Spring passe en argument (auth-service, gateway, eureka) | Plateforme | prompt du 10/10 soir ; Backend Rev 10 par. 53 | ouverte |
| 34 | SockJS -> WebSocket natif (a prouver a travers la gateway et nginx) | Frontend | prompt du 10/10 soir ; Frontend Rev 9 par. 49 | ouverte |
| 35 | Tableau de bord : totalPostes = elements de la page | Backend RH | prompt du 10/10 soir | ouverte |
| 36 | Organigramme vue liste : filtre Poste inoperant, .catch silencieux | Frontend | prompt du 10/10 soir | ouverte |
| 37 | Famille (conjoint, enfant, erp_contact) sans RLS, reponses non ApiResponse... (traitee a l'etape 2 des patrons) | Backend RH | prompt du 11/10 | ouverte |
| 38 | Referentiels employes non generiques ; rh_lien_contact sans ecran | Backend RH | prompt du 11/10 | ouverte |
| 39 | Frontend : npm audit (S1, S2.0, S2b, S2c, S2d faits et deployes ; livre aux navigateurs : 0 ; reste S3 Tailwind 4, juste avant 1.3 ; a venir, increments a part : TypeScript 7 et ESLint 8.57.1 -> 10) ; react-easy-crop dans le bundle principal ; import Excel non branche ; BarreLaterale / NavGroupe a sortir d'AppLayout ; textes en dur du repli ; lignes remplacees par l'indicateur pendant un rechargement ; @testing-library/user-event sans importeur depuis 1.4 (a utiliser en 1.5, sinon retirer) | Frontend | prompts du 11/10 et du 12/10 ; Frontend Rev 11 par. 58.4 | ouverte |
| 40 | Photo : erp_personne.photo_url et StorageService inutilises ; seuil 128 px repete (a exposer par le serveur) | Backend RH | prompt du 11/10 | ouverte |
| 41 | Tri libre : AbsDemandeController passe tri / ordre tels quels a Sort.by / Direction.fromString (valeur inconnue -> exception, 500 probable au lieu de 400) ; liste blanche des tris par objet ; inventaire des autres controleurs | Backend RH | prompt du 11/10 soir | ouverte, a prouver |
| 42 | Script de mise a jour du serveur de recette : en-tete a corriger (commande reelle du tunnel) ; recreation forcee du service reconstruit a verifier (mesure du 12/10 sur le PC : Compose ne recree pas un conteneur dont seule l'image a change d'identifiant) ; integrer le controle "image du conteneur = etiquette lue", les empreintes de contenu et de configuration nginx, les en-tetes par curl ; sauver le script de controle d'apres dans docs/digierp/scripts_recette/ | Plateforme | prompts du 11/10 soir et du 12/10 | ouverte, AVANT l'etape 1.9 |
| 44 | Contrat resume.route non valide cote serveur : WfResumeDocument devrait refuser une route qui n'est pas un chemin interne (aujourd'hui seules les constantes ROUTE_FICHE la produisent) | Backend RH | prompt du 12/10 | ouverte, basse |
| 45 | Lint frontend rouge : npm run lint = 1 (1604 erreurs dont react/prop-types 1542, 55 avertissements dont exhaustive-deps 52 ; no-dupe-keys 3 = vrais defauts possibles ; prop-types importe sans etre declare) ; cliquet en place | Frontend | prompt du 12/10 | ouverte, increment L |
| 46 | Depot de travail sur /mnt/c (NTFS par 9P) : lenteur des tests jsdom, de npm, vite, tsc, mvn ; sed -i en echec. Option R1 : depot sur ext4 de WSL (~/git/digierp), VS Code en mode WSL ; a decider, mesurer avant / apres, chemins des prompts et des scripts a reprendre | Plateforme | prompt du 12/10 | ouverte, decision a prendre |
| 47 | Fichiers inutiles suivis par Git : rh-api/node_modules/ (380 fichiers) RETIRE par 3a1b0dfa (14/10, avec la documentation et deux fichiers de cookies curl ; regles ajoutees au .gitignore racine) ; restent migration_old_archive_backup/ (racine) et rh-api/src/main/resources/db/migration_old/ (inutilise par Flyway, 0 reference) : retrait par un correctif a part, prouve (aucun usage) ; constat du 15/10 (D4.1, docs/digierp/tests/mesure_tailles_d4.log) : fichiers morts suivis a la racine (ERROR et [backend, 0 octet ; migrate.py, 6 956 octets ; patch_applayout_permissions.py, 4 618 octets) et rh-api/ACCC4CF8.asc (4 812 octets, nature a identifier) ; aucun n'est dans un filtre de Project, meme preuve d'absence d'usage avant retrait | Plateforme | dossier claude/DECOUPAGE_PROJECTS_20261012.md par. 1 ; prompts de decoupage du 14/10 et du 15/10 par. 2 | ouverte, a moitie soldee (3a1b0dfa) |
| 48 | Secrets de developpement en dur dans la configuration suivie par Git (cle de signature JWT et mot de passe de base dans docker-compose.yml, les application*.yaml d'auth-service et de gateway, postgres-init/01_create_app_role.sql, README.md) ; prouver que la recette en utilise d'AUTRES (comparaison d'empreintes sur le serveur, jamais de valeur affichee), puis sortir les valeurs de la configuration suivie | Plateforme | prompt de decoupage du 14/10 par. 2 | ouverte, a prouver |

## 2. DETTES SOLDEES

| # | Objet | Solde par |
|---|---|---|
| 18 | Identifiants GitLab | SSH par ProxyJump (10/10) |
| 23 | RLS d'ecriture de mis_mission | commit 89ae754f |
| 30 | Audit (auteur, IP, user-agent) | commit 5fe6d659 |
| 43 | nginx frontend : en-tetes de securite absents des statiques, Cache-Control en double | commit 5cd225ca (deploye, 15/15 PC et recette) |

## 3. DETTES SANS NUMERO (10/10 soir et 12/10, a numeroter a la prochaine revision)

| Objet | Project |
|---|---|
| Audit des props (cas c, f, g) | Frontend |
| 9 textarea ecrits a la main (7 fichiers) a migrer vers FormInput multiline | Frontend |
| NotificationsPanel.tempsRelatif en francais en dur (i18n) | Frontend |
| LocaleContext lit localStorage.token (inexistant) | Frontend |
| WebSocket setAllowedOriginPatterns("*") | Backend RH |
| Gateway : AbortedException journalisee en ERROR | Plateforme |
| Utilite reelle de RemoveResponseHeader a mesurer sur le port de la gateway | Plateforme |
| Purges des autres modules (contrats, organisations, sites, services, postes) en 409 generique | Backend RH |
| Motif du controle C9 du controle global de l'etape 1.4 (resume de Vitest non lu, codes couleur) a corriger a la prochaine reutilisation du script | Frontend |
