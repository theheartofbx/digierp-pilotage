# Standards de developpement DigiERP
# Derniere mise a jour : 30/05/2026

## EMPLACEMENT DES FICHIERS MD
> ~/git/digierp/rh-api/docs/
> Ces fichiers sont aussi uploades dans le Project Claude pour consultation.

---

## 0. REGLES DE TRAVAIL AVEC CLAUDE

- Donner UN fichier a la fois, attendre confirmation
- Si erreur collee -> corriger avant de continuer
- Expliquer les concepts, paralleles Laravel
- Verifier la compilation apres chaque fichier Java
- Lire ETAT_PROJET.md, ETAT_BASE.md, STANDARDS_PROJET.md, LECONS_APPRISES.md au debut de chaque session
- En fin de session : mettre a jour les MD + donner un prompt de reprise
- CRITIQUE : les mises a jour MD doivent enrichir sans jamais supprimer ni alterer
  les informations existantes. Toute synthese doit etre sans perte d information.
- SATURATION : quand la conversation approche de la saturation, Claude doit :
  1. Le signaler explicitement a l utilisateur
  2. Mettre a jour TOUS les fichiers MD dans ~/git/digierp/rh-api/docs/
  3. Proposer un prompt de reprise complet

---

## 1. CALCULS — REGLES CRITIQUES ERP

### Classe obligatoire : DigiErpCalculs
```java
import com.digierp.rh.shared.util.DigiErpCalculs;

// Jours entre deux dates (JAMAIS Period.getDays() — bug > 1 mois)
long jours = DigiErpCalculs.joursEntreInclus(debut, fin);

// Taux sur montant
BigDecimal cotisation = DigiErpCalculs.appliquerTaux(salaire, new BigDecimal("5.25"));

// Salaire journalier CEMAC (base 30j)
BigDecimal sj = DigiErpCalculs.salaireJournalier(salaireMensuel);

// Arrondi FCFA (0 decimale)
BigDecimal net = DigiErpCalculs.arrondirFCFA(montant);
```

### Regles absolues
- JAMAIS Period.getDays() — retourne jours residuels seulement !
- JAMAIS double pour les montants
- Toujours ChronoUnit.DAYS.between() ou DigiErpCalculs
- Toujours BigDecimal + RoundingMode.HALF_UP pour les montants
### Normes CEMAC/OHADA
- Salaire journalier : base 30 jours/mois
- Arrondi FCFA : 0 decimale, HALF_UP
- Conge annuel : 24 jours/an minimum legal
### DigiErpCalculs — methodes disponibles
```
joursEntreInclus(debut, fin)      // calendaires inclusif (JAMAIS Period.getDays())
joursEntreExclus(debut, fin)      // calendaires exclusif
moisEntres(debut, fin)            // mois complets
anneesEntres(debut, fin)          // annees completes
joursOuvrables(debut, fin)        // lundi-vendredi
seChevauche(d1,f1,d2,f2)         // chevauchement periodes
estDansPeriode(date, debut, fin)  // date dans periode
prorata(montant, jours, total)    // prorata annuel
appliquerTaux(montant, taux)      // % d un montant
arrondir(montant)                 // 2 decimales HALF_UP
arrondirFCFA(montant)             // 0 decimale (norme CEMAC)
salaireJournalier(mensuel)        // base 30j (norme CEMAC)
salaireJournalierOhada(m, jours)  // base jours ouvrables reels
```

---

## 2. VALIDATIONS METIER — STANDARD OBLIGATOIRE

```java
// Dans TOUS les modules avec dates/periodes, dans cet ordre :
validerDates(debut, fin);           // fin > debut (strict)
validerDatesFutures(debut, fin);    // debut >= aujourd hui (si planifie)
validerChevauchement(id, d, f, x);  // pas de doublon

if (!fin.isAfter(debut)) throw new RhBusinessException("...");
if (debut.isBefore(LocalDate.now())) throw new RhBusinessException("...");
if (repo.countChevauchements(id, debut, fin, excludeId) > 0)
    throw new RhBusinessException("...");
long nb = DigiErpCalculs.joursEntreInclus(debut, fin);
if (type.getDureeMax() != null && nb > type.getDureeMax())
    throw new RhBusinessException("Duree " + nb + "j > max " + type.getDureeMax() + "j");

// Commentaire obligatoire sur tout rejet
if (commentaire == null || commentaire.isBlank())
    throw new RhBusinessException("Le motif de rejet est obligatoire");
```

---

## 3. GARDE-FOU VISIBILITE (ContexteUtilisateurService)

```java
// Dans TOUS les services transactionnels :
@Transactional(readOnly = true)
public ApiResponse<...> lister(...) {
    if (!contexte.estAdminOuRH()) {
        Long employeId = contexte.getEmployeIdObligatoire();
        return listerParEmploye(employeId, ...);
    }
    // Admin/RH -> acces global
}
```

**Modules avec garde-fou applique (28/05/2026) :**
- AbsDemandeService : OK
- RhEmployeService : OK — findById() protege
- ContratService : OK — listerParEmploye() + obtenirContratActif() proteges
- RhConjointService : OK — findByEmployeId() + findById() proteges
- RhEnfantService : OK — findByEmployeId() + findById() proteges
```java
// Pattern injection (Boolean objet, pas boolean primitif) :
// MAUVAIS : m.isActif()
// CORRECT : Boolean.TRUE.equals(m.getActif())
```

---

## 4. PERIMETRE SECURITE (PerimetreService — Deny by default)

