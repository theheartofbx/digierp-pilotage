# STANDARDS BACKEND — DigiERP v2
# Version : 06/06/2026 — Rev 2 (multitenancy + pagination enrichie)
# Rev 3 : 24/09/2026 — sections 29 à 32 (TypeSequence, code métier, recalage séquences, surcharges)
# Rev 4 : 28/09/2026 — sections 33 à 39 (RLS transactionnelle, politiques RLS, absences générées,
#         workflow, jobs, checklist) ; corrections des sections 2, 4, 5, 10 et 21
#         (RlsTransactionInterceptor supprimé, repositories des tables sous RLS transactionnels)
# Rev 5 : 29/09/2026 — sections 40 à 47 (politiques RLS standard à deux moteurs lecture/écriture,
#         capacité du moteur de workflow, politique de document, document lisible par un tiers,
#         référentiel des types et vérificateurs au démarrage, erreurs du client, campagne de
#         sécurité, checklist) ; mises à jour des sections 1, 2, 6, 9, 10, 12, 17, 20, 21, 22,
#         35 et 37 (lecture par la RLS seule, actions par la politique de document)
# Rev 6 : 29/09/2026 soir (commit c124e576) — §42 réécrite (règle unique sur un lecteur
#         photographié, actionsPermises, méthodes imposées par le compilateur) ; §48 (une seule
#         porte pour décider : constat et dette) ; mises à jour des sections 2, 17, 37, 46, 47
# Rev 7 : 30/09/2026 (commits c7d94fbe et fbf5656d) — §49 (donnée dérivée calculée à la
#         lecture ; agrégat sur une table sous RLS indépendant du lecteur : fonctions SECURITY
#         DEFINER à garde) ; mises à jour des sections 1, 4, 5, 10, 17, 36, 40 et 47
# Rev 8 : 05/10/2026 (commit eee5170e) — §50 (résumé d'un document pour « Mes tâches » :
#         point d'extension du moteur, contrat à deux niveaux liste / détail, registre,
#         liste de contrôle d'un module) ; §51 (compléments : circuit générique, garde
#         chargée avant l'ouverture du serveur, semis, politique d'écriture sans relecture
#         par l'id) ; mises à jour des sections 2, 17, 37, 44, 47 et 49
# Rev 9 : 05/10/2026 après-midi (commit 89ae754f) — dette 23 soldée : §51.4 réécrite (les DEUX
#         effets d'un CHECK qui relit sa propre table, correction de mis_mission, inventaire
#         calculé par la base) ; §51.5 (restreindre un droit d'écriture : inventaire des
#         chemins, dirty checking compris) ; §51.6 (preuve d'une politique d'écriture : écriture
#         d'essai en digierp_app + ROLLBACK, script à deux modes avant / après) ; mises à jour
#         des sections 17, 40 et 47
# Remplace : l'ancienne section backend de STANDARDS_PROJET.md

---

## 1. PRINCIPES FONDAMENTAUX

### Règles d'or
1. Le backend est la SEULE ligne de défense réelle — jamais faire confiance au frontend
2. Toute action sensible est vérifiée côté backend, indépendamment du frontend
3. Fail secure : en cas de doute, refuser (Deny by default)
4. Séparation stricte Controller / Service / Repository / Entity
5. Aucune logique métier dans les Controller, aucun appel SQL dans les Service
6. [Rev 4] Un défaut ne doit jamais être silencieux : préférer l'échec immédiat et explicite
   (exception, démarrage refusé) à une liste vide ou à un traitement qui « ne fait rien »
7. [Rev 5] LIRE = la RLS seule (politique de lecture) ; AGIR = PBAC (le rôle) + politique de
   document (CE document) + RLS d'écriture (filet en base, jamais ouverte à un valideur).
   Une règle d'accès n'est jamais écrite deux fois (Java ET SQL) : voir §40 à §42
8. [Rev 7] Une donnée DÉRIVÉE (solde, total, disponibilité) se calcule à la lecture, elle ne se
   stocke pas ; et un calcul qui AGRÈGE une table sous RLS donne le même résultat à tout lecteur
   autorisé à voir le document : la RLS filtre des listes, pas des totaux (voir §49)
### Séparation des responsabilités
Controller  → recevoir la requête HTTP, déléguer au service, retourner ApiResponse
Service     → logique métier, orchestration, validation, transactions
Repository  → accès données uniquement (JPA + requêtes natives si besoin)
Entity      → modèle de données JPA + méthodes métier simples (supprimer, restaurer)
DTO         → contrat d'API (jamais exposer les entités JPA directement)

[Rev 4] Un Controller n'injecte JAMAIS un repository d'une table sous RLS : il passe par un
service (voir §34). Les jobs planifiés non plus (voir §38).

---

## 2. STRUCTURE DES PACKAGES

### Structure globale
com.digierp.{module}/
├── {sousdomaine}/
│   ├── controller/
│   │   └── {Entite}Controller.java
│   ├── service/
│   │   ├── {Entite}Service.java
│   │   └── {Entite}Politique.java   ← [Rev 5] politique de document (§42)
│   ├── repository/
│   │   └── {Entite}Repository.java
│   ├── entity/
│   │   └── {Entite}.java
│   └── dto/
│       ├── {Entite}Request.java      ← données reçues (création/modification)
│       ├── {Entite}Response.java     ← données retournées (détail complet)
│       └── {Entite}SummaryResponse.java ← données retournées (liste)
└── shared/
    ├── api/
    │   ├── ApiResponse.java          ← enveloppe standard toutes réponses
    │   ├── PageResponse.java         ← enveloppe pagination standard
    │   ├── GlobalExceptionHandler.java
    │   ├── CorrelationIdFilter.java  ← ID unique par requête (traçabilité)
    │   ├── RhBusinessException.java  ← erreurs métier (422)
    │   ├── RhNotFoundException.java  ← entité introuvable ou invisible (404)
    │   ├── WfAutorisationException.java  ← acteur non désigné (403)
    │   └── RhAccesDocumentException.java ← [Rev 5] action refusée sur CE document (403)
    ├── entity/
    │   └── RhBaseEntity.java         ← colonnes audit communes + tenant_id
    ├── security/
    │   ├── SecurityConfig.java
    │   ├── JwtUtil.java
    │   ├── JwtAuthenticationFilter.java
    │   ├── JwtBlacklistService.java
    │   ├── RefreshTokenService.java  ← gestion refresh tokens
    │   ├── ContexteUtilisateurService.java
    │   ├── PolitiqueDocument.java    ← [Rev 5] interface des politiques de document (§42)
    │   └── LecteurDocument.java      ← [Rev 6] photographie du lecteur (§42)
    ├── rls/                          ← [Rev 4] voir §33, §34 ; [Rev 5] §40, §41, §44
    │   ├── RlsContexte.java                 ← contexte RLS du thread (ThreadLocal)
    │   ├── RlsContexteFilter.java           ← calcule le contexte de la requête HTTP
    │   ├── RlsJpaTransactionManager.java    ← applique le contexte à CHAQUE transaction
    │   ├── RlsConnectionCustomizer.java     ← DataSource digierp_app, session ANONYME
    │   ├── RlsHorsTransactionDetecteur.java ← refuse toute requête hors transaction (tables RLS)
    │   ├── RlsRepositoriesVerificateur.java ← vérifie les repositories au démarrage
    │   ├── RlsPolitiquesVerificateur.java   ← [Rev 5] vérifie les politiques au démarrage
    │   └── RlsCapacite.java                 ← [Rev 5] capacité « action du workflow »
    └── service/
        ├── AuditService.java         ← audit trail complet
        └── CodeGenerateurService.java (voir §29)

[Rev 5] Vérificateur propre au workflow : `workflow/config/WfTypeDocumentVerificateur.java`
(référentiel des types de document, voir §44).

[Rev 8] Point d'extension du moteur : `workflow/resume/` (WfResumeDocument,
WfResumeurDocument, WfResumeurRegistre) ; contrat des listes `workflow/dto/WfTacheResponse` ;
un résumeur par module ET par table : `<module>/service/<Entité>Resumeur.java` (§50).

---

## 3. ENTITÉS JPA

### RhBaseEntity — héritage obligatoire
```java
// TOUTES les entités héritent de RhBaseEntity sauf exceptions explicites
// (ex: ErpAuditLog qui n'a pas de colonnes version/actif)
@MappedSuperclass
public abstract class RhBaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Optimistic locking — empêche modifications simultanées
    @Version
    @Column(nullable = false)
    private Long version = 0L;    // BIGINT, jamais INTEGER

    @Column(name = "date_creation", updatable = false)
    private LocalDateTime dateCreation;

    @Column(name = "cree_par", updatable = false)
    private String creePar;

    @Column(name = "date_modification")
    private LocalDateTime dateModification;

    @Column(name = "modifie_par")
    private String modifiePar;

    @Column(nullable = false)
    private Boolean actif = true;  // Boolean objet, jamais boolean primitif

    @Column(name = "date_suppression")
    private LocalDateTime dateSuppression;

    @Column(name = "supprime_par")
    private String supprimePar;

    @Column(name = "motif_suppression")
    private String motifSuppression;

    // [MULTITENANCY] Isolation inter-entreprises — DEFAULT 1 = tenant actuel
    // Rempli automatiquement par @PrePersist depuis le contexte de la requête.
    // Ne jamais positionner manuellement dans le code applicatif.
    // Valeur 1 = "DEFAULT" tant qu'un seul tenant est déployé.
    @Column(name = "tenant_id", nullable = false)
    private Long tenantId = 1L;

    // Rempli automatiquement par @PrePersist/@PreUpdate
    @PrePersist void onCreate() {
        dateCreation = LocalDateTime.now();
        creePar      = ContexteHolder.getIdentifiant();  // thread-local
        tenantId     = ContexteHolder.getTenantId();     // thread-local, défaut 1L
    }
    @PreUpdate void onUpdate() {
        dateModification = LocalDateTime.now();
        modifiePar       = ContexteHolder.getIdentifiant();
    }

    // Méthodes métier standard
    public void supprimer(String utilisateur, String motif) {
        this.actif            = false;
        this.dateSuppression  = LocalDateTime.now();
        this.supprimePar      = utilisateur;
        this.motifSuppression = motif;
    }

    public void restaurer() {
        this.actif            = true;
        this.dateSuppression  = null;
        this.supprimePar      = null;
        this.motifSuppression = null;
    }
}
```

### Entités PARAMETRAGE
```java
// PAS de @SQLRestriction ni @SQLDelete (bloquerait les @ManyToOne)
// PAS de tenant_id — les référentiels sont partagés entre tous les tenants
// Filtrer via findAllByActifTrueOrder...() dans le repository
@Entity @Table(name = "rh_type_contrat")
public class RhTypeContrat extends RhBaseEntity { ... }
```

### Entités TRANSACTIONNELLES
```java
// AVEC @SQLRestriction et @SQLDelete pour le soft delete transparent
// tenant_id hérité automatiquement de RhBaseEntity
@Entity
@Table(name = "rh_contrat")
@SQLRestriction("actif = true")
@SQLDelete(sql = "UPDATE rh_contrat SET actif = false WHERE id = ? AND version = ?")
public class RhContrat extends RhBaseEntity { ... }
```

### Règles obligatoires entités
```java
// Boolean objet, jamais boolean primitif
private Boolean actif = true;
Boolean.TRUE.equals(entity.getActif())  // pas entity.isActif()

// FetchType.LAZY sur TOUS les @ManyToOne et @OneToMany
@ManyToOne(fetch = FetchType.LAZY)

// Colonnes JSONB PostgreSQL
@JdbcTypeCode(SqlTypes.JSON)
@Column(columnDefinition = "jsonb")
private String donnees;

// Jamais d'égalité == sur les entités, toujours .equals() ou getId()

// [Rev 4] Entité @Builder : @Builder.Default sur TOUT champ initialisé
// (sinon le builder l'ignore et laisse null → violation NOT NULL à l'INSERT)
@Builder.Default
private String statut = "BROUILLON";

// [Rev 4] Enum persisté : toujours par nom
@Enumerated(EnumType.STRING)
private AbsOrigineType origineType;

// [Rev 5] Association vers une table sous RLS dans un document lisible par un tiers :
// lire l'IDENTIFIANT sur le proxy (getId() ne charge rien), jamais naviguer au-delà
// dans le mapping (voir §43)
```

---

## 4. MULTITENANCY — DÉCISION ARCHITECTURE [NOUVEAU 06/06/2026]

### Contexte et décision
DigiERP supporte le multitenancy dès la conception, même si actuellement
un seul tenant est déployé. Cette décision garantit une évolution vers le
SaaS mutualisé sans refactoring massif.

### Modèle choisi : tenant_id par ligne (Row-Level Tenancy)
Chaque ligne des tables transactionnelles porte un `tenant_id`.
Actuellement toutes les lignes ont `tenant_id = 1` (tenant DEFAULT).

### Table erp_tenant (créée en V204)
```sql
CREATE TABLE erp_tenant (
    id        BIGSERIAL    PRIMARY KEY,
    code      VARCHAR(50)  NOT NULL UNIQUE,   -- 'DEFAULT', 'ALPHA_SA', etc.
    libelle   VARCHAR(200) NOT NULL,
    actif     BOOLEAN      NOT NULL DEFAULT TRUE,
    date_creation TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Tenant par défaut toujours présent avec id=1
INSERT INTO erp_tenant (id, code, libelle) VALUES (1, 'DEFAULT', 'Tenant par défaut');
```

### Tables qui portent tenant_id (transactionnelles)
```
rh_employe, rh_poste, rh_affectation
rh_contrat, cnt_avenant, cnt_echeance, cnt_renouvellement, cnt_resiliation
cnt_historique_contrat
abs_demande, abs_droit, abs_historique      ([Rev 7] abs_compteur supprimée le 30/09 : §49)
disc_demande_explication, disc_mesure, disc_historique
wf_instance, wf_decision, wf_delegation, wf_alerte
rh_organisation, rh_site, rh_service
notif_envoi, notif_destinataire
erp_audit_log
erp_perimetre_role, erp_utilisateur_role, erp_utilisateur_permission
```

### Tables SANS tenant_id (référentiels partagés)
```
erp_pays, erp_subdivision, erp_ville
erp_role, erp_module, erp_action, erp_permission, erp_role_permission
rh_situation_matrimoniale, rh_niveau_etude, rh_type_employe, rh_statut_employe
rh_niveau_hierarchique, rh_type_lien_structure
cnt_type_contrat, cnt_type_remuneration, cnt_standard_temps
cnt_motif_resiliation, cnt_type_avenant
abs_type_absence, disc_parametre, disc_type_mesure, disc_delai_reponse
wf_type_document, wf_modele, wf_etape, wf_relance_config
notif_modele_message, notif_variable_template
erp_audit_action_ref, erp_code_sequence
erp_action_type, erp_groupe_niveau, erp_poste_config, erp_poste_groupe
erp_module_action, erp_rls_config
```

### Tables SANS tenant_id (système)
```
rh_utilisateur, rh_role (Spring Security)
jwt_blacklist
erp_personne
erp_tenant elle-même
```

### tenant_id et contexte RLS [Rev 4]
Le contexte RLS est posé par `RlsJpaTransactionManager` au début de chaque transaction
(voir §33). `app.tenant_id` n'est PAS encore posé : au passage en multitenant, l'ajouter
au même endroit (même `set_config(..., true)` local à la transaction), à partir de
`RlsContexte`, et JAMAIS par un filtre ou un intercepteur qui toucherait une connexion
hors transaction.

### ContexteHolder — thread-local enrichi
```java
// getTenantId() retourne toujours 1L en phase mono-tenant
// À enrichir lors du passage en SaaS mutualisé
public static Long getTenantId() {
    Long tenantId = TENANT_HOLDER.get();
    return (tenantId != null) ? tenantId : 1L;  // défaut sécurisé
}
```

### Règle absolue
JAMAIS positionner tenant_id manuellement dans le code applicatif.
C'est le rôle exclusif de RhBaseEntity.@PrePersist via ContexteHolder.

---

## 5. REPOSITORIES

### Méthodes obligatoires par module
```java
// [Rev 4] Table sous RLS : @Transactional(readOnly = true) sur l'INTERFACE (voir §34)
@Transactional(readOnly = true)
public interface RhContratRepository
        extends JpaRepository<RhContrat, Long> {

    // Liste active triée — avec pagination
    Page<RhContrat> findAllByActifTrueOrderByDateCreationDesc(Pageable pageable);

    // Archives (ignorer @SQLRestriction)
    @Query(value = "SELECT * FROM rh_contrat WHERE actif = false ORDER BY date_suppression DESC",
           nativeQuery = true)
    List<RhContrat> findAllArchives();

    // Par ID sans filtre actif (pour restaurer)
    @Query(value = "SELECT * FROM rh_contrat WHERE id = :id", nativeQuery = true)
    Optional<RhContrat> findByIdIgnoreActif(@Param("id") Long id);

    // Purge physique (suppression définitive)
    @Modifying
    @Transactional          // [Rev 4] écriture explicite, jamais en lecture seule
    @Query(value = "DELETE FROM rh_contrat WHERE id = :id", nativeQuery = true)
    void purgerById(@Param("id") Long id);

    // Chevauchements (validation métier)
    @Query(value = """
        SELECT COUNT(*) FROM rh_contrat
        WHERE employe_id = :employeId
        AND actif = true
        AND id != :excludeId
        AND date_debut <= :fin AND (date_fin IS NULL OR date_fin >= :debut)
        """, nativeQuery = true)
    long countChevauchements(@Param("employeId") Long employeId,
                             @Param("debut") LocalDate debut,
                             @Param("fin") LocalDate fin,
                             @Param("excludeId") Long excludeId);

    // [Rev 5] Projection pour le mapping d'un document lisible par un tiers (§43) :
    // une valeur, sans entité, sous la RLS de la table → vide si la ligne est invisible
    @Query("select c.numeroContrat from ContratEntity c where c.id = :id")
    Optional<String> findNumeroContratById(@Param("id") Long id);
}
```

### Règles repositories
```java
// Jamais de logique métier dans un repository
// [Rev 4] Table SANS RLS : pas de @Transactional nécessaire (lecture appelée depuis
//         un service @Transactional(readOnly = true))
// [Rev 4] Table SOUS RLS : @Transactional(readOnly = true) sur l'interface OBLIGATOIRE,
//         @Transactional sur chaque méthode @Modifying — le démarrage est refusé sinon (§34)
// Requêtes natives : utiliser des paramètres nommés (@Param), jamais de concaténation
// Index en base sur toutes les colonnes de recherche fréquente
// [Rev 4] Une liste de statuts qui porte une règle métier (ex : statuts qui n'occupent pas
//         une période) est passée en paramètre depuis le service qui la définit, jamais
//         recopiée en dur dans plusieurs requêtes
// [Rev 5] Projection d'identité : interface imbriquée + alias JPQL
//         (RhEmployeRepository.IdentiteEmploye / findIdentiteById, voir §43)
// [Rev 7] Un AGRÉGAT (SUM, COUNT, choix d'une règle) sur une table sous RLS destiné à un
//         calcul métier ne s'écrit PAS en SELECT SUM(...) FROM <table> : il appelle la
//         fonction d'agrégat SQL à garde (§49), sinon le résultat dépend du lecteur
```

---

## 6. SERVICES

