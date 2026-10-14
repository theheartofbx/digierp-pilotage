# STANDARDS — COMPLÉMENTS DU 10/10/2026
# STANDARDS_BACKEND Rev 10 (§52 à §55) et STANDARDS_FRONTEND Rev 9 (§47 à §49)
#
# Pourquoi un fichier de complément : STANDARDS_BACKEND.md (Rev 9) et STANDARDS_FRONTEND.md
# (Rev 8) ne se recopient pas pour s'allonger (leçon §173 : une recopie a déjà perdu une ligne).
# Ce fichier les COMPLÈTE ; en cas de contradiction, il fait foi. À fusionner lors d'une
# prochaine révision complète faite par script à garde-fous (difflib : aucune ligne retirée).
# Commits de référence : f41bf243 … b46d8e70 (correctifs), 9481a675 (export postes),
# 067a03ae (X-Correlation-Id), 77dc9af6 (profil Spring), e52cf7ec (recette sans données de
# test), 92e41a61 (organigramme).

---

## RÈGLES ANCIENNES DEVENUES FAUSSES (à ne plus appliquer)

| Où | Règle ancienne | Remplacée par |
|---|---|---|
| BACKEND §14 Nomenclature | « V100-V299 : modules RH (… données test …) », « V500-V599 : données de test périmètres » | Données de test dans `db/testdata`, versions décimales (§52) |
| BACKEND §22 « RemoveResponseHeader dans gateway » | filtre global `default-filters: RemoveResponseHeader=Transfer-Encoding` | posé ROUTE PAR ROUTE, jamais sur la route websocket (§55) |
| BACKEND §30 | « code métier immuable ensuite », sans exception | exception du matricule (§54.3) |
| BACKEND §17, prompts | reset attendu : « 38 migrations » | 42 en développement, 36 en recette (§52) |
| BACKEND §28 dette | `config-postes-acces.service.js → /rh/postes` | il appelle `/rh/parametrage/postes/tous` ; l'organigramme aussi (FRONTEND §48) |
| Dockerfile rh-api (avant 77dc9af6) | `ENTRYPOINT [... "--spring.profiles.active=docker"]` | `ENV SPRING_PROFILES_ACTIVE=docker` + ENTRYPOINT sans profil (§53) |
| `InitialisationDonnees` (avant e52cf7ec) | admin créé en `Admin@2025` partout | `ADMIN_PASSWORD`, repli seulement avec les données de test (§52.4) |

---

# STANDARDS BACKEND — REV 10

## 52. DONNÉES DE TEST SÉPARÉES — `db/testdata` ET PROFIL `recette` (e52cf7ec)

### 52.1 Principe
Les données de test (postes, employés, contrats, familles, affectations, organigramme,
comptes de test, absences, missions, formations, formateurs, configuration PBAC des postes)
vivent dans `rh-api/src/main/resources/db/testdata/`. Les données de RÉFÉRENCE (référentiels,
organisation, sites, services, séquences, barèmes, modèles de workflow, PBAC des modules)
restent dans `db/migration/`.
Parallèle Laravel : un `DatabaseSeeder` qui n'appelle les seeders de démonstration qu'en
environnement `local`.

### 52.2 Emplacements Flyway et profil
```yaml
# application.yaml ET application-docker.yaml (les deux : le profil docker répète la valeur)
spring.flyway.locations: classpath:db/migration,classpath:db/testdata
# application-recette.yaml — UN SEUL fichier porte les DEUX réglages, ensemble
spring.flyway.locations: classpath:db/migration
digierp.donnees-test.actif: false
```
Recette : `.env` du serveur (non versionné, mode 600) `SPRING_PROFILES_ACTIVE=docker,recette`
et `ADMIN_PASSWORD='…'` ; le dernier profil cité l'emporte.

### 52.3 Versions : garder l'ORDRE d'exécution du développement
Une partie de test extraite d'un script garde sa place par une version DÉCIMALE :
`V102_1` (102.1) passe après V102 et avant V103. Indispensable quand un script de référence
LIT ou MODIFIE les données de test (V211 : `UPDATE rh_employe … WHERE horaire_modele_id IS
NULL` ; V213 : supervision par codes de postes).
```
db/testdata : V102_1 (sections 1-3, 5-13 de l'ancien V102 + recalage des séquences par site),
              V212, V213_1 (supervision DRH des postes de test), V224_1 (missions + compteur),
              V304 (catalogue de formation de test), V306_1 (3 formateurs)
db/migration : V102__organisation_sites (organisation, sites, services, séquences à 0),
               V224__mis_baremes, V213 et V306 réduits
Comptes : développement 42 migrations (36 + 6) ; recette 36
```
Règles :
```
✅ Un script MIXTE se scinde dans la SOURCE (règle 16) : jamais de script correctif
✅ Une séquence de référence se crée à 0 ; les données de test la RECALENT après avoir créé
   leurs lignes (UPDATE … SET valeur_courante, mêmes valeurs qu'avant la séparation)
✅ Un script de référence ne cite AUCUN identifiant de test (code de poste, login, matricule,
   numéro) — contrôle C7 ci-dessous
✅ Un UPDATE de référence sur des données de test est toléré s'il est sans effet sur une base
   vide (V211) ; il reste APRÈS la partie de test dans l'ordre des versions
❌ Une donnée de test dans db/migration ; une donnée de référence dans db/testdata (barème)
```