```java
// Verification acces par perimetre
perimetreService.peutAcceder(utilisateurId, orgId, siteId, serviceId)

// ADMIN et AUDITEUR : toujours true (acces total)
// Autres roles : true seulement si perimetre configure et correspond

// Filtrage listes
List<Long> sites = perimetreService.getSitesAccessibles(utilisateurId);
// vide = pas de restriction (admin/auditeur)
// non vide = filtrer par ces sites uniquement
```

### Resolution workflow par perimetre
```
Priorite decroissante :
  3 = type_doc + org + site + service
  2 = type_doc + org + site
  1 = type_doc + org
  0 = type_doc global (fallback — TOUJOURS present)
```

### Pattern verifierPerimetreEmploye() dans les services
```java
private void verifierPerimetreEmploye(Long employeCibleId) {
    contexte.getUtilisateurConnecte().ifPresent(u -> {
        affectationRepo.findByEmployeIdAndPrincipaleTrue(employeCibleId)
            .ifPresent(aff -> {
                Long serviceId = aff.getPoste().getService().getId();
                Long siteId    = aff.getPoste().getService().getSite().getId();
                Long orgId     = aff.getPoste().getService().getSite().getOrganisation().getId();
                if (!perimetreService.peutAcceder(u.getId(), orgId, siteId, serviceId)) {
                    throw new RhBusinessException("Acces refuse : employe hors perimetre");
                }
            });
    });
}
```

---

## 5. NOTIFICATIONS (NotificationService — V400)

```java
// API principale
notificationService.notifier(
    "ABSENCE_SOUMISE",           // evenement
    destinataireId,               // ID utilisateur
    Map.of(                       // variables pour le template
        "nom_employe", "Jean Kamga",
        "type_absence", "Conge annuel",
        "date_debut", "01/06/2026"
    ),
    "ABSENCE",                    // type lien
    absDemandeId                  // ID document lie
);

// Messagerie interne directe
notificationService.envoyerInterne(destinataireId, sujet, corps, typeLien, docId);
```

### Evenements disponibles
```
ABSENCE_SOUMISE, ABSENCE_APPROUVEE, ABSENCE_REJETEE, ABSENCE_ANNULEE,
WF_ETAPE_EN_ATTENTE, WF_APPROUVE, WF_REJETE, WF_DELEGATION_RECUE,
EXPLICATION_EMISE, MESURE_APPROUVEE,
CONTRAT_EXPIRE_J30, CONTRAT_EXPIRE_J7, COMPTE_CREE, DELAI_REPONSE_DEPASSE
```

### Variables templates par evenement
```
ABSENCE_SOUMISE     : nom_employe, matricule, type_absence, date_debut, date_fin, nb_jours, etape_wf
ABSENCE_APPROUVEE   : nom_employe, type_absence, date_debut, date_fin, nb_jours
ABSENCE_REJETEE     : nom_employe, type_absence, date_debut, date_fin, commentaire_wf
WF_ETAPE_EN_ATTENTE : nom_employe, matricule, etape_wf
MESURE_APPROUVEE    : nom_employe, type_mesure
```

### WebSocket frontend (IMPLEMENTE)
```
useNotifications.jsx : WebSocket STOMP + polling fallback 30s
Canal individuel : /user/{login}/queue/notifications
Badge non lus : /user/{login}/queue/badge
NotificationsPanel.jsx : panneau lateral branche dans AppLayout
```

### Toujours entourer de try/catch
Les notifications ne doivent JAMAIS bloquer le flux metier.

---

## 6. GENERATION DE CODES (CodeSequenceService — V006)

### Pattern d appel
```java
// Generer un code pour un employe d un site specifique
String code = codeSequenceService.generer("EMPLOYE", siteId);
// Retourne : DLA-2026-00003 (Douala) ou BAF-2026-00002 (Bafoussam)
// Fallback : EMP-2026-00001 si pas de sequence pour ce site

// Generer un code global (sans site)
String code = codeSequenceService.generer("POSTE", null);
// Retourne : PST-042
```

### Template tokens
```
{PREFIXE}   -> prefixe de la sequence
{ANNEE}     -> annee courante (4 chiffres)
{SEQ:N}     -> numero sequentiel sur N chiffres (zero-padded)
```

### Regle cle
count() apres soft-delete cause des doublons.
TOUJOURS utiliser erp_sequence_code avec valeur_actuelle incrementee.
L ancienne methode MAX(matricule) est remplacee par CodeSequenceService.

---

## 7. STANDARDS PAGE FRONTEND

### Checklist obligatoire
- locales/fr/{module}.json + locales/en/{module}.json — TOUTES les cles
- Namespace dans i18n/index.js
- node check-i18n.cjs -> 0 probleme avant commit
- usePermissions sur tous les boutons
- Archives : purge via /purger (pas DELETE standard)
- ConfirmModal pour suppression avec avecMotif=true, motifRequired=true
### Composants partages obligatoires
```
- Breadcrumb : toujours en haut de page
- TableFilters : onSearch/onFilter/onReset/filterOptions
- Modal : isOpen/onClose/title/size
- FormInput : value/onChange/error/required/hint
- FormSelect : value/onChange/options/error/required/placeholder
- ConfirmModal : isOpen/onClose/onConfirm/title/message/type/avecMotif/motifRequired
- useToast : { succes, erreur }
- usePermissions : { peutFaire(module, action) }  <- DEUX arguments separement !
- useAuth : { user, logout, isAuthenticated }
```