### Structure obligatoire
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ContratService {

    private final RhContratRepository         contratRepo;
    private final RhEmployeRepository         employeRepo;
    private final ContexteUtilisateurService  contexte;
    private final AuditService                auditService;
    private final ContratPolitique            politique;     // [Rev 5] §42

    // ── Lecture ──────────────────────────────────────────

    @Transactional(readOnly = true)
    public PageResponse<ContratSummaryResponse> lister(Pageable pageable) {
        // [Rev 5] Table SOUS RLS : la visibilité relève de la RLS SEULE (§40). Aucun second
        // filtre Java « un employé ne voit que ses données » : il ignorerait les valideurs
        // et répéterait une règle déjà garantie par la base.
        // Table SANS RLS : le filtre Java reste la seule barrière (contexte.peutAcceder).
        Page<RhContrat> page = contratRepo.findAllByActifTrueOrderByDateCreationDesc(pageable);
        // [Rev 6] Lecteur photographié UNE fois pour la page (actionsPermises, §42)
        LecteurDocument lecteur = politique.lecteurCourant();
        return new PageResponse<>(page.map(contrat -> toSummaryResponse(contrat, lecteur)));
    }

    @Transactional(readOnly = true)
    public ContratResponse obtenir(Long id) {
        RhContrat contrat = trouverOuEchouer(id);   // invisible (RLS) = introuvable = 404
        return toResponse(contrat);
    }

    // ── Écriture ──────────────────────────────────────────

    @Transactional
    public ContratResponse creer(ContratRequest req) {
        validerCreation(req);
        RhContrat contrat = new RhContrat();
        remplir(contrat, req);
        contrat = contratRepo.save(contrat);
        auditService.logAction("CREER", "RhContrat", contrat.getId(),
                               null, toJson(contrat));
        log.info("Contrat créé : id={} employe={}", contrat.getId(), req.employeId());
        return toResponse(contrat);
    }

    @Transactional
    public ContratResponse resilier(Long id, ResiliationRequest req) {
        RhContrat contrat = trouverOuEchouer(id);
        politique.verifier(ContratPolitique.Action.RESILIER, contrat);  // [Rev 5] 403 motivé
        // ... suite de l'action
    }

    // ── Privé ──────────────────────────────────────────────

    private RhContrat trouverOuEchouer(Long id) {
        return contratRepo.findById(id)
            .orElseThrow(() -> new RhNotFoundException("Contrat", id));
    }

    private void validerCreation(ContratRequest req) {
        if (req.dateFin() != null && !req.dateFin().isAfter(req.dateDebut())) {
            throw new RhBusinessException("La date de fin doit être postérieure à la date de début");
        }
        if (contratRepo.countChevauchements(req.employeId(), req.dateDebut(),
                req.dateFin() != null ? req.dateFin() : LocalDate.MAX, -1L) > 0) {
            throw new RhBusinessException("Un contrat actif existe déjà sur cette période");
        }
    }
}
```

### Règles services
```java
// @Transactional(readOnly = true) sur TOUTES les méthodes de lecture
// @Transactional sur les méthodes d'écriture (sans readOnly)
// RhBusinessException pour toutes les erreurs métier (jamais RuntimeException)
// RhNotFoundException pour les entités introuvables (jamais EntityNotFoundException directe)
// AuditService.logAction() sur TOUTES les créations/modifications/suppressions sensibles
// log.info() sur toutes les actions importantes (pas de log en production = debugging aveugle)
// Jamais de try/catch qui avale les exceptions silencieusement
// Retourner PageResponse<T> (jamais Page<T> directement) pour les listes paginées
// [Rev 4] @Transactional sur une méthode PRIVÉE ou appelée depuis la même classe = sans
//         effet (pas de passage par le proxy Spring) : ne jamais s'y fier
// [Rev 4] Jamais de try/catch autour d'un appel qui écrit en base dans la même transaction :
//         l'exception marque la transaction « rollback-only » → UnexpectedRollbackException
//         (500) au commit. Laisser remonter : un refus 422 annule proprement toute l'opération
// [Rev 4] Mapper en DTO / extraire les valeurs DANS la transaction (relations LAZY)
// [Rev 5] TOUT chargement d'un document introuvable → RhNotFoundException (404), y compris
//         findByIdIgnoreActif (restaurer, purger) ; jamais RhBusinessException (422)
// [Rev 5] Chaque méthode d'ACTION sur un document existant appelle
//         politique.verifier(Action.X, document) juste après le chargement (§42)
// [Rev 6] Une règle évaluée pour chaque ligne d'une liste ne relit JAMAIS l'utilisateur :
//         lecteur photographié une fois (§42)
// [Rev 9] Une entité chargée dans une transaction est SUIVIE (dirty checking) : un simple
//         setX(...) part en UPDATE au commit, sans save(). Un inventaire des écritures d'une
//         table suit donc aussi les setters (§51.5)
```

---

## 7. PAGINATION — STANDARD [ENRICHI 06/06/2026]

### PageResponse — enveloppe standard pour toutes les listes
```java
public record PageResponse<T>(
    List<T>  contenu,
    int      pageActuelle,    // 0-indexed
    int      totalPages,
    long     totalElements,
    int      taille,          // éléments par page
    boolean  premiere,
    boolean  derniere
) {
    // Constructeur depuis Spring Page<T>
    public PageResponse(Page<T> page) {
        this(
            page.getContent(),
            page.getNumber(),
            page.getTotalPages(),
            page.getTotalElements(),
            page.getSize(),
            page.isFirst(),
            page.isLast()
        );
    }
}
```

### Paramètres de requête standard
```java
// Tous les endpoints liste acceptent ces paramètres
GET /api/rh/contrats?page=0&taille=20&tri=dateCreation,desc&recherche=dupont

// Controller — signature standard
@GetMapping
public ResponseEntity<ApiResponse<PageResponse<ContratSummaryResponse>>> lister(
        @RequestParam(defaultValue = "0")              int page,
        @RequestParam(defaultValue = "20")             int taille,
        @RequestParam(defaultValue = "dateCreation")   String tri,
        @RequestParam(defaultValue = "desc")           String ordre,
        @RequestParam(required = false)                String recherche) {
    // Sécurité : limiter la taille maximale
    taille = Math.min(taille, 100);
    Pageable pageable = PageRequest.of(page, taille, Sort.by(Sort.Direction.fromString(ordre), tri));
    return ResponseEntity.ok(ApiResponse.ok(contratService.lister(pageable, recherche)));
}
```

### Tailles de page
```
Défaut     : 20 éléments
Maximum    : 100 éléments (jamais dépasser — sécurité + performance)
Référentiels (types, catégories) : lister() sans pagination (< 200 éléments en général)
Listes transactionnelles : TOUJOURS paginer
```

---

## 8. CONTROLLERS

### Structure obligatoire
```java
@RestController
@RequestMapping("/api/rh/contrats")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Contrats", description = "Gestion des contrats de travail")
public class ContratController {

    private final ContratService contratService;

    @GetMapping
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'LIRE')")
    @Operation(summary = "Lister les contrats avec pagination")
    public ResponseEntity<ApiResponse<PageResponse<ContratSummaryResponse>>> lister(
            @RequestParam(defaultValue = "0")            int page,
            @RequestParam(defaultValue = "20")           int taille,
            @RequestParam(defaultValue = "dateCreation") String tri,
            @RequestParam(defaultValue = "desc")         String ordre,
            @RequestParam(required = false)              String recherche) {
        taille = Math.min(taille, 100);
        Pageable pageable = PageRequest.of(page, taille,
                                Sort.by(Sort.Direction.fromString(ordre), tri));
        return ResponseEntity.ok(ApiResponse.ok(contratService.lister(pageable, recherche)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'LIRE')")
    public ResponseEntity<ApiResponse<ContratResponse>> obtenir(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(contratService.obtenir(id)));
    }

    @PostMapping
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'CREER')")
    public ResponseEntity<ApiResponse<ContratResponse>> creer(
            @Valid @RequestBody ContratRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(contratService.creer(req), "Contrat créé avec succès"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'MODIFIER')")
    public ResponseEntity<ApiResponse<ContratResponse>> modifier(
            @PathVariable Long id,
            @Valid @RequestBody ContratRequest req) {
        return ResponseEntity.ok(ApiResponse.ok(contratService.modifier(id, req)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'SUPPRIMER')")
    public ResponseEntity<ApiResponse<Void>> supprimer(
            @PathVariable Long id,
            @RequestParam String motif) {
        contratService.supprimer(id, motif);
        return ResponseEntity.ok(ApiResponse.ok(null, "Contrat supprimé"));
    }

    @GetMapping("/archives")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'LIRE')")
    public ResponseEntity<ApiResponse<List<ContratSummaryResponse>>> archives() {
        return ResponseEntity.ok(ApiResponse.ok(contratService.listerArchives()));
    }

    @PostMapping("/{id}/restaurer")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'RESTAURER')")
    public ResponseEntity<ApiResponse<ContratResponse>> restaurer(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(contratService.restaurer(id)));
    }

    @DeleteMapping("/{id}/purger")
    @PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'PURGER')")
    public ResponseEntity<ApiResponse<Void>> purger(@PathVariable Long id) {
        contratService.purger(id);
        return ResponseEntity.ok(ApiResponse.ok(null, "Contrat purgé définitivement"));
    }
}
```

### Règles controllers
```java
// @PreAuthorize sur CHAQUE endpoint (jamais un endpoint sans contrôle)
// @Valid sur TOUS les @RequestBody (jamais faire confiance aux données reçues)
// Aucune logique métier dans le controller (déléguer au service)
// Retourner toujours ApiResponse (jamais une entité JPA directement)
// @Tag OpenAPI sur chaque controller (documentation auto-générée)
// @Operation sur chaque endpoint complexe
// taille = Math.min(taille, 100) sur toutes les paginations (sécurité)
// [Rev 4] Aucun accès direct à un repository d'une table sous RLS (passer par un service)
// [Rev 5] @PreAuthorize ne décide que pour le TYPE de document (le rôle) ; le droit sur
//         CE document est décidé par la politique de document dans le service (§42)
// [Rev 6] Endpoint de DÉCISION workflow : voir §48 (porte unique à venir, temps 3)
```

---

## 9. RÉPONSE API STANDARD

### ApiResponse — contrat immuable
```java
// TOUTES les réponses de l'API utilisent cette enveloppe
// Jamais retourner un objet brut ou une liste directement
public record ApiResponse<T>(
    boolean success,
    T data,
    String message,
    List<String> erreurs,
    String correlationId,    // ID unique de la requête (traçabilité)
    LocalDateTime timestamp
) {
    public static <T> ApiResponse<T> ok(T data) { ... }
    public static <T> ApiResponse<T> ok(T data, String message) { ... }
    public static <T> ApiResponse<T> erreur(String message) { ... }
    public static <T> ApiResponse<T> erreurValidation(List<String> erreurs) { ... }
}
```

### Codes HTTP utilisés
```
200 OK               → lecture, modification, suppression réussie
201 Created          → création réussie
400 Bad Request      → validation @Valid échouée ; [Rev 5] requête mal formée par le client
                       (paramètre obligatoire absent, paramètre de mauvais type, JSON illisible)
401 Unauthorized     → non authentifié (token absent/invalide)
403 Forbidden        → authentifié mais permission PBAC insuffisante ; [Rev 5] ou action
                       refusée sur CE document (politique de document) ; ou acteur non
                       désigné pour l'étape (workflow)
404 Not Found        → entité introuvable [Rev 5] OU invisible pour cet utilisateur (RLS) :
                       même réponse, l'existence n'est jamais révélée
409 Conflict         → doublon, contrainte unicité, optimistic locking
422 Unprocessable    → erreur métier (RhBusinessException)
429 Too Many Requests → rate limiting
500 Internal Server Error → erreur non prévue (ou erreur de développement volontairement
                       bruyante : [RLS-HORS-TX], type de document non branché,
                       [Rev 7] [RLS-AGREGAT] agrégat demandé pour un employé non lisible)
                       [Rev 9] DETTE 22 : une violation de RLS d'écriture (« new row violates
                       row-level security policy ») sort aujourd'hui en 500 → 403 attendu
503 Service Unavailable   → maintenance
```

---

## 10. SÉCURITÉ

### Authentification — httpOnly Cookies + Refresh Token
```java
// Access token  : 15 minutes, httpOnly cookie
// Refresh token : 7 jours, httpOnly cookie, rotation à chaque usage
// CSRF token    : retourné dans le body du login, envoyé en header X-XSRF-TOKEN

// Endpoints auth
POST /api/auth/login     → login, retourne cookies + csrf_token dans body
POST /api/auth/refresh   → renouvelle access_token via refresh_token cookie
POST /api/auth/logout    → blacklist token + supprime cookies

// JwtAuthenticationFilter lit le token depuis le cookie (pas le header Authorization)
// Rétrocompatibilité : accept aussi Authorization: Bearer pour les clients API
```

### Rate Limiting — protection brute force
```java
// Sur /api/auth/login : blocage après 5 échecs en 15 minutes
// Implémenté via bucket4j ou via table rh_tentative_connexion en base
// Réponse 429 Too Many Requests avec Retry-After header
// Déblocage automatique après 15 min ou manuel par admin

@Component
public class LoginRateLimiter {
    // Max 5 tentatives / 15 min par IP + par identifiant
    public void verifier(String identifiant, String ip) {
        if (tentativesExcessives(identifiant, ip)) {
            throw new TropDeTentativesException(
                "Trop de tentatives. Réessayez dans 15 minutes.");
        }
    }
}
```

### PBAC — Vérification permissions
```java
// @PreAuthorize OBLIGATOIRE sur chaque endpoint
@PreAuthorize("@pe.peutFaire('RH.CONTRAT', 'LIRE')")

// PermissionEvaluator — ordre de vérification
// 1. REFUSE direct → refus immédiat (prioritaire)
// 2. ACCORDE direct → accordé immédiatement
// 3. Rôles actifs → vérifier portée (GLOBAL/SITE/SERVICE)
// 4. Aucune permission trouvée → refus + audit log
```

### Visibilité et droits sur un document [Rev 5 — remplace le « garde-fou visibilité »]
```
Ancienne règle (Rev 2-4) : dans chaque service, if (!contexte.estAdminOuRH()) filtrer par
employé, « doublé par la RLS ». ABANDONNÉE pour les tables sous RLS : c'était la même règle
écrite deux fois, et la copie Java ignorait les valideurs (RLS-2).

Table SOUS RLS :
  LIRE  → la RLS seule (politique de lecture, §40) ; un document invisible est introuvable
          (RhNotFoundException, 404) ; aucun filtre Java de visibilité en lecture
  AGIR  → @PreAuthorize (rôle) + politique de document (§42, 403 motivé)
          + politique d'écriture RLS (filet en base : un valideur n'écrit jamais)
  Le filtre de PÉRIMÈTRE des gestionnaires (site, service) reste en Java : la RLS leur donne
  l'accès complet, plus large que leur périmètre métier (ce n'est pas un doublon)
  [Rev 7] CALCULER un agrégat (solde, total) → fonction d'agrégat à garde (§49) : même
          résultat pour tout lecteur qui peut voir le document, aucune ligne révélée
Table SANS RLS (règles de droit, famille...) : contexte.peutAcceder(employeId) reste la SEULE
barrière
```

### RLS PostgreSQL — isolation données [Rev 4, complété Rev 5]
```
// Détail complet : §33 (mécanisme), §34 (aucune requête hors transaction),
// §35 (fonctions de contexte), §40 (politiques standard lecture/écriture),
// §41 (capacité du moteur de workflow), [Rev 7] §49 (agrégats indépendants du lecteur),
// [Rev 9] §51.4 à §51.6 (propriétaire testé sur les colonnes, inventaire, preuve)
// - L'application se connecte en digierp_app (soumis à la RLS) ; Flyway en digierp_user
//   (propriétaire) ; [Rev 5] avec FORCE, le propriétaire passe lui aussi par une politique
//   (pol_<table>_owner, USING true) : accès explicite, jamais implicite
// - Le contexte (app.current_role, app.current_user_id) est posé par
//   RlsJpaTransactionManager au DÉBUT de CHAQUE transaction, en mode LOCAL
//   (set_config(..., true)) : effacé par PostgreSQL au commit/rollback
// - Hors transaction : contexte de session ANONYME → aucune ligne visible
// - JAMAIS de set_config(..., false) (session) ni de réglage d'une connexion
//   obtenue hors transaction (DataSourceUtils dans un filtre = connexion au hasard
//   du pool → fuite du rôle d'un utilisateur vers un autre)
```

### Headers de sécurité
```java
// SecurityConfig — headers HTTP
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cache-Control: no-store (sur toutes les réponses API)
// HSTS géré par nginx en production
// CSP géré par nginx en production
```

### Validation des entrées
```java
// @Valid sur TOUS les @RequestBody — jamais faire confiance au frontend
// Contraintes Bean Validation sur tous les champs sensibles
@NotNull, @NotBlank, @Size(max=255), @Email, @Pattern
// Requêtes natives : paramètres nommés (@Param) — jamais de concaténation SQL
// Jamais de eval() ou d'interpolation de chaînes dans les requêtes
```

### Healthcheck public [Rev 4]
```
// /actuator/health est appelé sans authentification (healthcheck Docker) :
// il ne doit exposer AUCUNE donnée métier (ni comptage d'employés, ni d'utilisateurs).
// Seulement : état de la base, migrations Flyway, version du module.
```

---

## 11. AUDIT TRAIL COMPLET

### Principe
Traçabilité complète de TOUTES les actions sensibles — pas seulement les refus.
Obligatoire RGPD + ISO 27001.

### Actions à auditer
```java
// OBLIGATOIRE — auditer dans AuditService
AUTH_LOGIN              // connexion réussie
AUTH_ECHEC              // tentative connexion échouée
AUTH_LOGOUT             // déconnexion
AUTH_ACCES_REFUSE       // permission manquante
CREER                   // création entité
MODIFIER                // modification entité (ancienne + nouvelle valeur)
SUPPRIMER               // suppression logique
RESTAURER               // restauration
PURGER                  // suppression définitive
EXPORT                  // export Excel/PDF (qui a exporté quoi)
CONSULTATION_SENSIBLE   // consultation données sensibles (salaires, etc.)
```

### Pattern utilisation dans les services
```java
// Après CHAQUE action sensible
auditService.logAction(
    "CREER",                  // action
    "RhContrat",              // type entité
    contrat.getId(),          // id entité
    null,                     // ancienne valeur (null pour création)
    toJson(contrat)           // nouvelle valeur
);

// Pour les modifications : capturer l'ancienne valeur AVANT modification
String ancienneValeur = toJson(contrat);
remplir(contrat, req);
contratRepo.save(contrat);
auditService.logAction("MODIFIER", "RhContrat", contrat.getId(),
                       ancienneValeur, toJson(contrat));
```

---

## 12. GESTION DES EXCEPTIONS

### Hiérarchie des exceptions
```java
// RhBusinessException (422) — erreur métier attendue
throw new RhBusinessException("Un contrat actif existe déjà sur cette période");

// RhNotFoundException (404) — entité introuvable OU invisible (RLS)
throw new RhNotFoundException("Contrat", id);          // « Contrat introuvable : 12 »

// [Rev 5] RhAccesDocumentException (403) — le document est visible, le rôle a la
// permission PBAC, mais pas sur CE document (levée par PolitiqueDocument.verifier, §42)
throw new RhAccesDocumentException("Seul le demandeur ou un gestionnaire peut annuler cette demande");

// WfAutorisationException (403) — acteur non désigné pour l'étape du workflow
throw WfAutorisationException.acteurNonDesigne(acteurId, etape);

// TropDeTentativesException (429) — rate limiting
throw new TropDeTentativesException("Trop de tentatives de connexion");

// Jamais RuntimeException, IllegalArgumentException, ou Exception directement
// Jamais throw new Exception("message") — non typé, non intercepté proprement
// [Rev 4] Exception d'infrastructure volontaire : IllegalStateException("[RLS-HORS-TX] ...")
//         levée par la garde RLS (§34) — un défaut de code, pas une erreur métier
// [Rev 5] Autre erreur de DÉVELOPPEMENT volontairement bruyante (500) :
//         IllegalStateException("[WF] Le type X n'a pas de table du document ...") (§44)
// [Rev 7] Idem : exception SQL « [RLS-AGREGAT] employe N non lisible » (SQLSTATE 42501)
//         levée par une fonction d'agrégat (§49) ; jamais rattrapée
// [Rev 5] Une entité absente n'est JAMAIS une IllegalArgumentException (→ 500) :
//         RhNotFoundException (→ 404)
```

### GlobalExceptionHandler — couverture complète
```java
// Tous ces cas doivent être interceptés et retourner ApiResponse
MethodArgumentNotValidException         → 400 (validation @Valid)
MissingServletRequestParameterException → 400 [Rev 5] « Paramètre obligatoire manquant : x »
MethodArgumentTypeMismatchException     → 400 [Rev 5] « Paramètre invalide : x »
HttpMessageNotReadableException         → 400 [Rev 5] « Corps de requête illisible ou mal formé »
RhNotFoundException                     → 404
AccessDeniedException                   → 403 (PBAC)
RhAccesDocumentException                → 403 [Rev 5] (politique de document, log.warn [ACCES])
WfAutorisationException                 → 403 (acteur non désigné, log.warn [WF])
RhBusinessException                     → 422
DataIntegrityViolationException         → 409 (doublon BDD)
ObjectOptimisticLockingFailureException → 409 (modification simultanée)
TropDeTentativesException               → 429
Exception (catch-all)                   → 500 (+ log.error())
// [Rev 9] Dette 22 : violation de RLS d'écriture (SQLSTATE 42501, « new row violates
//         row-level security policy ») tombe dans le catch-all → 500 ; à traduire en 403
```

---

## 13. LOGS STRUCTURÉS

### Niveaux de logs
```java
log.debug() → développement uniquement (désactivé en production)
log.info()  → actions importantes : création, modification, connexion
log.warn()  → anomalies non bloquantes : token expiré, RLS échoué, [Rev 5] action refusée
log.error() → erreurs non prévues (TOUJOURS avec stack trace)

// Jamais System.out.println() en production
// Jamais logger des données sensibles (mots de passe, tokens, données personnelles)
// [Rev 4] Pas de log.info à chaque requête HTTP (filtres) : log.debug
```

### Format structuré (Logback)
```java
// Chaque log inclut automatiquement :
// - timestamp ISO 8601
// - niveau
// - correlation_id (ID unique de la requête)
// - identifiant utilisateur
// - message

log.info("[Contrat] Créé : id={} employeId={} par={}",
         contrat.getId(), req.employeId(), contexte.getIdentifiant());
```

### Correlation ID
```java
// CorrelationIdFilter — généré au début de chaque requête
// Propagé dans tous les logs de la même requête
// Retourné dans ApiResponse.correlationId
// Permet de retrouver tous les logs d'une requête en erreur
```

---

## 14. FLYWAY — MIGRATIONS

### Nomenclature versions
```
V001-V099 : core (schéma, géo, sécurité, workflow, audit, séquences)
V100-V299 : modules RH (schéma, permissions, refs, données test, modèles WF)
V204      : tenant_id + table erp_tenant
V300-V306 : module Formation
V400-V499 : notifications
V500-V599 : données de test périmètres
V600+     : futurs modules (Budget, Stock, Achats...)
```

### Ordre dans chaque migration
```sql
-- 1. ALTER TABLE existantes
-- 2. Tables paramétrage
-- 3. Tables transactionnelles
-- 4. Tables historisation
-- 5. FK croisées (ALTER TABLE ADD CONSTRAINT)
-- 6. Index (sur colonnes de recherche fréquente)
-- 7. Données de référence (ON CONFLICT DO NOTHING)
-- 8. erp_module + erp_action (permissions)
-- 9. erp_permission
-- 10. [Rev 5] RLS : CALL rls_appliquer_politiques(...) pour chaque table sous RLS (§40)