### 52.4 InitialisationDonnees
```java
@Value("${digierp.donnees-test.actif:true}") private boolean donneesTest;
@Value("${ADMIN_PASSWORD:}")                 private String motDePasseAdminInitial;
// run() : mettreAJourMotsDePasseTest() et assignerRolesRbacCompteTest() SEULEMENT si donneesTest
// motDePasseInitialAdmin() : ADMIN_PASSWORD s'il est renseigné ; sinon Admin@2025 SEULEMENT
//   avec les données de test ; sinon IllegalStateException → démarrage REFUSÉ (message qui dit
//   quoi faire). N'agit qu'à la CRÉATION du compte admin.
```
`docker-compose.yml` (bloc backend) : `SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-docker}`
et `ADMIN_PASSWORD: ${ADMIN_PASSWORD:-}` (chaîne vide = non renseigné).

### 52.5 Inventaire calculé (avant toute séparation)
```
1. Ensemble « données d'employés » = FERMETURE des clés étrangères vers rh_employe, rh_poste,
   rh_contrat, lue dans pg_constraint (37 tables au 10/10) + erp_personne (parent JOINED)
2. Pour chaque migration : tables écrites (INSERT / UPDATE / DELETE, commentaires retirés)
   → catégories « tout test », « mixte », « hors ensemble »
3. Angles morts : un lien SANS clé étrangère (rh_utilisateur.employe_id) ; le contenu des
   blocs DO $$ … $$ (exclu de la regex) ; les LECTURES de données de test dans un script de
   référence (contrôle C7 : identifiants de test cités hors commentaires)
4. Contrôle d'ensemble après écriture : versions de migration seule = 36, migration +
   testdata = 42, aucune version en double, ordre décimal vérifié, C6 (aucune écriture dans
   l'ensemble hors V211), C7
```

### 52.6 Preuves (les trois sont obligatoires pour toute modification de ce mécanisme)
```
1. Reset DÉVELOPPEMENT : 42 migrations, versions de testdata présentes, compteurs EMPLOYE par
   site 5/2/2, 6 comptes de test initialisés, vérificateurs, non-régression complète inchangée
2. Reset local avec le profil RECETTE (.env local temporaire, ignoré par git) :
   démarrage A sans ADMIN_PASSWORD → REFUS observé EN DIRECT (le journal du conteneur
   disparaît quand il est recréé) ; démarrage B avec ADMIN_PASSWORD → profils "docker",
   "recette" actifs, 36 migrations, tables de l'ensemble vides, seul utilisateur admin,
   Admin@2025 refusé (401), premier matricule BIA-<année>-00001 ; `up -d` GLOBAL (§53.3)
3. Retour au développement : .env supprimé, reset, profil "docker" seul, 42, non-régression
```

