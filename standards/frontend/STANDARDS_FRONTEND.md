# STANDARDS FRONTEND — DigiERP v2
# Version : 06/06/2026 — Rev 2 (responsive + pagination frontend)
# Rev 3 : 24/09/2026 — sections 27 et 28 (modal de détail, formulaire autonome, code métier)
# Rev 4 : 28/09/2026 — sections 29 à 34 (workflow dans les écrans, documents générés,
#         conversion en options, contrats d'API, déploiement, checklist)
# Rev 5 : 29/09/2026 — sections 35 à 37 (droits sur un document calculés par le serveur,
#         ouverture d'un document et fiche de détail, checklist) ; mises à jour des
#         sections 1, 10 et 29 (valideur de rôle EMPLOYE, messages 400 / 403 / 404)
# Rev 6 : 29/09/2026 soir (commit c124e576) — §35 contrat en place (utilitaire permis) ;
#         §38 (composant partagé : lire sa signature, cas ConfirmModal sans children) ;
#         mises à jour des sections 29 et 37
# Rev 7 : 30/09/2026 nuit (commit b1f42b99) — §38 correctif livré : ConfirmModal rend ses
#         enfants, style success, type inconnu bruyant ; UNE saisie = UN champ = UN état ;
#         preuve avant / après ; inventaire des ConfirmModal ; §37 items 35-36 ; §14 clés
#         orphelines
# Rev 8 : 05/10/2026 (commits 1fee8425, ebec0a1b, eee5170e) — §39 règle unique des actions
#         d'un document ; §40 mise en forme selon la langue (trois mécanismes constatés,
#         cible F-a, dette 27) ; §41 pile de fenêtres ; §42 ouvrir une fiche par l'URL ;
#         §43 lignes de résumé venues du serveur ; §44 « Mes tâches » : fiche de la tâche et
#         décision ; §45 i18n contrôlée contre la source ; §46 checklist. Mises à jour des
#         sections 2, 11, 14, 29, 32, 33, 35 et 36
# Remplace : l'ancienne section frontend de STANDARDS_PROJET.md

---

## 1. PRINCIPES FONDAMENTAUX

### Règle d'or
Le frontend est une couche de CONFORT, pas de sécurité.
Toute restriction visible côté React doit être doublée côté backend.
Un utilisateur qui désactive JavaScript ne doit rien pouvoir faire de plus.
[Rev 5] Réciproque : l'écran ne doit pas PROPOSER une action que le serveur refusera. Le droit
sur un document précis n'est jamais recalculé côté React (statut, propriétaire...) : il est
fourni par le serveur, calculé par la même règle que celle qui protège l'action (§35).

### Séparation stricte des responsabilités
- Page       = orchestration uniquement (assemble hooks + composants)
- Composant  = affichage uniquement (reçoit props, émet events)
- Hook       = logique métier (appels API, état, calculs)
- Service    = appels API uniquement (aucune logique)
- [Rev 4] Utilitaire de module (`modules/{module}/utils/`) = fonction pure partagée par
  plusieurs composants du module (ex : conversion d'une réponse d'API en options de select)

---

## 2. STRUCTURE DES FICHIERS

### Structure globale src/
src/
├── config/
│   ├── navigation.js      ← groupes nav + permissions requises
│   ├── routes.jsx         ← définition routes (séparé de App.jsx)
│   └── theme.js           ← design tokens (couleurs, tailles, breakpoints)
├── context/
│   ├── AuthContext.jsx    ← user, token, login, logout, loading
│   └── LocaleContext.jsx  ← langue, formatage
├── hooks/
│   ├── useApi.js          ← appel API conditionnel par permission
│   ├── usePermissions.js  ← peutFaire(module, action)
│   ├── useToast.js        ← succes(msg), erreur(msg)
│   ├── useErrorHandler.js ← normalise erreurs API → messages lisibles
│   └── useListState.js    ← état pagination/tri/recherche partagé [NOUVEAU]
├── i18n/
│   ├── index.js
│   └── locales/fr/ + locales/en/
├── layouts/
│   ├── AppLayout.jsx      ← sidebar collapsible + header + footer [ENRICHI]
│   ├── AuthLayout.jsx     ← layout pages publiques
│   └── LoginPage.jsx
├── modules/
│   └── {module}/
│       ├── {Module}Page.jsx          ← page principale (orchestration)
│       ├── components/               ← composants UI du module
│       │   ├── {Module}Table.jsx
│       │   ├── {Module}Form.jsx
│       │   └── {Module}DetailModal.jsx
│       ├── hooks/                    ← logique métier
│       │   ├── use{Module}List.js    ← utilise useListState
│       │   └── use{Module}Form.js
│       ├── services/
│       │   └── {module}.service.js
│       └── utils/                    ← [Rev 4] fonctions pures partagées (voir §31)
├── services/
│   └── api.js             ← instance Axios centralisée
└── shared/
    ├── components/        ← composants réutilisables
    │   ├── ProtectedRoute.jsx
    │   ├── ErrorBoundary.jsx
    │   └── ...
    ├── pages/
    │   ├── NotAuthorizedPage.jsx
    │   └── MaintenancePage.jsx
    ├── ui/                ← composants atomiques (jamais de logique métier)
    │   ├── Button.jsx
    │   ├── Badge.jsx
    │   ├── Alert.jsx
    │   ├── Spinner.jsx
    │   ├── EmptyState.jsx
    │   ├── PageHeader.jsx
    │   └── Pagination.jsx  ← [NOUVEAU] partagé par tous les modules
    └── styles/            ← classes Tailwind centralisées
        ├── buttons.styles.js
        ├── table.styles.js
        ├── forms.styles.js
        └── layout.styles.js

[Rev 8] Fichiers transverses ajoutés depuis la Rev 7 (lus dans le code poussé) :
```
src/hooks/useFenetreEmpilee.js     ← inscription d'une fenêtre dans la pile unique (§41)
src/hooks/useFicheDepuisUrl.js     ← ouverture d'une fiche par ?fiche=<id> (§42)
src/shared/utils/pileFenetres.js   ← règle PURE de la pile (testable par Node, §41)
src/shared/utils/format.js         ← mise en forme selon la langue (§40 : à unifier, dette 27)
src/shared/utils/resume.js         ← valeur affichée d'une ligne de résumé du serveur (§43)
src/modules/{module}/utils/{module}Actions.js ← règle unique des actions d'un document (§39)
src/modules/workflow/components/CircuitValidation.jsx ← circuit générique (tous modules)
```
Règle : un fichier de `shared/utils/` est une fonction PURE (aucun hook, aucun appel réseau,
aucun accès au DOM) ; ce qui touche React ou le DOM va dans `src/hooks/`.

### Structure obligatoire par module
modules/contrats/
├── ContratsPage.jsx              ← ORCHESTRATION uniquement
├── components/
│   ├── ContratTable.jsx          ← affichage tableau
│   ├── ContratForm.jsx           ← formulaire création/modification
│   └── ContratDetailModal.jsx    ← détail lecture seule
├── hooks/
│   ├── useContratsList.js        ← utilise useListState + useApi
│   └── useContratForm.js         ← formulaire, validation, soumission
└── services/
    └── contrat.service.js        ← appels API uniquement

---

## 3. DESIGN TOKENS (theme.js)

### Principe
UNE modification dans theme.js = changement visuel partout.
Jamais de couleur codée en dur dans un composant.
Jamais de breakpoint codé en dur dans un composant.

### Fichier src/config/theme.js
```javascript
export const theme = {
  colors: {
    primary:    'blue',      // Changer ici change TOUS les boutons primaires
    danger:     'red',
    success:    'green',
    warning:    'amber',
    info:       'cyan',
    neutral:    'slate',
  },
  sidebar: {
    bg:         'slate-800',
    text:       'slate-300',
    active:     'blue-600',
    widthFull:  'w-64',      // sidebar étendue (desktop)
    widthMini:  'w-16',      // sidebar réduite (tablette/collapsed)
  },
  radius:   'rounded-lg',    // border-radius uniforme
  shadow:   'shadow-sm',     // ombre uniforme

  // [NOUVEAU] Breakpoints standard — utiliser ces valeurs dans les className
  // Ne jamais coder un breakpoint différent dans un composant
  breakpoints: {
    sm:  '640px',   // petit mobile
    md:  '768px',   // tablette (cible minimum DigiERP)
    lg:  '1024px',  // desktop
    xl:  '1280px',  // grand desktop
  },
}
```

### Utilisation dans les styles centralisés
```javascript
// shared/styles/buttons.styles.js
import { theme } from '../../config/theme'
const c = theme.colors
export const btnStyles = {
  primary: `px-4 py-2 bg-${c.primary}-600 text-white ${theme.radius} hover:bg-${c.primary}-700 ...`,
  danger:  `px-4 py-2 bg-${c.danger}-600  text-white ${theme.radius} hover:bg-${c.danger}-700  ...`,
}
```

---

## 4. RESPONSIVE — RÈGLES OBLIGATOIRES [NOUVEAU 06/06/2026]

### Cible
DigiERP doit être utilisable sur tablette (768px minimum) et desktop.
Mobile (< 640px) : lecture seule acceptable, formulaires complexes non requis.

### Sidebar collapsible (AppLayout)
```jsx
// AppLayout.jsx — sidebar avec 3 états
// - desktop (≥1024px) : sidebar étendue par défaut (w-64, texte visible)
// - tablette (768-1023px) : sidebar réduite par défaut (w-16, icônes seules)
// - collapsed (manuel) : icônes seules quelle que soit la taille

const [collapsed, setCollapsed] = useState(() => {
  // Persistance : mémoriser le choix de l'utilisateur
  return localStorage.getItem('sidebar-collapsed') === 'true'
    || window.innerWidth < 1024  // réduit automatiquement sur tablette
})

// Structure sidebar
<aside className={`
  flex flex-col h-screen bg-slate-800 transition-all duration-300
  ${collapsed ? 'w-16' : 'w-64'}
`}>
  {/* Bouton toggle */}
  <button onClick={() => {
    const next = !collapsed
    setCollapsed(next)
    localStorage.setItem('sidebar-collapsed', String(next))
  }} aria-label="Réduire/étendre la navigation" />

  {/* Item navigation */}
  <NavLink to={item.to}>
    <span className="text-xl">{item.icon}</span>
    {!collapsed && <span className="ml-3">{t(item.label)}</span>}
  </NavLink>
</aside>
```

### Grilles de formulaires — règle obligatoire
```jsx
// TOUJOURS grid responsive — jamais de grid fixe à 2 colonnes
<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
  <FormInput label="Nom" ... />
  <FormInput label="Prénom" ... />
</div>

// Champ pleine largeur (ex: description)
<div className="col-span-1 md:col-span-2">
  <FormTextarea label="Description" ... />
</div>

// Dates côte à côte dès tablette
<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
  <FormInput label="Date début" type="date" ... />
  <FormInput label="Date fin"   type="date" ... />
</div>
```

### Tableaux — règle obligatoire
```jsx
// TOUJOURS wrapper overflow-x-auto — jamais de tableau sans scroll horizontal
<div className="overflow-x-auto rounded-lg border border-slate-200">
  <table className="min-w-full ...">
    ...
  </table>
</div>
// Sur tablette : l'utilisateur scrolle horizontalement si le tableau est large
// Ne jamais cacher des colonnes importantes — laisser défiler
```

### Modales — règle obligatoire
```jsx
// TOUJOURS dimensionnement responsive — jamais de largeur fixe px
<div className="
  fixed inset-0 z-50 flex items-center justify-center p-4
  bg-black/50
">
  <div className="
    bg-white rounded-lg shadow-xl
    w-full max-w-2xl          ← max-w fixe, width 100% sur mobile
    max-h-[90vh] overflow-y-auto  ← scroll vertical si contenu long
  ">
    ...
  </div>
</div>
// Tailles standard de modales :
// Petite  : max-w-md   (confirmations, alertes)
// Moyenne : max-w-2xl  (formulaires standard)
// Grande  : max-w-4xl  (formulaires complexes multi-onglets)
// max-h-[90vh] + overflow-y-auto : TOUJOURS pour éviter débordement écran
```

### PageHeader — responsive
```jsx
// Sur mobile : titre en haut, actions en dessous (flex-col)
// Sur tablette+ : titre à gauche, actions à droite (flex-row)
<div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
  <div>
    <h1 className="text-xl font-bold text-slate-800">{title}</h1>
    {subtitle && <p className="text-sm text-slate-500 mt-1">{subtitle}</p>}
  </div>
  {actions && (
    <div className="flex flex-wrap gap-2">
      {actions}
    </div>
  )}
</div>
```

---

## 5. PAGINATION FRONTEND [NOUVEAU 06/06/2026]