-- JAMAIS INSERT dans erp_utilisateur_role (fait dans InitialisationDonnees.java)
-- version BIGINT (jamais INTEGER)
-- Toujours ON CONFLICT DO NOTHING sur les inserts de référence
```

### Règles absolues
```
JAMAIS de script correctif (V3xx__fix_...) : modifier le script SOURCE comme si on
repartait de zéro, puis reset complet (volume PostgreSQL supprimé + images reconstruites)
Reset : docker compose down && docker volume rm && docker compose up -d
[Rev 9] Le nom du volume se LIT sur le conteneur (volume monté sur /var/lib/postgresql/data),
il ne se recopie pas d'une note (deux noms circulaient dans la documentation ; réel : digierp_pgdata)
mvn clean OBLIGATOIRE après tout déplacement de dossier Flyway
[Rev 4] Un CHECK qui reflète une enum Java est GÉNÉRÉ depuis l'enum (lecture du fichier
Java par le script d'écriture), jamais recopié à la main
[Rev 4] Une donnée de référence dont dépend le code (type d'absence, séquence...) est
SEMÉE par le script du module qui en a besoin ; un code Java qui cherche une donnée
inexistante doit échouer bruyamment, jamais dans un catch silencieux
[Rev 5] Aucune politique RLS écrite à la main (CREATE POLICY, ENABLE/FORCE ROW LEVEL
SECURITY) : uniquement rls_appliquer_politiques (§40) ; contrôle :
grep -n -E "^\s*(CREATE|DROP) POLICY|ROW LEVEL SECURITY;" db/migration/*.sql → rien
[Rev 5] Un bloc de données qui est le miroir d'une enum (wf_type_document) est GÉNÉRÉ depuis
l'enum et vérifié au démarrage (§44)
[Rev 7] Jamais de donnée DÉRIVÉE semée ni stockée (solde, compteur) : elle se calcule (§49)
[Rev 7] Toute fonction SECURITY DEFINER vit dans V004 (à côté des fonctions RLS), avec
REVOKE ... FROM PUBLIC et GRANT ... TO digierp_app
[Rev 9] Exception historique : rls_proprietaire_mission est dans V219 (dette 3)
```

---

## 15. VALIDATION MÉTIER

### Validations obligatoires dans tous les services
```java
// 1. Dates : fin > début
if (req.dateFin() != null && !req.dateFin().isAfter(req.dateDebut())) {
    throw new RhBusinessException("La date de fin doit être postérieure à la date de début");
}

// 2. Dates futures (si applicable)
if (req.dateDebut().isBefore(LocalDate.now())) {
    throw new RhBusinessException("La date de début ne peut pas être dans le passé");
}

// 3. Chevauchements
if (repo.countChevauchements(id, debut, fin, excludeId) > 0) {
    throw new RhBusinessException("Un enregistrement actif existe déjà sur cette période");
}

// 4. Durée maximale (si applicable)
long nbJours = ChronoUnit.DAYS.between(debut, fin);
if (type.getDureeMax() != null && nbJours > type.getDureeMax()) {
    throw new RhBusinessException("Durée " + nbJours + "j dépasse le maximum " + type.getDureeMax() + "j");
}

// 5. Commentaire obligatoire sur tout rejet workflow
if (commentaire == null || commentaire.isBlank()) {
    throw new RhBusinessException("Le motif de rejet est obligatoire");
}

// 6. [Rev 4] Disponibilité d'un employé : UNIQUEMENT via
//    AbsAbsenceGenereeService.verifierDisponibilite (voir §36)
```

---

## 16. PERFORMANCE ET SCALABILITÉ

### Pagination obligatoire
```java
// JAMAIS retourner une liste sans pagination pour les données volumineuses
// Taille par défaut : 20  — Maximum : 100 (enforced dans le controller)
// Référentiels (< 200 éléments) : liste simple sans pagination autorisée
PageResponse<ContratSummaryResponse> lister(Pageable pageable, String recherche);
```

### N+1 queries — à éviter absolument
```java
// @ManyToOne : toujours LAZY — charger explicitement si besoin
// Pour les listes : utiliser des JOIN FETCH dans les requêtes JPQL
@Query("SELECT c FROM RhContrat c JOIN FETCH c.employe JOIN FETCH c.typeContrat WHERE c.actif = true")

// EntityGraph pour les cas complexes
@EntityGraph(attributePaths = {"employe", "typeContrat", "avenants"})

// [Rev 5] JOIN FETCH vers une table sous RLS non ouverte au lecteur : la ligne jointe
// disparaît ou la lecture échoue → dans un document lisible par un tiers, projection (§43)
// [Rev 6] Même vigilance pour une RÈGLE évaluée par ligne : jamais « relire l'utilisateur
// connecté » pour chaque ligne × action → lecteur photographié une fois (§42)
```

### Index base de données
```sql
-- Index obligatoires sur toutes les colonnes fréquemment filtrées
CREATE INDEX idx_contrat_employe_id ON rh_contrat(employe_id);
CREATE INDEX idx_contrat_statut ON rh_contrat(statut);
CREATE INDEX idx_contrat_actif ON rh_contrat(actif);
CREATE INDEX idx_contrat_dates ON rh_contrat(date_debut, date_fin);
-- Index partiel pour les actifs (plus performant)
CREATE INDEX idx_contrat_actifs ON rh_contrat(employe_id) WHERE actif = true;
-- Index tenant_id sur toutes les tables transactionnelles
CREATE INDEX idx_contrat_tenant ON rh_contrat(tenant_id);
-- [Rev 4] Unicité compatible soft delete : index unique PARTIEL WHERE actif = TRUE
CREATE UNIQUE INDEX uq_abs_type_origine ON abs_type_absence(origine_type)
    WHERE origine_type IS NOT NULL AND actif = TRUE;
```

### Cache (si besoin)
```java
// Spring Cache sur les référentiels statiques (types, catégories)
@Cacheable("types-contrat")
public List<TypeContratResponse> listerTypes() { ... }

@CacheEvict(value = "types-contrat", allEntries = true)
public void creerType(TypeContratRequest req) { ... }
```

---

## 17. TESTS

### 3 niveaux obligatoires

**Niveau 1 — Tests unitaires (Services)**
```java
// Tester la logique métier sans Spring, sans base de données
@ExtendWith(MockitoExtension.class)
class ContratServiceTest {
    @Mock RhContratRepository contratRepo;
    @Mock ContexteUtilisateurService contexte;
    @InjectMocks ContratService contratService;

    @Test void creer_dateFinAvantDebut_leveException() {
        ContratRequest req = new ContratRequest(...dateFin avant dateDebut...);
        assertThrows(RhBusinessException.class, () -> contratService.creer(req));
    }
}
```

**Niveau 2 — Tests d'intégration (Repositories)**
```java
// Tester les requêtes SQL avec base H2 ou PostgreSQL de test
@DataJpaTest
class ContratRepositoryTest {
    @Test void countChevauchements_retourneNombre() { ... }
}
```

**Niveau 3 — Tests API (Controllers)**
```java
// Tester les endpoints HTTP avec MockMvc
@SpringBootTest @AutoConfigureMockMvc
class ContratControllerTest {
    @Test void lister_sansAuthentification_retourne401() { ... }
    @Test void lister_sansPermission_retourne403() { ... }
    @Test void creer_avecPermission_retourne201() { ... }
}
```

### Tests PBAC obligatoires
```java
// Scénarios critiques à couvrir
- EMPLOYE ne peut pas voir les contrats des autres
- EMPLOYE ne peut pas créer/modifier/supprimer
- GESTIONNAIRE_RH peut tout faire dans son périmètre
- Auto-validation interdite (émetteur ≠ validateur)
- Bypass RBAC impossible (token falsifié, manipulation URL)
- [Rev 5] Un VALIDEUR lit le document qu'il décide et ne peut RIEN y faire d'autre que
  décider (toutes les actions refusées, données inchangées)
- [Rev 6] Ce que l'écran PROPOSE (actionsPermises) = ce que le serveur ACCEPTE (verifier),
  pour chaque lecteur (demandeur, valideur, gestionnaire)
- [Rev 7] Toute donnée CALCULÉE montrée au valideur (solde, total) : la même pour le
  demandeur, un gestionnaire et le valideur (test lancé EN TANT QUE VALIDEUR, §49)
- [Rev 9] Le PROPRIÉTAIRE réel crée son document (jamais un gestionnaire à sa place : l'accès
  complet masque un défaut de la politique d'écriture) ; et il ne peut pas réécrire une
  colonne de propriété vers quelqu'un d'autre (UPDATE refusé, §51.6)
```

### Non-régression rejouable [Rev 4, complété Rev 5, Rev 6, Rev 7 et Rev 9]
```
Scripts (hors dépôt, docs/digierp/tests/) :
  nonreg_rls_workflow.py        (14 contrôles)
    A. audit de tous les GET sans paramètre de chemin, 4 comptes : aucun 500 nouveau,
       aucune requête hors transaction sur une table sous RLS
    B. isolation RLS : 80 requêtes alternées, 4 comptes, ENSEMBLES d'identifiants comparés
       à un oracle écrit depuis la règle métier (ses lignes + celles qu'il décide)
    C. workflow complet par Mes demandes / Mes tâches
  test_rls2_valideurs.py        (13 contrôles) — valideur EMPLOYE : voit, décide, garde
                                  l'historique ; 404 invisible / 403 non désigné
  test_actions_permises.py      [Rev 6] (16 contrôles) — actionsPermises d'une demande créée
                                  par le script : demandeur, valideur (avec peutDecider),
                                  gestionnaire RH, admin ; détail ET liste ; refus 403 au même
                                  motif et donnée intacte ; annulation finale (rejouable)
  securite_rls_politiques.py    (45 contrôles depuis le 01/10 : + GET /taches/{instanceId}
                                  en S3-lecture) — campagne de sécurité, voir §46
  preuve_rejet_absence.py       [Rev 7] (12 contrôles) — rejet sans commentaire 422, avec 200
  preuve_solde_absence.py       [Rev 7] (11 contrôles) — solde « hors cette demande » et
                                  « Mes droits » = oracle SQL (lecteur : le demandeur)
  preuve_solde_valideur.py      [Rev 7] (13 contrôles) — même solde pour demandeur,
                                  gestionnaire et VALIDEUR ; RLS non élargie ; garde des
                                  fonctions d'agrégat (3 refus, 1 accès = oracle) ; §49
  preuve_circuit_absence.py     [Rev 8] (16 contrôles) — circuit générique (lireCircuit) de
                                  la fiche = oracle SQL, pour chaque lecteur (§51.1)
  preuve_taches.py              [Rev 8] (13 contrôles) — « Mes tâches » lu par le VALIDEUR
                                  EMPLOYE : liste (communes, demandeur, résumé = oracle SQL),
                                  détail (solde, circuit), Mes demandes, rejet, état final
  preuve_taches_mission.py      [Rev 8] (7 contrôles) — même preuve pour une mission (§50) ;
                                  [Rev 9] mission créée et soumise PAR la demandeuse (afeudjo),
                                  plus par admin pour elle
  preuve_d23_mission.py         [Rev 9] script à DEUX MODES (§51.6) — `apres` (6 contrôles,
                                  dans la non-régression) : le propriétaire crée sa mission,
                                  ne peut pas en réécrire le missionnaire principal (UPDATE
                                  refusé en digierp_app, ROLLBACK), soumission, rejet, état
                                  final ; `avant` (5 contrôles) : preuve du défaut, à ne jouer
                                  que sur l'image d'avant le correctif
  controle_cles_resume.py       [Rev 8] (19 contrôles) — clés de résumé citées par les
                                  résumeurs Java ↔ traductions fr / en, et types_document ↔
                                  WfTypeDocument ; contre-preuve sur données faussées (§50)
Bilans de référence (05/10, après reset) : 45 / 12 / 11 / 13 / 16 / 13 / 7 / 6 — 0 ECHEC
À relancer après tout changement touchant la sécurité, le workflow ou un repository.
Un test ne doit jamais passer « pour la mauvaise raison » : vérifier le MESSAGE d'un 422,
pas seulement le code ; signaler explicitement un défaut connu au lieu de le masquer.
[Rev 5] L'attendu d'un test de visibilité est CALCULÉ depuis la règle métier (requête en
connexion propriétaire), jamais figé, et jamais recopié des fonctions RLS testées.
[Rev 6] L'attendu d'un test de droits (et d'un scénario UI) est déduit des PERMISSIONS RÉELLES
des rôles (erp_role_permission), jamais supposé.
[Rev 7] Un test qui ne lit qu'en tant que PROPRIÉTAIRE ne couvre pas un calcul montré à un
tiers : relire le même document en tant que valideur et comparer (propriété d'invariance).
[Rev 9] Un contournement temporaire dans une preuve (« admin crée POUR l'employé ») est noté
comme dette et RETIRÉ dès que le défaut est corrigé : le test revient à l'acteur réel.
```

---

## 18. DOCUMENTATION API (OpenAPI/Swagger)

```java
// @Tag sur chaque Controller
@Tag(name = "Contrats", description = "Gestion des contrats de travail")

// @Operation sur chaque endpoint
@Operation(
    summary = "Créer un contrat",
    description = "Crée un nouveau contrat. Nécessite RH.CONTRAT:CREER.",
    responses = {
        @ApiResponse(responseCode = "201", description = "Contrat créé"),
        @ApiResponse(responseCode = "400", description = "Données invalides"),
        @ApiResponse(responseCode = "403", description = "Permission insuffisante"),
        @ApiResponse(responseCode = "422", description = "Erreur métier")
    }
)

// Accessible via : http://localhost:8090/swagger-ui.html
```

---

## 19. MONITORING ET SANTÉ

### Spring Actuator
```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, flyway
  endpoint:
    health:
      show-details: when-authorized
```

### Endpoints disponibles
```
GET /actuator/health   → état de l'application (BDD, disk, custom)
GET /actuator/metrics  → métriques (requêtes/sec, mémoire, etc.)
GET /actuator/flyway   → état des migrations Flyway
```

### HealthIndicator personnalisé
```java
@Component
public class DigiErpHealthIndicator implements HealthIndicator {
    public Health health() {
        // [Rev 4] Aucune donnée métier : base, migrations, version uniquement
        return Health.up().withDetail("migrations", "OK").build();
    }
}
```

---

## 20. CHECKLIST CRÉATION D'UN MODULE [MIS À JOUR 06/06/2026 — compléments §39 et §47]

Avant tout commit, vérifier :
[ ] 1.  Entity hérite de RhBaseEntity (tenant_id automatique)
[ ] 2.  @SQLRestriction + @SQLDelete si entité transactionnelle
[ ] 3.  version BIGINT (pas INTEGER) dans l'entité et en base
[ ] 4.  DTO Request + Response + SummaryResponse créés
[ ] 5.  @Valid sur tous les @RequestBody du controller
[ ] 6.  @PreAuthorize sur chaque endpoint du controller
[ ] 7.  @Transactional(readOnly=true) sur les lectures du service
[ ] 8.  [Rev 5] Visibilité : RLS seule pour une table sous RLS (aucun filtre Java en lecture) ;
        actions : politique de document (§42) ; table sans RLS : contexte.peutAcceder
[ ] 9.  RhBusinessException pour toutes les erreurs métier
[ ] 10. AuditService.logAction() sur créer/modifier/supprimer
[ ] 11. findByIdIgnoreActif() + purgerById() dans le repository
[ ] 12. Index sur colonnes de recherche dans la migration Flyway
[ ] 13. Index sur tenant_id dans la migration Flyway
[ ] 14. @Tag OpenAPI sur le controller
[ ] 15. Migration Flyway avec erp_module + erp_permission
[ ] 16. Tests unitaires service + tests API controller écrits
[ ] 17. log.info() sur les actions importantes
[ ] 18. Jamais d'entité JPA exposée directement dans l'API
[ ] 19. Pagination sur toutes les listes transactionnelles (taille max 100)
[ ] 20. PageResponse<T> retourné par le service (jamais Page<T> brut)
[ ] 21. taille = Math.min(taille, 100) dans le controller

---

## 21. PBAC — ARCHITECTURE COMPLÈTE (08/06/2026 — Session 9)

### 3 couches de sécurité distinctes
COUCHE 1 — ACTIONS (qui peut faire quoi ?)
Tables  : erp_module_action × erp_poste_groupe
Moment  : @PreAuthorize dans le contrôleur (PermissionEvaluator)
Exemple : "Le DRH peut valider les absences de ses N+1"
[Rev 5] Complétée, pour CE document, par la politique de document (§42) dans le service
COUCHE 2 — PÉRIMÈTRE GÉOGRAPHIQUE (sur quoi ?)
Tables  : erp_poste_config.perimetre_auto + erp_utilisateur_role
Moment  : dans le service Java avant la requête
Exemple : "Le gestionnaire de Douala ne voit que Douala"
COUCHE 3 — RLS DONNÉES (quelles lignes ?)
Tables  : politiques PostgreSQL standard (§40), fonctions uniques (§35, §40)
Moment  : automatique dans PostgreSQL à chaque requête, DANS une transaction
Exemple : "L'employé ne voit que ses propres contrats" ; [Rev 5] "le N+1 voit (et ne peut
          que lire) la demande qu'il doit décider"

### Algorithme PermissionEvaluator — PBAC prioritaire, RBAC fallback

```java
// Étape 0 : Admin MANUEL (ROLE_ADMIN_RH) → bypass affectation
// Étape 1 : Utilisateur avec affectation active ?
//           NON → refusé (retraités/licenciés bloqués)
// Étape 2 : Permission directe REFUSE → refusé (absolu)
// Étape 3 : Permission directe ACCORDE → accordé
// Étape 4 : Module a une matrice PBAC (erp_module_action) ?
//   OUI → résolution PBAC :
//     - SELF : l'utilisateur accède à ses propres données
//     - ALL  : tout le monde
//     - GRH  : rôle GESTIONNAIRE_RH actif
//     - Gx   : poste superviseur du poste cible (erp_poste_groupe)
//     Si aucun groupe → refusé (RBAC ignoré)
//   NON → fallback RBAC : rôle actif a la permission ?
// Étape 5 : Refusé + audit
```

### Double source de rôles — règle définitive
erp_utilisateur_role = SOURCE PRIMAIRE (rôle du poste)
rh_utilisateur_role  = FALLBACK (admin ROLE_ADMIN_RH + nouveaux comptes)
RhUserDetailsService :

Charge erp_utilisateur_role → ROLE_xxx Spring Security
Si erp vide → fallback rh_utilisateur_role
Admin : ROLE_ADMIN_RH toujours inclus (double protection)

ContexteUtilisateurService.getRolePrincipal() :

Lit erp_utilisateur_role en priorité (source=POSTE d'abord)
Retourne le rôle ERP le plus prioritaire
Sans authentification : ANONYME (jamais SYSTEM) [Rev 4]
Seul appelant : RlsContexteFilter


### Trigger affectation (V208) — poste fait foi

```sql
-- INSERT/UPDATE rh_affectation → assignation automatique rôle POSTE
-- Révoque les anciens rôles POSTE actifs avant d'en créer un nouveau
-- Lit erp_poste_config pour le rôle + périmètre_auto
-- Chaîne périmètre : rh_poste.service_id → rh_service.site_id → rh_site.organisation_id

-- Périmètre appliqué selon perimetre_auto :
-- SELF         → org/site/service tous NULL
-- SERVICE      → org NULL, site NULL, service conservé
-- SITE         → org NULL, service NULL, site conservé
-- ORGANISATION → site NULL, service NULL, org conservée
-- GLOBAL       → org/site/service conservés tels quels
```

### Hiérarchie : deux référentiels à tenir alignés [Rev 5]
```
rh_organigramme (lien HIERARCHIQUE)  → supérieur direct du WORKFLOW (étape SUPERIEUR_DIRECT)
erp_poste_groupe (G1, G2...)         → droits PBAC (qui peut valider pour qui)
Toute modification de la hiérarchie (y compris dans les données de test) se fait dans LES
DEUX : un N+1 d'organigramme est G1 de son subordonné, le N+2 est G2. Deux sources pour une
même règle = dette (à unifier : un maître, l'autre généré).
[Rev 7] Exception : un script de PREUVE qui change TEMPORAIREMENT le N+1 (le temps d'une
soumission) ne touche que rh_organigramme, journalise la valeur d'origine AVANT et la remet
dans un finally (preuve_solde_valideur.py)
```

### RLS PostgreSQL — règles critiques [Rev 4, mis à jour Rev 5]
app.current_user_id = employe_id (PAS utilisateur_id)
→ RlsContexteFilter range u.getEmployeId() dans RlsContexte
→ Les politiques RLS comparent employe_id::TEXT = rls_employe_courant(), jamais u.id
→ [Rev 5] wf_decision.acteur_id est un UTILISATEUR (rh_utilisateur.id) : les fonctions de
  visibilité des valideurs passent par rh_utilisateur.employe_id (§40)
Politiques actuelles [Rev 5] : modèle standard (§40) sur les 14 tables sous RLS, générées par
rls_appliquer_politiques dans V004 (6 tables), V208 (rh_poste), V219 (7 tables mis_*).
À implémenter :
- Chantier B : politiques dynamiques via erp_rls_config, portée SITE/SERVICE/ORGANISATION
- Visibilité hiérarchique « mon équipe » (tableau de bord du manager) : besoin distinct de
  RLS-2 (visibilité des documents à décider, livrée le 29/09)
### Compte de secours admin — règle absolue
admin (source=MANUEL, ROLE_ADMIN_RH) :

Jamais de trigger affectation sur ce compte
Bypass vérification affectation active dans PermissionEvaluator
Accès via rh_utilisateur_role (ROLE_ADMIN_RH) si erp vide
Ne JAMAIS supprimer rh_utilisateur_role pour admin


---

## 22. ARCHITECTURE MICROSERVICES — STANDARDS (session 14)

### Principe fondamental
Chaque service a UNE responsabilité unique et ne l'excède pas.

| Service | Responsabilité unique |
|---------|----------------------|
| auth-service | Émission JWT, login, refresh, logout, blacklist |
| digierp-gateway | Validation JWT, routage, CORS, corrélation ID |
| eureka | Registry de services (découverte) |
| rh-api | Module RH uniquement |

### Règle : seul émetteur JWT
auth-service est le SEUL service qui génère des JWT.
rh-api et gateway valident uniquement — jamais n'émettent.

### Règle : CORS centralisé
CORS géré UNIQUEMENT par le gateway.
Tous les services aval ont `.cors(cors -> cors.disable())`.

```java
// ✅ Dans SecurityConfig de rh-api, auth-service
.cors(cors -> cors.disable())

// ❌ INTERDIT dans les services aval
.cors(cors -> cors.configurationSource(corsConfigurationSource()))
```

### Règle : headers X-User-* downstream
Le gateway injecte ces headers vers les services aval après validation JWT :
- `X-User-Id`         → identifiant utilisateur
- `X-User-Roles`      → rôles CSV (ex: ROLE_ADMIN,ROLE_GESTIONNAIRE_RH)
- `X-User-Employe-Id` → id employé (vide si admin sans fiche)
Les services aval lisent ces headers via `GatewayHeaderFilter`.
Fallback : `JwtAuthenticationFilter` pour les accès directs en dev.

### Règle : GatewayHeaderFilter avant JwtAuthenticationFilter
```java
.addFilterBefore(gatewayHeaderFilter, UsernamePasswordAuthenticationFilter.class)
.addFilterBefore(jwtAuthFilter,       UsernamePasswordAuthenticationFilter.class)
.addFilterAfter(rlsFilter,            JwtAuthenticationFilter.class)   // [Rev 4] RlsContexteFilter
```

### Règle : nativeQuery pour entités inconnues
Dans auth-service, toute requête vers une table non mappée → nativeQuery=true.
```java
// ❌ JPQL sur entité non mappée dans auth-service
@Query("SELECT ur.role.code FROM ErpUtilisateurRole ur WHERE ...")

// ✅ SQL natif
@Query(value = "SELECT r.code FROM erp_utilisateur_role ur JOIN erp_role r ...",
       nativeQuery = true)
```

### Règle : compte de connexion à la base [Rev 5]
```
rh-api      : digierp_app (soumis à la RLS) ; Flyway : digierp_user (propriétaire)
auth-service: digierp_user (propriétaire) — passe par les politiques pol_<table>_owner
              depuis que les 14 tables sont en FORCE. Dette : rôle dédié au moindre privilège.
```

### Règle : Eureka sans Spring Security
Eureka ne doit pas avoir Spring Security.
Le réseau Docker interne protège suffisamment.
defaultZone sans credentials : `http://eureka:8761/eureka/`

### Règle : curl dans tous les Dockerfiles Alpine
```dockerfile
FROM eclipse-temurin:17-jre-alpine
RUN apk add --no-cache curl  # OBLIGATOIRE pour healthcheck
```

### Règle : start_period adapté par service
| Service | start_period |
|---------|-------------|
| eureka | 30s |
| auth-service | 60s |
| gateway | 60s |
| rh-api (Flyway+JPA) | 180s |

### Règle : RemoveResponseHeader dans gateway
Pour éviter ERR_INCOMPLETE_CHUNKED_ENCODING Chrome :
```yaml
spring:
  cloud:
    gateway:
      default-filters:
        - RemoveResponseHeader=Transfer-Encoding
```
Jamais de ResponseBufferingFilter Java custom — le filtre natif suffit.

### Règle : rh-api joignable seulement après réinscription Eureka [Rev 4, corrigé Rev 5]
Après `docker compose up -d backend`, le login (auth-service) répond avant que la gateway
ne route vers la nouvelle instance de rh-api (503 pendant quelques secondes).
[Rev 5] Un 401 SANS jeton ne prouve rien : il peut venir de la gateway elle-même, avant tout
routage (cas réel : campagne lancée 5 s après un rebuild, 500 sur la première création).
Seule preuve fiable : une requête AUTHENTIFIÉE à rh-api qui répond 200
(GET /api/rh/workflow/modules avec un jeton). Puis contrôler les lignes des vérificateurs
dans les logs ([RLS-VERIF], [RLS-POLITIQUES], [WF-VERIF], [RLS-HORS-TX]).

---

## 23. FLYWAY — RÈGLE EMETTRE_TIERS ET PERMISSIONS UI

### Règle : permission dédiée pour modes UI
Ne jamais utiliser une permission CRUD (CREER, MODIFIER) comme critère
pour basculer entre deux modes d'interface utilisateur.
Créer une permission dédiée avec une sémantique métier claire.

```sql
-- ✅ Permission dédiée — sémantique claire
'RH.ABSENCE:EMETTRE_TIERS' → peut soumettre pour un autre employé

-- ❌ Anti-pattern — utiliser CREER comme critère mode UI
if (peutFaire('RH.EMPLOYE', 'CREER')) { /* mode admin */ }
```

Avantage : configurable via matrice PBAC sans modifier le code.

### Règle : toujours ajouter dans les 3 endroits
Quand on ajoute une nouvelle action/permission :
1. `erp_action` (INSERT)
2. `erp_permission` (INSERT)
3. `erp_role_permission` (assignation aux rôles concernés)

---

## 24. CHECKLIST NOUVEAU SERVICE MICROSERVICES

Avant de créer un nouveau service Spring Boot dans l'architecture DigiERP :
[ ] 1.  pom.xml : spring-cloud-starter-netflix-eureka-client + BOM
[ ] 2.  application-docker.yaml : defaultZone http://eureka:8761/eureka/
[ ] 3.  SecurityConfig : .cors(cors -> cors.disable())
[ ] 4.  Dockerfile : RUN apk add --no-cache curl
[ ] 5.  docker-compose.yml : start_period adapté + healthcheck curl
[ ] 6.  Pas de Spring Security sur Eureka
[ ] 7.  Si service aval : GatewayHeaderFilter avant JwtAuthenticationFilter
[ ] 8.  gateway/application.yaml : routes ajoutées (local + docker)
[ ] 9.  gateway/application-docker.yaml : routes lb:// ajoutées
[ ] 10. CORS : désactivé dans le nouveau service
[ ] 11. [Rev 4] Si le service accède à des tables sous RLS : reprendre le socle shared/rls
        (gestionnaire de transactions, filtre, garde, vérificateurs, capacité)

---

## STANDARDS SESSION 15 — 24/06/2026

### PATTERN STANDARD — resolveEmployeId() dans tous les services

OBLIGATOIRE dans tout service qui crée un document pour un employé :

```java
// ✅ STANDARD DigiERP — self-service + admin en un seul appel
@Transactional
public ApiResponse<XxxResponse> creer(XxxRequest req, String utilisateur) {
    Long employeId = contexte.resolveEmployeId(req.getEmployeId());
    RhEmploye employe = chargerEmploye(employeId);
    // ... suite normale
}
```

JAMAIS :
```java
// ❌ Pansement — ne détecte pas l'usurpation
private RhEmploye chargerEmploye(Long id) {
    if (id == null) id = contexte.getEmployeIdObligatoire(); // ← non
    ...
}

