# STANDARDS — COMPLÉMENTS DU 11/10/2026
# STANDARDS_BACKEND Rev 11 (§56)
#
# Suite de claude/STANDARDS_COMPLEMENTS_20261010.md (Backend Rev 10 §52-55, Frontend Rev 9
# §47-50), inchangé. Même statut : ce fichier COMPLÈTE STANDARDS_BACKEND.md (Rev 9) et le
# complément du 10/10 ; en cas de contradiction, il fait foi. Nouveau fichier plutôt que
# recopie (leçon §173).
# Commits de référence : 1c6eabb9 (garde des migrations), 9e704517, f9545656, 7e861563
# (premières migrations datées V20261011_1 à _3). Tag de référence : recette-20261011.
# Sources de vérité de ce paragraphe : outils/verifier_migrations.py (dans le dépôt) ;
# ~/maj_digierp.sh et ~/sauvegarde_digierp.sh (serveur ; copies dans
# docs/digierp/scripts_recette/, md5 relevés le 11/10). Le script fait foi sur ce texte.

---

## RÈGLES ANCIENNES DEVENUES FAUSSES (à ne plus appliquer)

| Où | Règle ancienne | Remplacée par |
|---|---|---|
| Instructions du Project, prompt principal règle 16, STANDARDS_PROJET (Flyway) | « JAMAIS de script correctif : modifier le script SOURCE comme si on repartait de zéro, puis reset complet » | Vrai seulement pour `db/testdata` et pour un script de `db/migration` PAS ENCORE DÉPLOYÉ. Un script déployé est FIGÉ ; une évolution = nouveau script versionné daté (§56.2) |
| Prompt principal règle 17, BACKEND §17 | « Après toute modification Flyway : reset complet » | Reset sur le PC seulement ; le serveur n'est JAMAIS réinitialisé (§56.1) |
| BACKEND §14, STANDARDS_PROJET (plages V001-V099, V100-V299, V300-V306, V400-V499, V600+) | Version choisie dans la plage du module | Plages conservées pour les scripts EXISTANTS ; tout NOUVEAU script de `db/migration` prend une version datée `V<AAAAMMJJ>_<n>` (§56.2) |
| Complément du 10/10 §52.3, prompts | « 42 migrations en développement, 36 en recette » | 45 en développement (39 + 6 de `db/testdata`), 39 en recette, au 11/10 ; le nombre change à chaque script ajouté : le relire dans `flyway_schema_history` |

