#!/usr/bin/env bash
# CONTROLE DE REPRISE DigiERP - unique pour tous les Projects (revision 3 du 14/10/2026 : deux depots).
# Usage (lecture seule, depuis n'importe ou) :
#   bash /mnt/c/Users/lecoe/git/digierp-pilotage/commun/controle_reprise.sh <Pilote|Frontend|Backend|Plateforme> > /tmp/reprise.log 2>&1; cat /tmp/reprise.log
# Deux depots :
#   code     : DIGIERP_DEPOT    (defaut /mnt/c/Users/lecoe/git/digierp), remotes origin (GitHub) et biapay
#   pilotage : DIGIERP_PILOTAGE (defaut /mnt/c/Users/lecoe/git/digierp-pilotage), remote origin SEUL
#              (GitHub theheartofbx/digierp-pilotage) ; JAMAIS de remote biapay (regle du 14/10, R16).
# Les valeurs attendues sont LUES dans FIL_CONDUCTEUR.md du depot de pilotage (tableau "Etat commun"),
# jamais ecrites ici. Contrat avec le fil (libelles exacts, colonne 1 du tableau) :
#   "Dernier commit du depot de code"              -> hash complet (HEAD du depot de code)
#   "Tag de reference de la garde des migrations"  -> recette-AAAAMMJJ (premier mot)
#   "Migrations dev / recette"                     -> "<dev> / <recette> ; derniere <version>"
#   "Tables sous RLS (dev)"                        -> nombre
# R0 affiche la revision du fil du DEPOT DE PILOTAGE : elle doit egaler celle du fil SYNCHRONISE dans
# le Project (sinon "Sync" dans claude.ai avant toute chose). Code de sortie : 0 si aucun ECHEC.
# Aucun acces au serveur de recette ici (regle du depot de pilotage).

PROJET="$1"
case "$PROJET" in Pilote|Frontend|Backend|Plateforme) ;; *) echo "USAGE : controle_reprise.sh <Pilote|Frontend|Backend|Plateforme>"; exit 2;; esac
D="${DIGIERP_DEPOT:-/mnt/c/Users/lecoe/git/digierp}"
P="${DIGIERP_PILOTAGE:-/mnt/c/Users/lecoe/git/digierp-pilotage}"
URL_PILOTAGE="git@github.com:theheartofbx/digierp-pilotage.git"
[ -d "$P/.git" ] || { echo "ARRET|depot de pilotage absent : $P"; exit 2; }
cd "$D" || { echo "ARRET|depot de code absent : $D"; exit 2; }
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" > /dev/null 2>&1 && nvm use default > /dev/null 2>&1
ok=0; ko=0
chk(){ if [ "$2" = "1" ]; then ok=$((ok+1)); echo "[OK]    $1 : $3"; else ko=$((ko+1)); echo "[ECHEC] $1 : $3"; fi; }
vrai(){ [ "$1" = "$2" ] && echo 1 || echo 0; }
psqlq(){ docker exec -e PGPASSWORD=adempiere postgres16-digierp psql -U digierp_user -d digierp -At -c "$1" 2>&1 | grep '^DIAG|'; }
FIL="$P/FIL_CONDUCTEUR.md"
val(){ python3 -B - "$FIL" "$1" <<'PY'
import sys
try: L = open(sys.argv[1], encoding='utf-8').read().split('\n')
except OSError: sys.exit(0)
for l in L:
    c = [x.strip() for x in l.strip().strip('|').split('|')]
    if len(c) >= 2 and c[0] == sys.argv[2]: print(c[1]); break
PY
}
echo "PROJET|$PROJET|depot=$D|pilotage=$P"