### RBAC sur les boutons
```javascript
// MAUVAIS : peutFaire('RH.PERIMETRE:CONFIGURER')  -> retourne toujours false
// CORRECT : peutFaire('RH.PERIMETRE', 'CONFIGURER')
```

### Options dynamiques avec libelle admin
```javascript
.map(tp => ({ // i18n-ok
  value: String(tp.id), label: tp.libelle,
}))
```

### Traduction libelles avec fallback
```javascript
{t('module:types.' + item.code, { defaultValue: item.libelle })}
```

### Donnees de l API
```javascript
const items = r.data?.data?.contenu ?? r.data?.data ?? []
```

### i18n dans sous-composants
Chaque composant fils utilisant t() doit declarer son propre useTranslation.
NE PAS passer t en prop depuis le parent.
```javascript
function MonComposant({ ...props }) {
  const { t } = useTranslation(['common', 'mon-namespace'])
  // ...
}
```

---

## 8. STANDARDS UX FORMULAIRES

### Dates debut/fin toujours sur la meme ligne
```jsx
<div className='grid grid-cols-2 gap-4'>
  <FormInput label='Date de debut' type='date' ... />
  <FormInput label='Date de fin'   type='date' ... />
</div>
```

### Calcul bidirectionnel debut + fin + nb_jours
```javascript
const calculerFin = (debut, nbJours) => {
  if (!debut || !nbJours) return ''
  const d = new Date(debut)
  d.setDate(d.getDate() + Number(nbJours))
  return d.toISOString().split('T')[0]
}
const calculerNbJours = (debut, fin) => {
  if (!debut || !fin) return ''
  const diff = (new Date(fin) - new Date(debut)) / (1000 * 60 * 60 * 24)
  return diff > 0 ? String(Math.round(diff)) : ''
}
```

### Validation dates — regle obligatoire dans tous les formulaires
```javascript
if (form.dateFin && form.dateDebut && form.dateFin <= form.dateDebut) {
  setErreur(t('common:date_fin_avant_debut')); return
}
```

### Reinitialisation champs enfants si type change
```javascript
setForm(p => ({ ...p, typeMesure: val, dateDebut: '', dateFin: '', nbJours: '' }))
```

### Filtrage cascade parent -> enfant
```javascript
const regionsFiltrees = pays ? regions.filter(r => r.paysId === Number(pays)) : []
```

---

## 9. BACKEND — STRUCTURE MODULE

### Pattern obligatoire par module
```
Entity -> Repository -> Service -> Controller
+ DTO (Request, Response, SummaryResponse)
+ Archives (restaurer + purger)
```

### Entite
- Heriter de RhBaseEntity
- Parametrage : PAS de @SQLRestriction ni @SQLDelete
- Transactionnel : @SQLRestriction("actif = true") + @SQLDelete
- version BIGINT NOT NULL DEFAULT 0 (jamais INTEGER)
- RhBusinessException pour toutes les erreurs metier (jamais RuntimeException)
- Boolean objet (pas boolean primitif) -> getActif() pas isActif()
- Boolean.TRUE.equals(m.getActif()) pour eviter NullPointerException
### Repository — methodes obligatoires
```java
List<E> findAllByActifTrueOrderByOrdreAffichageAscLibelleAsc();

@Query(value = "SELECT * FROM table WHERE actif = false ORDER BY date_suppression DESC",
       nativeQuery = true)
List<E> findAllArchives();

@Query(value = "SELECT * FROM table WHERE id = :id", nativeQuery = true)
Optional<E> findByIdIgnoreActif(@Param("id") Long id);

@Modifying
@Query(value = "DELETE FROM table WHERE id = :id", nativeQuery = true)
void purgerById(@Param("id") Long id);
```

### Standards endpoints
```
GET    /api/{module}/{entite}s              -> lister
GET    /api/{module}/{entite}s/{id}         -> detail
POST   /api/{module}/{entite}s              -> creer
PUT    /api/{module}/{entite}s/{id}         -> modifier
DELETE /api/{module}/{entite}s/{id}         -> supprimer (soft)
GET    /api/{module}/{entite}s/archives     -> lister archives
POST   /api/{module}/{entite}s/{id}/restaurer -> restaurer
DELETE /api/{module}/{entite}s/{id}/purger    -> supprimer definitif
POST   /api/{module}/{entite}s/rechercher     -> recherche avancee
GET    /api/{module}/{entite}s/export/excel   -> export
```

---

## 10. FLYWAY — ORDRE STANDARD

```sql
-- 1. ALTER TABLE existantes
-- 2. Tables parametrage
-- 3. Tables transactionnelles
-- 4. Tables historisation
-- 5. FK croisees (ALTER TABLE ADD CONSTRAINT)
-- 6. Index
-- 7. Donnees de reference (ON CONFLICT DO NOTHING)
-- 8. erp_module + erp_action
-- 9. erp_permission
-- JAMAIS INSERT dans erp_utilisateur_role (fait dans InitialisationDonnees)
-- version BIGINT (jamais INTEGER)
-- migration_backup_archive/ hors de src/main/resources
```

### Nomenclature
```
V001-V099 : core (schema, geo, securite, workflow, audit, sequences)
V100-V399 : modules RH (schema, permissions, refs, donnees_test, modeles_wf)
V400-V499 : notifications
V500-V599 : donnees de test perimetres
```

---

## 11. WORKFLOW — INTEGRATION STANDARD