### Hook useListState — état partagé pagination/tri/recherche
```javascript
// hooks/useListState.js
// Ce hook centralise TOUT l'état d'une liste paginée.
// Chaque module use{Module}List utilise useListState en interne.

export function useListState({
  pageDefaut   = 0,
  tailleDefaut = 20,
  triDefaut    = 'dateCreation',
  ordreDefaut  = 'desc',
} = {}) {
  const [page,      setPage]      = useState(pageDefaut)
  const [taille,    setTaille]    = useState(tailleDefaut)
  const [tri,       setTri]       = useState(triDefaut)
  const [ordre,     setOrdre]     = useState(ordreDefaut)
  const [recherche, setRecherche] = useState('')

  // Changer de tri : retour à la page 0
  const changerTri = (colonne) => {
    if (colonne === tri) {
      setOrdre(o => o === 'asc' ? 'desc' : 'asc')
    } else {
      setTri(colonne)
      setOrdre('asc')
    }
    setPage(0)
  }

  // Changer la recherche : retour à la page 0
  const changerRecherche = (valeur) => {
    setRecherche(valeur)
    setPage(0)
  }

  // Réinitialiser tout
  const reinitialiser = () => {
    setPage(pageDefaut)
    setTaille(tailleDefaut)
    setTri(triDefaut)
    setOrdre(ordreDefaut)
    setRecherche('')
  }

  // Paramètres prêts à envoyer à l'API
  const params = { page, taille, tri, ordre, recherche }

  return {
    page, setPage,
    taille, setTaille,
    tri, ordre, changerTri,
    recherche, changerRecherche,
    reinitialiser,
    params,   // ← passer directement à useApi
  }
}
```

### Pattern use{Module}List — intégration pagination
```javascript
// hooks/useContratsList.js
export function useContratsList() {
  const listState = useListState({ triDefaut: 'dateCreation', ordreDefaut: 'desc' })

  const { data, loading, refetch } = useApi({
    endpoint:   '/rh/contrats',
    permission: 'RH.CONTRAT:LIRE',
    params:     listState.params,  // ← page, taille, tri, ordre, recherche
  })

  // data.contenu     = éléments de la page courante
  // data.totalPages  = nb total de pages
  // data.totalElements = nb total d'éléments
  return {
    contrats:      data?.contenu ?? [],
    totalPages:    data?.totalPages ?? 0,
    totalElements: data?.totalElements ?? 0,
    loading,
    refetch,
    ...listState,  // expose page, setPage, changerTri, changerRecherche, etc.
  }
}
```

### Composant Pagination.jsx — partagé tous modules
```jsx
// shared/ui/Pagination.jsx
// Utilisé sur TOUTES les pages avec liste paginée

export function Pagination({
  page,           // page courante (0-indexed)
  totalPages,     // nb total de pages
  totalElements,  // nb total d'éléments
  taille,         // éléments par page
  onPageChange,   // (pageIndex) => void
  loading = false,
}) {
  if (totalPages <= 1) return null  // masqué si une seule page

  const debut = page * taille + 1
  const fin   = Math.min((page + 1) * taille, totalElements)

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-3 mt-4 px-2">
      {/* Info éléments */}
      <span className="text-sm text-slate-500">
        {debut}–{fin} sur {totalElements} élément(s)
      </span>

      {/* Boutons navigation */}
      <div className="flex items-center gap-1">
        {/* Première page */}
        <button
          onClick={() => onPageChange(0)}
          disabled={page === 0 || loading}
          aria-label="Première page"
          className="p-1.5 rounded hover:bg-slate-100 disabled:opacity-40"
        >«</button>

        {/* Page précédente */}
        <button
          onClick={() => onPageChange(page - 1)}
          disabled={page === 0 || loading}
          aria-label="Page précédente"
          className="p-1.5 rounded hover:bg-slate-100 disabled:opacity-40"
        >‹</button>

        {/* Numéros de pages (fenêtre glissante ±2) */}
        {Array.from({ length: totalPages }, (_, i) => i)
          .filter(i => Math.abs(i - page) <= 2)
          .map(i => (
            <button
              key={i}
              onClick={() => onPageChange(i)}
              disabled={loading}
              className={`
                px-3 py-1.5 rounded text-sm font-medium
                ${i === page
                  ? 'bg-blue-600 text-white'
                  : 'hover:bg-slate-100 text-slate-600'}
              `}
            >{i + 1}</button>
          ))
        }

        {/* Page suivante */}
        <button
          onClick={() => onPageChange(page + 1)}
          disabled={page === totalPages - 1 || loading}
          aria-label="Page suivante"
          className="p-1.5 rounded hover:bg-slate-100 disabled:opacity-40"
        >›</button>

        {/* Dernière page */}
        <button
          onClick={() => onPageChange(totalPages - 1)}
          disabled={page === totalPages - 1 || loading}
          aria-label="Dernière page"
          className="p-1.5 rounded hover:bg-slate-100 disabled:opacity-40"
        >»</button>
      </div>
    </div>
  )
}
```

### Utilisation dans une page
```jsx
// ContratsPage.jsx
function ContratsPage({ canRead, canWrite }) {
  const {
    contrats, totalPages, totalElements, loading,
    page, setPage, taille,
    tri, ordre, changerTri,
    recherche, changerRecherche,
  } = useContratsList()

  return (
    <div>
      <PageHeader title={t('contrats:titre')} subtitle={`${totalElements} contrat(s)`} ... />

      {/* Barre de recherche */}
      <input
        type="search"
        value={recherche}
        onChange={e => changerRecherche(e.target.value)}
        placeholder={t('common:rechercher')}
        className="..."
      />

      {/* Tableau */}
      <ContratTable
        data={contrats}
        loading={loading}
        canWrite={canWrite}
        tri={tri}
        ordre={ordre}
        onTri={changerTri}
        ...
      />

      {/* Pagination — composant partagé */}
      <Pagination
        page={page}
        totalPages={totalPages}
        totalElements={totalElements}
        taille={taille}
        onPageChange={setPage}
        loading={loading}
      />
    </div>
  )
}
```

### Règles pagination
```
Taille par défaut : 20 éléments
Taille utilisateur : ne pas exposer le changement de taille en UI (complexité inutile)
Référentiels (types, catégories < 200 éléments) : liste simple sans pagination
Toute liste transactionnelle (employés, contrats, absences...) : TOUJOURS paginée
Retour page 0 obligatoire lors d'un changement de recherche ou tri
```

---

## 6. AUTHENTIFICATION

### Stockage token
- Access token  : httpOnly cookie (non accessible par JavaScript → anti-XSS)
- Refresh token : httpOnly cookie séparé, rotation à chaque usage
- CSRF token    : localStorage uniquement (envoyé en header X-XSRF-TOKEN)
- user (identifiant, roles, permissions) : sessionStorage (vidé à fermeture onglet)
### Flux complet
```
Login →
  POST /api/auth/login
  ← Set-Cookie: access_token (httpOnly, 15min)
  ← Set-Cookie: refresh_token (httpOnly, 7j)
  ← Body: { user, csrf_token }

Requête API →
  Cookie: access_token (automatique)
  Header: X-XSRF-TOKEN: {csrf_token}

Token expiré (401) →
  Intercepteur Axios → POST /api/auth/refresh (cookie refresh_token)
  ← Nouveau access_token (cookie)
  → Retry requête originale silencieusement

Refresh expiré →
  logout() → redirect /login

Logout →
  POST /api/auth/logout (blacklist token serveur)
  sessionStorage.clear()
  → redirect /login (rechargement complet)
```

### AuthContext — contrat
```javascript
const { user, loading, login, logout, isAuthenticated } = useAuth()
// user = { identifiant, roles[], permissions[], langueCode }
// loading = true pendant restauration session au démarrage
// isAuthenticated = !!user && !loading
```

### Warning expiration session
- 2 minutes avant expiration → popup "Votre session expire dans 2 min"
- Bouton "Prolonger" → appel /api/auth/refresh silencieux

---

## 7. HOOK useApi — APPELS API SÉCURISÉS

### Principe
Remplace les appels directs api.get(). Vérifie la permission AVANT l'appel.
Utilise Promise.allSettled — une erreur sur un appel secondaire ne plante pas la page.

### Signature
```javascript
const { data, loading, error, refetch } = useApi({
  endpoint:   '/rh/postes',
  permission: 'RH.POSTE:LIRE',  // optionnel — si absent, appel sans vérification
  params:     listState.params,  // ← passer params de useListState directement
  enabled:    true,              // false = appel suspendu (ex: attend un ID)
})
// Si permission manquante : data=null, loading=false, error=null, pas d'appel réseau
// Si permission présente  : appel normal
```

### Appels multiples indépendants
```javascript
// Promise.allSettled — un 403 n'empêche pas les autres
const [employes, postes] = useApiMultiple([
  { endpoint: '/rh/employes', permission: 'RH.EMPLOYE:LIRE' },
  { endpoint: '/rh/postes',   permission: 'RH.POSTE:LIRE'  },
])
```

### JAMAIS
```javascript
// ❌ JAMAIS appel direct sans vérification de permission
useEffect(() => { api.get('/rh/postes') }, [])

// ✅ TOUJOURS via useApi avec permission
const { data } = useApi({ endpoint: '/rh/postes', permission: 'RH.POSTE:LIRE' })
```

---

## 8. PROTECTEDROUTE — CONTRÔLE D'ACCÈS

### Signature complète
```jsx
<ProtectedRoute
  permission="RH.CONTRAT:LIRE"         // requis pour accéder à la page
  writePermission="RH.CONTRAT:CREER"   // optionnel — détermine mode readonly/full
>
  <ContratsPage />
</ProtectedRoute>
```

### Props transmises automatiquement à la page
```javascript
function ContratsPage({ canRead, canWrite }) {
  // canRead  = true si permission présente
  // canWrite = true si writePermission présente
  // Boutons Créer/Modifier/Supprimer masqués si canWrite=false
}
```

### Comportement
1. loading=true → spinner (jamais de redirect prématurée)
2. Pas authentifié → redirect /login
3. Authentifié sans permission → redirect /403
4. Authentifié avec permission → affiche la page + injecte canRead/canWrite

---

## 9. NAVIGATION DYNAMIQUE

### Principe
La sidebar affiche UNIQUEMENT les items accessibles à l'utilisateur connecté.
Zéro item cliquable pour lequel l'utilisateur recevrait un 403.

### navigation.js — structure obligatoire
```javascript
export const navGroupes = [
  {
    id: 'rh',
    label: 'nav:groupe_rh',
    actif: true,
    items: [
      {
        to:                 '/employes',
        label:              'nav:employes',
        icon:               '👤',
        actif:              true,
        permissionRequired: 'RH.EMPLOYE:LIRE',  // ← OBLIGATOIRE sur chaque item
      },
    ]
  }
]
```

### Filtrage dans AppLayout
```javascript
// Item visible si : actif=true ET (permission présente OU admin)
const itemsVisibles = groupe.items.filter(item =>
  item.actif && (
    !item.permissionRequired ||
    permissions.includes(item.permissionRequired)
  )
)
// Groupe masqué si tous ses items sont masqués
```
[Rev 5] Le rôle EMPLOYE a désormais `RH.WORKFLOW:LIRE` : l'entrée Workflow (Mes tâches,
Mes demandes) lui est visible ; les lignes sont filtrées par le serveur.

---

## 10. GESTION DES ERREURS

### 3 niveaux

**Niveau 1 — ErrorBoundary React (crash composant)**
```jsx
<ErrorBoundary fallback={<PageErreur />}>
  <ContratsPage />
</ErrorBoundary>
```

**Niveau 2 — Intercepteur Axios (erreurs réseau)**
```javascript
401 → logout() + redirect /login
403 → géré par ProtectedRoute (pas de redirect ici)
5xx → toast erreur "Erreur serveur, réessayez"
timeout → toast erreur "Serveur indisponible" + retry x2
réseau down → redirect /maintenance
```

**Niveau 3 — Pages (erreurs métier)**
```javascript
const { handleError } = useErrorHandler()
try {
  await contratService.creer(data)
} catch (err) {
  handleError(err)
}
```

### useErrorHandler — messages standardisés
```javascript
400 → message du backend (validation ; [Rev 5] « Paramètre obligatoire manquant : x »)
401 → "Session expirée, reconnectez-vous"
403 → [Rev 5] message du backend s'il existe (« Seul le demandeur ou un gestionnaire peut
      annuler cette demande », « Vous n'êtes pas le valideur désigné... »), sinon
      "Vous n'avez pas les droits pour cette action"
404 → "Élément introuvable" (le document peut aussi être INVISIBLE pour cet utilisateur :
      ne jamais afficher « il existe mais... »)
409 → message du backend (conflit)
422 → message du backend (règle métier) [Rev 4 : toujours afficher le message du 422]
5xx → "Erreur serveur, veuillez réessayer"
réseau → "Impossible de joindre le serveur"
```

---

## 11. COMPOSANTS ATOMIQUES (shared/ui/)

### Principe
Composants sans logique métier. Reçoivent props, émettent events.
Modifier un composant = changement partout où il est utilisé.
[Rev 6] Réciproque : un composant partagé ne rend QUE les props qu'il déclare. Avant de lui
passer une prop ou des enfants, lire sa signature (§38).
[Rev 7] Un composant partagé qui reçoit une valeur inconnue (type, variante) le SIGNALE
(`console.error`) au lieu de se replier en silence ; le repli reste, pour ne rien casser.