⚠️ Les **instructions du Project** (texte saisi par l'utilisateur dans claude.ai) citent encore
l'ancienne règle Flyway : à mettre à jour par l'utilisateur (Claude ne peut pas les modifier).

---

# STANDARDS BACKEND — REV 11

## 56. MIGRATIONS SANS RESET : SCRIPTS FIGÉS, VERSIONS DATÉES, GARDE, SAUVEGARDE (11/10/2026)

### 56.1 Principe
La base de recette contient des données saisies (employés, photos, contacts) : elle n'est
**plus jamais réinitialisée**. Le reset complet (volume supprimé, images reconstruites) reste
permis sur le PC de développement seulement.
Conséquence : Flyway compare la somme de contrôle de chaque script déjà appliqué ; un script
déployé puis modifié ferait REFUSER le démarrage du backend en recette (`Validate failed`).
Parallèle Laravel : une migration déjà passée en production ne se modifie jamais ; on en crée
une nouvelle (`php artisan make:migration`, nom horodaté). C'est exactement la règle ici.

### 56.2 Phase A (EN VIGUEUR) : figé, daté
```
✅ Un script de db/migration présent dans la RÉFÉRENCE (ce qui est déployé) est FIGÉ
✅ Toute évolution du schéma ou des données de référence = NOUVEAU script versionné DATÉ :
     V<AAAAMMJJ>_<n>__<description>.sql      (n = 1, 2, 3… dans la journée)
     ex. V20261011_1__employe_identifiants_legaux.sql, V20261011_2__employe_personne_contact.sql,
         V20261011_3__employe_photo.sql
   Nom contrôlé par la garde : ^V(\d+(?:_\d+)*)__[A-Za-z0-9_]+\.sql$  (description en
   lettres, chiffres et « _ », sans accent ni tiret)
✅ La version datée est toujours supérieure aux versions historiques (20261011.1 > 306.1) :
   l'ordre d'exécution suit l'ordre chronologique d'écriture
✅ Un script ajouté APRÈS la référence et pas encore déployé reste modifiable (source
   modifiée, reset du PC) : il n'existe encore sur aucun serveur
✅ db/testdata reste modifiable (jamais déployé) ; seule contrainte : pas de version en
   double avec db/migration (G4) ; ordre décimal du §52.3 inchangé
❌ Modifier, renommer ou supprimer un script de db/migration présent dans la référence
❌ Un script correctif qui « répare » un script non déployé : on modifie la source (règle
   d'origine, toujours vraie avant le déploiement)
❌ Une version datée inférieure ou égale à la plus haute version appliquée sur le serveur (G3)
```

### 56.3 La garde : `outils/verifier_migrations.py` (1c6eabb9)
```
python3 -B outils/verifier_migrations.py --reference REF [--cible COMMIT] [--version-max V]
  --reference    ce qui est déployé : sur le PC, le DERNIER tag recette-AAAAMMJJ ;
                 sur le serveur, le HEAD avant la mise à jour
  --cible        commit à déployer (défaut : HEAD)
  --version-max  plus haute version appliquée sur le serveur (flyway_schema_history,
                 ex. 306 ou 306.1) ; sans elle, déduite des scripts de la référence
Code retour : 0 conforme, 1 non conforme, 2 erreur d'usage ou de git
```
Contrôles (libellés du script) :

| Contrôle | Ce qu'il garantit |
|---|---|
| G0 référence ancêtre de la cible | la cible part bien de ce qui est déployé (avance rapide possible) |
| G0b version max du serveur = version max des scripts de la référence | la base du serveur correspond à la référence (aucun script appliqué hors dépôt) — seulement avec `--version-max` |
| G1 db/migration : uniquement des ajouts | aucun script de la référence modifié, renommé ou supprimé |
| G2 ajouts nommés `V<version>__<description>.sql` | nommage |
| G3 versions ajoutées > version max | Flyway les appliquera (jamais « en retard ») |
| G4 aucune version en double (migration + testdata) | le développement démarre |
| G5 db/migration ne contient que des scripts versionnés | pas de `R__` ni de fichier parasite (à faire évoluer en phase B, §56.6) |

Emploi :
```
✅ PC : avant CHAQUE commit qui touche db/ :
     python3 -B outils/verifier_migrations.py --reference recette-20261011
   (remplacer par le dernier tag recette-* posé) → code 0
✅ Tag : poser un tag recette-AAAAMMJJ sur le commit déployé à chaque déploiement qui AJOUTE
   des migrations (recette-20261010 → 92e41a61, recette-20261011 → 7e861563) ; il devient
   la référence du PC
✅ Serveur : maj_digierp.sh lit la garde DANS LA CIBLE (git show CIBLE:outils/…) — la règle
   appliquée est celle de la version déployée ; garde absente de la cible = ARRET ; appel
   avec --reference = HEAD avant mise à jour et --version-max lue en base
✅ -B : aucun __pycache__ dans le dépôt (et `__pycache__/` dans .gitignore)
❌ Lancer la garde du PC sur le serveur, ou la garde de la référence au lieu de celle de la cible
```

### 56.4 Sauvegarde prouvée avant toute mise à jour du backend
`~/sauvegarde_digierp.sh [etiquette]` (serveur, hors dépôt) :
```
1. place disque (≥ 10 × la taille de la base)
2. comptes EXACTS de toutes les tables (table|lignes)
3. pg_dump -Fc dans ~/sauvegardes (mode 600)
4. restauration d'ESSAI dans une base temporaire du même conteneur, comptes comparés table
   par table, base temporaire supprimée
Dernière ligne en cas de succès : SAUVEGARDE=<chemin>. Code 0 / 1.
--comptes : comptes exacts seuls, sans sauvegarde. Ne modifie jamais la base digierp.
```
```
✅ Une sauvegarde n'est prouvée que par sa restauration d'essai (un fichier non restauré
   n'est pas une sauvegarde)
✅ maj_digierp.sh l'appelle JUSTE AVANT de recréer le backend (étiquette maj-<départ>) ;
   échec = ARRET, conteneurs en service inchangés, commande de reprise affichée
✅ Après la mise à jour : comptes relus ; AUCUNE table ne doit perdre de ligne
✅ Restaurer = décision HUMAINE, jamais automatique
Sauvegarde de référence du 11/10 : ~/sauvegardes/digierp_20261011_044908_maj-92e41a61.dump
```
Parallèle Laravel : un `pg_dump` avant `php artisan migrate --force` en production, mais
vérifié par une restauration.

### 56.5 Nouvelle table
```
✅ Accès de digierp_app par les PRIVILÈGES PAR DÉFAUT : aucun GRANT à écrire dans le script
✅ Table sous RLS (§33-35, §40, §51.4 : propriétaire testé sur les COLONNES) : elle doit être
   vue par [RLS-HORS-TX], [RLS-POLITIQUES] et [RLS-VERIF] (repository
   @Transactional(readOnly = true)) ET par securite_rls_politiques.py (S1 : EMPLOYE_ID ou
   ECRITURE_PROPRE) ; nombres de tables relus au démarrage (16 au 11/10), jamais écrits de tête
✅ Script testé par un reset du PC (base neuve) ET par une mise à jour sans reset (base au
   niveau de la référence), car en recette il s'applique sur une base qui contient des données
```

### 56.6 Phase B (DÉCIDÉE, option O1, NON COMMENCÉE)
```
- Objets idempotents (fonctions, vues, procédures, politiques : CREATE OR REPLACE) en
  scripts répétables R__ — MODIFIABLES : Flyway les rejoue quand leur somme change
- Tables et données en scripts versionnés (figés, §56.2)
- CONSOLIDATION à chaque jalon : la chaîne de scripts est réécrite en scripts consolidés ;
  preuve = égalité des pg_dump --schema-only (ancienne chaîne / chaîne consolidée) ;
  historique Flyway rebasé ; outillée, SANS reset du serveur
- À faire avec la phase B : G5 accepte les R__ ; la garde contrôle l'idempotence des R__
```
Tant que la phase B n'est pas faite : une fonction RLS ou une procédure changée = nouveau
script daté qui la remplace (`CREATE OR REPLACE`), jamais une modification de V004.

### 56.7 Enchaînement d'une évolution de schéma (PC → recette)
```
1. Script V<AAAAMMJJ>_<n>__… dans db/migration (données de test éventuelles : db/testdata)
2. mvn -q compile = 0 ; rebuild backend ; journal : « Successfully applied N migration… »
   avec N = nombre de scripts ajoutés, compté (base de dev au niveau précédent) ;
   vérificateurs ; puis reset du PC si la base neuve doit être prouvée
3. Garde : code 0 contre le dernier tag recette-*
4. Preuves + non-régression complète ; commit ; push origin + biapay (trois hashes)
5. Serveur : ~/maj_digierp.sh <hash complet> (garde de la cible, sauvegarde prouvée,
   comptes avant / après, vérificateurs, marqueurs) ; tag recette-AAAAMMJJ sur la cible
```