### Pattern integration WorkflowService dans un service metier
```java
// 1. Injections obligatoires
private final WorkflowService           workflowService;
private final WfDecisionRepository      decisionRepo;
private final NotificationService       notificationService;
private final RhUtilisateurRepository   utilisateurRepo;
private final RhAffectationRepository   affectationRepo;
private final PerimetreService          perimetreService;
private final ContexteUtilisateurService contexte;

// 2. soumettre()
WfInstanceEntity instance = workflowService.demarrer(
    "TYPE_DOC",  // doit exister dans wf_type_document
    documentId, employeId
);
document.setStatut("EN_WORKFLOW");
document.setInstanceWorkflowId(instance.getId());
notifierValideurs(instance, document);

// 3. decider()
Long acteurId = contexte.getUtilisateurIdObligatoire(); // STANDARD workflow : rh_utilisateur.id (PAS employe_id)
WfDecisionEntity.Statut statut = WfDecisionEntity.Statut.valueOf(req.getStatut());
WfInstanceEntity instance = workflowService.decider(instanceId, acteurId, statut, commentaire);

if (APPROUVE) { document.setStatut("APPROUVEE"); notifierEmploye(document, "EVT_APPROUVE"); }
if (REJETE)   { document.setStatut("REJETEE");   notifierEmploye(document, "EVT_REJETE"); }
else          { notifierValideurs(instance, document); }
```

### Modes validation wf_etape
```
SEQUENTIEL   : nbValides >= 1 (1 acteur suffit)
PARALLELE_ET : nbValides >= nbTotal (unanimite)
PARALLELE_OU : nbValides >= nbValidateursRequis (N parmi M)
```

### 5 types acteurs
```
SUPERIEUR_DIRECT     : poste principal -> lien HIERARCHIQUE organigramme
SUPERIEUR_FONCTIONNEL: lien FONCTIONNEL dans organigramme
ROLE                 : utilisateurs ayant le roleCode, filtres par perimetre
SERVICE              : CHEF_SERVICE/DIRECTEUR du service employe
UTILISATEUR          : ID fixe (Long.parseLong(etape.acteurValeur))
```

### DeciderRequest DTO standard
```
statut : "VALIDE" ou "REJETE" (majuscules obligatoires)
commentaire : optionnel sauf si REJETE
```

### Frontend — adaptation service pour /decider
```javascript
decider: (id, data) => api.post(`/rh/module/${id}/decider`, data),

case 'valider':
case 'approuver': await service.decider(id, { statut: 'VALIDE', commentaire: payload.commentaire }); break
case 'rejeter':   await service.decider(id, { statut: 'REJETE', commentaire: payload.commentaire }); break
```

---

## 12. WORKFLOW ADMIN — ENDPOINTS

Permission requise : RH.WORKFLOW:CONFIGURER

```
GET    /api/workflow/modeles              -> liste tous les modeles actifs
GET    /api/workflow/modeles/{id}         -> detail modele + etapes
POST   /api/workflow/modeles              -> creer modele
PUT    /api/workflow/modeles/{id}         -> modifier modele
DELETE /api/workflow/modeles/{id}         -> desactiver modele (body: {motif})
POST   /api/workflow/modeles/{id}/etapes  -> ajouter etape
PUT    /api/workflow/modeles/etapes/{eid} -> modifier etape
DELETE /api/workflow/modeles/etapes/{eid} -> supprimer etape
```

### Frontend WorkflowModelesPage
- Liste groupee par module avec filtres boutons
- BadgeMode (SEQUENTIEL=bleu, PARALLELE_ET=violet, PARALLELE_OU=orange)
- BadgePerimetre (priorite 0=gris, 1=vert, 2=bleu, 3=violet)
- Panel slide-over etapes avec circuit visuel (cercles numerotes + connecteurs)

---

## 13. PERIMETRES UTILISATEURS — ENDPOINTS

Permission requise : RH.PERIMETRE:*

```
GET    /api/administration/perimetres                    -> liste utilisateurs + perimetres
GET    /api/administration/perimetres/utilisateur/{id}   -> perimetres d un utilisateur
GET    /api/administration/perimetres/options            -> selects (roles, orgs, sites, services)
GET    /api/administration/perimetres/archives           -> perimetres archives
POST   /api/administration/perimetres                    -> creer perimetre
PUT    /api/administration/perimetres/{id}               -> modifier dates
DELETE /api/administration/perimetres/{id}               -> supprimer (body: {motif})
POST   /api/administration/perimetres/{id}/restaurer     -> restaurer
DELETE /api/administration/perimetres/{id}/purger        -> purge physique
```

### Frontend PerimetresPage
- Tableau utilisateurs avec statut acces (Acces refuse / Acces configure)
- Panel slide-over Gerer : liste perimetres + ajout + retrait
- Selects cascades : org -> site -> service (filtrage parentId)
- Dates debut/fin optionnelles (NULL = permanent)
- Badge BadgeRole colore par role (ADMIN=rouge, GESTIONNAIRE_RH=bleu, etc.)

---

## 14. PIPELINE CI/CD GITLAB (30/05/2026)

### Configuration
- Branche source : DigiErp-Spring-React
- Branche deploiement : DigiErp-Spring-React-Development
- Fichier : .gitlab-ci.yml a la racine du projet
- Stages : test, build, deploy
### Procedure de deploiement serveur
```bash
# Sur le serveur, apres git pull
cd ~/git/digierp

# Si migration Flyway modifiee
docker compose down -v

# Toujours
docker compose build --no-cache
docker compose up -d
sleep 45
docker compose logs backend 2>&1 | grep -iE "successfully applied|error" | tail -5
```