### Button
```jsx
<Button variant="primary" size="md" loading={saving} disabled={!isValid} onClick={handleSubmit}>
  Enregistrer
</Button>
// variants : primary, secondary, danger, success, warning, ghost
// sizes    : sm, md, lg
// loading  : affiche spinner + désactive automatiquement
```

### Badge
```jsx
<Badge variant="success">Actif</Badge>
// variants : success, danger, warning, info, neutral
```

### EmptyState
```jsx
<EmptyState
  icon="📭"
  title="Aucun contrat"
  message="Créez votre premier contrat"
  action={canWrite && <Button onClick={openForm}>Nouveau contrat</Button>}
/>
```

### PageHeader
```jsx
<PageHeader
  title={t('contrats:titre')}
  subtitle={`${totalElements} contrat(s)`}
  actions={canWrite && (
    <>
      <Button variant="secondary" onClick={openArchives}>Archives</Button>
      <Button variant="primary"   onClick={openForm}>+ Nouveau</Button>
    </>
  )}
/>
// Breadcrumb intégré automatiquement
// Responsive : flex-col sur mobile, flex-row sur tablette+
```

### Spinner
```jsx
<Spinner size="md" />  // sizes : sm, md, lg, full (plein écran)
```

### Pagination
```jsx
// Voir section 5 — composant partagé par tous les modules
<Pagination
  page={page} totalPages={totalPages} totalElements={totalElements}
  taille={taille} onPageChange={setPage} loading={loading}
/>
```

### ConfirmModal [Rev 7] (shared/components/ConfirmModal.jsx)
```jsx
<ConfirmModal
  isOpen={…} onClose={…}
  onConfirm={(motif) => gererX(motif)}   // reçoit la saisie du champ interne
  title={…} message={…}
  type="danger"            // danger | warning | info | success (inconnu → console.error)
  avecMotif={true}         // affiche LE champ de saisie (le seul)
  motifLabel={t('…')}      // libellé du champ (défaut : common:motif)
  motifRequired={true}     // bloque Confirmer si vide (le serveur doit AUSSI l'exiger)
  loading={enSuppression}
>
  {/* facultatif : contenu rendu entre le message et le champ (avertissement, rappel) */}
</ConfirmModal>
```
Voir §38 pour les règles (un seul champ, gestionnaire qui reçoit et transmet `motif`).
[Rev 8] `Modal` et `ConfirmModal` s'inscrivent dans la PILE UNIQUE des fenêtres (§41) :
Échap ne ferme que la fenêtre du dessus (pour `ConfirmModal` : Échap = « Annuler », ignoré
pendant `loading`) ; le défilement de la page est bloqué tant qu'une fenêtre est ouverte.
Aucun composant n'écoute Échap ni ne touche `document.body.style.overflow` lui-même.

---

## 12. FORMULAIRES

### Pattern obligatoire
```javascript
function useContratForm({ contrat, onSuccess }) {
  const [form, setForm]       = useState(initialState)
  const [errors, setErrors]   = useState({})
  const [saving, setSaving]   = useState(false)
  const { handleError }       = useErrorHandler()
  const { succes }            = useToast()

  useEffect(() => {
    setForm(contrat ? mapToForm(contrat) : initialState)
    setErrors({})
  }, [contrat])

  const valider = () => { /* ... retourne errors */ }

  const soumettre = async () => {
    const errs = valider()
    if (Object.keys(errs).length) { setErrors(errs); return }
    setSaving(true)
    try {
      await contratService.creer(form)
      succes(t('contrats:messages.cree'))
      onSuccess()
    } catch (err) {
      handleError(err)
    } finally {
      setSaving(false)
    }
  }

  return { form, setForm, errors, saving, soumettre }
}
```

### Règles obligatoires
- useEffect pour initialiser le formulaire (jamais useState avec valeur initiale complexe)
- Validation locale AVANT envoi
- Grilles TOUJOURS responsive : `grid grid-cols-1 md:grid-cols-2 gap-4`
- Dates début/fin sur la même ligne en md
- Validation date : fin > début obligatoire
- FK envoyées en Number(), reçues converties en String() pour les selects
- Référentiels chargés via useApi avec permission — pas d'appel direct
- [Rev 4] `FormSelect` : il ajoute TOUJOURS sa propre option vide (prop `placeholder`,
  toujours passée en i18n) → jamais d'option `value: ''` dans `options` ; texte d'aide par
  la prop `hint` ; `onChange` reçoit l'ÉVÉNEMENT (`e.target.value`)
- [Rev 4] Une remise à zéro liée à une action de l'utilisateur va dans le `onChange`,
  jamais dans un `useEffect` (sinon elle s'exécute aussi au préremplissage)
- [Rev 4] Valeur `null` venant du backend dans un champ contrôlé → `?? ''`
### Champs conditionnels selon canWrite
```jsx
{canWrite ? (
  <FormInput label="Libellé" value={form.libelle} onChange={...} />
) : (
  <ReadOnlyField label="Libellé" value={form.libelle} />
)}
```

---

## 13. TABLEAUX

### Structure obligatoire
```jsx
function ContratTable({ data, loading, canWrite, tri, ordre, onTri, onEdit, onDelete }) {
  if (loading) return <Spinner size="full" />
  if (!data?.length) return <EmptyState ... />

  return (
    // overflow-x-auto OBLIGATOIRE — scroll horizontal sur tablette
    <div className="overflow-x-auto rounded-lg border border-slate-200">
      <table className="min-w-full divide-y divide-slate-200">
        <thead className="bg-slate-50">
          <tr>
            {/* En-tête cliquable pour tri */}
            <th
              scope="col"
              className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase cursor-pointer select-none"
              onClick={() => onTri('nom')}
            >
              {t('contrats:colonnes.nom')}
              {tri === 'nom' && (ordre === 'asc' ? ' ↑' : ' ↓')}
            </th>
            {canWrite && <th scope="col" className="px-4 py-3">Actions</th>}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {data.map(item => (
            <tr key={item.id} className="hover:bg-slate-50">
              <td className="px-4 py-3 text-sm">{item.nom}</td>
              {canWrite && (
                <td className="px-4 py-3 whitespace-nowrap">
                  <Button variant="ghost" size="sm" onClick={() => onEdit(item)}>✏️</Button>
                  <Button variant="ghost" size="sm" onClick={() => onDelete(item)}>🗑️</Button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
```

---

## 14. INTERNATIONALISATION (i18n)

### Règles
- Fichiers fr/ et en/ créés AVANT d'écrire le composant
- Namespace déclaré dans i18n/index.js avant usage
- Chaque composant déclare son propre useTranslation (jamais passer t en prop)
- node check-i18n.cjs → 0 problème avant tout commit
- [Rev 4] Réutiliser un libellé d'un autre namespace par interpolation plutôt que le
  recopier : `t('typeAbsence:reserve.badge', { module: t('absences:origines.' + code) })`
- [Rev 4] Modification des JSON par insertion textuelle (diff minimal), validation
  `json.loads`, parité fr/en contrôlée, écriture tout-ou-rien des 2 langues
- [Rev 7] Une clé devenue inutilisée par une modification est RETIRÉE dans le même commit
  (fr et en) : `grep -rn "<clé>" src --include=*.js --include=*.jsx` vide avant retrait ;
  attention aux homonymes d'un AUTRE namespace (`discipline:commentaire_rejet` ≠
  `absences:form.commentaire_rejet`). `check-i18n.cjs` détecte les clés MANQUANTES, pas les
  clés INUTILISÉES (dette : l'étendre)
- [Rev 8] `check-i18n.cjs` ne lit que les `.jsx` : une clé citée dans un `.js` (toast d'un
  hook, utilitaire) lui est INVISIBLE (cas réel corrigé en (c) : deux toasts du workflow
  citaient des clés inexistantes) → la vérifier contre le JSON
- [Rev 8] Valeurs d'enum et clés envoyées par le serveur : contrôlées CONTRE LA SOURCE Java,
  jamais recopiées de mémoire (§45)
### Structure obligatoire par module
```json
{
  "titre": "...",
  "sous_titre": "... au total",
  "colonnes": { "champ": "..." },
  "form": { "champ": "...", "champ_hint": "..." },
  "messages": {
    "cree": "... créé avec succès",
    "modifie": "... modifié avec succès",
    "supprime": "... supprimé avec succès",
    "confirmer_suppression": "Confirmer la suppression de {{nom}} ?"
  },
  "vide": "Aucun élément trouvé",
  "archives": { "titre": "Archives", "vide": "Aucune archive" }
}
```

---

## 15. PERFORMANCE

### Lazy loading obligatoire sur toutes les pages
```javascript
const ContratsPage = lazy(() => import('./modules/contrats/ContratsPage'))
// Wrappé dans Suspense avec fallback spinner
```

### Virtualisation pour listes > 100 éléments affichés
```javascript
// Avec pagination côté serveur (taille=20), la virtualisation est rarement nécessaire
// Utiliser react-virtual uniquement pour les listes sans pagination (référentiels larges)
import { useVirtualizer } from '@tanstack/react-virtual'
```

### Timeout sur toutes les requêtes
```javascript
api.defaults.timeout = 30000  // 30 secondes max
```

---

## 16. TESTS

### 3 niveaux obligatoires

**Niveau 1 — Hooks (logique métier)**
```javascript
import { renderHook, act } from '@testing-library/react'
test('soumettre avec données invalides affiche erreurs', async () => { ... })
test('changerRecherche remet page à 0', () => {
  const { result } = renderHook(() => useListState())
  act(() => { result.current.setPage(3) })
  act(() => { result.current.changerRecherche('dupont') })
  expect(result.current.page).toBe(0)
})
```

**Niveau 2 — Composants (affichage)**
```javascript
test('masque boutons si canWrite=false', () => {
  render(<ContratTable data={[...]} canWrite={false} />)
  expect(screen.queryByText('✏️')).not.toBeInTheDocument()
})
test('Pagination masquée si totalPages=1', () => {
  render(<Pagination page={0} totalPages={1} totalElements={5} taille={20} onPageChange={vi.fn()} />)
  expect(screen.queryByRole('button')).not.toBeInTheDocument()
})
```

**Niveau 3 — E2E (parcours utilisateur)**
```javascript
test('afeudjo ne peut pas accéder à /postes', async ({ page }) => {
  await loginAs(page, 'afeudjo')
  await page.goto('/postes')
  await expect(page).toHaveURL('/403')
})
```

[Rev 5] Tests UI d'un document soumis au workflow : les jouer AUSSI avec le valideur de rôle
EMPLOYE (pnkouatchou, N+1 d'afeudjo) : il voit la demande, l'ouvre, la décide, et ne se voit
proposer AUCUNE autre action.
[Rev 6] Les ATTENDUS d'un scénario UI (boutons visibles par compte) se déduisent des
permissions RÉELLES des rôles (lues en base) ET des actionsPermises renvoyées par le serveur ;
jamais de tête. La preuve positive d'un bouton se fait avec un compte qui a les deux (ex :
🗑 et archives avec admin, seul rôle à SUPPRIMER / PURGER au 29/09).
[Rev 7] Quand une SAISIE doit partir au serveur (motif, commentaire, détail) : le test UI
vérifie les trois étages — ce que l'écran affiche, la CHARGE UTILE (F12 → Réseau → la
requête → Payload) et la valeur EN BASE. Un défaut de transmission se prouve AVANT la
correction (même requête, même acteur désigné) et se contre-prouve (même requête valide →
200) pour savoir s'il est dans l'écran ou dans le serveur. Une saisie facultative absente en
base ne prouve rien si l'on ne sait pas qu'elle a été saisie : rejouer avec la saisie.

---

## 17. ACCESSIBILITÉ (WCAG AA minimum)

- Tous les inputs ont un label associé (htmlFor)
- Contraste couleur ≥ 4.5:1 (vérifier avec theme.js)
- Focus visible sur tous les éléments interactifs
- Modales : focus renvoyé à l'élément déclencheur à la fermeture
- Images décoratives : alt=""
- Tables : thead obligatoire avec scope="col" sur chaque th
- Boutons icône : aria-label obligatoire
- Boutons pagination : aria-label obligatoire ("Page précédente", etc.)
- Sidebar réduite : title ou aria-label sur chaque icône de navigation

---

## 18. SÉCURITÉ FRONTEND

### CSRF
```javascript
api.interceptors.request.use(config => {
  if (['post','put','patch','delete'].includes(config.method)) {
    config.headers['X-XSRF-TOKEN'] = sessionStorage.getItem('csrf_token')
  }
  return config
})
```

### Sanitisation des inputs
```javascript
import DOMPurify from 'dompurify'
const safeHtml = DOMPurify.sanitize(userInput)
```

### Content Security Policy
```nginx
# nginx.conf — pas dans le frontend
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'";
```

---

## 19. CHECKLIST CRÉATION DE PAGE [MIS À JOUR 06/06/2026 — compléments §34 et §37]