// ❌ Logique dans le contrôleur — anti-pattern
if (req.getEmployeId() == null) {
    req.setEmployeId(contexte.getEmployeIdObligatoire()); // ← non
}
```

[Rev 9] Écart connu (dette 26, non prouvé) : `MissionService.creer` prend le missionnaire
principal dans `participantIds.get(0)` sans `resolveEmployeId`. Depuis 89ae754f, la RLS
d'écriture de mis_mission refuse qu'un EMPLOYE crée une mission au nom d'un autre, mais en
500 (dette 22) ; à aligner sur ce pattern avec l'incrément 5.

---

### PATTERN STANDARD — Super-rôles via SuperRoleService

JAMAIS de nom de rôle hardcodé dans le code Java :
```java
// ❌ INTERDIT
"ROLE_ADMIN_RH".equals(r.getNom())
a.getAuthority().contains("ADMIN_RH")
List.of("ADMIN", "GESTIONNAIRE_RH")

// ✅ STANDARD
superRoleService.bypassAffectation(roleErpCode)
superRoleService.bypassPbac(roleErpCode)
superRoleService.estSuperRole(roleErpCode)
```

Ajouter un super-rôle = UPDATE en base uniquement :
```sql
UPDATE erp_role SET bypass_pbac = TRUE WHERE code = 'MON_NOUVEAU_ROLE';
```

---

### PATTERN STANDARD — WfTypeDocument

Toujours utiliser l'enum pour les codes type document :
```java
// ✅ STANDARD
workflowService.demarrer(
    WfTypeDocument.ABSENCE_CONGE_ANNUEL.getCode(),
    documentId, employeId
);

// ❌ INTERDIT — string littéral
workflowService.demarrer("CONGE_ANNUEL", ...);
```

L'enum `WfTypeDocument` est la référence de vérité.
Les codes en base (V005) DOIVENT correspondre à `WfTypeDocument.getCode()`.
[Rev 4] Reconnaître le module d'un type : `WfTypeDocument.values()` + `getModule()`,
jamais un préfixe de chaîne (voir §37).
[Rev 5] Chaque constante déclare aussi sa table du document (`tableDocument`) ; le miroir
V005 est généré depuis l'enum et vérifié au démarrage (voir §44).

---

### PATTERN STANDARD — WfInstanceEntity

Toujours renseigner `documentType` à la création :
```java
// Dans WorkflowService.demarrer()
instance.setDocumentType(typeDocumentCode);  // OBLIGATOIRE — NOT NULL en base
instance.setDocumentId(documentId);
instance.setEmployeId(employeId);
```

---

### PATTERN STANDARD — Actions PBAC dans erp_action_type

Avant tout INSERT dans erp_module_action, vérifier que l'action existe :
```sql
-- Actions standard à déclarer dans V101 si absentes
INSERT INTO erp_action_type (code, libelle, libelle_en, categorie,
    necessite_workflow, interdit_emetteur, ordre_affichage, actif, cree_par, version)
VALUES
    ('CREER',     'Créer',     'Create',  'EMISSION', FALSE, FALSE, 20, TRUE, 'SYSTEM', 0),
    ('MODIFIER',  'Modifier',  'Modify',  'EMISSION', FALSE, FALSE, 21, TRUE, 'SYSTEM', 0),
    ('SUPPRIMER', 'Supprimer', 'Delete',  'EMISSION', FALSE, FALSE, 22, TRUE, 'SYSTEM', 0),
    ('SOUMETTRE', 'Soumettre', 'Submit',  'EMISSION', TRUE,  TRUE,  23, TRUE, 'SYSTEM', 0)
ON CONFLICT (code) DO NOTHING;
```

---

### RÈGLE — URLs contrôleurs RH

Tout contrôleur du module RH = préfixe `/api/rh/` :
```java
@RequestMapping("/api/rh/workflow")      // ✅
@RequestMapping("/api/rh/organigramme")  // ✅
@RequestMapping("/api/rh/absences")      // ✅

@RequestMapping("/api/workflow")         // ❌ gateway ne route pas
@RequestMapping("/api/organigramme")     // ❌ gateway ne route pas
```

---

### RÈGLE — GatewayHeaderFilter principal

```java
// ✅ OBLIGATOIRE — UserDetails comme principal
var userDetails = new User(userId, "", authorities);
var authentication = new UsernamePasswordAuthenticationToken(
    userDetails, null, authorities
);

// ❌ INTERDIT — String comme principal → @AuthenticationPrincipal = null
new UsernamePasswordAuthenticationToken(userId, null, authorities)
```

---

### RÈGLE — docker build backend

```bash
# Changement Java uniquement (sources) → RAPIDE (60-90s)
docker compose build backend

# Changement pom.xml ou Dockerfile → COMPLET (9min)
docker compose build backend --no-cache
```


---

## 25. CHECKLIST CONTROLLER AVANT MERGE (session 17)

Violations fréquentes détectées sur ConfigPosteAccesController — à vérifier
sur tout nouveau controller avant commit :
[ ] 1.  Logique métier absente du controller

→ tout extraire dans XxxService.java

[ ] 2.  DTOs dans fichier dédié dto/XxxDto.java

→ jamais de Records Java inline dans le controller

[ ] 3.  @Valid sur tous les @RequestBody POST/PUT

[ ] 4.  @Transactional dans le Service (pas dans le Controller)

[ ] 5.  URL /api/rh/ obligatoire (gateway route uniquement /api/rh/)

→ vérifier application.yaml gateway avant déploiement

[ ] 6.  @Tag + @Operation sur chaque endpoint

[ ] 7.  @PreAuthorize @pe.peutFaire() sur chaque endpoint

→ jamais hasRole() hardcodé

[ ] 8.  log.info() sur créer/modifier/supprimer

→ log.warn() sur modifications sécurité (RLS, rôles)

[ ] 9.  RhNotFoundException pour entité introuvable (404)

→ RhBusinessException pour erreur métier (422)

[ ] 10. Jamais d'entité JPA exposée dans la réponse API

→ toujours des DTOs

[ ] 11. [Rev 4] Aucun repository d'une table sous RLS injecté dans le controller

[ ] 12. [Rev 5] Tout nouvel endpoint d'action à paramètre de chemin est couvert
        automatiquement par la campagne S3 (§46) : la relancer

---

## 26. RÈGLE URL GATEWAY — CRITIQUE (session 17)

Tout controller rh-api DOIT utiliser le préfixe `/api/rh/` :

```java
// ✅ CORRECT — gateway route /api/rh/**
@RequestMapping("/api/rh/administration/postes")
@RequestMapping("/api/rh/organisations")
@RequestMapping("/api/rh/absences")

// ❌ INTERDIT — gateway ne route pas ces URLs
@RequestMapping("/api/administration/postes")
@RequestMapping("/administration/postes")
```

Vérifier TOUJOURS avant déploiement :
```bash
grep -n "path\|uri\|/api/" \
  gateway/src/main/resources/application.yaml | head -20
```

---

## 27. RÈGLE DTOs — JAMAIS DANS LE CONTROLLER (session 17)
// ❌ INTERDIT — Records inline dans le controller

public class MonController {

public record MonDto(Long id, String code) {}  // ← INTERDIT

}
// ✅ CORRECT — fichier dédié

// dto/MonDto.java

public class MonDto {

public record Request(Long id, String code) {}

public record Response(Long id, String code) {}

}

Structure package obligatoire :
erp/permission/

├── controller/

│   └── ConfigPosteAccesController.java   ← délègue au service

├── service/

│   └── ConfigPosteAccesService.java      ← logique métier

├── dto/

│   └── ConfigPosteAccesDto.java          ← tous les Records/DTOs

├── entity/

│   └── ErpRlsConfig.java

└── repository/

└── ErpRlsConfigRepository.java

---

## 28. STANDARD PARAMETRAGE — SELECTS FORMULAIRES (session 21)

### Principe
Chaque module a UN controller `{Module}ParametrageController` qui sert des **listes simples** 
pour les selects de formulaires. Les formulaires n'appellent JAMAIS directement les endpoints 
CRUD paginés (`/rh/employes`, `/rh/organisations`, etc.) pour remplir les selects.

### Convention URL

/api/rh/{module}/parametrage/{entité} → liste simple
/api/rh/{module}/parametrage/{entité}/{parentId} → cascade enfant


### Convention DTO — RefSimpleDto
Un seul record réutilisable pour les selects simples cross-module :
```java
public record RefSimpleDto(Long id, String code, String libelle) {}
```
Déclaré dans chaque controller parametrage (pas de classe partagée) pour éviter le couplage.
Pour les référentiels spécifiques au module (avec champs supplémentaires), 
utiliser les `SummaryResponse` du module (ex: `MisTypeMissionDto.SummaryResponse`).
[Rev 4] Pour un employé : code = matricule, libelle = "NOM Prénom". Le frontend lit
`libelle` et `code` (jamais prenom / nom / matricule, absents de ce DTO).

### Règles
1. **Controllers CRUD** → `PageResponse<SummaryResponse>` pour les grids/tableaux
2. **Controllers Parametrage** → `List<RefSimpleDto>` ou `List<SummaryResponse>` pour les selects
3. **Cross-module** : si un formulaire (ex: missions) a besoin d'employés ou d'organisations, 
   c'est le `MisParametrageController` du module appelant qui expose les listes, 
   pas un appel direct au controller CRUD de l'autre module
4. **Frontend** : les hooks/services appellent uniquement `/rh/{module}/parametrage/*` 
   pour les selects, jamais les endpoints CRUD directement
5. **Cascade** : les selects parent/enfant utilisent `/{entité}/{parentId}` 
   (ex: `/sites/{orgId}`, `/departements/{regionId}`)
### Exemple — MisParametrageController

/api/rh/mission/parametrage/types-mission → SummaryResponse (spécifique module)
/api/rh/mission/parametrage/employes → RefSimpleDto (cross-module)
/api/rh/mission/parametrage/organisations → RefSimpleDto (cross-module)
/api/rh/mission/parametrage/sites/{orgId} → RefSimpleDto (cascade)
/api/rh/mission/parametrage/pays → RefSimpleDto (cross-module)
/api/rh/mission/parametrage/subdivisions/{id} → RefSimpleDto (cascade)


### Dette technique (à migrer dans une session dédiée)
Modules avec appels directs aux CRUD pour remplir des selects :
- PosteForm.jsx → /rh/services
- contrat.service.js → /rh/postes, /rh/services, /rh/employes
- DisciplineModales.jsx → /rh/employes
- EmployeForm.jsx → /rh/sites
- AffectationsOnglet.jsx → /rh/postes
- config-postes-acces.service.js → /rh/postes
[Rev 4] Les controllers de paramétrage servent aujourd'hui leurs listes directement depuis
les repositories (sans service) : conforme tant que les tables lues sont SANS RLS ; une liste
d'employés (rh_employe, sous RLS) doit passer par un service transactionnel.

---

## 29. GÉNÉRATION DE CODES MÉTIER — ENUM TypeSequence (24/09/2026)

### Contexte
Le nom réel du moteur est `CodeGenerateurService` (package `com.digierp.rh.shared.service`).
Les mentions `CodeSequenceService` de LECONS_APPRISES §9/§16/§17
désignent ce même service sous son ancien nom.

Jusqu'au 24/09/2026, `generer(String module, Long siteId)` filtrait uniquement sur
`erp_code_sequence.module` et ignorait `type_document`. Un module à plusieurs séquences
(CONTRAT : CNT/AVN, DISCIPLINE : EXPL/DISC, FORMATION : FRM/DFR/PRG) obtenait une
séquence au hasard, et `generer("AVENANT")` / `generer("EXPLICATION")` échouaient.

### API unique — paramètre typé
```java
// Séquence globale (site_id NULL)
codeGenerateur.generer(TypeSequence.CONTRAT);

// Séquence du site, sinon fallback global
codeGenerateur.generer(TypeSequence.EMPLOYE, siteId);
```
Les anciennes signatures `generer(String)` et `generer(String, Long)` sont SUPPRIMÉES.

### Enum TypeSequence (shared/service/TypeSequence.java)
Chaque constante porte le couple (module, type_document) d'une ligne de erp_code_sequence :
```java
EMPLOYE             ("EMPLOYE",     "EMPLOYE"),
POSTE               ("POSTE",       "POSTE"),
CONTRAT             ("CONTRAT",     "CONTRAT"),
AVENANT             ("CONTRAT",     "AVENANT"),
ABSENCE             ("ABSENCE",     "ABSENCE"),
EXPLICATION         ("DISCIPLINE",  "EXPLICATION"),
DISCIPLINE          ("DISCIPLINE",  "DISCIPLINE"),
MISSION             ("MISSION",     "MISSION"),
FORMATION_SESSION   ("FORMATION",   "SESSION"),     // FRM
FORMATION_DEMANDE   ("FORMATION",   "DEMANDE"),     // DFR
FORMATION_PROGRAMME ("FORMATION",   "PROGRAMME"),   // PRG
PRET, STAGE, RECRUTEMENT                            // modules à venir
```

### Règles
```
✅ Toujours codeGenerateur.generer(TypeSequence.XXX[, siteId])
❌ Jamais de chaîne "MODULE" passée au générateur
✅ Toute nouvelle séquence Flyway = une constante TypeSequence dans le même commit
✅ La requête filtre module + type_document + actif, site puis fallback global,
   avec verrou PESSIMISTIC_WRITE (SELECT ... FOR UPDATE)
✅ Message d'erreur explicite : "Aucune séquence configurée pour CONTRAT / AVENANT"
```

### Parallèle Laravel
Backed enum PHP 8.1 passé en paramètre typé, au lieu de chaînes magiques —
mais vérifié à la compilation en Java.

---

## 30. PATTERN CODE MÉTIER — FACULTATIF À LA CRÉATION, IMMUABLE ENSUITE (24/09/2026)

Référence : `RhPosteService` (Postes) puis `FrmCatalogueService` (Programmes).

### DTO Request
```java
/**
 * Code — FACULTATIF.
 * Création : si vide, généré (TypeSequence.XXX) ; sinon majuscules + unicité.
 * Modification : ignoré — immuable après création.
 */
@Size(max = 40)          // PAS de @NotBlank
private String code;
```

### Service
```java
@Transactional
public XxxDto.Response creer(XxxDto.Request req, String utilisateur) {
    String code = StringUtils.hasText(req.getCode())
            ? req.getCode().toUpperCase().trim()
            : codeGenerateur.generer(TypeSequence.XXX);
    if (repo.existsByCode(code))
        throw new RhBusinessException("Le code '" + code + "' existe deja");
    Xxx entite = new Xxx();
    entite.setCode(code);
    remplir(entite, req);          // remplir() ne touche JAMAIS au code
    ...
}

@Transactional
public XxxDto.Response modifier(Long id, XxxDto.Request req, String utilisateur) {
    Xxx entite = trouverOuEchouer(id);
    // Code immuable : req.getCode() volontairement ignoré
    remplir(entite, req);
    ...
}
```

### Règles
```
✅ remplir() ne positionne jamais le code
✅ Pas de existsByCodeAndIdNot en modification (le code ne change pas)
✅ StringUtils.hasText() : null, "" et "   " → génération (équivalent Laravel filled())
❌ @NotBlank sur code dans un Request dont le code peut être généré
```

### Dette connue
`FrmModuleDto.Request` exige encore `code` (@NotBlank) alors que `ModuleForm` ne l'envoie
pas → création/modification des modules en 400. À aligner sur ce pattern
(+ séquence FORMATION/MODULE en V302 + constante TypeSequence).

---

## 31. FLYWAY — RECALAGE DES COMPTEURS APRÈS DONNÉES DE TEST (24/09/2026)

### Problème
Des données de test insérées avec des codes fixes (ex : FRM-2026-00001..00003) laissent
le compteur de erp_code_sequence à 0 → le premier code généré entre en collision
(contrainte UNIQUE).

### Pattern obligatoire — recalage sur le MAX réel
```sql
UPDATE erp_code_sequence s
SET valeur_courante = GREATEST(s.valeur_courante, COALESCE((
        SELECT MAX(CAST(SPLIT_PART(t.code, '-', 3) AS INTEGER))
        FROM ma_table t
        WHERE t.code LIKE s.prefixe || '-' || s.annee || '-%'
    ), 0))