### Vider cache navigateur
Obligatoire apres chaque deploiement frontend :
Ctrl+Shift+R (Chrome/Edge) — Vite genere de nouveaux noms de fichiers.

### Deux remotes Git
```bash
git remote -v
# origin = gitlab.biapay.net (remote principal)
# perso  = github.com (backup personnel)

git push origin DigiErp-Spring-React
git push perso DigiErp-Spring-React
```

---

## 15. MODULES — STATUT

| Module | Prefixe | RBAC | Backend | Frontend |
|--------|---------|------|---------|----------|
| Employes | rh_ | RH.EMPLOYE | OK | OK |
| Postes | rh_ | RH.POSTE | OK | OK |
| Contrats | cnt_ | RH.CONTRAT | OK | OK |
| Organisation/Site | rh_ | RH.ORGANISATION | OK | OK |
| Organigramme | rh_ | RH.ORGANIGRAMME | OK | OK (arbre recursif) |
| Workflow | wf_ | RH.WORKFLOW | OK + mode_validation | OK |
| Workflow Admin | wf_ | RH.WORKFLOW:CONFIGURER | OK | OK |
| Absences | abs_ | RH.ABSENCE | OK | OK |
| Discipline | disc_ | RH.DISCIPLINE | OK | OK |
| Perimetre Admin | erp_ | RH.PERIMETRE | OK | OK |
| Notifications | notif_ | — | OK | OK |
| Sequences Codes | erp_ | — | OK (30/05) | A faire |
| Missions | mis_ | RH.MISSION | A faire | A faire |
| Recrutement | rec_ | RH.RECRUTEMENT | A faire | A faire |
| Formation | for_ | RH.FORMATION | A faire | A faire |
| Paie | pai_ | RH.PAIE | A faire | A faire |
| Prets | prt_ | RH.PRET | A faire | A faire |
| Stages | stg_ | RH.STAGE | A faire | A faire |

---

## 16. FONCTIONNALITES TRANSVERSES — STATUT

### Fait
- Recherche/filtrage (TableFilters, SearchRequest) : OK
- Tri colonnes (useSortableTable) : OK
- Pagination (Page/pageable Spring) : OK
- Export Excel (useExport, /export/excel) : OK
- Archives/soft delete + restauration + purge : OK
- Visibilite par role (ContexteUtilisateurService) : OK
- Perimetre securite Deny by default : OK backend + frontend
- Notifications WebSocket + email : OK backend + frontend
- Workflow parametrable + mode validation : OK
- Admin modeles workflow : OK
- Admin perimetres : OK
- Generation codes par site : OK (CodeSequenceService)
- Pipeline CI/CD : OK (GitLab)
### A faire
- Import Excel/CSV avec validation
- Pieces jointes (upload CV, CNI, contrats, justificatifs)
- Tableau de bord RH avec indicateurs cles
- Interface admin sequences de codes
- Connecter moteur codes aux autres modules (Absences, Discipline, Contrats)

---

## 17. SECURITE — RAPPELS

- Login : identifiant=admin, motDePasse=Admin@2025
- Port backend : 8090, frontend : 5173, mailhog UI : 8025
- Role admin Spring : ROLE_ADMIN_RH
- estAdminOuRH() verifie ADMIN + GESTIONNAIRE_RH dans ContexteUtilisateurService
- ADMIN et AUDITEUR : exempts de perimetre (acces total)
- Autres roles : Deny by default (acces refuse sans perimetre)
- WebSocket endpoint : /ws (SockJS), JWT valide a la connexion
- CONSULTER supprime (28/05/2026) — utiliser uniquement LIRE
- JWT secret externalise via variable d environnement Docker
- BCrypt : hash genere dynamiquement dans InitialisationDonnees (jamais en dur)

---

## 12. WORKFLOW — HARDENING V2 (31/05/2026)

### WorkflowResultat — nouveau contrat de retour de decider()
```java
// decider() retourne WorkflowResultat, plus WfInstanceEntity
WorkflowResultat resultat = workflowService.decider(
    instanceId, acteurId, statut, commentaire);

if (resultat.estApprouve()) { document.setStatut("APPROUVEE"); }
if (resultat.estRejete())   { document.setStatut("REJETEE"); }
if (resultat.estEnCours())  { /* étape intermédiaire */ }

// Accès aux infos utiles
resultat.getInstanceId()      // Long
resultat.getEtapeCourante()   // int
resultat.getLibelleEtape()    // String
resultat.getCommentaire()     // String (si rejet)
```

### Race condition éliminée — findByIdForUpdate()
```java
// WorkflowService.decider() utilise désormais un verrou pessimiste
// PostgreSQL : SELECT ... FOR UPDATE
// Analogie Laravel : WfInstance::lockForUpdate()->findOrFail($id)
// Sans ce verrou : 2 clics simultanés = double avancement d étape
// Avec ce verrou : le 2ème thread attend que le 1er committe
```

### Rejet immédiat — règle standard
Tout rejet clôture immédiatement l instance,
quel que soit le mode (SEQUENTIEL, PARALLELE_ET, PARALLELE_OU).
Standard SAP/Odoo : un seul opposant suffit.
Les décisions EN_ATTENTE des co-validateurs passent à ANNULE.