Avant tout commit, vérifier :
[ ] 1.  Fichiers i18n fr/ et en/ créés avec TOUTES les clés
[ ] 2.  Namespace ajouté dans i18n/index.js
[ ] 3.  node check-i18n.cjs → 0 problème
[ ] 4.  Route ajoutée dans routes.jsx avec ProtectedRoute + permission
[ ] 5.  Item ajouté dans navigation.js avec permissionRequired
[ ] 6.  Page = orchestration uniquement (pas de logique directe)
[ ] 7.  Logique dans hooks/, appels API dans services/
[ ] 8.  useApi avec permission sur TOUS les appels
[ ] 9.  canWrite vérifié avant TOUS les boutons d'action
[ ] 10. EmptyState si liste vide
[ ] 11. Spinner pendant chargement
[ ] 12. ErrorBoundary dans App.jsx autour de la nouvelle route
[ ] 13. Test hook (logique) + test composant (affichage) écrits
[ ] 14. Lazy import dans routes.jsx
[ ] 15. Labels sur tous les inputs (accessibilité)
[ ] 16. overflow-x-auto sur tous les tableaux
[ ] 17. grid grid-cols-1 md:grid-cols-2 sur tous les formulaires
[ ] 18. Modales avec w-full max-w-Xnl max-h-[90vh] overflow-y-auto
[ ] 19. useListState utilisé dans use{Module}List (pagination)
[ ] 20. <Pagination /> présent sous chaque tableau transactionnel
[ ] 21. Sidebar collapsible : état persisté dans localStorage

---

## 20. STANDARDS MICROSERVICES FRONTEND (session 14)

### VITE_API_URL — règle définitive
```javascript
// .env.development et .env.production — IDENTIQUES
VITE_API_URL=http://localhost:8080/api  // gateway uniquement
VITE_WS_URL=http://localhost:8080/ws

// ❌ INTERDIT — accès direct au backend
VITE_API_URL=http://localhost:8090/api
```

Le frontend appelle TOUJOURS le gateway (port 8080), jamais les services directement.

### nginx.conf — règle définitive
nginx sert UNIQUEMENT les fichiers statiques React.
Il ne proxifie PLUS /api/ (double proxy = chunked encoding corrompu).

```nginx
# ✅ CORRECT — nginx = fichiers statiques seulement
location / {
    try_files $uri $uri/ /index.html;
}

# ❌ INTERDIT — ne plus proxifier /api/
location /api/ {
    proxy_pass http://gateway:8080/api/;  # cause ERR_INCOMPLETE_CHUNKED_ENCODING
}
```

[Rev 7] Le frontend servi par nginx est TOUJOURS un build de production : `import.meta.env.DEV`
y vaut `false` et Vite supprime le code qu'il garde. Une alerte destinée au développeur
(ex : type inconnu de `ConfirmModal`) qui doit être vue sur l'environnement de travail ne se
cache pas derrière `import.meta.env.DEV`.

### AuthContext — employeId obligatoire
```javascript
// AuthContext.jsx — user doit toujours contenir employeId
const userData = {
  identifiant,
  roles,
  permissions,
  langueCode,
  employeId: employeId ?? null,  // null = admin sans fiche employé
}
```

Ne jamais faire un appel réseau pour récupérer employeId dans un composant.
Il est disponible directement via `useAuth().user.employeId`.

---

## 21. STANDARDS PERMISSIONS PBAC FRONTEND (session 14)

### writePermission — règle définitive App.jsx
```jsx
// ✅ TOUJOURS CREER
<ProtectedRoute permission="MODULE:LIRE" writePermission="MODULE:CREER">

// ❌ JAMAIS MODIFIER
<ProtectedRoute permission="MODULE:LIRE" writePermission="MODULE:MODIFIER">
```

MODIFIER n'est pas dans le rôle EMPLOYE.
CREER = "peut créer des enregistrements" = canWrite=true pour les formulaires.

### Permission dédiée pour modes UI
Ne jamais utiliser une permission CRUD comme critère de mode d'interface.
Utiliser une permission dédiée avec sémantique métier.

```javascript
// ✅ Permission dédiée — configurable via PBAC
const peutLireEmployes = peutFaire('RH.ABSENCE', 'EMETTRE_TIERS')

// ❌ Anti-pattern — permission CRUD comme critère UI
const estAdmin = peutFaire('RH.EMPLOYE', 'CREER')
const estAdmin = peutFaire('RH.EMPLOYE', 'MODIFIER')
```

### Checklist création AbsenceForm-like (formulaire 2 modes)
```javascript
// 1. Identifier la permission dédiée (PBAC)
const peutGererTous = peutFaire('MODULE', 'ACTION_DEDIEE')

// 2. Charger les données selon le mode
if (peutGererTous) {
  // Charger la liste complète
} else {
  // Auto-sélection depuis user.employeId (AuthContext)
  // Pas d'appel réseau pour la liste
}

// 3. Afficher selon le mode
{peutGererTous
  ? <FormSelect options={liste} ... />
  : <div readonly>{nomEmploye}</div>
}
```

[Rev 5] Une permission PBAC dit ce que le RÔLE peut faire sur un TYPE de document ; elle ne
dit pas ce que l'utilisateur peut faire sur CE document (voir §35).

---

## 22. COMPOSANT MODAL — STANDARD DigiERP (session 14)

### Props standard (anglais)
```jsx
// ✅ CORRECT — props anglaises
<Modal isOpen={ouvert} onClose={onFermer} title={titre}>

// ❌ INTERDIT — props françaises sur Modal partagé
<Modal ouvert={ouvert} titre={titre}>
```

Props : `isOpen` (boolean) + `title` (string) + `onClose` (fonction)

Les props internes des composants peuvent utiliser `ouvert` (français)
mais doivent passer `isOpen` au composant `<Modal>` partagé.

```jsx
// ✅ Pattern correct
export default function MonForm({ ouvert, onClose }) {
  return (
    <Modal isOpen={ouvert} onClose={onClose} title="Mon titre">
      ...
    </Modal>
  )
}
```

### Module de référence
Postes = référence zéro violation pour tous les patterns v3.
Vérifier PostesModales.jsx avant d'implémenter un nouveau module.
[Rev 7] Réserve : `usePostesList.supprimerPoste` ignorait le motif saisi jusqu'au commit
b1f42b99 (§38) — même un module « de référence » se vérifie par l'inventaire, pas par la
réputation.

---

## 23. CHECKLIST NOUVEAU MODULE FRONTEND (mise à jour session 14)

Avant tout commit d'un nouveau module :
[ ] 1.  Structure : Page / components / hooks / services respectée
[ ] 2.  useXxxList() retourne le contrat standard pattern v3
[ ] 3.  writePermission = MODULE:CREER dans App.jsx (jamais MODIFIER)
[ ] 4.  Modal : isOpen + title (anglais) sur le composant partagé
[ ] 5.  Permission dédiée pour modes UI (pas de permission CRUD)
[ ] 6.  VITE_API_URL pointe sur gateway:8080 (jamais backend:8090)
[ ] 7.  user.employeId depuis useAuth() (jamais appel réseau /auth/me)
[ ] 8.  Formulaire 2 modes si émission pour tiers (self-service vs admin)
[ ] 9.  erreurCatch (jamais e, err), gerer* (jamais handle*)
[ ] 10. enSauvegarde (jamais loading pour les soumissions)
[ ] 11. employe => (jamais e =>) dans les .map()
[ ] 12. npm run build sans erreur avant push

---

## 25. PATTERNS ADMINISTRATION — DEUX APPROCHES (session 17)

### Quand utiliser le Pattern 1 — Référentiels simples (useParametrageOnglet)

**Critères :**
- Structure CRUD identique : code + libellé + description + ordreAffichage
- Pas de relations hiérarchiques entre entités
- Formulaire simple (champs génériques)
- Archives + purge standard
**Exemples :** Types de contrat, Statuts employé, Niveaux hiérarchiques,
Types de mesure discipline, Standards de temps

**Structure :**
```jsx
// Page = 10 lignes — toute la logique dans useParametrageOnglet
const ONGLETS = [
  { id: 'typesContrat', labelKey: 'ongletTypesContrat', service: 'typesContrat' },
]
export default function ParametrageContratsPage({ canWrite = false }) {
  const [ongletActif, setOngletActif] = useState('typesContrat')
  const onglet = ONGLETS.find(o => o.id === ongletActif)
  return (
    <div className="p-6 space-y-6">
      {/* onglets nav */}
      <OngletWrapper key={ongletActif} onglet={onglet} canWrite={canWrite} />
    </div>
  )
}
function OngletWrapper({ onglet, canWrite }) {
  const hook = useParametrageOnglet(monService[onglet.service], canWrite)
  return <ParametrageOnglet onglet={onglet} hook={hook} canWrite={canWrite} />
}
```

**Fichiers concernés :**
- `useParametrageOnglet.js` — hook générique
- `ParametrageOnglet.jsx` — composant générique (formulaire adaptatif)

---

### Quand utiliser le Pattern 2 — Pages complexes (hook dédié)

**Critères :**
- Relations hiérarchiques (Org → Site → Service)
- Logique métier spécifique (groupement, filtres avancés, slide-over)
- Formulaires avec selects en cascade
- UI non réductible à un tableau CRUD simple
**Exemples :** OrganisationPage, SequencesAdminPage, WorkflowModelesPage,
PerimetresPage, PbacAdminPage, TypeAbsencePage

**Structure :**
```jsx
// Page = logique propre, hook dédié ou logique inline
export default function OrganisationPage({ canWrite = false }) {
  const [ongletActif, setOngletActif] = useState('organisations')
  return (
    <div className="p-6 space-y-6">
      {/* navigation onglets */}
      {ongletActif === 'organisations' && <OngletOrganisations canWrite={canWrite} />}
      {ongletActif === 'sites'         && <OngletSites         canWrite={canWrite} />}
    </div>
  )
}
// Chaque onglet = composant autonome avec sa propre logique
function OngletOrganisations({ canWrite }) {
  const [items, setItems]             = useState([])
  const [chargement, setChargement]   = useState(false)
  const [enSauvegarde, setEnSauvegarde] = useState(false)
  // ... logique propre
}
```

**Conventions obligatoires (Pattern 2) :**
- `canWrite` reçu depuis ProtectedRoute et propagé aux sous-composants
- `chargement` (jamais `loading`)
- `enSauvegarde` (jamais `saving` ou `loading` pour les soumissions)
- `erreurCatch` dans les catch (jamais `e`, `err`)
- `gererXxx` pour les handlers (jamais `handleXxx`)
- `charger` pour la fonction de rechargement

---

### Règle de décision rapide
Structure CRUD simple (code/libellé) ?

OUI → Pattern 1 (useParametrageOnglet)

NON → Pattern 2 (hook dédié)
Relations entre entités (parent/enfant) ?

OUI → Pattern 2 obligatoire

NON → Pattern 1 possible
Formulaire avec selects en cascade ?

OUI → Pattern 2 obligatoire

NON → Pattern 1 possible

---

## 26. PATTERN 2 — PAGES COMPLEXES (standard officiel session 17)

### Critères d'utilisation Pattern 2
Utiliser Pattern 2 quand AU MOINS UN de ces critères est vrai :
- Relations hiérarchiques entre entités (Org → Site → Service)
- Formulaires avec selects en cascade
- UI non réductible à un tableau CRUD simple (fiche détail, slide-over, tabs)
- Logique métier spécifique par sous-composant
- Chargement de référentiels multiples
### Structure canonique