### 52.7 Déploiement sur la recette avec base neuve
Script dédié `~/deploie_recette_sans_test.sh` (hors dépôt, sur le serveur) : HEAD de départ
et cible en dur, .env vérifié (600, profil, mot de passe sans l'afficher), fichiers changés
limités à rh-api et docker-compose.yml, build du backend PENDANT que la recette tourne, puis
`down`, suppression du volume, `up -d` global relancé toutes les 2 min, contrôles V0-V8.
Le mot de passe admin de la recette ne passe JAMAIS par une conversation ni par un argument
de commande (lu dans .env par Python, passé à curl sur l'entrée standard).

---

## 53. PROFIL SPRING : LU DANS `SPRING_PROFILES_ACTIVE`, NULLE PART AILLEURS (77dc9af6)

### 53.1 Constat
`ENTRYPOINT ["java", "-jar", "app.jar", "--spring.profiles.active=docker"]` : un argument de
ligne de commande (comme un `-D…`) l'EMPORTE sur une variable d'environnement. La variable
`SPRING_PROFILES_ACTIVE` de docker-compose n'avait AUCUN effet, sans erreur : prouvé par la
preuve recette locale (variable `docker,recette` dans le conteneur, profil `"docker"` seul
actif selon Spring). Le serveur aurait eu le même défaut.
Parallèle Laravel : `APP_ENV=local` forcé dans la commande de lancement, qui ignore le `.env`.

### 53.2 Règle
```dockerfile
# Profil par défaut ; Compose le remplace (SPRING_PROFILES_ACTIVE du .env, ex. docker,recette).
ENV SPRING_PROFILES_ACTIVE=docker
ENTRYPOINT ["java", "-jar", "app.jar"]
```
```
✅ Le profil vient d'UN endroit : la variable (défaut dans l'image, valeur dans Compose / .env)
✅ Preuve d'un profil : la ligne « The following N profiles are active: … » du journal,
   jamais la seule variable vue dans le conteneur
❌ --spring.profiles.active / -Dspring.profiles.active en argument (dette 33 : auth-service,
   gateway, eureka le font encore, sans effet aujourd'hui car ils n'ont pas de profil recette)
```

### 53.3 Démarrage refusé et dépendances Compose
Un service qui refuse de démarrer laisse les services qui en dépendent
(`depends_on: … condition: service_healthy`) à l'état `created`, jamais démarrés. Après un
refus voulu (preuve), relancer `docker compose up -d` GLOBAL, pas le seul service corrigé ;
toute attente d'un 200 relance `up -d` toutes les 2 minutes.

---

## 54. ARCHIVES, PURGE ET CODE MÉTIER (f41bf243, ccb5d662, 8dadfcc2)

### 54.1 Lecture des archives par projection
Une liste d'archives (requête NATIVE, car `@SQLRestriction("actif = true")` masque les
archivés en JPQL) se lit par une PROJECTION qui ne contient que ce que l'écran affiche,
libellés compris, en UNE requête (alias entre guillemets). Jamais une liste de colonnes
recopiée de l'entité : elle dérive à chaque colonne ajoutée (horaire_modele_id → 500).

### 54.2 Purge : la base décide
```
✅ DELETE dans try/catch(DataIntegrityViolationException) ; la table qui retient est lue dans
   le message de PostgreSQL (« … on table "x" ») ; refus traduit en 422 qui la NOMME
❌ Liste des tables liées comptées à la main (elle citait une table inexistante → 500, et en
   oubliait la plupart)
```
Dette : les purges des autres modules (contrats, organisations, sites, services, postes) ne
suivent pas encore ce motif (409 générique).

### 54.3 Exception à §30 : le matricule (8dadfcc2)
Le matricule d'un employé est corrigeable en MODIFICATION, avec un MOTIF obligatoire, et la
correction est auditée. Tout autre code métier reste immuable après création (§30).

---

## 55. GATEWAY : EN-TÊTES DE RÉPONSE ET WEBSOCKET (b46d8e70, 067a03ae)

### 55.1 Un en-tête de réponse se pose dans `beforeCommit`
```java
exchange.getResponse().beforeCommit(() -> {
    exchange.getResponse().getHeaders().set(HEADER, corrId);
    return Mono.empty();
});
return chain.filter(exchange.mutate().request(requeteEnrichie).build());
```
```
❌ .then(...) APRÈS la chaîne : en-têtes déjà envoyés (ReadOnlyHttpHeaders) — erreur à
   chaque réponse et connexion WebSocket coupée après le 101
❌ set AVANT la chaîne seulement : le service en aval (rh-api) RENVOIE l'en-tête reçu, la
   gateway l'AJOUTE en recopiant sa réponse → deux exemplaires (mesuré en local ET en recette)
✅ beforeCommit : après la recopie des en-têtes du service en aval, avant leur envoi ;
   s'applique aussi aux réponses écrites par la gateway elle-même (401)
```
Parallèle Laravel : modifier `$response` dans un middleware après `$next($request)`, avant
`send()` — jamais dans `terminate()`.

### 55.2 Filtres « après » : jamais sur la route websocket
`RemoveResponseHeader=Transfer-Encoding` modifie la réponse APRÈS son envoi : impossible sur un
101. Il est posé route par route, sauf sur la route `websocket` (remplace §22). Son utilité
réelle reste à mesurer directement sur le port de la gateway (dette).

### 55.3 WebSocket authentifié par la poignée de main
L'utilisateur d'une session STOMP est celui de la poignée de main HTTP (`/ws`), authentifiée
par le cookie httpOnly `access_token`, comme toute requête (liste noire comprise). Un CONNECT
sans utilisateur est refusé (`MessageDeliveryException`). Abonnements SANS login :
`/user/queue/notifications`, `/user/queue/badge` ; côté serveur `convertAndSendToUser(login,
"/queue/…", …)`. Aucun en-tête `Authorization` dans la trame CONNECT (le navigateur ne lit pas
un cookie httpOnly).

### 55.4 Mesurer couche par couche
Un en-tête, un code ou un corps se MESURE (Python `get_all`, `curl -D -`), séparément sur
rh-api direct (8090), la gateway (8082) et nginx (5173), avec les VALEURS (deux valeurs
identiques = écho ; différentes = deux générations). Un en-tête « vu une fois » dans le
navigateur n'est pas une mesure (le test S7 l'a laissé passer en double).