### Statut ANNULE dans WfDecisionEntity.Statut
EN_ATTENTE : décision attendue
VALIDE     : acteur a validé
REJETE     : acteur a rejeté (commentaire obligatoire)
DELEGUE    : acteur a délégué
ANNULE     : annulée automatiquement (étape franchie ou rejet co-validateur)
EXPIRE     : délai dépassé

### WfNotificationHelper — API centralisée
```java
// Injection dans tout service métier
private final WfNotificationHelper wfNotificationHelper;

// 1. Notifier les valideurs (à la soumission ou étape suivante)
wfNotificationHelper.notifierValideurs(
    instance.getId(),
    instance.getEtapeCourante(),
    "WF_ETAPE_EN_ATTENTE",          // ou événement spécifique du module
    Map.of(
        "nom_employe", employe.getNomComplet(),
        "matricule",   employe.getMatricule(),
        "etape_wf",    "Validation N+1",
        "app_url",     APP_URL
    ),
    "MISSION",                       // typeLien = nom du module en majuscules
    documentId
);

// 2. Notifier l employé (après approbation ou rejet)
wfNotificationHelper.notifierEmploye(
    employe.getId(),
    "MISSION_APPROUVEE",
    Map.of("nom_employe", employe.getNomComplet(), ...),
    "MISSION",
    documentId
);

// 3. Notifier un userId direct (délégation, admin)
wfNotificationHelper.notifierUtilisateurDirect(
    userId, evenement, variables, typeLien, documentId);
```

### Pattern complet decider() dans un service métier
```java
// Remplace les ~40 lignes copiées-collées dans chaque service
@Transactional
public ApiResponse<MaResponse> decider(Long id, DeciderRequest req, String utilisateur) {

    MonDocument doc = getOrThrow(id);
    if (!"EN_WORKFLOW".equals(doc.getStatut()))
        throw new RhBusinessException("Statut invalide : " + doc.getStatut());

    // STANDARD workflow : rh_utilisateur.id (PAS employe_id)
    Long acteurId = contexte.getUtilisateurIdObligatoire();

    WfDecisionEntity.Statut statutDecision =
        WfDecisionEntity.Statut.valueOf(req.getStatut().toUpperCase());

    WorkflowResultat resultat = workflowService.decider(
        doc.getInstanceWorkflowId(), acteurId, statutDecision, req.getCommentaire());

    String avant = doc.getStatut();

    if (resultat.estApprouve()) {
        doc.setStatut("APPROUVEE");
        enregistrerHistorique(id, avant, "APPROUVEE", req.getCommentaire(), utilisateur);
        wfNotificationHelper.notifierEmploye(
            doc.getEmployeId(), "MODULE_APPROUVE",
            buildVars(doc), "MODULE", id);

    } else if (resultat.estRejete()) {
        doc.setStatut("REJETEE");
        enregistrerHistorique(id, avant, "REJETEE", req.getCommentaire(), utilisateur);
        wfNotificationHelper.notifierEmploye(
            doc.getEmployeId(), "MODULE_REJETE",
            buildVars(doc), "MODULE", id);

    } else {
        // Étape intermédiaire — notifier les valideurs suivants
        enregistrerHistorique(id, avant, doc.getStatut(),
            "Étape " + resultat.getEtapeCourante(), utilisateur);
        wfNotificationHelper.notifierValideurs(
            resultat.getInstanceId(), resultat.getEtapeCourante(),
            "WF_ETAPE_EN_ATTENTE", buildVars(doc), "MODULE", id);
    }

    monRepository.save(doc);
    return ApiResponse.ok(toResponse(doc), "Décision enregistrée");
}
```

### wf_relance_config — configuration des relances automatiques
```sql
-- Ajouter une config de relance pour un nouveau module
INSERT INTO wf_relance_config
    (module, type_document, delai_heures, max_relances, evenement_notif, actif, cree_par)
VALUES
    ('MON_MODULE', NULL, 24, 2, 'WF_ETAPE_EN_ATTENTE', true, 'SYSTEM');
-- delai_heures : délai avant 1ère relance
-- max_relances : nombre max de relances (après = EXPIRE)
```

### Événements de notification disponibles par module (V105)
MISSION    : MISSION_SOUMISE, MISSION_APPROUVEE, MISSION_REJETEE
PRET       : PRET_SOUMIS, PRET_APPROUVE, PRET_REJETE
STAGE      : STAGE_SOUMIS, STAGE_APPROUVE, STAGE_REJETE
RECRUTEMENT: RECRUTEMENT_OFFRE_SOUMISE, RECRUTEMENT_OFFRE_APPROUVEE
FORMATION  : FORMATION_INSCRIPTION_SOUMISE, FORMATION_INSCRIPTION_APPROUVEE
GENERIQUE  : WF_ETAPE_EN_ATTENTE (tous modules, tous canaux)

---

## 9. NORME ONCHANGE FORMULAIRES (v3 — DÉFINITIF)

### Règle unique
FormInput ET FormSelect émettent un ÉVÉNEMENT DOM natif (comme un <input> HTML).
Tous les handlers utilisent e.target.value.

### Fonction gererChangement() — handler générique (formulaires avec name=)
```javascript
const gererChangement = (e) => {
  const { name, value } = e.target
  setForm(prev => ({ ...prev, [name]: value }))
  if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }))
}
```
Usage : <FormInput name="libelle" onChange={gererChangement} />

### Handler ciblé (formulaires sans name= ou logique spéciale)
```javascript
<FormInput onChange={(e) => changer('dateDebut', e.target.value)} />
<FormSelect onChange={(e) => changer('typeId', e.target.value)} />
```