```jsx
// Page principale — reçoit canWrite de ProtectedRoute
export default function MaPageComplexe({ canWrite = false }) {
  const [ongletActif, setOngletActif] = useState('premier')

  return (
    <div className="p-6 space-y-6">
      <Breadcrumb />
      {/* navigation onglets */}
      {ongletActif === 'premier' && <OngletPremier canWrite={canWrite} />}
      {ongletActif === 'second'  && <OngletSecond  canWrite={canWrite} />}
    </div>
  )
}

// Sous-composant — logique propre + canWrite propagé
function OngletPremier({ canWrite }) {
  const { t } = useTranslation(['monModule', 'common'])
  const { succes, erreur: toastErreur } = useToast()
  const { peutFaire } = usePermissions()

  // ✅ Permissions — booléens directs
  const peutCreer     = canWrite && peutFaire('MODULE', 'CREER')
  const peutModifier  = canWrite && peutFaire('MODULE', 'MODIFIER')
  const peutSupprimer = canWrite && peutFaire('MODULE', 'SUPPRIMER')

  // ✅ États — nommage obligatoire
  const [items,        setItems]        = useState([])
  const [chargement,   setChargement]   = useState(false)
  const [enSauvegarde, setEnSauvegarde] = useState(false)
  const [selection,    setSelection]    = useState(null)
  const [modalForm,    setModalForm]    = useState(false)
  const [modalSuppr,   setModalSuppr]   = useState(false)

  // ✅ Chargement — useCallback
  const charger = useCallback(async () => {
    setChargement(true)
    try {
      const reponse = await monService.lister()
      setItems(reponse.data?.data ?? [])
    } catch (erreurCatch) {
      toastErreur(erreurCatch.response?.data?.message ?? t('common:erreurChargement'))
    } finally {
      setChargement(false)
    }
  }, [])

  useEffect(() => { charger() }, [charger])

  // ✅ Handlers — préfixe gerer
  const gererSauvegarde = async (form) => {
    setEnSauvegarde(true)
    try {
      if (selection) {
        await monService.modifier(selection.id, form)
        succes(t('common:updated'))
      } else {
        await monService.creer(form)
        succes(t('common:created'))
      }
      fermerModales()
      charger()
    } catch (erreurCatch) {
      toastErreur(erreurCatch.response?.data?.message ?? t('common:erreurEnregistrement'))
    } finally {
      setEnSauvegarde(false)
    }
  }

  // [Rev 7] Le motif reçu de ConfirmModal est TRANSMIS au service (§38) —
  // l'exemple d'origine l'oubliait (motif reçu puis ignoré)
  const gererSuppression = async (motif) => {
    try {
      await monService.supprimer(selection.id, motif)
      succes(t('common:deleted'))
      fermerModales()
      charger()
    } catch (erreurCatch) {
      toastErreur(erreurCatch.response?.data?.message ?? t('common:erreurSuppression'))
    }
  }

  // ✅ Ouverture modales — préfixe ouvrir
  const ouvrirCreer    = ()     => { setSelection(null);  setModalForm(true)  }
  const ouvrirModifier = (item) => { setSelection(item);  setModalForm(true)  }
  const ouvrirSuppr    = (item) => { setSelection(item);  setModalSuppr(true) }
  const fermerModales  = ()     => {
    setModalForm(false); setModalSuppr(false); setSelection(null)
  }

  // ✅ Itération .map() — nom du domaine au singulier
  return (
    <div>
      {items.map(item => (           // ✅ item — pas i, pas x
        <div key={item.id}>{item.libelle}</div>
      ))}
      {(refs?.roles ?? []).map(role => (   // ✅ role — pas r
        <option key={role.id}>{role.code}</option>
      ))}
    </div>
  )
}
```

### Conventions obligatoires — tableau récapitulatif

| Contexte | ❌ Interdit | ✅ Obligatoire |
|----------|------------|----------------|
| État chargement liste | `loading`, `isLoading` | `chargement` |
| État sauvegarde form | `loading`, `saving` | `enSauvegarde` |
| Catch block | `e`, `err`, `error` | `erreurCatch` |
| Handlers | `handleXxx` | `gererXxx` |
| Rechargement | `reload`, `fetch` | `charger` |
| Itération rôles | `.map(r =>` | `.map(role =>` |
| Itération postes | `.map(p =>` | `.map(poste =>` |
| Itération services | `.map(s =>` | `.map(service =>` |
| Toast erreur | `console.error` | `toastErreur` |
| Textes UI | hardcodés | clés i18n |
| Permissions | fonctions `peutXxx()` | booléens `peutXxx` |

### Checklist Pattern 2 avant commit
[ ] canWrite reçu en prop (jamais calculé dans la page)

[ ] canWrite propagé à tous les sous-composants

[ ] chargement (jamais loading)

[ ] enSauvegarde (jamais saving/loading pour soumissions)

[ ] erreurCatch dans TOUS les catch (jamais e, err)

[ ] gererXxx pour TOUS les handlers (jamais handleXxx)

[ ] charger = fonction de rechargement useCallback

[ ] toastErreur (jamais console.error)

[ ] Tous les textes dans i18n (jamais hardcodés)

[ ] .map(domaine => ...) — nom du domaine au singulier

[ ] Permissions = booléens directs (jamais fonctions)

[ ] npm run build sans erreur

### Exemples Pattern 2 dans le projet
- `OrganisationPage.jsx` — 3 onglets hiérarchiques Org/Site/Service
- `ConfigPostesAccesPage.jsx` — liste postes + fiche 4 tabs
- `SequencesAdminPage.jsx` — groupement par module
- `WorkflowModelesPage.jsx` — liste + slide-over étapes
- `PerimetresPage.jsx` — liste utilisateurs + panel périmètres
- `PbacAdminPage.jsx` — 3 sous-composants matrice/config/supervision
### Règle de décision Pattern 1 vs Pattern 2
Structure CRUD simple (code/libellé) ?

OUI → Pattern 1 (useParametrageOnglet + ParametrageOnglet)

NON → continuer
Relations entre entités (parent/enfant) ?

OUI → Pattern 2 obligatoire
Formulaire avec selects en cascade ?

OUI → Pattern 2 obligatoire
UI avec tabs/fiche/slide-over ?

OUI → Pattern 2 recommandé
Sinon → Pattern 1 si possible, Pattern 2 si nécessaire

---

## 27. MODAL DE DÉTAIL + FORMULAIRE AUTONOME (24/09/2026)

Référence : module Formation — `ProgrammeDetailModal.jsx`, `CatalogueForm.jsx`,
`useFormationList.passerEnEdition`.

### Principe
La liste renvoie un `SummaryResponse` (colonnes du tableau). Il NE contient PAS tous les
champs du `Request` (type, domaine, description, objectifs...). Le passer tel quel à un
formulaire d'édition = champs vides → validation bloquante, ou pire, données effacées
à l'enregistrement.

### Règle 1 — le détail charge la fiche complète
```javascript
const { data: detail } = useApi({
  endpoint:   '/rh/formation/catalogues/' + catalogueId,   // GET /{id}
  permission: 'RH.FORMATION:LIRE',
  enabled:    isOpen && !!catalogueId,                      // chargement paresseux
})
// Protection contre les données d'un élément ouvert précédemment
const ficheComplete = detail?.id === catalogueId ? detail : null
```
Les hooks (`useApi`, `useTranslation`) sont appelés AVANT tout `if (!x) return null`.

### Règle 2 — le formulaire est AUTONOME en édition
Le formulaire recharge lui-même la fiche complète (même code que ci-dessus) et
n'utilise de la prop reçue que son `id`. Tout appelant (crayon du tableau, bouton
« Modifier » du détail, futur appelant) est ainsi correct par construction.
Parallèle Laravel : `edit($id)` qui fait `findOrFail($id)` au lieu de faire confiance
aux données reçues.

### Règle 3 — deux useEffect, une responsabilité chacun
```javascript
// 1. Ouverture : repartir d'un formulaire vide
useEffect(() => {
  if (ouvert) { setForm(FORM_VIDE); setErreurs({}) /* ... */ }
}, [ouvert, catalogue])

// 2. Arrivée des données serveur : remplir
useEffect(() => {
  if (ouvert && ficheComplete) setForm({ /* ... depuis ficheComplete */ })
}, [ouvert, ficheComplete])
```

### Règle 4 — pas de soumission sur une fiche incomplète
```javascript
if (catalogue && !ficheComplete) return   // édition : attendre la fiche complète
```
Le bouton « Modifier » du détail est `disabled={!ficheComplete}`.

### Règle 5 — bascule détail → édition dans le hook
```javascript
// useXxxList — fermer le détail, sélectionner la fiche complète, ouvrir le formulaire
const passerEnEdition = useCallback((item) => {
  setModalDetail(false)
  setSelection(item)
  setModalForm(true)
}, [])   // les 3 setState sont regroupés en un seul rendu (batching React 18)
```
Page : `<XxxDetailModal ... onModifier={liste.passerEnEdition} />`

### Règle 6 — un modal par onglet
Dans une page multi-onglets partageant `modalDetail`/`selection`, chaque modal est
conditionné à son onglet : `{liste.onglet === 'catalogues' && <ProgrammeDetailModal ... />}`.

---

## 28. FORMULAIRES — CHAMPS DU REQUEST ET CODE MÉTIER (24/09/2026)

### Tout champ du Request doit exister dans le formulaire
Le backend fait `remplir(entite, req)` : un champ absent du formulaire est envoyé
`null` et ÉCRASE la valeur en base à chaque modification.
Cas réel : `CatalogueForm` n'avait pas `description` → description effacée à chaque
enregistrement.
Vérification : comparer `XxxDto.Request` (Java) avec l'objet passé à `onSauvegarder()`.

### Code métier (pattern PosteForm / CatalogueForm)
```jsx
{/* Pas de champ code à la création : généré par le backend (PRG-2026-00001) */}
{/* Édition : code en lecture seule */}
{catalogue && (
  <FormInput
    label={t('formation:catalogue.code')}
    name="code"
    value={ficheComplete?.code ?? catalogue.code ?? ''}
    onChange={() => {}}
    disabled
    hint={t('common:codeNonModifiable', { defaultValue: 'Code non modifiable' })}
  />
)}
```
Le formulaire n'envoie jamais `code` en modification (immuable côté backend).

### Dette connue
`ModuleForm.jsx` n'envoie pas `code` alors que `FrmModuleDto.Request` l'exige →
400 en création/modification des modules. À traiter avec le même pattern.
`FormationPage` : le bouton « Archives » charge les archives mais aucune liste
d'archives n'est affichée.

---

## 29. WORKFLOW DANS LES ÉCRANS DE MODULE (28/09/2026, complété Rev 5, Rev 6 et Rev 7)

Référence : `AbsencesTable.jsx`, `MissionDetailModal.jsx`, `AbsencesModales.jsx` (Rev 7).

### Boutons Valider / Rejeter
```javascript
// ✅ Donnée dérivée calculée par le backend (Response ET SummaryResponse)
const peutDeciderCetteDemande = (d) => peutValider && d.peutDecider === true
//   peutValider   = permission PBAC 'VALIDER' (calculée dans le hook de liste)
//   d.peutDecider = l'utilisateur connecté a une décision EN_ATTENTE à l'étape courante
//                   (gère les étapes ROLE à plusieurs acteurs)

// ❌ Comparer des identifiants côté frontend (acteurAttenduUtilisateurId === utilisateurId)
//    — supprimé : ne gère qu'un acteur ; le frontend n'a pas à connaître les ids d'acteurs
```

### Règles
```
✅ Une décision prise depuis « Mes tâches » a le même effet que depuis l'écran du module :
   après une décision, recharger la liste (le statut vient du serveur, jamais déduit)
✅ Motif obligatoire en cas de rejet : modale de motif avant l'appel
✅ Titres de modale par TABLE explicite action → clé i18n (jamais de clé construite)
❌ Garder dans une page un appel au contexte d'authentification devenu inutile
   (ex : useAuth() pour un utilisateurId qui ne sert plus) : le retirer
```

### Modale de décision — un seul champ [Rev 7]
```javascript
// AbsencesModales (b1f42b99) : le champ est CELUI de ConfirmModal, pour toutes les actions
<ConfirmModal
  onConfirm={handleConfirmDecision}            // (motif) => …
  type={typeModal()}                           // danger (rejeter, annuler) | success
  avecMotif={avecCommentaire || estQualification}
  motifLabel={estQualification ? t('absences:form.detail_justification')
                               : t('absences:form.commentaire')}
  motifRequired={commentaireObligatoire}       // rejet seulement
>
  {avertissementSolde && <Avertissement … />}  // enfant : désormais RENDU
  {estQualification && <RappelStatut … />}
</ConfirmModal>

const handleConfirmDecision = (motif) => {
  const payload = { commentaire: motif }
  if (estQualification) Object.assign(payload, {
    justificationStatut: extra.justificationStatut, detailJustification: motif })
  liste.executerDecision(action, demande.id, payload)
}
// Aucun état `commentaire` dans AbsencesModales. La modale est rendue sous condition
// ({liste.confirmDecision && …}) : démontée à la fermeture, sa saisie repart de zéro.
```

### Valideur de rôle EMPLOYE [Rev 5, mis à jour Rev 6]
```
Depuis RLS-2, un EMPLOYE voit dans la liste d'un module les documents qu'il DÉCIDE (en plus
des siens), et le rôle EMPLOYE a RH.WORKFLOW:LIRE (Mes tâches, Mes demandes).
Constat du 29/09 (test U4) : dans AbsencesTable, le bouton « Annuler » s'affichait sur la
demande d'afeudjo pour son valideur pnkouatchou (condition « statut non final && PBAC »).
[Rev 6] CORRIGÉ (c124e576) : condition complétée par permis(d, 'ANNULER') (§35) ; vérifié en
UI et par la campagne (S3-droits).
[Rev 6] Constat : le même valideur n'a PAS de ✓ ✕ dans la page Absences — le rôle EMPLOYE n'a
pas RH.ABSENCE:VALIDER (porte PBAC de /absences/{id}/decider) ; il décide depuis « Mes tâches »
(porte RH.WORKFLOW:LIRE). Deux portes pour un même acte : unification au temps 3
(STANDARDS_BACKEND §48). Ne pas « corriger » l'écran en élargissant le PBAC.
```