---

# STANDARDS FRONTEND — REV 9

## 47. `FormInput` MULTILIGNE (fb2dcb92)
```jsx
<FormInput name="description" label={…} value={…} onChange={…} multiline rows={4} error={…} />
// rend un <textarea> avec le même libellé, la même aide, la même erreur et les mêmes classes ;
// resize-none ; type, min, max, step sans objet (non transmis)
```
```
✅ Toute zone de texte d'un formulaire passe par FormInput multiline
✅ La prop d'erreur s'appelle `error` (FormInput ET FormSelect) : `erreur=` est ignorée sans
   bruit (cas réel : AbsenceForm, 5 champs, messages jamais affichés)
Dette : 9 <textarea> écrits à la main (7 fichiers) à migrer
```

## 48. LISTE DÉROULANTE : JAMAIS UNE PAGE (92e41a61)

### Constat
`OrganigrammePage` remplissait sa liste de postes par `GET /rh/postes` (une PAGE :
`PageResponse { contenu, totalElements, … }`) lue par `res.data?.data?.content ?? res.data?.data`.
`content` n'existe pas (c'est le nom Spring, pas le nôtre) : le `??` rendait l'OBJET page,
`postes.map` faisait planter la vue liste. Un VALIDATEUR (RH.ORGANIGRAMME:LIRE sans
RH.POSTE:LIRE) recevait en plus un 403, avalé par `.catch(() => {})`.

### Règles
```
✅ Liste déroulante = endpoint de LISTE COMPLÈTE non paginé (BACKEND §28 :
   /rh/{module}/parametrage/…, RefSimpleDto) — postes : posteService.listerTous()
   → /rh/parametrage/postes/tous (isAuthenticated, bornée par la RLS de rh_poste)
✅ Lire la réponse selon sa forme RÉELLE (relevée par un appel) : liste → res.data.data ;
   page → res.data.data.contenu
❌ `.content` (n'existe pas dans PageResponse) ; un `??` qui se rabat sur un objet là où une
   liste est attendue
❌ `.catch(() => {})` sur un chargement : un 403 disparaît sans message (dette)
✅ Une fonction de service sans appelant se retire ; une adresse écrite à deux endroits est
   le début d'une divergence (cas de l'export des postes, 9481a675)
```

## 49. NOTIFICATIONS ET TEMPS RÉEL (863fe7ff)
```
✅ HTTP par api.js (cookie httpOnly, CSRF, renouvellement sur 401) : /rh/notifications…
✅ STOMP sur SockJS, même origine (/ws) ; aucun jeton lu en JavaScript (localStorage.token
   n'existe pas : authentification par cookie) ; abonnements /user/queue/notifications et
   /user/queue/badge ; le compteur envoyé par le serveur fait foi
✅ Repli : relevé HTTP toutes les 30 s tant que le temps réel est coupé
✅ NotificationsPanel : contrat (ouvert, onFermer stable par useCallback, notifications,
   nbNonLus, connecte, chargement, marquerLu, marquerToutLu) ; heure relative sur dateCreation ;
   la cloche stoppe la propagation de son mousedown (sinon fermer puis rouvrir)
Dettes : SockJS déclenche « Permissions policy violation: unload » (Chrome) → WebSocket natif
(brokerURL), à prouver à travers la gateway et nginx (dette 34) ; tempsRelatif en français
en dur (i18n) ; LocaleContext lit localStorage.token (inexistant)
```

## 50. EXPORTS
```
✅ L'adresse d'un export appelée par le hook de liste (useExport) = le mapping réel
   (/rh/<module>/export/excel) ; inventaire calculé frontend ↔ contrôleurs avant d'en ajouter
Constat du 10/10 : seuls Employés et Postes ont un export serveur ; Absences, Contrats et
Missions appellent une adresse sans endpoint (dette 31)
```