### Checkbox natif
```javascript
<input type="checkbox" onChange={(e) => changer('actif', e.target.checked)} />
```

### INTERDIT
```javascript
// ❌ NE JAMAIS FAIRE
onChange={(val) => changer('champ', val)}   // val = Event, pas une string !
onChange={val => changer('champ', val)}      // idem
```
---

## 10. STANDARD PAGINATION — RÈGLE DÉFINITIVE (13/06/2026)

### Quand intégrer une pagination
Toute page affichant une liste transactionnelle (employés, contrats,
postes, absences, discipline...) DOIT utiliser le composant Pagination.
Seuls les référentiels courts (< 200 éléments, types/catégories) peuvent
se passer de pagination.

### Checklist d'intégration obligatoire

**Hook use{Module}List :**
```javascript
// 1. Utiliser useListState
const listState = useListState({ triDefaut: 'xxx', ordreDefaut: 'asc' })

// 2. Exposer OBLIGATOIREMENT dans le return
return {
  // ...
  page:          listState.page,
  taille:        listState.taille,
  totalPages:    donneesXxx?.totalPages ?? 0,
  totalElements: donneesXxx?.totalElements ?? 0,
  setPage:       listState.setPage,
  changerTaille: listState.changerTaille,  // ← OBLIGATOIRE
  // ...
}
```

**Page {Module}Page :**
```jsx
// 3. Toujours passer onTailleChange
<Pagination
  page={liste.page}
  totalPages={liste.totalPages}
  totalElements={liste.totalElements}
  taille={liste.taille}
  onPageChange={liste.setPage}
  onTailleChange={liste.changerTaille}   // ← OBLIGATOIRE
/>
```

### Comportement du composant Pagination
- `totalElements === 0` → rien affiché
- `totalElements > 0` → sélecteur "Par page" TOUJOURS visible
- `totalPages > 1` → boutons de navigation affichés en plus
- Tailles disponibles : 10, 25, 50, 100
- Changement de taille → retour automatique à la page 0
### Mnémotechnique
> "Le sélecteur de taille est un contrôle utilisateur — toujours visible.
>  Les boutons de navigation sont conditionnels — uniquement si nécessaire."
---

## 11. STANDARD PAGES LISTE — CHECKLIST COMPLÈTE (13/06/2026)

Toute nouvelle page liste DOIT respecter cette checklist avant livraison.

### Checklist hook use{Module}List
- useListState avec triDefaut/ordreDefaut/statutDefaut
- useApi avec endpoint + permission + params
- Return explicite (jamais spread en page) avec :
  page, taille, tri, ordre, recherche, filtreStatut
  setPage, changerTri, changerRecherche, changerStatut
  changerTaille (OBLIGATOIRE — sélecteur pagination)
  reinitialiser, iconeTri, classesTri, params
  totalPages, totalElements, loading, charger
  archives: { data, loading, page, totalPages, totalElements,
    peutRestaurer, peutPurger, charger,
    confirmerRestaurer, confirmerPurger,
    setConfirmerRestaurer, setConfirmerPurger,
    handleRestaurer, handlePurger }
- Si useApiMultiple (référentiels) : ajouter useEffect race condition
  useEffect(() => { const t = setTimeout(() => charger(), 300); return () => clearTimeout(t) }, [])
### Checklist page {Module}Page
- import Pagination from shared/ui/Pagination
- import Breadcrumb, TableFilters
- État modeArchives + basculerArchives()
- Pagination avec TOUTES les props :
  page, totalPages, totalElements, taille
  onPageChange={liste.setPage}
  onTailleChange={liste.changerTaille} (OBLIGATOIRE)
- Zéro useEffect manuel dans la page
- Zéro logique métier dans la page
### Modules conformes (13/06/2026)
- Postes   : hook + page conformes
- Employes : hook + page conformes
- Contrats : hook + page conformes + fix race condition

---

## STANDARDS SESSION 16 — 25/06/2026

### CONVENTION CRITIQUE — deux IDs distincts

```java
// rh_employe.id    → données métier (créer demande, lire dossier)
Long employeId     = contexte.getEmployeIdObligatoire();

// rh_utilisateur.id → workflow uniquement (wf_decision.acteur_id)
Long utilisateurId = contexte.getUtilisateurIdObligatoire();
```

JAMAIS confondre les deux. Vérifiable dans V001 :
```sql
-- wf_decision.acteur_id FK → rh_utilisateur(id)
-- PAS rh_employe(id)
```

---

### PATTERN STANDARD — resolveEmployeId() avec moduleCode

TOUJOURS passer le moduleCode pour utiliser EMETTRE_TIERS :
```java
// ✅ STANDARD — utilise permission PBAC granulaire
Long employeId = contexte.resolveEmployeId(req.getEmployeId(), "RH.ABSENCE");
Long employeId = contexte.resolveEmployeId(req.getEmployeId(), "RH.DISCIPLINE");

// ❌ DÉPRÉCIÉ — fallback sur estAdminOuRH() trop large
Long employeId = contexte.resolveEmployeId(req.getEmployeId());
```

---

### PATTERN STANDARD — estAdminOuRH() via PBAC