### Décision depuis « Mes tâches » [Rev 8]
```
Depuis eee5170e, « Mes tâches » identifie le document (type, numéro, demandeur, résumé du
module) et la décision se prend depuis la FICHE de la tâche (§44), puis une ConfirmModal :
motif obligatoire au rejet, facultatif à la validation ; un commentaire vide part en `null`
(jamais ''). Après la décision : fiche et confirmation fermées, liste rechargée (le statut
vient du serveur). Le valideur EMPLOYE décide ici, pas dans la page du module (portes PBAC
unifiées au temps 3).
```

---

## 30. DOCUMENTS GÉNÉRÉS PAR UN AUTRE MODULE (28/09/2026)

Référence : absences générées (`AbsencesTable.jsx`).

```
✅ Badge d'origine sous le numéro (couleurs dédiées, distinctes des statuts) :
   libellé i18n par origine + info-bulle « se gère depuis son origine »
✅ Aucune action manuelle sur un document généré (ni soumettre, annuler, supprimer…) :
   `const estGeneree = (d) => d.origineType != null` ; à la place, un tiret avec l'info-bulle
✅ Le backend refuse de toute façon (422) : le frontend évite seulement de proposer l'action
✅ Types réservés à un module (MISSION, MISE_A_PIED, FORMATION) : absents des listes de
   saisie ; dans l'écran de paramétrage, badge « Réservé : {{module}} » et PAS de bouton
   d'archivage (le backend refuse aussi)
```

---

## 31. CONVERSION EN OPTIONS — UTILITAIRES DE MODULE (28/09/2026)

### Principe
Une conversion « réponse d'API → options de select » utilisée par plusieurs composants est
écrite UNE fois, dans `modules/{module}/utils/`, et porte la règle métier associée.

```javascript
// modules/absences/utils/typesAbsence.js
export const optionsTypesSaisissables = (types) =>
  (types ?? [])
    .filter(typeAbs => typeAbs.origineType == null)   // règle : types réservés exclus
    .map(typeAbs => ({ value: String(typeAbs.id), label: typeAbs.libelle, _type: typeAbs }))

// modules/absences/utils/employesAbsence.js — contrat RefSimpleDto(id, code, libelle)
export const optionsEmployes = (employes) =>
  (employes ?? []).map(employe => ({
    value: String(employe.id),
    label: `${employe.libelle} (${employe.code})`,
  }))
```
Parallèle Laravel : un scope `TypeAbsence::saisissables()` au lieu d'un `where` recopié.

### Règles
```
❌ Recopier le même .map(...) dans plusieurs formulaires (ou deux fois dans le même)
✅ Utilitaire = fonction pure, testable, sans appel réseau
✅ Nommer la règle (« saisissables ») plutôt que l'opération (« filtrer »)
```

---

## 32. CONTRATS D'API — LIRE LA RÉPONSE RÉELLE (28/09/2026)

```
✅ Avant d'écrire un composant, lire le DTO Java OU appeler l'endpoint (curl + jeton) et
   regarder les champs réellement renvoyés
✅ Listes de sélection : RefSimpleDto(id, code, libelle) — employé : code = matricule,
   libelle = "NOM Prénom" ; jamais prenom / nom / matricule sur ce DTO
❌ Code bâti sur une hypothèse fausse (cas réel : /rh/absences/droits/moi renvoie la LISTE
   des droits, pas un objet { employe } → branche jamais exécutée, requête inutile) :
   le supprimer, noter la dette, ne pas le « réparer » par supposition
✅ Symptôme « undefined undefined (undefined) » dans un select = noms de champs faux
✅ [Rev 5] Un champ peut être VIDE selon le lecteur (ex : contratNumero vide pour le valideur
   d'une absence : le contrat du demandeur ne le concerne pas). Afficher '—', jamais d'erreur
✅ [Rev 6] « Mes tâches » (GET /api/rh/workflow/taches) renvoie aujourd'hui des WfInstanceResponse
   SANS documentType, numéro, demandeur, dates ni noms d'acteurs (relevé réel du 29/09) : ne
   pas bâtir d'écran sur des champs absents ; le contrat WfTacheResponse arrive au temps 2 (c)
✅ [Rev 8] Livré (eee5170e) : GET /taches et GET /instances/mes-demandes renvoient des
   WfTacheResponse { instanceId, documentType, module, documentId, statut, dateSoumission,
   etapeCourante, nbEtapes, etapeLibelle, demandeur{employeId, nom, prenom, matricule},
   resume{numero, lignes[], route} | null, circuit (DÉTAIL seulement : GET /taches/{instanceId}) }.
   La clé d'une tâche est `instanceId` ; la réponse de DÉCISION (POST /instances/{id}/decider)
   reste un WfInstanceResponse avec `id`. Un même mot (« id ») ne désigne pas la même chose
   d'un contrat à l'autre : lire chaque DTO
✅ [Rev 7] Le CONTRAT D'UNE REQUÊTE aussi : ce que l'écran ENVOIE se lit dans F12 → Réseau →
   Payload, pas dans le code qu'on croit exécuté (cas réel : {statut: "REJETE", commentaire: ""}
   alors que l'utilisateur avait saisi un motif)
```

---

## 33. DÉPLOIEMENT ET CACHE NAVIGATEUR (28/09/2026)

```
Après un rebuild du frontend, les fichiers JavaScript découpés par page changent de nom
(empreinte). Un onglet resté ouvert garde l'ancien index.html et échoue au chargement d'une
page paresseuse (« veuillez rafraîchir »). Ctrl+F5 corrige.
Dette : servir index.html avec Cache-Control: no-cache (nginx) et recharger
automatiquement sur l'événement 'vite:preloadError'.
Tests UI : toujours Ctrl+F5 avant de commencer.

[Rev 8] Preuve que le NOUVEAU code est servi (avant tout test UI) : chercher une chaîne
littérale du changement dans TOUS les fichiers servis — Vite découpe le code en morceaux
(chunks) et la chaîne peut être dans n'importe lequel :
  docker exec digierp-frontend sh -c 'grep -l "<chaine>" /usr/share/nginx/html/assets/*.js'
Au moins un fichier attendu. Chercher dans un seul fichier (index-*.js) peut conclure à tort
que le code n'est pas servi. Choisir une chaîne qui survit à la minification (clé i18n,
chemin d'API), pas un nom de variable.
```

---

## 34. CHECKLIST — COMPLÉMENTS REV 4