rev=$(head -1 "$FIL" 2>/dev/null | sed -n -E 's/.*revision ([0-9]+) .*/\1/p')
chk "R0 revision du fil (depot de pilotage) = celle du fil synchronise dans le Project" "$( [ -n "$rev" ] && echo 1 || echo 0 )" "revision=$rev (a comparer a la premiere ligne du fil lu dans le Project)"
l=$(git status -sb | head -1)
chk "R1 code : branche a jour d'origin" "$(vrai "$l" "## DigiErp-Spring-React...origin/DigiErp-Spring-React")" "$l"
l=$(git -C "$P" status -sb | head -1)
chk "R1p pilotage : branche a jour d'origin" "$(vrai "$l" "## main...origin/main")" "$l"
h=$(git rev-parse HEAD); attendu=$(val "Dernier commit du depot de code")
chk "R2 HEAD du depot de code = fil" "$( [ -n "$attendu" ] && [ "$h" = "$attendu" ] && echo 1 || echo 0 )" "depot=$h fil=$attendu"
r=$(git ls-remote origin refs/heads/DigiErp-Spring-React 2>&1 | cut -f1)
chk "R3 code : origin distant = HEAD" "$(vrai "$r" "$h")" "HEAD=$h origin=$r"
hp=$(git -C "$P" rev-parse -q --verify HEAD 2>&1); rp=$(git -C "$P" ls-remote origin refs/heads/main 2>&1 | cut -f1)
chk "R3p pilotage : origin distant = HEAD" "$( [ -n "$hp" ] && [ "$rp" = "$hp" ] && echo 1 || echo 0 )" "HEAD=$hp origin=$rp"
n=$(git stash list | wc -l); f=$(git stash list | grep -c 'formation-demandes-wip'); d=$(git stash list | grep -c 'dette27-wip')
chk "R4 stash : 3 entrees dont formation-demandes-wip et dette27-wip" "$(vrai "$n|$f|$d" "3|1|1")" "entrees=$n formation=$f dette27=$d"
n=$(git status --porcelain --untracked-files=all | wc -l)
chk "R5 code : arbre de travail propre" "$(vrai "$n" 0)" "lignes porcelain=$n"
n=$(git -C "$P" status --porcelain --untracked-files=all | wc -l)
chk "R5p pilotage : arbre de travail propre" "$(vrai "$n" 0)" "lignes porcelain=$n"
chk "R6 aucun .env local" "$( [ ! -e .env ] && echo 1 || echo 0 )" "$( [ -e .env ] && echo present || echo absent )"
tag=$(val "Tag de reference de la garde des migrations" | cut -d' ' -f1); t=$(git rev-parse "$tag^{commit}" 2>&1)
chk "R7 tag de reference du fil present" "$( [ -n "$tag" ] && git rev-parse -q --verify "$tag^{commit}" > /dev/null 2>&1 && echo 1 || echo 0 )" "$tag -> $t"
python3 -B outils/verifier_migrations.py --reference "$tag" > /tmp/reprise_garde.log 2>&1; c=$?
chk "R8 garde des migrations (reference $tag)" "$(vrai "$c" 0)" "code=$c, derniere ligne : $(tail -1 /tmp/reprise_garde.log)"
fuite=$(python3 -B - "$P" <<'PY'
import os, re, sys
# Adresse IP PUBLIQUE (les adresses locales et privees ne donnent acces a rien) ; mot de passe
# ADMIN_PASSWORD avec une VRAIE valeur (gabarits ignores : vide, ..., <...>, ${...}) ; cle privee.
# Perimetre : tout le depot de pilotage sauf .git/ et ce script (il contient les motifs eux-memes).
racine = sys.argv[1]
ip = re.compile(r'(?<![0-9.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![0-9.])')
mdp = re.compile(r'ADMIN_PASSWORD=[\'"]?([^\'"\s`]*)')
def publique(m):
    a, b = int(m.group(1)), int(m.group(2))
    return not (a in (0, 10, 127) or (a == 192 and b == 168) or (a == 172 and 16 <= b <= 31) or (a == 169 and b == 254))
def gabarit(v):
    return v == '' or set(v) <= set('.' + chr(0x2026)) or v.startswith('<') or v.startswith('${')
n = 0
for d, s, fs in os.walk(racine):
    if '.git' in s: s.remove('.git')
    for f in fs:
        p = os.path.join(d, f)
        if os.path.relpath(p, racine).replace(os.sep, '/') == 'commun/controle_reprise.sh': continue
        for l in open(p, encoding='utf-8', errors='replace').read().split('\n'):
            if any(publique(m) for m in ip.finditer(l)) or any(not gabarit(m.group(1)) for m in mdp.finditer(l)) \
               or re.search(r'BEGIN [A-Z ]*PRIVATE KEY', l):
                n += 1
print(n)
PY
)
chk "R9 aucun acces serveur ni secret dans le depot de pilotage" "$(vrai "$fuite" 0)" "lignes suspectes=$fuite"
# R16 : URL ecrite (remote.origin.url) ET URL effective (get-url, apres reecritures insteadOf de
# toute configuration) = digierp-pilotage ; aucune URL de push distincte ; aucun biapay.
rem=$(git -C "$P" remote | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
ue=$(git -C "$P" config --get remote.origin.url 2>&1); uf=$(git -C "$P" remote get-url origin 2>&1)
up=$(git -C "$P" remote get-url --push --all origin 2>&1 | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')
nb=$(grep -ci 'biapay' "$P/.git/config")
chk "R16 pilotage : remote origin SEUL, vers digierp-pilotage, aucun biapay" "$( [ "$rem" = "origin" ] && [ "$ue" = "$URL_PILOTAGE" ] && [ "$uf" = "$URL_PILOTAGE" ] && [ "$up" = "$URL_PILOTAGE" ] && [ "$nb" = "0" ] && echo 1 || echo 0 )" "remotes=[$rem] ecrite=$ue effective=$uf push=[$up] biapay_dans_config=$nb"

if [ "$PROJET" = "Backend" ] || [ "$PROJET" = "Plateforme" ]; then
  (cd rh-api && mvn -q compile > /tmp/reprise_compile.log 2>&1); c=$?
  chk "R10 mvn -q compile (rh-api)" "$(vrai "$c" 0)" "code=$c"
fi
if [ "$PROJET" != "Pilote" ]; then
  for k in postgres16-digierp digierp-auth digierp-gateway digierp-eureka digierp-backend digierp-frontend digierp-mailhog; do
    s=$(docker inspect -f '{{.State.Status}} {{.State.StartedAt}}' $k 2>&1)
    chk "R11 conteneur $k" "$(vrai "${s%% *}" running)" "$s"
  done
fi
if [ "$PROJET" = "Backend" ] || [ "$PROJET" = "Plateforme" ]; then
  m=$(val "Migrations dev / recette"); mdev=$(echo "$m" | cut -d' ' -f1); mder=$(echo "$m" | sed -n -E 's/.*derniere ([0-9.]+).*/\1/p')
  p=$(psqlq "SELECT 'DIAG|' || count(*) FILTER (WHERE success) || '|' || count(*) FILTER (WHERE NOT success) || '|' || (SELECT version FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 1) FROM flyway_schema_history")
  chk "R12 Flyway dev = fil ($mdev reussies, 0 en echec, derniere $mder)" "$( [ -n "$mdev" ] && [ "$p" = "DIAG|$mdev|0|$mder" ] && echo 1 || echo 0 )" "$p"
  rls=$(val "Tables sous RLS (dev)")
  p=$(psqlq "SELECT 'DIAG|' || count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity")
  chk "R13 tables sous RLS (dev) = fil ($rls)" "$( [ -n "$rls" ] && [ "$p" = "DIAG|$rls" ] && echo 1 || echo 0 )" "$p"
fi
if [ "$PROJET" = "Frontend" ] || [ "$PROJET" = "Plateforme" ]; then
  dk=$(sed -n -E 's/^FROM node:([0-9.]+)-alpine.*/v\1/p' rh-frontend/Dockerfile); v=$(node -v 2>&1)
  chk "R14 Node du PC = Node de l'image de build" "$( [ -n "$dk" ] && [ "$v" = "$dk" ] && echo 1 || echo 0 )" "pc=$v dockerfile=$dk"
fi
# R15 : fichiers du depot de code qui devraient entrer dans le filtre de synchronisation du Project
# (listes mesurees le 12/10, conception par. 3.4 ; un nouvel element = filtre a completer)
if [ "$PROJET" = "Frontend" ]; then
  att=".dockerignore .env.development .env.example .env.production .eslintrc.cjs .gitignore Dockerfile check-i18n.cjs e2e index.html nginx package-lock.json package.json playwright.config.js postcss.config.js public src tailwind.config.js test-results tsconfig.json vite.config.js vitest.config.js"
  lu=$(git ls-files rh-frontend | cut -d/ -f2 | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')
  hors=$(comm -13 <(echo "$att" | tr ' ' '\n' | LC_ALL=C sort) <(echo "$lu" | tr ' ' '\n' | LC_ALL=C sort) | tr '\n' ' ')
  chk "R15 racine de rh-frontend/ couverte par le filtre" "$( [ -z "$hors" ] && echo 1 || echo 0 )" "elements nouveaux=[${hors% }]"
fi
if [ "$PROJET" = "Backend" ]; then
  att="application-docker.yaml application-recette.yaml application.yaml db logback-spring.xml"
  lu=$(git ls-files rh-api/src/main/resources | cut -d/ -f5 | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')
  hors=$(comm -13 <(echo "$att" | tr ' ' '\n' | LC_ALL=C sort) <(echo "$lu" | tr ' ' '\n' | LC_ALL=C sort) | tr '\n' ' ')
  chk "R15 ressources de rh-api couvertes par le filtre" "$( [ -z "$hors" ] && echo 1 || echo 0 )" "elements nouveaux=[${hors% }]"
  att="migration migration_old testdata"
  lu=$(git ls-files rh-api/src/main/resources/db | cut -d/ -f6 | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')
  hors=$(comm -13 <(echo "$att" | tr ' ' '\n' | LC_ALL=C sort) <(echo "$lu" | tr ' ' '\n' | LC_ALL=C sort) | tr '\n' ' ')
  chk "R15b dossiers de db/ couverts par le filtre" "$( [ -z "$hors" ] && echo 1 || echo 0 )" "elements nouveaux=[${hors% }]"
fi
echo "BILAN : $ok OK / $ko ECHEC"
[ "$ko" = "0" ]