`estAdminOuRH()` utilise `erp_utilisateur_role` (PBAC), PAS Spring Security :
```java
// ✅ CORRECT — tous les comptes ont ROLE_EMPLOYE en Spring Security
// seul erp_utilisateur_role reflète le vrai rôle métier du poste
public boolean estAdminOuRH() {
    return getUtilisateurConnecte()
        .map(u -> erpRoleRepo.findRolesActifs(u.getId())
            .stream()
            .map(ur -> ur.getRole().getCode())
            .anyMatch(superRoleService::estSuperRole))
        .orElse(false);
}

// ❌ INTERDIT — auth.getAuthorities() = toujours ROLE_EMPLOYE pour tous
auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().contains("ADMIN"))
```

---

### PATTERN STANDARD — WfAutorisationException

Toujours lever `WfAutorisationException` (jamais `IllegalStateException`) :
```java
// ✅ STANDARD
throw WfAutorisationException.acteurNonDesigne(acteurId, etape);
throw WfAutorisationException.instanceCloturee();
throw WfAutorisationException.delegationImpossible();
throw new WfAutorisationException("Message métier clair");

// ❌ INTERDIT
throw new IllegalStateException("Cet acteur n'est pas autorisé...");
// → mappé en 500 au lieu de 403
```

GlobalExceptionHandler :
```java
WfAutorisationException → 403 (règle workflow)
RhBusinessException     → 422 (règle métier)
AccessDeniedException   → 403 (permission PBAC)
// NE PAS utiliser IllegalStateException pour les règles métier
```

---

### PATTERN STANDARD — Séparation calcul/lecture compteurs

Standard ERP (SAP/Odoo) : les compteurs sont des données persistées,
mis à jour par des événements métier, jamais recalculés à la volée.

```java
// ✅ STANDARD — recalculer aux bons moments
creer()   → recalculerUnType() // jours_en_attente ↑
decider() approuvé → recalculerUnType() // jours_pris ↑, en_attente ↓
decider() rejeté   → recalculerUnType() // en_attente ↓
annuler()          → recalculerUnType() // en_attente ↓
supprimer()        → recalculerUnType() si avait jours en attente

// ❌ INTERDIT — recalcul en lecture = INSERT dans @Transactional(readOnly=true)
@Transactional(readOnly = true)
public Response obtenir(Long id) {
    absDroitCalculService.recalculerUnType(...); // → ERROR: read-only transaction
}

// ✅ obtenir() = lecture seule du compteur existant
private String construireAvertissementSolde(...) {
    return absCompteurRepo.findBy...(...) // SELECT pur, jamais INSERT
}
```

---

### PATTERN STANDARD — acteurAttenduUtilisateurId dans SummaryResponse

Tout module avec workflow DOIT retourner `acteurAttenduUtilisateurId`
dans son `SummaryResponse` pour que le frontend conditionne les boutons :

```java
// Dans toSummaryResponse()
.acteurAttenduUtilisateurId(
    "EN_WORKFLOW".equals(d.getStatut()) && d.getInstanceWorkflowId() != null
        ? wfDecisionRepo.findFirstByInstanceIdAndStatut(
            d.getInstanceWorkflowId(), WfDecisionEntity.Statut.EN_ATTENTE)
          .map(WfDecisionEntity::getActeurId)
          .orElse(null)
        : null)
```

Frontend — conditionner les boutons :
```javascript
// STANDARD DigiERP — 3 conditions obligatoires
const peutDeciderCetteDemande = (d) =>
  peutValider &&                                           // 1. permission globale
  d.acteurAttenduUtilisateurId != null &&                 // 2. valideur désigné existe
  d.acteurAttenduUtilisateurId === user.utilisateurId     // 3. c'est moi

// JAMAIS
{peutValider && <button>Valider</button>}  // ← apparaît sur TOUTES les demandes EN_WORKFLOW
```

---

### PATTERN STANDARD — Gestion erreurs frontend (erreurs.js)

```javascript
// shared/utils/erreurs.js — TOUJOURS importer dans les composants
import { extraireMessageErreur } from '../../../shared/utils/erreurs'

// Dans TOUS les catch
} catch (erreurCatch) {
  setErreur(extraireMessageErreur(erreurCatch, t('module:erreur_generique')))
}

// JAMAIS
} catch (e) { setErreur(e.message) }           // variable non standard
} catch (err) { console.error(err) }            // catch silencieux
} catch (erreurCatch) { setErreur(e.message) }  // mauvaise variable
```

---

### PATTERN STANDARD — resoudreSupereurDirect() défensif

`WorkflowService.resoudreSupereurDirect()` DOIT lever `RhBusinessException`
si la chaîne hiérarchique est incomplète — jamais retourner `employeId` comme fallback :

```java
// ✅ STANDARD — message clair, pas de FK violation
if (affPrincipale.isEmpty()) {
    throw new RhBusinessException(
        "Workflow impossible : cet employé n'a pas d'affectation principale active.");
}

// ❌ DANGEREUX — employeId utilisé comme acteurId → FK violation wf_decision
if (affPrincipale.isEmpty()) {
    return employeId; // acteurId=employe_id ≠ rh_utilisateur.id → ERREUR 500
}
```

---

### PATTERN STANDARD — utilisateurId dans AuthContext

`AuthContext` stocke `utilisateurId` (rh_utilisateur.id) distinct de `employeId` :
```javascript
// auth-service retourne les deux dans le body login
const userData = {
  identifiant, roles, permissions, langueCode,
  employeId:     employeId     ?? null, // rh_employe.id
  utilisateurId: utilisateurId ?? null, // rh_utilisateur.id
}

// Usage frontend pour conditionner les boutons workflow
d.acteurAttenduUtilisateurId === user.utilisateurId
```