[ ] 22. Boutons de décision sur `peutValider && d.peutDecider` (jamais de comparaison d'ids)
[ ] 23. Document généré : badge d'origine, aucune action manuelle
[ ] 24. Listes de saisie sans les types réservés ; paramétrage sans archivage des réservés
[ ] 25. Conversions en options partagées dans `utils/` du module
[ ] 26. Champs lus = champs réellement renvoyés (DTO Java ou appel réel vérifié)
[ ] 27. Code mort (imports, hooks, appels devenus inutiles) retiré dans le même commit
[ ] 28. `npx vite build` = 0 et `node check-i18n.cjs` sans erreur ; Ctrl+F5 avant les tests UI

---

## 35. DROITS SUR UN DOCUMENT — CALCULÉS PAR LE SERVEUR (29/09/2026, en place Rev 6)

### Principe
Même motif que `peutDecider` (§29) : le serveur CALCULE, l'écran N'INTERPRÈTE PAS.
Le droit « cette personne peut-elle faire cette action sur CE document ? » est décidé côté
serveur par la politique de document du module (STANDARDS_BACKEND §42) : c'est aussi elle qui
refuse l'action (403). L'écran lit sa réponse, il ne refait pas la règle.

### Contrat (en place pour Absences depuis c124e576)
```javascript
// Response ET SummaryResponse du document (liste, détail, archives) :
// actionsPermises : codes de l'enum d'actions du module permis à l'utilisateur connecté
//                   sur CE document, dans l'ordre de l'enum (calculés par la même règle
//                   que le refus 403). Le STATUT n'y entre pas.
d.actionsPermises   // demandeur    : ['SOUMETTRE', 'ANNULER', 'SUPPRIMER']
                    // son valideur : []
                    // gestionnaire : les 9 actions de l'enum

// Utilitaire local du composant (une ligne, un seul endroit par composant) :
const permis = (d, action) => d.actionsPermises?.includes(action) === true

// Bouton = règle d'affichage (statut, document généré) ET PBAC (le rôle) ET droit sur CE document
{d.statut === 'BROUILLON' && peutSoumettre && permis(d, 'SOUMETTRE') && ( <button … /> )}
{!['APPROUVEE','CLOTUREE','ANNULEE','REJETEE'].includes(d.statut)
  && peutAnnuler && permis(d, 'ANNULER') && ( <button … /> )}
{peutSupprimer && permis(d, 'SUPPRIMER') && ( <button … /> )}
// Archives : {peutRestaurer && permis(d, 'RESTAURER') && …} ; {peutPurger && permis(d, 'PURGER') && …}
```
Correspondance appliquée dans `AbsencesTable` (7 conditions) : SOUMETTRE, MARQUER_SIGNALEE,
DEMANDER_JUSTIFICATION, QUALIFIER, CLOTURER, ANNULER, SUPPRIMER ; `AbsencesArchivesTable` :
RESTAURER, PURGER.
[Rev 8] Depuis 1fee8425, l'utilitaire local `permis` d'`AbsencesTable` est remplacé par la
RÈGLE UNIQUE `modules/absences/utils/absenceActions.js`, partagée par le tableau et la fiche
de détail (§39) : un même document ne peut plus montrer des actions différentes selon la vue.

### Règles
```
✅ Un bouton d'action = permission PBAC && permis(d, ACTION)
   (+ règles d'affichage purement visuelles : statut, document généré)
✅ La décision reste sur d.peutDecider (moteur de workflow), pas sur actionsPermises
✅ Codes d'action = noms de l'enum du backend (jamais traduits, jamais construits)
✅ `=== true` : un champ absent (ancien backend, autre module pas encore branché) masque le
   bouton au lieu de l'afficher
✅ Absence d'un bouton alors que actionsPermises le contient = la permission PBAC manque au
   rôle (lire erp_role_permission) : ce n'est PAS un défaut de l'écran
❌ Déduire le droit côté React (d.employeId === user.employeId, rôle, statut seul)
❌ Afficher un bouton que le serveur refusera (le 403 motivé reste le filet, pas l'UX)
❌ Élargir une permission PBAC « pour faire apparaître un bouton »
Modules sans actionsPermises (Discipline, Missions, Formation) : noter l'écart en dette
jusqu'à leur branchement.
```

---

## 36. OUVRIR UN DOCUMENT — FICHE DE DÉTAIL (29/09/2026)

### Constat
Dans `AbsencesTable`, le numéro de la demande est un lien (`ouvrirDetail(d)`), mais
`AbsencesModales` ne rend AUCUNE modale de détail : `demandeDetail` est mémorisé par le hook
et jamais affiché. Le clic ne fait rien, pour tous les comptes. Ce n'était pas une régression
(prouvé : `grep demandeDetail` → uniquement dans le hook) mais une fonctionnalité jamais
construite, révélée par le test du valideur (qui doit pouvoir lire ce qu'il décide).

### Règles
```
✅ Tout élément cliquable (numéro, lien) ouvre quelque chose : sinon, pas de style de lien
✅ Fiche de détail d'un document soumis au workflow : pattern §27 (GET /{id}, fiche complète),
   lecture seule, avec : demandeur, type, dates, jours, motif, pièces, statut, circuit ;
   [Rev 6] et l'avertissement de solde (renvoyé par le serveur) ;
   boutons selon §35 et, pour le valideur, Valider / Rejeter (d.peutDecider)
✅ Ouvrable depuis la liste du module ET depuis « Mes tâches »
✅ Champs vides selon le lecteur affichés '—' (§32)
Livraison : temps 2 (b) de l'incrément 3bis (Absences) — PROCHAIN depuis le correctif (b0)
de §38 (b1f42b99) —, puis chaque module branché.
Vérifier l'existence d'un composant avant de conclure à une régression :
grep -rn "Detail" rh-frontend/src/modules/{module}
```

### Livré (1fee8425, Absences) [Rev 8]
```
AbsenceDetailModal : GET /absences/{id} (§27, ficheComplete), en-tête, SoldeCongeEncart,
  CircuitValidation (composant GÉNÉRIQUE de modules/workflow/components, réutilisable par
  tout module), boutons = règle unique (§39) ; rendue AVANT les ConfirmModal dans
  AbsencesModales (la confirmation s'ouvre par-dessus).
Ouvrable depuis « Mes tâches » par le lien du résumé (/absences?fiche=<id>, §42).
Missions : MissionsPage consomme ?fiche= ; la fiche Mission (MissionDetailModal) reste une
fenêtre maison hors pile et sans actionsPermises (incrément 5, dette 26).
```

---

## 37. CHECKLIST — COMPLÉMENTS REV 5 (et Rev 6, Rev 7)

[ ] 29. Boutons d'action sur `permission PBAC && permis(d, 'ACTION')` ;
        aucun droit sur un document calculé côté React
[ ] 30. Messages 400 / 403 du backend affichés tels quels (toast) ; 404 sans révéler
        l'existence
[ ] 31. Tout lien ouvre quelque chose ; fiche de détail des documents soumis au workflow
[ ] 32. Tests UI rejoués avec le valideur de rôle EMPLOYE (voit, ouvre, décide, ne peut rien
        faire d'autre)
[ ] 33. [Rev 6] Attendus des tests UI déduits des permissions réelles des rôles et des
        actionsPermises (jamais de tête)
[ ] 34. [Rev 6] Toute prop ou tout enfant passé à un composant partagé figure dans sa
        signature (§38)
[ ] 35. [Rev 7] Chaque `ConfirmModal` avec `avecMotif` : gestionnaire qui REÇOIT `(motif)` et
        le TRANSMET au service ; aucun second état de saisie dans le parent ; charge utile
        vérifiée en test UI (F12) et valeur contrôlée en base
[ ] 36. [Rev 7] Clé i18n devenue inutilisée retirée (fr et en) dans le même commit

---

## 38. COMPOSANT PARTAGÉ : LIRE SA SIGNATURE — CAS ConfirmModal (29/09/2026 soir, livré 30/09)

### Constat (test U7 du 29/09, prouvé par le code)
`shared/components/ConfirmModal.jsx` déclarait : `isOpen, onClose, onConfirm, title, message,
type, avecMotif, motifLabel, motifRequired, loading` — **pas `children`**. Tout ce que
`AbsencesModales` plaçait entre `<ConfirmModal>` et `</ConfirmModal>` n'était JAMAIS rendu :
```
- le commentaire facultatif (annuler, valider, signaler, clôturer) : invisible
- l'AVERTISSEMENT DE SOLDE (calculé par le serveur pour le valideur) : jamais affiché
- rejet depuis la page Absences : le motif saisi dans le champ de ConfirmModal était passé à
  onConfirm(motif), mais handleConfirmDecision l'ignorait et envoyait son état `commentaire`
  (vide) → 422 « commentaire obligatoire »
```
Aucune erreur, aucun avertissement : React ignore silencieusement une prop non lue.
Autre écart : `type="success"` (7 appelants, dont 6 modales de RESTAURATION) n'existait pas
dans les styles → repli silencieux sur `danger` (🗑️ rouge pour une restauration).
Parallèle Laravel : un composant Blade `<x-confirm>` dont la vue n'écrit jamais `{{ $slot }}`
avale en silence tout ce qu'on met entre ses balises.

### Inventaire (30/09, produit par script, pas par grep -A1)
```
Chaque balise lue jusqu'à sa VRAIE fin (accolades JSX et chaînes) ; signature et styles lus
dans la source du composant ; import sous un autre nom signalé.
42 ConfirmModal dans 20 fichiers ; 1 seul avec enfants (AbsencesModales, décision) ;
0 prop hors signature ; 6 type="success" + 3 types dynamiques.
21 avec avecMotif : gestionnaire de onConfirm résolu et ses paramètres lus →
2 ignoraient le motif : AbsencesModales.handleConfirmDecision() ET
usePostesList.supprimerPoste() (motif « obligatoire » à l'écran, perdu en route ; le serveur
enregistrait « Suppression manuelle » par défaut → perte SILENCIEUSE).
Piège : un gestionnaire résolu PAR NOM dans tout src remonte des homonymes d'autres fichiers
(EmployesModales, OrganisationPage...) → trier chaque signalement par la page qui passe la
prop ; un `onConfirm={onConfirm}` relayé (DisciplineModales) se suit jusqu'à l'appelant.
```

### Preuve AVANT correction (30/09)
```
API  : preuve_rejet_absence.py (hors dépôt) — afeudjo crée et soumet ; pnkouatchou valide
       l'étape 1 ; précondition : mtsafack a peutDecider = true (sinon ARRET, un 422 ne
       prouverait rien) ; requête EXACTE de l'écran {statut:"REJETE", commentaire:""} → 422
       + message ; donnée intacte ; contre-preuve AVEC commentaire → 200 → le serveur est
       juste, le défaut est dans l'écran. 12/12.
Écran: mtsafack, ✕ sur ABS-2026-00046, motif saisi → toast 422 ; F12 → Payload :
       {statut: "REJETE", commentaire: ""} ; base : EN_WORKFLOW, 0 décision REJETE.
```

### Correctif livré (b1f42b99, 30/09)
```
ConfirmModal : `children` dans la signature, rendu entre le message et le motif ;
               style `success` (vert, ✅) ; type inconnu → console.error (repli danger
               conservé ; alerte active aussi en production, voir §20)
AbsencesModales : état `commentaire` et <textarea> enfant SUPPRIMÉS ; le champ unique est
               celui de ConfirmModal (avecMotif = avecCommentaire || estQualification,
               motifLabel selon l'action, motifRequired = rejet) ; handleConfirmDecision(motif)
               transmet commentaire (et detailJustification pour une qualification — elle
               partait vide aussi) ; avertissement de solde et rappel ✅/❌ = enfants rendus
usePostesList : supprimerPoste(motif) → posteService.supprimer(id, motif)
i18n        : absences:form.commentaire_hint (placeholder du champ supprimé) retirée fr/en
```

### Preuve APRÈS correction (30/09)
```
U1 rejet par mtsafack : champ vide bloqué avant envoi ; saisie → 200, commentaire en base
U2 validation : modale verte, champ facultatif, « validation b0 » en base (ABS-2026-00050)
U3 restauration (Postes, Archives) : modale verte ✅
U4 suppression d'un poste : motif_suppression = 'motif b0 poste' (lu par to_jsonb)
Campagne de sécurité 44/44 ; vite build 0 ; check-i18n OK
```

### Règles
```
✅ Avant de passer une prop ou des enfants à un composant partagé : lire sa signature
✅ Un composant partagé qui accepte du contenu déclare `children` et le rend
✅ Une valeur saisie dans un composant enfant est transmise par son callback (onConfirm(valeur)),
   jamais doublée par un second état du parent
✅ UNE saisie = UN champ = UN état. Un gestionnaire branché sur un ConfirmModal avec
   avecMotif REÇOIT (motif) et le TRANSMET jusqu'au service
✅ Une valeur inconnue passée à un composant partagé (type) est SIGNALÉE, pas absorbée
✅ Défaut de transmission : prouver AVANT (requête exacte de l'écran, acteur désigné),
   contre-prouver (même requête valide), corriger, prouver APRÈS (payload + base)
✅ Un motif exigé par l'écran est exigé par le serveur (400 / 422), sans defaultValue qui
   masque sa perte (dette : RhPosteController.supprimer et autres DELETE avec motif)
❌ Deux champs pour la même saisie (état du parent + état interne du composant)
❌ Gestionnaire sans paramètre (`async () =>`) branché sur un onConfirm qui passe un motif
Symptômes typiques : un élément « prévu dans le code » n'apparaît jamais, pour personne ;
un 422 « obligatoire » alors que l'utilisateur a saisi ; une valeur par défaut du serveur en
base à la place de la saisie.
```

---

## 39. RÈGLE UNIQUE DES ACTIONS D'UN DOCUMENT (1fee8425, 30/09/2026)

Référence : `modules/absences/utils/absenceActions.js`, consommé par `AbsencesTable.jsx`
(icônes) et `AbsenceDetailModal.jsx` (boutons libellés).

### Principe
Ce qu'on peut faire sur un document est décidé à UN seul endroit du frontend ; chaque vue
(tableau, fiche) choisit seulement COMMENT l'afficher. Avant (b), le tableau portait ses
conditions et la fiche aurait dû les recopier : deux vues, deux règles, deux dérives
possibles. Parallèle Laravel : une Policy consultée par toutes les vues, au lieu d'un
`@if` recopié dans chaque Blade.

### Contrat
```javascript
// modules/{module}/utils/{module}Actions.js — fonctions PURES
export const permis     = (d, code) => d?.actionsPermises?.includes(code) === true  // §35
export const estGeneree = (d) => d?.origineType != null                             // §30

// droits = booléens PBAC du hook de liste { peutSoumettre, peutValider, peutAnnuler, … }
export function actionsDisponibles(d, droits) → [ descripteur, … ]   // ordre d'affichage
//   descripteur = { cle,        // clé React stable
//                   action,     // code du dispatch du hook (null pour la suppression)
//                   extra,      // données de la confirmation (ex : qualification)
//                   libelle,    // clé i18n COMPLÈTE
//                   variante,   // 'succes' | 'danger' | 'avertissement'
//                   icone,      // pictogramme du tableau
//                   suppression // true : confirmation à motif dédiée }

// Ouverture de la confirmation, partagée par toutes les vues
export function declencherAction(d, action, { setConfirmSuppr, setConfirmDecision })
```
Chaque action = règle d'affichage (statut, document généré) && PBAC && `permis(d, CODE)` ;
la décision (Valider / Rejeter) = `peutValider && d.peutDecider === true` (moteur).

### Utilisation (schéma)
```jsx
// Tableau : icône + style par variante
const actions = actionsDisponibles(d, droits)
{actions.map(action => (
  <button key={action.cle} className={STYLE_ICONE[action.variante]}
    onClick={() => declencherAction(d, action, { setConfirmSuppr, setConfirmDecision })}
    title={t(action.libelle)}>{action.icone}</button>
))}
// Fiche : mêmes descripteurs, calculés sur la FICHE COMPLÈTE (ficheComplete), bouton libellé
```

### Règles
```
✅ Un module branché sur le workflow a SON {module}Actions.js, sur ce modèle
✅ Les descripteurs portent des CLÉS i18n et des VARIANTES, jamais des classes CSS ni du texte
✅ La fiche calcule les actions sur la fiche complète (le résumé de liste peut être en retard)
✅ Les styles par variante vivent dans la vue, avec un repli neutre pour une variante
   inconnue (la fiche le fait : `STYLE_BOUTON[action.variante] ?? btnStyles.secondary`)
❌ Une condition d'action écrite directement dans un composant (tableau OU fiche)
❌ Une action dérivée côté React d'un statut seul ou d'une comparaison d'identifiants
```

---

## 40. MISE EN FORME SELON LA LANGUE (dates, nombres) — ÉTAT RÉEL ET CIBLE (05/10/2026)

### Constat (inventaire du 05/10, `grep` sur `rh-frontend/src`, comptes calculés)
TROIS mécanismes coexistent pour la même chose :

| Mécanisme | Utilisé par | Comportement |
|---|---|---|
| `useLocale().formaterDate / formaterDateHeure / formaterNombre / formaterMontant` (`context/LocaleContext.jsx`) | 22 fichiers : Contrats, Discipline, Employés, Missions, Postes, tableau de bord | locale RÉGIONALE de `localeConfig` (`fr-FR`, `en-GB`), `2-digit`, fuseau `Africa/Douala` fixé |
| `shared/utils/format.js` : `formatDate`, `formatDateHeure`, `formatNombre` (créé en (b), 1fee8425) | 7 fichiers : `AbsenceDetailModal`, `AbsenceForm`, `SoldeCongeEncart`, `CircuitValidation`, `TacheDetailModal`, `TachesTable`, `resume.js` | `toLocaleDateString(i18n.language)` : langue SANS région (`'fr'`, `'en'`) ; date `AAAA-MM-JJ` construite en date locale |
| Copies locales et `'fr-FR'` en dur | 9 définitions locales de `formatDate` (Absences, paramétrage des types, Formation, Audit) ; 20 lignes `'fr-FR'` dans 17 fichiers (Missions, Formation, Contrats, ConfigPostesAcces, Absences, Audit) | langue figée en français |

Incohérence PROUVÉE (05/10, Node, même date du 19/05/2026) :
```
format.js     en : 5/19/2026      ← 'en' = en-US : mois/jour
LocaleContext en : 19/05/2026     ← 'en-GB'      : jour/mois
format.js     fr : 19/05/2026
LocaleContext fr : 19/05/2026
```
En anglais, « Mes tâches » et la fiche d'absence affichent les dates dans un autre ordre que
Missions ou Contrats. Dans un même module, `AbsencesTable` (copie locale `'fr-FR'`) et
`AbsenceDetailModal` (`format.js`) ne suivent pas la même règle.
Autres constats : `OngletLiquidation.jsx` récupère `formaterDate` sans l'utiliser (code
mort) ; `LocaleContext.formaterDate` construit `new Date('AAAA-MM-JJ')` (minuit UTC), juste
seulement parce que le fuseau configuré est ≥ UTC.

Cause : `format.js` a été écrit en (b) SANS inventaire de l'existant (le mécanisme dominant
existait déjà). Une règle transverse s'écrit APRÈS l'inventaire calculé de ce qui fait déjà
la même chose (`grep` des noms de fonctions, des appels `toLocale*` / `Intl.*`, des locales
en dur).

### Cible retenue : option F-a (05/10) — dette 27, correctif séparé
```
UNE règle pure, DEUX portes d'entrée :
- config/locales.js        : localeConfig (dateLocale, numberLocale, timeZone, formats,
                             devise) sorti de LocaleContext — source UNIQUE de la configuration
- shared/utils/format.js   : SEULE mise en forme ; fonctions pures (valeur, langue) qui lisent
                             la configuration de la langue (en → en-GB, fr → fr-FR) ;
                             AAAA-MM-JJ = date locale ; vide ou invalide → '—'
- useLocale().formaterX    : DÉLÈGUE à format.js avec la langue courante (les 22 fichiers
                             appelants ne changent pas)
- fonctions pures (resume.js) et tests Node : appellent format.js avec la langue
- les 9 copies locales et les 20 lignes 'fr-FR' : migrées ; code mort retiré
Écartées : F-b (tout par useLocale : une fonction pure comme resume.js ne peut pas appeler
un hook) ; F-c (documenter deux règles pour la même chose).
Preuve AVANT du correctif : la comparaison Node ci-dessus ; preuve APRÈS : mêmes sorties
pour les deux portes, en fr et en en, + test Node de format.js.
```

### Règles (dès maintenant, avant le correctif)
```
✅ Composant React : useLocale().formaterDate / formaterNombre (porte d'entrée composant)
✅ Fonction pure : format.js avec la langue passée en paramètre (i18n.language)
✅ Valeur vide ou invalide : '—'
✅ Une date seule AAAA-MM-JJ (LocalDate) se construit en date LOCALE, jamais new Date(texte)
❌ 'fr-FR' (ou toute locale) écrite en dur dans un composant ; toLocale*() / Intl.* direct
❌ Une nouvelle copie locale de formatDate
❌ Un nouvel utilitaire transverse sans inventaire calculé de l'existant
```

---

## 41. PILE DE FENÊTRES — ÉCHAP ET DÉFILEMENT (ebec0a1b, 01/10/2026)

### Constat corrigé
Chaque fenêtre écoutait Échap sur tout le `document` et se fermait sans savoir si elle était
au premier plan : la fiche se fermait SOUS sa confirmation. Chaque `Modal` rendait le
défilement de la page en se fermant, même si une autre fenêtre restait ouverte.

### Mécanisme
```javascript
// shared/utils/pileFenetres.js — règle PURE, effets globaux INJECTÉS (testable par Node)
const pile = creerPileFenetres({ quandNonVide, quandVide })
pile.ouvrir(onEchap) → jeton   // inscrit au sommet ; ordre d'inscription = ordre visuel
pile.fermer(jeton)    → bool   // désinscrit, où qu'elle soit dans la pile
pile.echap()          → bool   // Échap à la SEULE fenêtre du sommet (même si elle l'ignore)

// hooks/useFenetreEmpilee.js — singleton branché au DOM
//   un seul écouteur keydown (posé à la 1re inscription, retiré à la dernière) ;
//   overflow du body bloqué puis RESTAURÉ à sa valeur d'origine ; isComposing ignoré
useFenetreEmpilee(isOpen, onClose)     // AVANT tout `return null` du composant
```
`Modal` : Échap = `onClose`. `ConfirmModal` : Échap = « Annuler », ignoré pendant `loading`
(comme le bouton désactivé).

### Règles
```
✅ Toute fenêtre passe par Modal ou ConfirmModal (donc par la pile)
✅ L'inscription ne dépend QUE de l'état d'ouverture ; le callback est lu dans un useRef au
   moment de la touche (un onClose recréé à chaque rendu ne fait pas remonter la fenêtre au
   sommet) — vaut pour tout hook d'inscription globale
✅ Échap ne traverse jamais vers la fenêtre du dessous
✅ Une règle d'interface qui dépend d'un état global s'écrit en module PUR + hook de
   branchement ; le module pur a son test Node (/tmp/test_pile.mjs : 10 OK, à pérenniser)
❌ document.addEventListener('keydown', …) ou document.body.style.overflow dans un composant
❌ Fenêtre « maison » (div fixed inset-0) : hors pile — 7 fichiers restants (dette 19,
   MissionDetailModal à l'incrément 5)
```
Parallèle Laravel : un singleton du conteneur auquel chaque fenêtre s'enregistre, au lieu
que chacune s'abonne seule à l'événement global.

---

## 42. OUVRIR UNE FICHE PAR L'URL — `?fiche=<id>` (eee5170e, 02/10/2026)

### Mécanisme
```javascript
// src/hooks/useFicheDepuisUrl.js — dans la PAGE du module, une ligne :
useFicheDepuisUrl(liste.ouvrirDetail)
// ?fiche=<entier positif> → ouvrir({ id }) une seule fois, puis paramètre RETIRÉ (replace) :
//   Retour ramène à la page précédente ; F5 ne rouvre pas la fiche
// valeur invalide → paramètre retiré, aucune fiche
// ouvrir lu dans un useRef ; valeur déjà traitée mémorisée (StrictMode), oubliée quand le
// paramètre disparaît (un nouveau lien vers la même fiche la rouvre)
```
La fiche charge elle-même le document par son id (§27) : c'est la RLS du lecteur qui décide
de ce qu'il voit (invisible = erreur de chargement dans la fiche, jamais « il existe mais »).
En place : `AbsencesPage`, `MissionsPage`. La route vient du SERVEUR (`resume.route`, fournie
par le résumeur du module) : « Mes tâches » ne connaît aucune route de module.
Parallèle Laravel : `$request->query('fiche')` lu par la page, puis `redirect()` sans le
paramètre.

### Règles
```
✅ Un module branché sur le workflow appelle useFicheDepuisUrl dans sa page, avec la MÊME
   fonction que le clic sur une ligne
✅ Paramètre consommé puis retiré (replace), jamais laissé dans l'historique
❌ Lire ?fiche dans un composant de fiche, ou construire la route du module côté workflow
```

---

## 43. LIGNES DE RÉSUMÉ VENUES DU SERVEUR (eee5170e, 02/10/2026)

### Contrat (STANDARDS_BACKEND §50)
```javascript
// tache.resume = WfResumeDocument | null (type sans résumeur : résumé minimal)
{ numero: 'ABS-2026-00049',
  route:  '/absences?fiche=49',
  lignes: [ { cle: 'absences:resume.du', valeur: '2026-05-19', format: 'DATE',  alerte: false },
            { cle: 'absences:resume.solde_disponible_apres', valeur: '-3', format: 'JOURS',
              alerte: true } ] }
// valeurs CANONIQUES : DATE 'AAAA-MM-JJ' ; NOMBRE / JOURS stripTrailingZeros ('9.5', '-3')
```

### Affichage
```javascript
// shared/utils/resume.js — fonction pure
valeurLigne(ligne, langue, t)
//   DATE   → formatDate ; NOMBRE → formatNombre ; JOURS → t('workflow:resume.unite_jours',
//   { nombre }) ; TEXTE → tel quel ; vide → '—' ; format inconnu → valeur brute

// modules/workflow/components/ResumeDocument.jsx — affichage pur
<ResumeDocument resume={tache.resume} variante="liste" />   // cellule compacte
<ResumeDocument resume={fiche.resume} variante="detail" />  // grille de la fiche
//   libellé = t(ligne.cle) ; alerte = ligne.alerte (ambre + ⚠), JAMAIS recalculée
//   aucune ligne → « résumé indisponible »
```

### Règles
```
✅ Un nouveau module n'a RIEN à modifier côté frontend du workflow : il fournit un résumeur
   (serveur) et ses clés i18n (fr + en) dans son namespace
✅ Le numéro et le lien (resume.route) sont placés par l'appelant, pas par ResumeDocument
✅ Liste : lignes légères ; détail : lignes dérivées coûteuses (solde) — décidé par le serveur
✅ Clés citées par les résumeurs Java contrôlées contre fr / en (§45)
❌ Mettre en forme une valeur selon la CLÉ (« si c'est une date… ») : le format est porté par
   la ligne
❌ Recalculer une alerte côté React (solde insuffisant…)
```
Parallèle Laravel : un cast générique dont le type est porté par la donnée.

---

## 44. « MES TÂCHES » — FICHE DE LA TÂCHE ET DÉCISION (eee5170e, 02/10/2026)

Référence : `WorkflowPage.jsx` (orchestrateur pur, aucun `useEffect`),
`hooks/useWorkflowTaches.js` v3, `TachesTable.jsx`, `TacheDetailModal.jsx`.

### Déroulé
```
Liste (TachesTable, mode 'taches') : type, numéro + lien (resume.route), demandeur, résumé
  LÉGER, étape n / N + libellé, date de soumission ; filtre par type PRÉSENT dans les tâches
  chargées (options déduites de la liste, libellé workflow-modeles:types_document.<CODE>)
  → clic : ouvrirTache(tache)
Fiche (TacheDetailModal) : GET /rh/workflow/taches/{instanceId} (useApi paresseux)
  ficheComplete = detail?.instanceId === instanceId ? detail : null   // §27
  en-tête (moteur) + résumé DÉTAILLÉ (module : solde…) + CircuitValidation
  Valider / Rejeter rendus SEULEMENT sur la fiche complète (on décide sur ce qu'on voit)
  → setConfirmDecision({ statut: 'VALIDE' | 'REJETE', tache: ficheComplete })
Confirmation (WorkflowPage) : {decision && <ConfirmModal isOpen …/>} rendue APRÈS la fiche
  (par-dessus), MONTÉE À LA DEMANDE (saisie vide à chaque décision, sans dépendre d'une
  remise à zéro) ; avecMotif ; motifRequired au rejet ; type danger / success
  → deciderTache(motif) : POST /instances/{instanceId}/decider
    { statut, commentaire: motif.trim() || null } ; UN toast ; fiche et confirmation fermées ;
    refetch du groupe (tâches, demandes, compteur d'alertes)
Mes demandes (mode 'demandes') : lecture seule, lien vers la fiche du module
404 (tâche invisible ou déjà décidée) : « erreur de chargement » dans la fiche
```

### Règles
```
✅ Un groupe useApiMultiple pour les données qui doivent rester cohérentes : un seul refetch
✅ Boutons de décision rendus sur la fiche complète, jamais sur la ligne de liste
✅ ConfirmModal à saisie : montée à la demande ({x && <ConfirmModal isOpen …/>}) — évite la
   question du motif conservé d'une ouverture à l'autre (dette 20, non prouvée, pour les
   ConfirmModal montées fermées)
✅ Un seul toast par action (succès OU erreur), émis par le hook
✅ Aucun code propre à un module dans WorkflowPage, TachesTable, TacheDetailModal, ResumeDocument
❌ Bouton « Déléguer » dans la décision : retiré jusqu'au chantier Délégations
```

---

## 45. I18N CONTRÔLÉE CONTRE LA SOURCE (30/09 – 02/10/2026)

### Principe
Une traduction qui reflète une donnée du SERVEUR (valeur d'enum, clé de résumé, code de type)
se contrôle contre la source Java, par script : jamais recopiée de mémoire.

### Contrôles (scripts hors dépôt, dossier tests)
```
controle_enums_absences.py      valeurs des enums Absences ↔ clés fr / en
controle_enums_workflow.py      valeurs des enums Workflow ↔ clés fr / en
controle_cles_resume.py         clés citées par les résumeurs Java ↔ fr / en ;
                                types_document ↔ WfTypeDocument ; contre-preuve → 19 OK
controle_cles_i18n.py <f.jsx>   clés citées par un composant ↔ JSON
node check-i18n.cjs             clés manquantes des .jsx (pas des .js : §14)
```
Chaîne avant tout build frontend : les cinq codes à 0 (enums absences, enums workflow,
résumé, `npx vite build`, `check-i18n`).

### Règles
```
✅ Chaque contrôle a sa CONTRE-PREUVE (une clé retirée exprès doit le faire échouer)
✅ Clés dynamiques (préfixe + code) : contrôlées par la liste des codes de la source, la regex
   des clés ne doit pas capturer le préfixe seul
❌ Valeur d'enum recopiée de mémoire dans fr / en
Dette : intégrer ces contrôles dans la chaîne de build du dépôt (dette 11) ; détecter les clés
inutilisées et celles des .js (dette 14).
```

---

## 46. CHECKLIST — COMPLÉMENTS REV 8

[ ] 37. Actions d'un document par la règle unique `{module}Actions.js` (tableau ET fiche)
[ ] 38. Dates et nombres par `useLocale()` (composant) ou `format.js` (fonction pure) ;
        aucune locale en dur, aucune copie locale (§40 ; dette 27 en cours)
[ ] 39. Fenêtres par `Modal` / `ConfirmModal` (pile, §41) ; aucun écouteur Échap ni overflow
        dans un composant
[ ] 40. Module branché sur le workflow : `useFicheDepuisUrl` dans sa page, résumeur côté
        serveur, clés `resume.*` en fr et en
[ ] 41. Décision : boutons sur la fiche complète ; `ConfirmModal` montée à la demande ;
        commentaire vide = `null` ; un toast
[ ] 42. Preuve que le nouveau code est servi : chaîne cherchée dans TOUS les chunks
[ ] 43. Contrôles i18n contre la source à 0 (§45) ; clés citées dans un `.js` vérifiées
[ ] 44. Nouvel utilitaire transverse : inventaire calculé de l'existant AVANT de l'écrire
[ ] 45. Hook d'inscription globale : dépend du seul état d'ouverture, callback par `useRef`