WHERE s.module = 'MODULE'
  AND s.type_document = 'TYPE'
  AND s.site_id IS NULL;
```
Placé dans le script de données de test, APRÈS les INSERT.

### Règles
```
❌ valeur_courante = 2            (valeur en dur : se désynchronise)
❌ valeur_courante = COUNT(*)     (faux dès qu'un numéro manque dans la série)
✅ GREATEST(valeur_courante, MAX(numéro extrait)) — un compteur ne recule jamais
```
Parallèle Laravel : `SELECT setval('seq', MAX(id))` après un seeder à ID explicites.

### Dette connue
V102 (COUNT(*) sur contrats et explications) et V224 (valeur 2 en dur pour MISSION)
sont à aligner sur ce pattern. V223 tente de créer MISSION avec le préfixe MIS alors que
V007 l'a déjà créée en MSN (WHERE NOT EXISTS → ignoré) : les données de test sont en
MIS-…, les missions générées en MSN-….

---

## 32. SURCHARGES DE MÉTHODES — PIÈGE DU null (24/09/2026)

### Problème
Remplacer `generer(String module, Long siteId)` par `generer(String module, String typeDocument)`
laisse compiler les anciens appels `generer("ABSENCE", null)` : `null` est accepté comme
`String`. L'erreur n'apparaît qu'à l'exécution.

### Règle
Quand on change le sens d'un paramètre d'une API partagée, changer aussi son TYPE
(enum, record, classe dédiée) pour que le compilateur signale TOUS les appels à migrer.
Supprimer les anciennes signatures plutôt que les marquer @Deprecated.
[Rev 6] Réciproque utile : une surcharge dont les paramètres DIFFÈRENT PAR LEUR TYPE est sûre
(`estGestionnaire()` publique / `estGestionnaire(RhUtilisateur)` privée ; `refus(a, d)` /
`refus(a, d, lecteur)`), et rendre une méthode d'interface ABSTRAITE fait signaler par le
compilateur chaque implémentation à compléter.

### Procédure de migration guidée par le compilateur
```bash
cd rh-api && mvn -q compile 2>&1 | grep "ERROR.*\.java" \
  | sed 's#.*/com/digierp/rh/##' | sort -u; echo "code retour mvn : ${PIPESTATUS[0]}"
```
Migrer fichier par fichier jusqu'à 0 erreur (code retour 0).
[Rev 7] Même technique pour RETIRER une méthode d'un repository : annoncer la liste EXACTE
des fichiers qui doivent échouer (l'inventaire des appelants) ; toute erreur ailleurs est un
appelant que l'inventaire n'avait pas vu.

---

## 33. RLS — CONTEXTE POSÉ DANS CHAQUE TRANSACTION (28/09/2026)

### Problème corrigé (commit 65f37d0)
L'ancien `RlsTransactionInterceptor` était un FILTRE HTTP qui posait le rôle par
`set_config(..., false)` (réglage de SESSION) sur une connexion obtenue par
`DataSourceUtils.getConnection()` HORS transaction : une connexion quelconque du pool,
rendue aussitôt. La transaction de la requête recevait une AUTRE connexion, portant le rôle
laissé par une requête précédente (celui d'un autre utilisateur, ou SYSTEM du healthcheck).
Résultats aléatoires et fuite de droits entre utilisateurs.

### Mécanisme en place
| Composant | Rôle |
|---|---|
| `RlsContexte` | `ThreadLocal` (rôle, employé) ; `SYSTEM` par défaut hors requête HTTP |
| `RlsContexteFilter` | pose `ANONYME`, puis le rôle de l'utilisateur ; `vider()` en `finally` ; ne touche AUCUNE connexion ; enregistrement automatique Tomcat désactivé (`FilterRegistrationBean.setEnabled(false)`), placé après `JwtAuthenticationFilter` |
| `RlsJpaTransactionManager` | bean `transactionManager` ; après `doBegin`, `set_config('app.current_role', ?, true)` et `app.current_user_id` sur la connexion de LA transaction ; échec → `CannotCreateTransactionException` (jamais de transaction sans contexte) |
| `RlsConnectionCustomizer` | DataSource `digierp_app` ; `connectionInitSql` = `ANONYME` (filet : hors transaction, on ne voit rien) |
| `RlsCapacite` [Rev 5] | pose `app.action_workflow` sur la connexion de LA transaction, le temps d'une action du moteur de workflow (§41) |

### Rôles techniques
```
SYSTEM  : traitements de fond (jobs, initialisation, @Async) — accès complet
ANONYME : requête HTTP sans utilisateur (login, healthcheck) — aucun accès
Une requête HTTP ne reçoit JAMAIS SYSTEM (RlsContexteFilter le refuse et journalise).
```

### Règles
```
✅ set_config(..., true) (LOCAL à la transaction) exclusivement, dans RlsJpaTransactionManager
   [Rev 5] et RlsCapacite (même technique : Session.doWork sur la connexion de la transaction)
❌ set_config(..., false), SET sans LOCAL, DataSourceUtils.getConnection() hors transaction
❌ Poser un contexte RLS dans un filtre, un intercepteur ou un @PostConstruct
✅ Un traitement qui doit voir toutes les lignes (job, initialisation) s'exécute hors
   requête HTTP → SYSTEM par défaut, dans une transaction ; ne pas « injecter ADMIN »
✅ Toute transaction imbriquée REQUIRED rejoint la transaction et son contexte
```
Parallèle Laravel : un écouteur de `TransactionBeginning` qui fait `SET LOCAL`, au lieu
d'un middleware qui ferait un `SET` sur une connexion persistante au hasard.

---

## 34. RLS — AUCUNE REQUÊTE HORS TRANSACTION SUR UNE TABLE SOUS RLS (28/09/2026)

### Problème
Hors transaction, une requête s'exécute avec le contexte de session ANONYME et ne voit
AUCUNE ligne des tables sous RLS, sans erreur. Or seules les méthodes HÉRITÉES de Spring
Data (`findAll`, `findById`, `save`) sont transactionnelles par défaut ; les méthodes
DÉCLARÉES (`@Query`, requêtes nommées) ne le sont pas. Appelées depuis un controller, un job
ou un service non annoté : liste vide silencieuse (cas réel : « Mes tâches » vide, jobs
Missions qui ne trouvaient plus rien).

### Trois défenses, garanties par le code
1. **Repository d'une table sous RLS** : `@Transactional(readOnly = true)` sur l'INTERFACE,
   `@Transactional` sur chaque méthode `@Modifying`. Une transaction existante est rejointe
   (aucun changement pour un service correct) ; `save` hérité reste en écriture.
2. **`RlsRepositoriesVerificateur`** (ApplicationRunner) : au démarrage, lit les tables sous
   RLS dans PostgreSQL (`pg_class.relrowsecurity`), énumère TOUS les repositories
   (`RepositoryFactoryInformation`) et REFUSE DE DÉMARRER si l'un ne respecte pas la règle 1
   (liste complète des manquements dans les logs `[RLS-VERIF]`).
3. **`RlsHorsTransactionDetecteur`** (StatementInspector Hibernate) : toute requête HORS
   transaction qui vise une table sous RLS lève `IllegalStateException("[RLS-HORS-TX] ...")`
   (table, requête, endroit du code) au lieu de renvoyer zéro ligne.
### Règles
```
✅ Nouvelle table sous RLS → politiques standard (§40) + repository annoté ; le démarrage
   le vérifie (§44)
✅ Controller → Service @Transactional → Repository, toujours
✅ Lecture pour un écran générique (Mes tâches) : méthode de service readOnly qui renvoie
   des DTO construits DANS la transaction
❌ Contourner la garde (session SYSTEM par défaut, @Transactional sur un controller)
⚠  JdbcTemplate n'est pas couvert par la garde : ne l'utiliser sur une table sous RLS que
   dans une transaction
[Rev 7] Une fonction d'agrégat (§49) appelée hors transaction échoue aussi, par sa garde
   (contexte ANONYME → [RLS-AGREGAT]) : même principe, défaut bruyant
```

---

## 35. RLS — FONCTIONS DE CONTEXTE (28/09/2026, mis à jour Rev 5)

### Fonctions uniques (V004)
```sql
-- Liste UNIQUE des rôles à accès complet (SYSTEM inclus ; ANONYME et EMPLOYE exclus)
CREATE OR REPLACE FUNCTION rls_acces_complet() RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT coalesce(current_setting('app.current_role', TRUE), '') IN (
        'SYSTEM', 'ADMIN', 'GESTIONNAIRE_RH', 'GESTIONNAIRE_SITE', 'AUDITEUR', 'VALIDATEUR')
$$;
CREATE OR REPLACE FUNCTION rls_employe_courant() RETURNS TEXT LANGUAGE sql STABLE AS $$
    SELECT coalesce(current_setting('app.current_user_id', TRUE), '')
$$;
-- [Rev 5] Capacité du moteur de workflow (§41)
CREATE OR REPLACE FUNCTION rls_action_workflow() RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT coalesce(current_setting('app.action_workflow', TRUE), '') = 'on'
$$;
```
Les fonctions de visibilité des valideurs et le modèle de politique sont en §40 ; [Rev 7] les
fonctions d'agrégat et leur garde `rls_employe_lisible` en §49.

### Modèles de politique [Rev 5 — REMPLACÉS]
Les modèles écrits à la main de la Rev 4 (`CREATE POLICY pol_x_self ON x USING (...)` sans
`FOR`, table fille par EXISTS en `FOR ALL`) sont ABANDONNÉS : une politique `USING` sans
`FOR` ouvre la même visibilité en lecture ET en écriture (un valideur qui lit un document
pouvait aussi l'écrire). Seul modèle autorisé : `rls_appliquer_politiques` (§40).

### Règles
```
❌ Recopier une liste de rôles dans une politique : toujours rls_acces_complet()
❌ Lire current_setting directement dans une politique (fonctions uniques)
❌ ENABLE ROW LEVEL SECURITY sans politique pour digierp_app (= refus total silencieux)
❌ [Rev 5] CREATE POLICY / ENABLE / FORCE écrits à la main : rls_appliquer_politiques
✅ Contrôle : SELECT count(*) FILTER (WHERE qual LIKE '%current_setting%') FROM pg_policies = 0
```

---

## 36. ABSENCES GÉNÉRÉES — SOURCE UNIQUE DE DISPONIBILITÉ (28/09/2026)

### Principe
`abs_demande` est la SEULE source de disponibilité d'un employé. Tout module qui immobilise
un employé (mission, mise à pied, formation) y crée, met à jour et annule ses absences
UNIQUEMENT par `AbsAbsenceGenereeService`, dans SA transaction.

### Lien polymorphe
```
abs_demande.origine_type (AbsOrigineType : MISSION | DISCIPLINE | FORMATION) + origine_id
CHECK généré depuis l'enum ; CHECK (origine_type IS NULL) = (origine_id IS NULL)
Clé d'une absence générée : (origine_type, origine_id, employe_id) — plusieurs possibles
Aucune colonne « absence_generee_id » / « mission_id » dans les tables métier
```

### Types réservés
```
abs_type_absence.origine_type : NULL = saisissable ; sinon réservé au module
Index unique partiel : un seul type ACTIF par origine
Le type d'une absence générée est DÉDUIT de l'origine (findByOrigineType), jamais passé en chaîne
Saisie manuelle (creer, signaler) d'un type réservé → 422 (interdireTypeReserve)
Archivage d'un type réservé → 422
Nouveau module générateur : semer son type réservé dans SON script Flyway
```

### API
```java
absenceGenereeService.synchroniser(AbsOrigineType.X, origineId, employeId,
    List.of(new AbsAbsenceGenereeService.Periode(debut, fin, nbJours)), detail, utilisateur);
// réconciliation : garde / annule / crée ; liste vide = tout annuler pour cet employé
absenceGenereeService.annuler(AbsOrigineType.X, origineId, motif, utilisateur);
absenceGenereeService.verifierDisponibilite(employeId, debut, fin, excludeId);
absenceGenereeService.interdireSiGeneree(absence, "annuler");
```

### Règles
```
✅ Absence générée : APPROUVEE, source SYSTEME, emetteur null, historique ; [Rev 7] elle
   compte d'elle-même dans le solde (calculé à la lecture, §49) : plus aucun recalcul
✅ Origine disparue → absence ANNULEE (historique conservé), jamais supprimée
✅ Statuts qui n'occupent pas la période (BROUILLON, REJETEE, ANNULEE) définis UNE fois
   (AbsAbsenceGenereeService.STATUTS_NON_OCCUPANTS) ; contrôle refait à la soumission
✅ Conflit de disponibilité → 422 qui annule TOUTE l'opération du module appelant
❌ try/catch autour de synchroniser (voir §6 : rollback-only → 500)
❌ Modifier / annuler / supprimer à la main une absence générée
✅ [Rev 5] Une absence générée pour un AUTRE employé (participant d'une mission) pendant une
   décision est une écriture pour autrui : elle passe par la capacité du moteur (§41) ;
   abs_demande est déclarée « écrite par le workflow » (§40)
```

---

## 37. WORKFLOW — DÉCISION, CLÔTURE ET peutDecider (28/09/2026, complété Rev 5 et Rev 6)

### Pattern d'un module (référence : MissionService, AbsDemandeService)
```
soumettre : workflowService.demarrer(...) ; statut EN_WORKFLOW ; id d'instance ; notification
decider   : contrôles (EN_WORKFLOW, VALIDE|REJETE, commentaire obligatoire si REJETE)
            → workflowService.decider(...) ; si l'instance reste en cours : historique +
            notification de l'étape suivante ; relecture du document. PAS de clôture ici.
@EventListener surClotureWorkflow(WfInstanceClotureeEvent) : filtre par module, ignore
            l'annulation ; APPROUVEE / REJETEE, historique, effets (absences générées...),
            notification. Même transaction : un échec annule la décision.
annuler   : si EN_WORKFLOW → workflowService.annuler(instance, motif) (tâches retirées)
```
Conséquence : une décision prise depuis « Mes tâches » (endpoint générique) a EXACTEMENT
le même effet que depuis l'écran du module.

### Moteur — règles Rev 5
```
demarrer : refuse un type sans table du document (WfTypeDocument.tableDocument null) :
           IllegalStateException [WF] (erreur de développement, 500) — ses valideurs ne
           verraient pas le document (§44)
decider / deleguer :
  1. instanceRepository.existsById(id) SANS capacité (politique de LECTURE) : inexistante ou
     invisible → RhNotFoundException (404), l'existence n'est jamais révélée
  2. puis TOUT le reste sous rlsCapacite.pendantActionWorkflow(...) (§41) : verrou
     SELECT ... FOR UPDATE, contrôle de l'acteur désigné (403 WfAutorisationException) AVANT
     toute écriture, décision, étape suivante, clôture et événement synchrone
  Instance visible mais acteur non désigné → 403 ; clôturée → 403 (instanceCloturee)
annuler  : appelé par le demandeur (propriétaire) ou un gestionnaire (accès complet) :
           pas de capacité nécessaire
Instance introuvable : RhNotFoundException (404), jamais IllegalArgumentException (500)
```
Dette (temps 3 de l'incrément 3bis) : une étape INTERMÉDIAIRE validée depuis « Mes tâches »
n'écrit ni historique ni notification du module → événement `WfDecisionEnregistreeEvent`
(D-a) ; lecture VALIDE|REJETE et commentaire obligatoire à factoriser dans le moteur ;
[Rev 6] porte PBAC unique pour décider (§48).

### Reconnaître le module d'un document
```java
private static boolean estDocumentAbsence(String documentType) {
    String module = WfTypeDocument.ABSENCE_CONGE_ANNUEL.getModule();
    for (WfTypeDocument t : WfTypeDocument.values())
        if (t.getCode().equals(documentType)) return module.equals(t.getModule());
    return false;
}
```

### peutDecider et actionsPermises — données dérivées
```
Response ET SummaryResponse du document : Boolean peutDecider =
    EN_WORKFLOW && workflowService.peutDecider(instance, utilisateurConnecte)
Gère les étapes ROLE à plusieurs acteurs. Remplace acteurAttenduUtilisateurId (supprimé).
[Rev 6] Livré (c124e576, Absences) : List<String> actionsPermises, calculée par la politique
de document (§42) avec le lecteur photographié ; l'écran ne propose que les actions permises
sur CE document. La décision reste sur peutDecider (moteur), jamais dans actionsPermises.
```

### Écrans génériques
```
Mes tâches / Mes demandes / réponse de la décision générique : méthodes de WorkflowService
@Transactional(readOnly = true) qui renvoient des WfInstanceResponse (§34)
[Rev 5] RH.WORKFLOW:LIRE est accordé au rôle EMPLOYE : les lignes sont filtrées par la RLS
(ses demandes ; les instances qu'il décide)
[Rev 6] WfInstanceResponse (relevé réel le 29/09) : id, documentId, employeId, statut,
etapeCourante, modeleCode, modeleLibelle, dateCreation, dateCloture, decisions[{id, acteurId,
etapeOrdre, etapeLibelle, statut, commentaire, delegueAId, dateDecision}] — sans documentType,
numéro, demandeur, dates, total d'étapes ni noms d'acteurs : le valideur ne sait pas sur quoi
il décide → WfTacheResponse et résumé par module (temps 2 (c) de l'incrément 3bis)
[Rev 7] Tout chiffre d'un résumé montré au valideur (solde restant...) passe par la règle
indépendante du lecteur (§49)
[Rev 8] Livré (eee5170e) : /taches et /instances/mes-demandes renvoient WfTacheResponse ;
GET /taches/{instanceId} = détail (résumé détaillé + circuit) ; la réponse de la DÉCISION
reste WfInstanceResponse (champ id) — voir §50
```

---

## 38. JOBS PLANIFIÉS (28/09/2026)

```
Contexte RLS : SYSTEM (thread hors requête HTTP), dans une transaction
Lecture : service dédié en @Transactional(readOnly = true) (ex : MisJobService) qui renvoie
          des IDENTIFIANTS ou des RECORDS extraits dans la transaction (aucune entité LAZY
          manipulée après la fin de la transaction)
Écriture : une transaction PAR élément (méthode @Transactional du service métier) ;
           catch par élément autorisé car HORS de toute transaction englobante :
           log.error(..., e) avec la pile, puis élément suivant
❌ @Transactional sur la méthode du job entier (écritures en lecture seule, un échec annule tout)
❌ Repository injecté dans un job
❌ catch autour d'un simple log (masquerait une vraie erreur future)
Pas de déclenchement manuel à ce jour : vérifier les logs [JOB] le lendemain d'un déploiement.
```

---

## 39. CHECKLIST — COMPLÉMENTS REV 4 (nouveau module)

[ ] 22. Table sous RLS : [Rev 5] politiques standard par rls_appliquer_politiques (§40) ;
        table fille : lecture par EXISTS sur le parent, écriture réservée aux propriétaires
[ ] 23. Repository d'une table sous RLS : @Transactional(readOnly = true) sur l'interface,
        @Transactional sur les @Modifying (le démarrage le vérifie)
[ ] 24. Aucun repository de table sous RLS dans un controller ou un job
[ ] 25. Document soumis à validation : pattern §37 (soumettre / decider / surClotureWorkflow /
        annuler), peutDecider dans Response et SummaryResponse
[ ] 26. Document qui immobilise un employé : absences via AbsAbsenceGenereeService (§36),
        type réservé semé dans le script Flyway du module, constante AbsOrigineType
[ ] 27. Données de référence utilisées par le code : semées par Flyway, recherchées sans catch
[ ] 28. Entité @Builder : @Builder.Default sur chaque champ initialisé
[ ] 29. Jobs : lecture par service readOnly, une transaction par élément (§38)
[ ] 30. Relancer docs/digierp/tests/nonreg_rls_workflow.py : 0 ECHEC

---

## 40. RLS — POLITIQUES STANDARD : DEUX MOTEURS, LECTURE ET ÉCRITURE (29/09/2026)

### Problème corrigé
Les politiques écrites à la main (`USING` sans `FOR`) donnaient la même visibilité en lecture
et en écriture. RLS-2 ayant ouvert la LECTURE d'un document à son valideur, celui-ci pouvait
aussi le MODIFIER en base : preuve, `POST /absences/{id}/annuler` par le N+1 passait le PBAC
et le chargement ; seule une lecture annexe (le contrat du demandeur) l'arrêtait, par hasard.
Deux styles coexistaient aussi (V004 `TO public` sans FORCE ; V208/V219 `TO digierp_app` +
FORCE + owner).

### Principe
```
LECTURE  = accès complet OU propriétaire OU valideur du document (ou parent visible)
ÉCRITURE = accès complet OU propriétaire [OU action du moteur de workflow (§41)]
Un valideur n'apparaît JAMAIS en écriture : il lit, il ne modifie pas — quel que soit le code Java.
Les autres verbes métier (annuler, soumettre, qualifier...) sont tous des UPDATE : la base ne
peut pas les distinguer → ils relèvent de la politique de document (§42), pas de la RLS.
```

### Procédure unique (V004) — aucune politique écrite à la main
```sql
CALL rls_appliquer_politiques(
    'abs_demande',                                   -- table
    'employe_id::TEXT = rls_employe_courant()',      -- PROPRIÉTAIRE (obligatoire ; 'FALSE' = aucun)
    'rls_decideur_de(''abs_demande'', id)',          -- lecture en plus (valideur / parent), ou NULL
    TRUE);                                           -- le moteur de workflow écrit-il ici ?
```
La procédure : vérifie ses arguments ; supprime TOUTE politique existante de la table ;
`ENABLE` + `FORCE ROW LEVEL SECURITY` ; crée exactement :

| Politique | Commande | Rôle | Condition |
|---|---|---|---|
| `pol_<t>_owner` | toutes | propriétaire de la table (lu dans pg_tables) | `USING (true) WITH CHECK (true)` |
| `pol_<t>_lecture` | `SELECT` | `digierp_app` | accès complet OR propriétaire [OR lecture en plus] |
| `pol_<t>_ecriture` | toutes | `digierp_app` | accès complet OR propriétaire [OR `rls_action_workflow()`], `USING` = `WITH CHECK` |

Parallèle Laravel : un trait appliqué à chaque modèle, au lieu d'un global scope recopié.

[Rev 9] ⚠️ Le paramètre PROPRIÉTAIRE entre dans la LECTURE ET dans l'ÉCRITURE. Pour donner la
seule LECTURE à d'autres personnes (participants d'une mission, valideurs), on passe par
« lecture en plus » ; restreindre l'écriture en touchant le propriétaire sans reporter
l'ancienne condition en « lecture en plus » retirerait aussi la lecture (§51.4). Et le
propriétaire se teste sur les COLONNES de la ligne, jamais par une fonction qui relit la table
par son id (§51.4) : `USING` et `WITH CHECK` étant égaux, le défaut toucherait l'INSERT ET l'UPDATE.

### Pourquoi l'écriture en FOR ALL (et pas INSERT/UPDATE/DELETE)
Hibernate relit ce qu'il écrit (`INSERT ... RETURNING`, `UPDATE ... WHERE version = ?`) :
PostgreSQL applique alors AUSSI les politiques de lecture aux lignes écrites. Une absence
générée pour un participant (invisible pour le valideur de la mission) échouerait sans
`pol_<t>_ecriture` en FOR ALL.

### Piège : SELECT ... FOR UPDATE applique les politiques d'ÉCRITURE
Un verrou pessimiste pris par un valideur sur une ligne qu'il ne peut que LIRE ne trouve
aucune ligne. D'où, dans le moteur : visibilité vérifiée d'abord par une lecture simple (404),
puis verrou pris SOUS la capacité (§37, §41).

### Fonctions de visibilité des valideurs (V004, V219)
```sql
-- Toutes : LANGUAGE sql STABLE SECURITY DEFINER SET search_path FROM CURRENT
-- REVOKE EXECUTE ... FROM PUBLIC ; GRANT EXECUTE ... TO digierp_app
-- Ne renvoient qu'un BOOLÉEN, jamais de lignes.
rls_decideur_de(p_table TEXT, p_document_id BIGINT)
    -- ai-je (eu) une décision sur ce document ? (wf_instance ⋈ wf_type_document.table_document
    --  ⋈ wf_decision ⋈ rh_utilisateur.employe_id = moi), QUEL QUE SOIT le statut de la décision
rls_decideur_instance(p_instance_id BIGINT)    -- ai-je une décision sur cette instance ?
rls_demandeur_visible(p_employe_id BIGINT)     -- est-il le demandeur d'une instance que je décide ?
rls_proprietaire_mission(p_mission_id BIGINT)  -- missionnaire principal ou participant (V219)
    -- [Rev 9] LECTURE de la mission (« lecture en plus ») et PROPRIÉTÉ des tables filles ;
    --  JAMAIS dans le propriétaire de mis_mission elle-même (elle relit mis_mission : §51.4)
```
- **SECURITY DEFINER** : exécution avec les droits du propriétaire, non soumis à la RLS de
  wf_instance → pas de récursion entre politiques (la politique d'abs_demande lit wf_instance
  dont la politique relirait...). Parallèle Laravel : `withoutGlobalScopes()` confiné dans une
  méthode qui ne renvoie qu'un booléen.
- **search_path figé** : une fonction DEFINER ne doit pas pouvoir être détournée par le
  search_path de l'appelant (dette : durcir `FROM CURRENT` en `SET search_path = public` ;
  [Rev 7] déjà fait pour les fonctions d'agrégat de §49).
- Les acteurs d'une étape FUTURE ne voient rien : les décisions sont créées étape par étape.
- Le valideur garde la lecture de ce qu'il a décidé (historique), y compris après clôture ou
  annulation.
- [Rev 7] Deuxième famille de fonctions DEFINER : les fonctions d'AGRÉGAT (§49), qui
  renvoient un nombre ou l'id d'une règle, jamais une ligne, derrière une garde.
### État des 14 tables (V004, V208, V219) — [Rev 9] relu en base le 05/10 après 89ae754f
| Table | Propriétaire (lecture + écriture) | Lecture en plus | Workflow écrit |
|---|---|---|---|
| rh_employe | id = moi | `rls_demandeur_visible(id)` | non |
| rh_contrat | employe_id = moi | — (rémunération : jamais ouverte au valideur) | non |
| rh_poste | `FALSE` (un poste n'appartient pas à son titulaire) | mes postes actifs + poste du demandeur | non |
| abs_demande | employe_id = moi | `rls_decideur_de('abs_demande', id)` | **oui** |
| disc_demande_explication | employe_id = moi | `rls_decideur_de(...)` | non (pas encore sur le workflow) |
| disc_mesure | employe_id = moi | `rls_decideur_de('disc_mesure', id)` | **oui** |
| wf_instance | employe_id = moi | `rls_decideur_instance(id)` | **oui** |
| mis_mission | [Rev 9] **employe_principal_id = moi** (colonne) | [Rev 9] `rls_proprietaire_mission(id)` (participants) OR `rls_decideur_de('mis_mission', id)` | **oui** |
| mis_mission_employe | employe_id = moi | valideurs de la mission | non (incrément 5 si besoin) |
| mis_avance, mis_reglement, mis_rapport_mission | employe_id = moi | — | non |
| mis_frais, mis_affectation_moyen (filles) | `rls_proprietaire_mission(mission_id)` (parent : correct, §51.4) | mission parente visible (EXISTS) | non |

### Règles
```
✅ Toute table sous RLS : UN appel rls_appliquer_politiques dans le script de son module
✅ Moindre privilège : p_workflow = TRUE seulement si le moteur écrit RÉELLEMENT dans la
   table (mesuré, pas supposé : compteurs pg_stat_user_tables avant/après décisions)
✅ Table fille : lecture = parent visible ; écriture = propriétaires du parent (fonction
   SECURITY DEFINER unique, jamais le simple « parent visible »)
✅ Colonne qualifiée dans une sous-requête de table fille (mis_frais.mission_id)
✅ [Rev 9] Propriétaire = condition sur les COLONNES de la ligne écrite ; lecture élargie par
   « lecture en plus » ; moindre privilège en écriture (le missionnaire principal seul écrit
   sa mission, comme personne n'écrit son poste)
❌ Condition de valideur dans le paramètre PROPRIÉTAIRE (elle ouvrirait l'écriture)
❌ [Rev 9] Fonction qui relit la table elle-même dans le paramètre PROPRIÉTAIRE (§51.4)
❌ Ouvrir une table sensible au valideur « pour afficher un champ » (rh_contrat) :
   projection vide acceptée (§43) ; [Rev 7] ni « pour calculer un total » : fonction
   d'agrégat (§49)
Démarrage refusé si une table ne porte pas exactement ce modèle (§44)
```

---

## 41. CAPACITÉ DU MOTEUR DE WORKFLOW — RlsCapacite (29/09/2026)

### Besoin
Seul le moteur écrit pour autrui : étape suivante (`wf_instance`), clôture (statut du
document), absences générées pour d'autres employés. Ces écritures ne doivent être possibles
QUE pendant l'acte du moteur, après vérification de l'acteur désigné.

### API
```java
// WorkflowService — après le contrôle de visibilité (404), avant tout le reste
return rlsCapacite.pendantActionWorkflow(
    () -> deciderSousCapacite(instanceId, acteurId, statut, commentaire));
```
`pendantActionWorkflow(Supplier<T>)` :
1. exige une transaction active (sinon `IllegalStateException [RLS]`) ;
2. pose `set_config('app.action_workflow', 'on', true)` sur la connexion de LA transaction
   (`Session.doWork`, comme `RlsJpaTransactionManager`) ;
3. exécute l'action (décision, clôture par l'événement SYNCHRONE) ;
4. **`entityManager.flush()`** : JPA diffère les écritures jusqu'au commit ; elles doivent
   partir PENDANT que la capacité est active ;
5. retire la capacité (`'off'`).
### Pièges traités
```
Réentrance   : marqueur lié à la transaction (TransactionSynchronizationManager.bindResource) ;
               seul l'appel le plus externe pose, flush et retire
Exception    : la transaction peut être « aborted » → le retrait échouerait et masquerait
               l'erreur ; l'échec du retrait est attaché en suppressed, l'exception d'origine
               est relancée intacte (la capacité, locale, meurt de toute façon au rollback)
Fuite        : set_config local (true) → effacée au COMMIT/ROLLBACK, jamais héritée par une
               autre requête via le pool (prouvé par la campagne, S4)
Nom          : app.action_workflow écrit à UN endroit en Java (constante), miroir de
               rls_action_workflow() (V004)
```

### Règles
```
✅ Appelée UNIQUEMENT par le moteur (WorkflowService.decider / deleguer), APRÈS le contrôle
   de visibilité et AVANT le contrôle de l'acteur désigné (qui lève 403 → rollback)
✅ La capacité n'ouvre que l'ÉCRITURE des tables « écrites par le workflow » (§40) : jamais
   la lecture, jamais les autres tables (rh_employe, rh_contrat, rh_poste...)
❌ Capacité posée par un module, un contrôleur ou un job
❌ Oublier le flush avant le retrait
Parallèle Laravel : un Gate::before activé pour la durée d'une closure DB::transaction().
```

---

## 42. POLITIQUE DE DOCUMENT — QUI PEUT FAIRE QUOI SUR CE DOCUMENT (29/09/2026, réécrite Rev 6)

### Trois couches d'autorisation, chacune à son niveau
| Couche | Question | Parallèle Laravel |
|---|---|---|
| PBAC `@pe.peutFaire('RH.ABSENCE','ANNULER')` | ce rôle peut-il annuler DES absences ? | Gate |
| **Politique de document** | cette personne peut-elle annuler CETTE absence ? | Policy (`$this->authorize()`) |
| RLS (§40) | filet en base : lecture/écriture séparées | global scope imposé par la base |

### La même règle sert à REFUSER et à INFORMER [Rev 6]
`verifier` lève le 403 motivé ; `actionsPermises` dit à l'écran quelles actions proposer
(STANDARDS_FRONTEND §35). Les deux passent par LA règle unique `refus(action, doc, lecteur)` :
ce que l'écran propose et ce que le serveur accepte ne peuvent pas diverger.

### Lecteur photographié [Rev 6]
```java
// shared/security/LecteurDocument.java
public record LecteurDocument(boolean gestionnaire, Long employeId) {
    public static final LecteurDocument AUCUN = new LecteurDocument(false, null);
    public boolean estProprietaire(Long employeIdDocument) {      // sûr face au null
        return employeId != null && employeId.equals(employeIdDocument);
    }
}
// ContexteUtilisateurService — 2 requêtes (utilisateur, rôles), mêmes critères que
// estGestionnaire() / estProprietaire() (critère « gestionnaire » factorisé dans une
// surcharge privée estGestionnaire(RhUtilisateur), une règle un endroit)
public LecteurDocument lecteurDocument() {
    return getUtilisateurConnecte()
        .map(u -> new LecteurDocument(estGestionnaire(u), u.getEmployeId()))
        .orElse(LecteurDocument.AUCUN);
}
```
Pourquoi : `estGestionnaire()` relit l'utilisateur et ses rôles à chaque appel. Évaluer
20 lignes × 9 actions ferait des centaines de requêtes ; avec le lecteur photographié UNE fois
par requête, 2 requêtes suffisent. Parallèle Laravel : un petit DTO readonly calculé une fois
et passé aux Policies, au lieu d'appeler `auth()->user()->roles` à chaque ligne.
Ne porter dans le lecteur que ce dont une règle a besoin (ajouter un champ quand une règle
l'exige, jamais avant).

### Interface (shared/security)
```java
public interface PolitiqueDocument<D, A extends Enum<A>> {

    /** LA règle : motif du refus pour ce lecteur, ou vide si permise. */
    Optional<String> refus(A action, D document, LecteurDocument lecteur);

    /** Enum des actions du module : sert à énumérer les actions permises. */
    Class<A> typeActions();

    /** Photographie du lecteur connecté (ContexteUtilisateurService.lecteurDocument()). */
    LecteurDocument lecteurCourant();

    default Optional<String> refus(A action, D document) {
        return refus(action, document, lecteurCourant());
    }

    default void verifier(A action, D document) {          // 403 motivé
        refus(action, document).ifPresent(motif -> { throw new RhAccesDocumentException(motif); });
    }

    /** Codes (noms de l'enum, ordre de déclaration) des actions permises. */
    default List<String> actionsPermises(D document, LecteurDocument lecteur) {
        return EnumSet.allOf(typeActions()).stream()
            .filter(action -> refus(action, document, lecteur).isEmpty())
            .map(Enum::name).toList();
    }

    default List<String> actionsPermises(D document) {
        return actionsPermises(document, lecteurCourant());
    }
}
```
Les trois méthodes ABSTRAITES sont imposées par le compilateur : une politique qui n'énumère
pas ses actions, ou qui n'évalue pas sa règle sur le lecteur, NE COMPILE PAS (preuve du
29/09 : la seule erreur de compilation après le changement d'interface portait sur
AbsDemandePolitique). Renvoyer un MOTIF (et non un booléen) : le message vit avec la règle.

### Implémentation d'un module (référence : AbsDemandePolitique)
```java
@Component @RequiredArgsConstructor
public class AbsDemandePolitique implements PolitiqueDocument<AbsDemande, AbsDemandePolitique.Action> {

    public enum Action {                       // chaque action se prononce sur le demandeur :
        SOUMETTRE("soumettre", true),           // une nouvelle constante ne compile pas sans
        ANNULER("annuler", true),               // cette décision
        SUPPRIMER("supprimer", true),
        MARQUER_SIGNALEE("marquer comme signalee", false),
        DEMANDER_JUSTIFICATION("demander un justificatif pour", false),
        QUALIFIER("qualifier", false),
        CLOTURER("cloturer", false),
        RESTAURER("restaurer", false),
        PURGER("purger", false);
        ...
    }

    private final ContexteUtilisateurService contexte;

    @Override
    public Optional<String> refus(Action action, AbsDemande demande, LecteurDocument lecteur) {
        if (lecteur.gestionnaire()) return Optional.empty();               // portée non SELF
        if (action.demandeurAdmis && demande.getEmploye() != null
                && lecteur.estProprietaire(demande.getEmploye().getId()))  // id du proxy
            return Optional.empty();
        return Optional.of(action.demandeurAdmis
            ? "Seul le demandeur ou un gestionnaire peut " + action.libelle + " cette demande"
            : "Seul un gestionnaire peut " + action.libelle + " cette demande");
    }

    @Override public Class<Action> typeActions()        { return Action.class; }
    @Override public LecteurDocument lecteurCourant()   { return contexte.lecteurDocument(); }
}
```

### Utilisation dans le service
```java
// Action sur un document : inchangé
@Transactional
public ApiResponse<AbsDemandeDto.Response> annuler(Long id, ..., String utilisateur) {
    AbsDemande d = chargerDemande(id);                              // 404 si invisible
    politique.verifier(AbsDemandePolitique.Action.ANNULER, d);     // 403 motivé
    ...
}

// Mapping : un document → lecteur photographié pour lui ; une liste → UNE fois
private AbsDemandeDto.Response toResponse(AbsDemande d) {
    return toResponse(d, politique.lecteurCourant());
}
private List<AbsDemandeDto.Response> toResponses(List<AbsDemande> demandes) {
    LecteurDocument lecteur = politique.lecteurCourant();
    return demandes.stream().map(d -> toResponse(d, lecteur)).toList();
}
private AbsDemandeDto.Response toResponse(AbsDemande d, LecteurDocument lecteur) {
    ... .peutDecider(peutDecider(d))
        .actionsPermises(politique.actionsPermises(d, lecteur)) ...
}
// findAll : LecteurDocument lecteur = politique.lecteurCourant();
//           page.map(demande -> toSummaryResponse(demande, lecteur))
```

### DTO
```java
// Response ET SummaryResponse, juste après peutDecider
// Donnee derivee (calculee a la lecture par la politique, meme regle que le refus 403)
private List<String> actionsPermises;   // noms de l'enum : le DTO ne dépend pas du package service
```

### Règles
```
✅ UNE politique par module (une règle, un seul endroit) ; enum d'actions du module
✅ La règle est évaluée sur le LECTEUR (jamais d'appel à contexte.estGestionnaire() /
   estProprietaire() dans refus) ; lecteurCourant() délègue à contexte.lecteurDocument()
✅ Chaque méthode d'ACTION sur un document existant : politique.verifier juste après le
   chargement — y compris restaurer / purger (chargement par findByIdIgnoreActif)
✅ actionsPermises dans Response ET SummaryResponse ; listes (findAll, archives, liste par
   employé) : lecteur photographié UNE fois
✅ La politique ne dit que « QUI » : le STATUT n'y entre pas (règle d'affichage côté écran ;
   le service le contrôle toujours par validerTransition → 422)
✅ La DÉCISION workflow n'est pas une action de la politique : le moteur vérifie l'acteur
   désigné (une seule règle) ; l'écran l'affiche selon peutDecider
✅ La clôture (surClotureWorkflow) n'est pas une action utilisateur : pas de politique
✅ Le périmètre des gestionnaires (site, service) reste dans le service (verifierPerimetre...)
❌ Inscrire un droit qui n'existe pas en base (ex : « émetteur » non gestionnaire : la RLS
   d'écriture le refuserait de toute façon)
Couverture : les 9 actions d'AbsDemandeService. Discipline (incrément 4), Missions (5) et
Formation (6) reçoivent leur politique ET actionsPermises avec leur branchement sur le workflow.
[Rev 9] Missions : la RLS réserve déjà l'écriture de mis_mission au missionnaire principal
(89ae754f) ; sans MisMissionPolitique, un participant non principal qui tente modifier /
soumettre / annuler reçoit un 500 (violation RLS, dette 22) au lieu d'un 403 motivé, et
l'écran lui propose peut-être ces boutons (dette 26, non prouvé)
```

---

## 43. DOCUMENT LISIBLE PAR UN TIERS — MAPPING PAR PROJECTION (29/09/2026)

### Problème
Depuis RLS-2, un document peut être lu par un TIERS (le valideur), qui n'a pas à voir toutes
les données liées. `toResponse` naviguait dans `d.getContrat().getNumeroContrat()` :
rh_contrat étant fermé au valideur, Hibernate levait `EntityNotFoundException` et TOUTE la
lecture de la demande échouait (404 « Unable to find ContratEntity »).

### Règle
```
Dans le mapping d'un document lisible par un tiers : AUCUNE navigation d'association vers
une table sous RLS non ouverte à ce lecteur.
  - identifiant : lu sur le proxy (getId() ne charge rien)
  - valeurs     : lues par une PROJECTION du repository de la table liée, sous sa RLS ;
                  ligne invisible → Optional.empty() → champ vide, et la lecture RÉUSSIT
Exception documentée : une association vers une ligne EXPLICITEMENT ouverte au tiers
(le demandeur, via rls_demandeur_visible) peut rester en navigation — le dire en commentaire.
[Rev 7] Une projection vide est acceptable pour AFFICHER un champ (« — ») ; elle est FAUSSE
pour DÉCIDER ou CALCULER (un contrat invisible n'est pas « aucun contrat ») → §49
```

### Exemple (AbsDemandeService.toResponse)
```java
if (d.getContrat() != null) {
    Long contratId = d.getContrat().getId();                  // proxy : aucune lecture
    b.contratId(contratId);
    contratRepo.findNumeroContratById(contratId).ifPresent(b::contratNumero);
}
if (d.getEmetteur() != null) {
    Long emetteurId = d.getEmetteur().getId();
    b.emetteurId(emetteurId);
    employeRepo.findIdentiteById(emetteurId).ifPresent(e -> b
        .emetteurNom(e.getNom()).emetteurPrenom(e.getPrenom()).emetteurMatricule(e.getMatricule()));
}
```
```java
// RhEmployeRepository — projection par interface (alias JPQL)
interface IdentiteEmploye { Long getId(); String getNom(); String getPrenom(); String getMatricule(); }
@Query("select e.id as id, e.nom as nom, e.prenom as prenom, e.matricule as matricule "
     + "from RhEmploye e where e.id = :id")
Optional<IdentiteEmploye> findIdentiteById(@Param("id") Long id);
```
Parallèle Laravel : `Contrat::whereKey($id)->value('numero_contrat')` au lieu de
`$absence->contrat->numero_contrat` dans une Resource.

### Règles
```
❌ Rattraper l'exception dans toResponse (pansement)
❌ Ouvrir la table liée au tiers « pour un champ » (rh_contrat = rémunération)
❌ Donner la FICHE complète d'une personne (/employes/{id}) à un valideur : la RLS filtre
   des LIGNES, pas des colonnes ; le résumé de décision lira des projections dédiées
✅ Détecté par la campagne : S3-lecture (§46) lit chaque GET à paramètre en tant que valideur
```

---

## 44. RÉFÉRENTIEL DES TYPES DE DOCUMENT ET VÉRIFICATEURS AU DÉMARRAGE (29/09/2026)

### WfTypeDocument.tableDocument
```java
ABSENCE_CONGE_ANNUEL("ABSENCE_CONGE_ANNUEL", "Congé annuel", "ABSENCE", "abs_demande"),
MISSION_DEMANDE("MISSION_DEMANDE", "Demande de mission", "MISSION", "mis_mission"),
CONTRAT_NOUVEAU("CONTRAT_NOUVEAU", "Nouveau contrat", "CONTRAT", null),   // non branché
```
- Constructeur UNIQUE à 4 arguments : une nouvelle constante qui n'indique pas sa table ne
  compile pas (le compilateur fait respecter la règle).
- Table du document = table qui porte `wf_instance.document_id` (le module seul ne suffit
  pas : explication n°5 et mesure n°5 ont le même identifiant).
- `null` = type non branché : `WorkflowService.demarrer` REFUSE d'en démarrer une instance
  (IllegalStateException [WF], 500 — erreur de développement).
- Miroir : `wf_type_document.table_document` (V001), bloc V005 GÉNÉRÉ depuis l'enum.
- Branchés au 29/09 : abs_demande (6 types), disc_mesure (5), disc_demande_explication (1),
  mis_mission (MISSION_DEMANDE). À brancher : FORMATION_INSCRIPTION (incrément 6), etc.
### Vérificateurs (ApplicationRunner) — le démarrage est REFUSÉ au moindre manquement
| Journal | Classe | Vérifie |
|---|---|---|
| `[RLS-VERIF]` | RlsRepositoriesVerificateur | repositories des tables sous RLS transactionnels (§34) |
| `[RLS-POLITIQUES]` | RlsPolitiquesVerificateur | chaque table sous RLS : FORCE ; exactement `_owner` (ALL, propriétaire, true), `_lecture` (SELECT, digierp_app, accès complet), `_ecriture` (ALL, digierp_app, USING = WITH CHECK) ; AUCUNE condition de valideur en écriture ; `rls_action_workflow()` seulement en écriture ; aucun `current_setting` direct ; journalise les tables écrites par le workflow |
| `[WF-VERIF]` | WfTypeDocumentVerificateur | enum ↔ wf_type_document (code, libellé, module, table) ; chaque table citée existe ; une table branchée sous RLS appelle `rls_decideur_de('<table>'` dans sa politique de LECTURE |
| `[RLS-HORS-TX] Garde active` | RlsHorsTransactionDetecteur | tables surveillées (§34) |
| `[WF-RESUME]` [Rev 8] | WfResumeurRegistre | résumeurs ↔ types branchés (§50) ; `afterSingletonsInstantiated`, avant l'ouverture du serveur (§51.2) |

[Rev 9] Aucun vérificateur ne détecte encore un PROPRIÉTAIRE d'écriture qui relit sa propre
table (§51.4) : contrôle aujourd'hui par l'inventaire calculé de §51.4 (piste : l'ajouter à
RlsPolitiquesVerificateur en lisant pg_proc, comme l'inventaire).

Lignes attendues au démarrage (29/09, inchangées le 30/09 après b1 et b1-bis, et le 05/10
après 89ae754f) :
```
[RLS-VERIF] 17 repository(ies) de tables sous RLS conformes
[RLS-POLITIQUES] 14 table(s) sous RLS conformes au modele standard ;
                 ecrites par le workflow : [abs_demande, disc_mesure, mis_mission, wf_instance]
[WF-VERIF] 28 type(s) de document conformes a l'enum ;
           tables des documents : [abs_demande, disc_demande_explication, disc_mesure, mis_mission]
[RLS-HORS-TX] Garde active sur 14 table(s)
[WF-RESUME] 2 resumeur(s), 7 type(s) couvert(s) : [6 ABSENCE_*, MISSION_DEMANDE]   [Rev 8]
[WF-RESUME] 6 type(s) branche(s) sans resume (resume minimal) : [6 DISCIPLINE_*]   [Rev 8]
```
[Rev 8] Les nombres de `[WF-RESUME]` se recalculent EN BASE : couverts = lignes de
wf_type_document dont la table a un résumeur ; sans résumé = les autres lignes à table.
Les deux premiers se complètent : `[WF-VERIF]` exige que le valideur PUISSE LIRE ;
`[RLS-POLITIQUES]` exige qu'il ne puisse JAMAIS ÉCRIRE.

---

## 45. CODES DE REFUS : 400, 403, 404 (29/09/2026)

```
400 — la REQUÊTE est mal formée par le client : MissingServletRequestParameterException
      (« Paramètre obligatoire manquant : motif »), MethodArgumentTypeMismatchException,
      HttpMessageNotReadableException. Jamais 500 : un client qui oublie un paramètre ne
      doit pas faire croire à une panne serveur.
404 — le document est introuvable OU invisible pour cet utilisateur (RLS) : même réponse,
      même message ; l'existence d'un document d'autrui n'est jamais révélée
403 — le document est VISIBLE mais l'action est refusée : permission PBAC (AccessDenied),
      politique de document (RhAccesDocumentException, message motivé), acteur non désigné
      ou instance clôturée (WfAutorisationException)
Ordre dans le moteur : visibilité (404) AVANT désignation (403) — sinon un inconnu recevrait
403 et saurait que l'instance existe.
[Rev 9] Le refus par la RLS d'ÉCRITURE (document visible, écriture refusée en base) est
sémantiquement un 403 ; il sort aujourd'hui en 500 (dette 22). Il doit rester un FILET :
l'action est normalement refusée avant, par la politique de document (§42)
```

---

## 46. CAMPAGNE DE SÉCURITÉ RLS / POLITIQUES — securite_rls_politiques.py (29/09/2026, étendue Rev 6)

Script hors dépôt (docs/digierp/tests/), rejouable, GÉNÉRÉ depuis l'inventaire réel :
```
S0  données : A1 soumise (le valideur EMPLOYE en attente), A2 (contrôle positif)
S1  matrice SQL : CHAQUE table sous RLS (pg_class) × 6 contextes (ANONYME, propriétaire,
    valideur, étranger, GESTIONNAIRE_RH, valideur + capacité) × SELECT / UPDATE / DELETE,
    toujours en ROLLBACK ; attendus calculés depuis les règles métier (comptés en connexion
    propriétaire), JAMAIS depuis les politiques testées ; une table sous RLS sans règle
    connue du test FAIT ÉCHOUER le test
S1c cibles : le valideur LIT et N'ÉCRIT PAS A1, son instance, la fiche du demandeur ;
    la capacité écrit A1 et l'instance, jamais la fiche ; l'étranger ne voit rien
S2  structure : FORCE + trio standard sur chaque table ; aucune condition de valideur en
    écriture ; tables ouvertes au workflow = celles prévues
S3  CHAQUE POST/PUT/PATCH/DELETE à paramètre des contrôleurs (lus dans le code) appelé par le
    valideur sur A1 : code dans {400, 403, 404, 422} (un 500 est un ÉCHEC) ET empreinte des
    données inchangée ; seules les actions légitimes (decider, deleguer) sont exclues ;
    contrôle positif : le demandeur annule A2 (200)
S3-lecture CHAQUE GET à paramètre des contrôleurs, en tant que valideur : 200 ; une variable
    de chemin sans valeur de scénario FAIT ÉCHOUER le test ; pour une liste, A1 présent
S3-droits [Rev 6] l'enum des actions est LUE DANS LA SOURCE (AbsDemandePolitique.java :
    constantes et indicateur « demandeur admis ») → oracle : demandeur = actions admises,
    valideur = [], gestionnaire = toutes ; vérifié sur A1 pour les trois lecteurs, puis sur
    TOUTE la liste du valideur (chaque demande d'autrui : actionsPermises == []). Avec S3
    (toutes ses actions refusées) : « l'écran ne propose rien ⇔ le serveur refuse tout »
S4  fuite de capacité : active dans la transaction, éteinte après le COMMIT (même connexion)
S5  test_rls2_valideurs.py (13/0), nonreg_rls_workflow.py (14/0), [Rev 6]
    test_actions_permises.py (16/0)
Bilan de référence (29/09 soir, confirmé le 30/09 après b1-bis) : 44 OK / 0 ECHEC
[Rev 8] 45 OK depuis le 01/10 (GET /taches/{instanceId} en S3-lecture) ; [Rev 9] 45 OK le
05/10 après 89ae754f et reset
```
Extension obligatoire à chaque module branché (Discipline, Missions, Formation) : ajouter
son contrôleur à S3 / S3-lecture, sa politique à S3-droits ; ses tables apparaissent seules
dans S1 et S2.
[Rev 9] Angle mort constaté : la matrice S1 teste SELECT / UPDATE / DELETE, pas l'INSERT, et
ses UPDATE ne changent pas une colonne de propriété → elle n'a pas vu la dette 23. À ajouter :
un INSERT par le propriétaire de chaque table et un UPDATE qui réécrit la colonne de propriété
vers un autre employé (attendu : refus), sur le modèle de preuve_d23_mission.py (§51.6).
Le script est HORS DÉPÔT : toute modification passe par un script qui en fait une copie dans
/tmp, vérifie la syntaxe (`compile`) et calcule ses attendus avant d'écrire.
[Rev 7] Hors campagne (preuve dédiée) : preuve_solde_valideur.py couvre les fonctions
d'agrégat (§49). À intégrer à S5 si d'autres agrégats apparaissent.

---

## 47. CHECKLIST — COMPLÉMENTS REV 5 (et Rev 6, Rev 7, Rev 8, Rev 9)

[ ] 31. Table sous RLS : UN `CALL rls_appliquer_politiques` ; p_workflow = TRUE seulement si
        le moteur y écrit (mesuré) ; jamais de valideur dans le paramètre propriétaire
[ ] 32. Aucune politique ni ENABLE/FORCE écrits à la main (grep sur db/migration : rien)
[ ] 33. Lecture : RLS seule (aucun filtre Java de visibilité sur une table sous RLS) ;
        introuvable ou invisible = RhNotFoundException (404), y compris findByIdIgnoreActif
[ ] 34. Politique de document du module ; politique.verifier dans CHAQUE action
[ ] 35. Mapping lisible par un tiers : aucune navigation vers une table fermée au tiers
        (identifiant sur le proxy, projections)
[ ] 36. Type de document branché : tableDocument renseigné dans l'enum (miroir V005 généré),
        politique de LECTURE de la table avec rls_decideur_de('<table>', ...)
[ ] 37. Écriture pour autrui pendant une décision : uniquement par le moteur, sous capacité
[ ] 38. Démarrage : [RLS-VERIF], [RLS-POLITIQUES], [WF-VERIF], [RLS-HORS-TX] conformes
[ ] 39. Campagne securite_rls_politiques.py étendue au module : 0 ECHEC
[ ] 40. Attente après rebuild : réponse AUTHENTIFIÉE 200 de rh-api (jamais 401 sans jeton)
[ ] 41. [Rev 6] Politique : refus(action, doc, lecteur) + typeActions() + lecteurCourant() ;
        actionsPermises dans Response ET SummaryResponse ; listes : lecteur photographié une fois
[ ] 42. [Rev 6] Attendus des tests de droits et des scénarios UI déduits des permissions RÉELLES
        des rôles (erp_role_permission)
[ ] 43. [Rev 7] Donnée dérivée (solde, total, disponibilité) : calculée à la lecture par une
        règle unique, jamais stockée ni semée (§49)
[ ] 44. [Rev 7] Tout agrégat sur une table sous RLS montré à un tiers : fonction d'agrégat à
        garde dans V004 (§49) ; prouvé EN TANT QUE VALIDEUR (même résultat que le demandeur,
        RLS non élargie, garde : refus + contrôle positif)
[ ] 45. [Rev 8] Type de document branché : un résumeur par table (§50, liste de contrôle
        10 points) ; `[WF-RESUME]` le compte « couvert » ; preuve preuve_taches_<module>.py
[ ] 46. [Rev 8] Clés de résumé traduites fr / en : controle_cles_resume.py = 0 ECHEC
[ ] 47. [Rev 8] Politique RLS d'écriture : propriétaire testé sur les colonnes de la ligne,
        jamais par une fonction qui relit la table par l'id (§51.4) — [Rev 9] contrôle :
        inventaire calculé de §51.4 = aucune table en défaut
[ ] 48. [Rev 9] Restreindre un droit d'écriture (RLS ou politique) : inventaire calculé des
        chemins qui l'exercent, par endpoint et action PBAC, setters compris, puis angles
        morts (§51.5) AVANT d'écrire
[ ] 49. [Rev 9] Preuve d'une politique d'écriture : création par le propriétaire réel ET
        réécriture de la colonne de propriété refusée (écriture d'essai en digierp_app,
        ROLLBACK, état relu) — §51.6

---

## 48. DÉCIDER : UNE SEULE PORTE (constat du 29/09/2026 soir — dette, temps 3 de 3bis)

### Constat (prouvé par les annotations des contrôleurs et les permissions en base)
Le même acte — décider une étape de workflow — passe aujourd'hui par QUATRE portes PBAC :
```
POST /api/rh/workflow/instances/{id}/decider  → @pe.peutFaire('RH.WORKFLOW', 'LIRE')
POST /api/rh/absences/{id}/decider            → @pe.peutFaire('RH.ABSENCE', 'VALIDER')
POST /api/rh/discipline/mesures/{id}/decider  → @pe.peutFaire('RH.DISCIPLINE', 'APPROUVER')
POST /api/rh/mission/{id}/decider             → @pe.peutFaire('RH.MISSION', 'VALIDER')
```
Conséquence réelle : pnkouatchou (EMPLOYE, N+1 désigné d'afeudjo) décide depuis « Mes tâches »
(il a RH.WORKFLOW:LIRE) mais PAS depuis la page Absences (EMPLOYE n'a pas RH.ABSENCE:VALIDER :
pas de boutons ✓ ✕, 403 sur /decider). Deux règles pour un même acte, alors que la seule qui
compte est celle du moteur : l'utilisateur est-il l'acteur désigné de l'étape (peutDecider,
WfAutorisationException 403) ?

### Options examinées
```
A. Accorder RH.ABSENCE:VALIDER (etc.) au rôle EMPLOYE : pansement, à refaire pour chaque
   module, et une permission « VALIDER » sans sens pour un rôle SELF
B. RETENUE : une seule porte au temps 3 (décision uniforme, D-a) — le /decider d'un module et
   celui de « Mes tâches » passent par la même règle, portée par le moteur ; lire d'abord la
   porte réelle de l'endpoint générique et en faire la règle unique
C. Statu quo : décider uniquement depuis « Mes tâches »
```

### Règles (à appliquer au temps 3)
```
✅ L'autorisation de DÉCIDER = l'acteur désigné (moteur), une seule règle pour tous les écrans
✅ Le PBAC d'un /decider de module ne peut pas être plus restrictif que celui de « Mes tâches »
✅ Les boutons Valider / Rejeter d'un écran de module s'affichent sur d.peutDecider (et sur la
   même porte que l'endpoint appelé)
❌ Donner une permission PBAC à un rôle « pour que le bouton s'affiche »
Campagne : ajouter un contrôle « un valideur désigné peut décider par chaque endpoint de
décision de son document » (aujourd'hui exclu de S3 comme action légitime)
```

---

## 49. DONNÉE DÉRIVÉE ET AGRÉGAT INDÉPENDANT DU LECTEUR (30/09/2026 — c7d94fbe, fbf5656d)

### 49.1 Une donnée dérivée se calcule à la lecture (b1, c7d94fbe)
Constat prouvé (preuve_solde_absence.py, 8 OK / 3 ECHEC avant) : la table `abs_compteur`
stockait le solde de congé et chaque transition devait « penser » à le recalculer. Deux
défauts : `soumettre` ne recalculait pas (compteur périmé : 3 j manquants en 2027) ; et
l'avertissement comparait les jours d'une demande à un « restant » qui les déduisait DÉJÀ
(double comptage).
```
✅ Le solde est une donnée DÉRIVÉE : calculée à chaque lecture par UNE règle
   (AbsDroitCalculService.calculerSolde), jamais stockée ni semée à la main
✅ Objet valeur : record AbsSolde(acquis, pris, enAttente) ; disponible() et
   insuffisantPour(jours) = critère UNIQUE de l'avertissement ; constructeur qui refuse null
✅ Statuts comptés à UN endroit (STATUTS_PRIS = [APPROUVEE], STATUTS_EN_ATTENTE =
   [EN_WORKFLOW]), passés en paramètre aux requêtes
✅ Évaluer un élément contre un agrégat : l'agrégat se calcule HORS cet élément
   (demandeExclueId) — sinon il est compté deux fois
✅ Besoins futurs (report d'une année sur l'autre, ajustement manuel) : des MOUVEMENTS
   additionnés par la règle, jamais un solde stocké
❌ Table de compteurs / soldes mise à jour par les transitions
```

### 49.2 Un agrégat sur une table sous RLS ne dépend pas du lecteur (b1-bis, fbf5656d)
Constat prouvé (preuve_solde_valideur.py, 6 OK / 2 ECHEC avant) : `calculerSolde` lisait des
tables sous RLS avec le contexte du LECTEUR. Pour un valideur EMPLOYE (RLS-2) :
```
Défaut A : rh_contrat fermé au valideur → type de contrat inconnu → aucune règle abs_droit
           (il n'existe que des règles par type de contrat pour le congé annuel) → aucun
           solde → avertissement ABSENT, sur TOUTE demande consultée par un valideur EMPLOYE
Défaut B : il ne voit que les demandes où il a une décision → sommes « pris » et « en
           attente » PARTIELLES (après un changement de N+1 : disponible surestimé)
Même document, même instant : afeudjo et mtsafack lisaient « 9 j disponibles », le valideur
qui devait décider ne lisait RIEN. Silence total : aucune erreur.
```
Principe : la RLS filtre les LIGNES qu'on liste ; un TOTAL ou une règle calculée pour un
document doit être le même pour tout lecteur autorisé à voir ce document.

### Options examinées (30/09)
```
1. RETENUE : fonctions SQL SECURITY DEFINER qui calculent sur toutes les lignes mais ne
   renvoient qu'un NOMBRE ou l'id d'une règle, derrière une garde (même esprit que RLS-2 T1)
2. Calcul en contexte SYSTEM pendant la requête HTTP : contraire à §33 (jamais SYSTEM pour
   une requête), et toute la suite de la transaction verrait tout
3. Élargir la RLS (rh_contrat et toutes les demandes du demandeur visibles au valideur) :
   ouvre la rémunération (§43), contraire au moindre privilège
4. Recopier la règle de droit dans abs_demande à la création : donnée dérivée stockée (49.1)
```

### Fonctions (V004, après rls_demandeur_visible)
```sql
-- Garde : l'appelant peut-il lire cet employé ? Même condition que la lecture de rh_employe.
rls_employe_lisible(p_employe_id BIGINT) RETURNS BOOLEAN        -- sql STABLE (non DEFINER)
    = p_employe_id IS NOT NULL AND (rls_acces_complet()
        OR p_employe_id::TEXT = rls_employe_courant() OR rls_demandeur_visible(p_employe_id))

-- Règle de droit applicable : celle du type du contrat ACTIF, sinon la générique ; NULL = aucune
abs_droit_applicable(p_employe_id BIGINT, p_type_absence_id BIGINT) RETURNS BIGINT

-- Somme des jours ACTIFS d'un employé, type, année (de date_debut), statuts, hors une demande
abs_somme_jours(p_employe_id BIGINT, p_type_absence_id BIGINT, p_annee INTEGER,
                p_statuts TEXT[], p_demande_exclue_id BIGINT) RETURNS NUMERIC

-- Les deux fonctions d'agrégat : LANGUAGE plpgsql STABLE SECURITY DEFINER
--   SET search_path = public
--   IF NOT rls_employe_lisible(p_employe_id) THEN
--       RAISE EXCEPTION '[RLS-AGREGAT] employe % non lisible par l''appelant (...)'
--           USING ERRCODE = '42501';
-- Les trois : REVOKE EXECUTE ... FROM PUBLIC ; GRANT EXECUTE ... TO digierp_app
```
Pourquoi `plpgsql` et une EXCEPTION : une fonction `sql` ne pourrait que renvoyer NULL, et un
NULL passerait pour « aucune règle » (le défaut A, recréé). Hors transaction, le contexte est
ANONYME : la garde échoue aussi.

### Appel côté Java
```java
// AbsDemandeRepository (signature inchangée, appelants inchangés)
@Query(value = """
    SELECT abs_somme_jours(
        :employeId, :typeAbsenceId, :annee,
        CAST(ARRAY[:statuts] AS TEXT[]),          -- Hibernate déploie la liste dans ARRAY[...]
        CAST(:demandeExclueId AS BIGINT))         -- null sans type pour PostgreSQL
    """, nativeQuery = true)
BigDecimal sommeJours(Long employeId, Long typeAbsenceId, Integer annee,
                      Collection<String> statuts, Long demandeExclueId);

// AbsDroitRepository
@Query(value = "SELECT abs_droit_applicable(:employeId, :typeAbsenceId)", nativeQuery = true)
Optional<Long> idDroitApplicable(Long employeId, Long typeAbsenceId);

// AbsDroitCalculService : le CHOIX de la règle est en SQL, la règle chargée par son id
// (abs_droit hors RLS) ; un id introuvable → IllegalStateException [RLS-AGREGAT]
droitRepo.idDroitApplicable(employe.getId(), typeAbsence.getId())
    .map(id -> droitRepo.findById(id).orElseThrow(...));
```
Restent en Java : les majorations (rh_employe lisible par le valideur via
rls_demandeur_visible ; rh_employe_enfant hors RLS), les listes de statuts, AbsSolde.

### Règles
```
✅ Une fonction d'agrégat renvoie un NOMBRE ou un IDENTIFIANT de référentiel, jamais une ligne
✅ Garde en tête (rls_employe_lisible) → exception [RLS-AGREGAT] (42501), jamais NULL
✅ SET search_path = public ; REVOKE ... FROM PUBLIC ; GRANT ... TO digierp_app ; dans V004
✅ Appelée dans une transaction (contexte RLS posé) ; une requête native qui l'appelle ne
   réécrit JAMAIS l'agrégat en SELECT SUM(...) FROM <table sous RLS> (commentaire obligatoire)
✅ Le choix d'une règle qui dépend d'une donnée fermée au lecteur (type de contrat) est fait
   par la fonction, à UN endroit ; les méthodes Java devenues inutiles sont retirées
✅ Preuve obligatoire, lancée EN TANT QUE VALIDEUR : même résultat que le demandeur et un
   gestionnaire, cité et égal à l'oracle SQL ; « RLS non élargie » (le valideur ne voit
   toujours ni le contrat ni les autres demandes) ; garde : refus pour un employé non lisible
   et hors contexte, ET contrôle positif (le valideur légitime obtient la valeur exacte)
❌ SELECT SUM / COUNT sur une table sous RLS pour un chiffre métier montré à un tiers
❌ Confondre « invisible » et « absent » : Optional.empty() d'un contrat invisible pris pour
   « pas de contrat » (défaut A)
❌ Calculer en SYSTEM, élargir la RLS ou recopier la donnée dans le document
Parallèle Laravel : Demande::withoutGlobalScopes()->sum('jours') confiné dans une méthode qui
commence par Gate::authorize('voir', $employe) et ne renvoie qu'un total.
```

### Inventaire (30/09)
Solde de congé : corrigé (avertissement d'une demande, « Mes droits ») ; [Rev 8] appliqué au
détail de « Mes tâches » par la même règle (AbsDroitCalculService.soldeDeLaDemande, §50).
À appliquer à tout futur
agrégat montré à un tiers (Discipline, Missions, Formation) : inventorier les `SUM(` / `COUNT(`
des repositories des tables sous RLS à chaque module branché.

---

## 50. RÉSUMÉ D'UN DOCUMENT POUR « MES TÂCHES » — POINT D'EXTENSION DU MOTEUR (05/10/2026 — eee5170e)

### Principe
« Mes tâches » et « Mes demandes » (moteur de workflow) affichent chaque document soumis avec :
- des **informations communes** remplies par le MOTEUR (`WfTacheResponse` : type, module,
  étape n / N, libellé de l'étape, demandeur, date de soumission) ;
- un **résumé** fourni par le MODULE du document, via le point d'extension
  `com.digierp.rh.workflow.resume.WfResumeurDocument`.
Le moteur ne connaît aucune table de module. Le frontend ne contient aucun code propre à un
module dans « Mes tâches » : libellés = clés i18n fournies par le serveur, mise en forme =
`format` de chaque ligne, lien = `route`.
**Critère de conception (01/10) : un nouveau module n'a RIEN à toucher dans « Mes tâches »**
(ni backend du moteur, ni écran) — il ajoute son résumeur, ses traductions, et une ligne dans
sa page pour ouvrir sa fiche depuis l'URL.

Constat d'origine (Rev 6, §37) : `WfInstanceResponse` ne portait ni type, ni numéro, ni
demandeur, ni total d'étapes ; le valideur ne savait pas sur quoi il décidait, et l'écran
devinait le module par `modeleCode.split('_')`.

### Contrat (workflow/dto/WfTacheResponse)
```
instanceId, documentType, module, documentId, statut, dateSoumission,
etapeCourante, nbEtapes, etapeLibelle,
demandeur { employeId, nom, prenom, matricule }        -- projection par lot, sous RLS (C10)
resume    { numero, lignes[], route } | null            -- null = type sans résumeur
circuit   (détail seulement ; null en liste)            -- WorkflowService.lireCircuit (§51.1)
ligne     { cle, valeur, format, alerte }               -- format : TEXTE | DATE | NOMBRE | JOURS
```
Endpoints (RH.WORKFLOW:LIRE) : `GET /taches` (liste), `GET /taches/{instanceId}` (détail :
invisible ou absente = 404), `GET /instances/mes-demandes` (même contrat). La réponse de
`POST /instances/{id}/decider` reste `WfInstanceResponse`.

### Contrat à DEUX NIVEAUX (C12-a)
```java
Map<Long, WfResumeDocument> resumer(Collection<Long> documentIds, boolean detail);
```
- **Liste** (`detail = false`) : un appel par résumeur et par liste (documents regroupés PAR
  RÉSUMEUR par le moteur) ; **aucun calcul coûteux** ; nombre de requêtes indépendant du nombre
  de lignes.
- **Détail** (`detail = true`, UN seul document, sinon `IllegalArgumentException [WF-RESUME]`) :
  données dérivées autorisées, en appelant **la règle unique du module** (ex. solde de congé :
  `AbsDroitCalculService.soldeDeLaDemande`, la même que la fiche Absences), jamais recopiée.
- Sous la RLS du LECTEUR : document invisible = absent de la Map (jamais d'exception) ; un
  document visible par son instance mais absent du résumé → résumé minimal + avertissement
  `[WF-RESUME] … absent du resume de son module (invisible pour le lecteur)`.
- Valeurs CANONIQUES, construites uniquement par les fabriques `Ligne.texte / date / nombre /
  jours` (`AAAA-MM-JJ` ; `stripTrailingZeros().toPlainString()`), `avecAlerte(...)` ; pas de
  titre (C11) ; numéro obligatoire.
Écartés : solde calculé pour chaque ligne de la liste (C12-b : N fois plusieurs requêtes) ;
solde regroupé dans le résumeur (C12-c : règle du solde dupliquée).

### Ce qui est IMPOSÉ par le code (registre WfResumeurRegistre, journal [WF-RESUME])
Construit dans `afterSingletonsInstantiated` (avant l'ouverture du serveur, §51.2), à partir
des beans collectés par `ObjectProvider`. Démarrage REFUSÉ si :
- un résumeur ne couvre aucun type ;
- un résumeur couvre un type non branché (`WfTypeDocument.tableDocument` null) ;
- un résumeur couvre des types de PLUSIEURS tables (le moteur regroupe les identifiants par
  résumeur : deux tables mélangeraient leurs ids) ;
- un type est couvert par deux résumeurs.
Type branché SANS résumeur : avertissement à chaque démarrage (résumé minimal à l'écran).
**Le registre deviendra strict (refus de démarrer) à l'incrément 4**, quand la Discipline aura
ses deux résumeurs (décision du 01/10 : aucune instance disciplinaire n'existe en base, donc
pas de résumeur Discipline dans (c)).

### Liste de contrôle pour tout module qui branche des types de documents
| # | Règle |
|---|---|
| 1 | Un résumeur **par table de documents** : `<module>/service/<Entité>Resumeur`, `@Component`, calqué sur `AbsDemandeResumeur` (avec donnée dérivée au détail) ou `MisMissionResumeur` (sans) |
| 2 | Types couverts **déduits de la source** : `TYPES = WfTypeDocument.deLaTable(<Entité>.class.getAnnotation(Table.class).name())` — jamais une liste de codes recopiée |
| 3 | **Lecture par lot** dans le repository du module (sous RLS) : `@Query("select x from X x left join fetch x.<assoc> where x.id in :ids") List<X> findAllByIdInAvec<Assoc>(@Param("ids") Collection<Long> ids)` — `left join` : une association filtrée ne doit pas faire disparaître le document comme s'il était invisible ; jamais appelée avec une collection vide |
| 4 | `resumer(ids, detail)` : **liste sans aucun calcul coûteux** ; **détail (un seul document)** : données dérivées par **la règle unique du module**, jamais recopiée |
| 5 | Lignes construites **uniquement par les fabriques** (valeurs canoniques) ; `avecAlerte(...)` pour une valeur à signaler ; `null` = « — » à l'écran |
| 6 | Clés i18n `<namespace>:resume.<champ>` en **constantes** du résumeur ; traductions fr ET en dans `rh-frontend/src/i18n/locales/{fr,en}/<namespace>.json` ; contrôle **`tests/controle_cles_resume.py`** = 0 ECHEC (dans la chaîne de build frontend) |
| 7 | `route = "/<page du module>?fiche=" + id` ; la page du module ouvre sa fiche depuis ce paramètre : **`useFicheDepuisUrl(liste.ouvrirDetail)`** (hook partagé `src/hooks/useFicheDepuisUrl.js`) |
| 8 | Donnée agrégée sur une table sous RLS : par une fonction d'agrégat à garde (§49.2), jamais un `SUM` sous la RLS du lecteur |
| 9 | **Preuve** `tests/preuve_taches_<module>.py` sur le modèle de `preuve_taches.py` / `preuve_taches_mission.py` : document fabriqué par l'API **par le demandeur réel** ([Rev 9]), lu par l'acteur réel (lu en base), informations communes + demandeur + lignes comparés à un **oracle SQL** au même format, détail avec circuit, « Mes demandes », **état final** (rejet) ; ajoutée à la non-régression complète |
| 10 | **Journal de démarrage** : le type passe de « branche(s) sans resume » à « couvert(s) » ; nombres attendus **recalculés en base** (`wf_type_document.table_document`) |

### Contrôle des clés venues du serveur — controle_cles_resume.py
`check-i18n.cjs` ne voit que les clés littérales des `.jsx` ; ce contrôle (hors dépôt) couvre :
```
C1  résumeurs trouvés (implements WfResumeurDocument, lus dans rh-api)
C2  chaque résumeur cite au moins une clé "<ns>:resume.<champ>"
C3  chaque clé citée existe en fr ET en (texte non vide)
C4  réciproque : aucune clé resume.* orpheline dans un namespace de module (hors workflow)
C5  clé d'unité CLE_UNITE_JOURS de shared/utils/resume.js en fr / en, avec {{nombre}}
C6  workflow-modeles:types_document = exactement les constantes de WfTypeDocument
P   contre-preuve : 4 altérations faites en mémoire, chacune détectée par le contrôle attendu
```
Bilan de référence (02/10) : 19 OK / 0 ECHEC (2 résumeurs, 13 clés, 28 constantes).

### Côté écran (STANDARDS_FRONTEND Rev 8)
`TachesTable` (tâches et demandes), `ResumeDocument` (variantes liste / détail),
`shared/utils/resume.js` (`valeurLigne` : DATE → formatDate, NOMBRE / JOURS → formatNombre,
unité traduite), `TacheDetailModal` (détail, circuit, décision par `ConfirmModal`, motif
obligatoire au rejet), `useFicheDepuisUrl` (paramètre consommé à l'ouverture). Libellé d'un
type : `workflow-modeles:types_document.<CODE>` (miroir de l'enum, contrôlé par C6).

### Modules
- **Absences** (`abs_demande`, 6 types) : `AbsDemandeResumeur` — liste : type, du, au, jours,
  motif ; détail : + solde disponible, disponible après (alerte si insuffisant) ; route
  `/absences?fiche=<id>`
- **Missions** (`mis_mission`, `MISSION_DEMANDE`) : `MisMissionResumeur` — type, objet,
  destination, départ, retour, jours (liste = détail) ; route `/missions?fiche=<id>`
- **Discipline** (incrément 4) : **deux** résumeurs — `disc_mesure` (5 types de mesures) et
  `disc_demande_explication` (`DISCIPLINE_EXPLICATION`) ; puis registre strict
- **Formation** (incrément 6) : `frm_demande` (`FORMATION_INSCRIPTION`)
### Règles
```
✅ Un point d'extension = une interface dans le package du moteur, UN bean par module ET par
   table, collectés par ObjectProvider dans un registre construit avant l'ouverture du serveur
✅ Conflit = démarrage refusé ; absence de couverture = avertissement (puis strict)
✅ Ce que couvre un module se DÉDUIT de la source (deLaTable(@Table)), jamais recopié
✅ Une règle déplacée pour être partagée (solde d'une demande) : corps identique contrôlé,
   l'ancien emplacement supprimé (aucune règle à deux endroits)
❌ Code propre à un module dans le moteur ou dans « Mes tâches »
❌ Calcul coûteux dans la liste ; règle dérivée recopiée dans un résumeur
Parallèle Laravel : des JsonResource taguées dans le conteneur ($app->tagged('resumeurs')),
résolues par type de document, avec un ServiceProvider qui refuse de booter en cas de conflit.
```

---

## 51. COMPLÉMENTS REV 8 (30/09 – 05/10/2026) ET REV 9 (05/10/2026)

### 51.1 Circuit de validation générique (1fee8425)
```
WorkflowService.lireCircuit(instanceId) : chargement par findByIdWithModele, sous la RLS du
LECTEUR ; noms des acteurs en UNE requête (findIdentitesActeurs) ; état de chaque étape par la
règle pure etatEtape ; nbEtapes = nombreEtapes(instance) (fonction unique, partagée par le
circuit et les listes). Utilisé par la fiche d'un document (Absences) et par le détail de
« Mes tâches ». Preuve : preuve_circuit_absence.py.
✅ Un module ne reconstruit jamais un circuit : il appelle lireCircuit
```

### 51.2 Garde chargée AVANT l'ouverture du serveur
```
Cycle : beans (Flyway migre) → afterSingletonsInstantiated → ouverture des connecteurs Tomcat
        → ApplicationRunner → ApplicationReadyEvent
✅ Toute garde qui protège le trafic ([RLS-HORS-TX]) et tout registre dont dépend une requête
   ([WF-RESUME]) : SmartInitializingSingleton.afterSingletonsInstantiated
❌ ApplicationReadyEvent pour une garde (des requêtes passent avant elle — correctif 30cfc8f5)
Dette 15 : les vérificateurs [RLS-VERIF], [RLS-POLITIQUES], [WF-VERIF] sont encore des
ApplicationRunner (après l'ouverture de Tomcat)
```

### 51.3 Semis Flyway : seulement des états que l'application sait produire
```
✅ Une donnée de test semée décrit un état atteignable par l'application
❌ Document semé EN_WORKFLOW / EMISE / REPONDUE sans instance de workflow (dette 17 :
   disc_demande_explication) ; ❌ donnée dérivée semée (§49)
✅ Nettoyer une donnée de test : par l'API, avec l'acteur légitime (annulation, rejet),
   jamais par UPDATE
```

### 51.4 Politique RLS d'écriture : jamais une fonction qui relit la ligne par son id
[Rev 9 — réécrite : dette 23 SOLDÉE, commit 89ae754f, 05/10/2026]

#### Le mécanisme
`USING` filtre les lignes EXISTANTES qu'on peut toucher (UPDATE, DELETE) ; `WITH CHECK`
valide la NOUVELLE version de la ligne (INSERT, UPDATE). Une condition écrite sur les colonnes
(`employe_principal_id::TEXT = rls_employe_courant()`) est évaluée sur cette nouvelle version.
Une fonction qui fait `SELECT … FROM <la même table> WHERE id = p_id` ne la voit PAS : elle
interroge l'instantané pris au début de l'instruction.
Parallèle Laravel : une règle de validation qui ferait `Mission::find($this->id)` au lieu de
lire `$this->employe_principal_id` — elle ne voit pas ce qu'on s'apprête à enregistrer.

#### Les DEUX effets (prouvés AVANT sur l'image en service, preuve_d23_mission.py avant 5/5)
```
1. INSERT : la ligne n'existe pas encore pour la sous-requête → CHECK faux → refus
   systématique. Un EMPLOYE ne pouvait pas créer sa mission (« new row violates row-level
   security policy for table "mis_mission" », rendu en 500). VISIBLE.
2. UPDATE : la sous-requête relit l'ANCIENNE version → le CHECK juge l'état d'avant, jamais
   la valeur écrite. Un EMPLOYE changeait le missionnaire principal de sa mission vers un
   collègue (UPDATE 1 en digierp_app, puis ROLLBACK). FAILLE SILENCIEUSE : aucun test ne
   l'aurait signalée, découverte en raisonnant sur le premier effet.
```
Le défaut était masqué dans les preuves par un contournement (« admin crée POUR afeudjo ») :
l'accès complet de l'admin passe par `rls_acces_complet()` et n'évalue jamais le propriétaire.

#### Correction (V219, option A, retenue le 05/10)
```sql
-- mis_mission : ECRITURE reservee au missionnaire principal, testee sur la COLONNE
-- de la ligne ecrite ; participants et valideurs LISENT la mission (lecture en plus).
CALL rls_appliquer_politiques('mis_mission',
    'employe_principal_id::TEXT = rls_employe_courant()',
    'rls_proprietaire_mission(id) OR rls_decideur_de(''mis_mission'', id)', TRUE);
```
- L'ancienne condition (`rls_proprietaire_mission(id)` : principal OU participant) passe en
  « lecture en plus » : sans ce report, les participants auraient perdu la LECTURE (§40 : le
  propriétaire sert aux deux politiques).
- Moindre privilège : seul le principal écrit sa mission ; les actions d'un participant
  (frais, prolongation, rapport, complément d'avance) écrivent leurs propres tables.
- Écartées : B (fonction à deux paramètres testant la colonne passée, écriture gardée aux
  participants : privilège plus large, deux règles de propriété) ; C (paramètre « propriétaire
  en écriture » ajouté à la procédure : change le standard des 14 tables et le vérificateur
  pour un seul cas).
- Tables FILLES inchangées et correctes : `rls_proprietaire_mission(mission_id)` reçoit la
  colonne de la ligne fille ÉCRITE et relit la mission PARENTE, qui existe déjà (écrite par une
  instruction précédente de la transaction ou commitée) : ni l'effet 1 ni l'effet 2.
#### Inventaire calculé (par la BASE, jamais par regex sur les fichiers)
```
1. pg_policies : politiques pol_<t>_ecriture (CHECK, à défaut USING)
2. pg_proc : corps des fonctions du schéma ; fermeture des appels depuis le CHECK
   (fonctions qui appellent des fonctions), tables lues (FROM / JOIN) filtrées sur pg_tables
3. Verdict : DÉFAUT si le CHECK relit SA PROPRE table ; « à examiner » s'il relit une autre
   table (cas des filles : parent → correct) ; sinon « colonnes seulement »
4. Recoupement : tables à politique d'écriture (base) = tables des CALL des migrations
   (commentaires retirés) = tables à RLS activée (pg_class.relrowsecurity)
Résultat du 05/10 : 14 / 14 / 14, ensembles identiques ; mis_mission SEULE en défaut ;
mis_frais et mis_affectation_moyen « à examiner » (parent, corrects) ; 11 tables sur colonnes.
```

#### Règles
```
✅ Le paramètre PROPRIÉTAIRE de rls_appliquer_politiques se teste sur les COLONNES de la ligne
   (employe_principal_id::TEXT = rls_employe_courant()) ; une fonction par id reste permise
   pour la LECTURE et pour les tables FILLES (la ligne parente existe déjà)
✅ Restreindre le propriétaire : reporter l'ancienne condition en « lecture en plus » si la
   lecture doit rester ouverte
✅ Preuve : création par le propriétaire réel (pas par un gestionnaire, qui passe par l'accès
   complet et masque le défaut) ET réécriture de la colonne de propriété refusée (§51.6)
✅ Nouvelle table sous RLS (Formation : frm_demande à l'incrément 6) : inventaire ci-dessus
   relancé = aucune table en défaut
❌ Fonction qui relit la table elle-même dans le propriétaire d'écriture
```

### 51.5 Restreindre un droit d'écriture : inventaire des chemins qui l'exercent [Rev 9]
Avant de réserver l'écriture de mis_mission au missionnaire principal, il fallait prouver
qu'aucun flux LÉGITIME d'un participant n'écrivait la mission (sinon le correctif cassait un
écran). Inventaire calculé, en lecture seule :
```
1. Actions PBAC du rôle concerné LUES EN BASE (EMPLOYE sur RH.MISSION : ANNULER, CREER,
   DEMANDER_AVANCE_COMP, DEMANDER_PROLONGATION, EMETTRE, EXPORTER, LIRE, MODIFIER,
   SAISIR_FRAIS, SOUMETTRE)
2. TOUS les endpoints @pe.peutFaire('RH.MISSION', …) des contrôleurs (action, verbe, route)
3. Pour chacun, appels de service suivis récursivement (même classe, services injectés) ;
   écritures relevées : save* / delete* du repository de la table, méthodes @Modifying, ET
   setters sur une variable de l'entité ou getMission().set… (dirty checking : un set suffit)
4. Angles morts fermés à part : SQL natif écrivant la table hors migrations (UPDATE / INSERT
   INTO / DELETE FROM), publishEvent / @EventListener, JdbcTemplate, EntityManager
Résultat du 05/10 : 55 endpoints RH.MISSION, 34 ouverts à EMPLOYE, 7 écrivent mis_mission —
tous de GESTION de la mission (créer, modifier, soumettre, annuler, ajouter / retirer un
participant, recalculer : MisParticipantService.recalculerBudgetMission) → revenant au
principal. Angles morts : @SQLDelete (SUPPRIMER) et purgerById (PURGER), absents d'EMPLOYE ;
écouteur de clôture (MissionService, sous capacité workflow, inchangé).
```
```
✅ Restreindre un droit = inventaire calculé AVANT d'écrire la politique
✅ Le constat inverse est une découverte : avant 89ae754f, un participant non principal
   pouvait modifier / soumettre / annuler la mission d'un autre (aucun contrôle Java) ; la RLS
   le refuse désormais, la politique de document doit le motiver (dette 26)
❌ Inventaire limité aux save() : le dirty checking écrit sans save
```

### 51.6 Preuve d'une politique d'écriture [Rev 9]
```
Écriture d'ESSAI en simulant l'application, toujours annulée :
  BEGIN; SET LOCAL ROLE digierp_app;
  SELECT 'CTX|' || set_config('app.current_role','EMPLOYE',true) || '|'
         || set_config('app.current_user_id','<employe>',true);
  UPDATE <table> SET <colonne de propriété> = <autre employé> WHERE id = <id>;
  ROLLBACK;
  → psql -f - en entrée standard ; erreur lue sur stderr ; état RELU en base après
  → la ligne CTX|… doit être présente (sinon le contexte n'a pas été posé et la preuve ne
    prouve rien)
Script à DEUX MODES pour une même reproduction : preuve_d23_mission.py avant | apres
  avant : A1-A3 création par le propriétaire refusée (500 + violation au journal + aucune
          ligne) ; A4 réécriture du principal ACCEPTÉE puis annulée ; A5 état final
  apres : P1-P2 création acceptée (BROUILLON ; principal et participants lus en base) ;
          P3 réécriture REFUSÉE ; P4-P6 soumission, rejet par l'acteur de l'étape 1 (lu en
          base), REJETEE
  Le mode avant ne se joue QUE sur l'image d'avant : relancé après le correctif, il
  « échoue » et laisse une donnée sans état final ; seul le mode apres entre dans la
  non-régression
```

[Rev 9] Dette résiduelle (PROMPT_REPRISE, dettes 22 et 26) : violation de RLS d'écriture
rendue en 500 au lieu de 403 ; MissionService.creer sans resolveEmployeId ; ajout de
participants par un EMPLOYE (collègue invisible, INSERT dans mis_mission_employe) non prouvé ;
pas encore de MisMissionPolitique ni d'actionsPermises pour les missions.
