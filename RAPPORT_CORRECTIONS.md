# Rapport de corrections — Les Gourmands Paris

Audit réalisé sur `index.html` (site mono-fichier) le 25 octobre 2026.
Méthode : analyse statique (HTML/CSS/JS), puis tests d'exécution réels
(jsdom/Node) reproduisant chaque bug avant correction, et re-testés après :
**30 tests de régression, 30 réussis, aucune erreur JS au chargement.**

---

## 🔴 Erreurs critiques corrigées

### 1. Crash complet du site si le panier stocké contient un plat inconnu
`renderCart()` faisait `MENU.find(...).price` sans vérifier le résultat.
Si le `localStorage` contenait un identifiant de plat supprimé/renommé (ou
des données corrompues), le script plantait au chargement (`TypeError`) —
et comme `renderCart()` est appelé *avant* l'enregistrement des écouteurs
(menu mobile, connexion admin, planning…), **tout le reste du site mourait
avec lui**.
→ Ajout de `dishById()` / `cleanCart()` / `cartTotal()` : le panier est
assaini au chargement, les entrées invalides sont ignorées, plus aucun
accès `.find(...).propriété` non protégé. `getData()` garantit aussi de
toujours renvoyer un tableau et `saveData()` n'échoue plus bruyamment si
le `localStorage` est indisponible (mode privé, quota…).

### 2. Réservation impossible pour tout nouveau visiteur
Aucune table n'existait tant que l'admin n'en avait pas ajouté *dans le
même navigateur* : le formulaire répondait systématiquement « Aucune table
disponible ».
→ Au premier affichage, un **planning de démonstration de 14 jours**
(tables de 2, 4, 4, 6 et 10 places par service) est pré-rempli, une seule
fois (clé `lg_tables_seeded_v1` ; un planning vidé volontairement par
l'admin n'est pas réinjecté). Mention ajoutée dans l'aide de l'admin.
⚠️ Cela reste une démo locale : voir « limites connues » ci-dessous.

### 3. Faille XSS stockée dans l'espace restaurant
Le prénom, le nom, l'adresse, le téléphone et la note des commandes (ainsi
que les champs de réservation) étaient injectés tels quels dans
`innerHTML` côté admin : un nom comme `<img src=x onerror=…>` exécutait du
code dans le navigateur du restaurateur.
→ Ajout d'une fonction `esc()` appliquée à **toutes** les données
utilisateur affichées (commandes, réservations, planning, carte, panier),
et validation du format des identifiants/date/heure avant insertion dans
les attributs `onclick`.

### 4. L'assistant de planning créait n'importe quoi
Exemples reproduits avant correction :
- « Ajoute une table de 4 personnes demain à 20h » → créait **4 tables** ;
- « … le 25/12/26 » → tables créées le **25 décembre 1926** ;
- « … le 3 mai » → la date était ignorée (tables créées *aujourd'hui*) ;
- « … à 18h » → créneau créé alors qu'**aucune réservation n'est possible
  à 18h00** (absent de la liste des services) ;
- « … à 23h50 » → horaire invalide **24:00** ;
- « Ajoute 2 tables demain à 20h » (sans nombre de places) → refusé.
→ Analyseur entièrement réécrit : extraction ciblée tables/places
(chiffres **ou** toutes lettres : « deux tables de six »), défaut 4 places
(signalé), dates `jj/mm/aa` → 20aa, mois en lettres (« 3 mai » → mai
prochain si passé), dates invalides rejetées (31/02), « midi », « 8h du
soir », horaires validés contre la liste des services réservables
(`SERVICE_TIMES`), créneaux passés refusés, messages d'erreur explicites,
touche **Entrée** fonctionnelle dans le champ de l'assistant.

### 5. On pouvait réserver un créneau déjà passé
Aujourd'hui à 12h00 alors qu'il est 15h → « Bonne nouvelle… ».
→ `isPastSlot()` vérifié dans le contrôle de disponibilité, à l'envoi de
la réservation, dans le formulaire de tables admin et dans l'assistant.

### 6. « Retirer un créneau » supprimait aussi les tables déjà réservées
La réservation restait « Confirmée » avec une table fantôme.
→ Seules les tables **libres** sont retirées ; message adapté si tout est
réservé. De plus, l'annulation d'une réservation demande confirmation, le
badge « Annulée » passe en orange (il restait vert) et le bouton
« Annuler » disparaît une fois annulée.

## 🟠 Erreurs fonctionnelles / UX corrigées

- **Date de réservation effacée** après un envoi réussi (`form.reset()`
  vidait le champ date) → date du jour restaurée.
- **Page défilante derrière les fenêtres** de commande/confirmation
  (`overflow` non bloqué) → blocage cohérent à l'ouverture/fermeture.
- **Touche Échap** : ferme maintenant le panier et les modales.
- **Toast** « ajouté au panier » disparaissait trop tôt lors d'ajouts
  rapides (minuteurs non annulés) → `clearTimeout` ; texte qui ne déborde
  plus sur petit écran (`max-width`, retour à la ligne).
- **Tiroir panier accessible au clavier alors qu'il est fermé**
  (juste translaté hors écran) → `visibility:hidden` + `aria-hidden`.
- **Ancres masquées sous l'en-tête fixe** → `scroll-margin-top`.
- **Galerie mobile** : la 3e rangée d'images n'avait pas de hauteur
  définie → `grid-auto-rows:175px`.
- **Prix de la carte** affichés « 27 € » au lieu du format français
  « 27,00 € » (incohérent avec le panier) → formatage `euro()` partout.
- **Téléphones acceptés avec n'importe quel texte** → `pattern`
  (chiffres, espaces, `+`, parenthèses ; échappements compatibles avec le
  mode regex `v` des navigateurs récents), `inputmode="tel"`,
  `autocomplete="tel"` manquant ajouté.
- **Pluriel** : « 0 libre » → « 0 libres ».
- **Planning admin** : les créneaux passés encombraient la liste →
  affichage à partir d'aujourd'hui (le filtre par date reste possible) ;
  compteur « Tables planifiées » limité aux créneaux à venir.
- **Faute dans la carte** : « La tarte **Tintin** » → « La tarte **Tatin** ».

## 🟡 HTML, accessibilité, SEO, performance

- 9 `<label>` sans attribut `for` (commande + admin) → associés à leur champ.
- Boutons sans `type` (défaut `submit`, source d'envois accidentels) →
  `type="button"` sur tous les boutons non-soumettants, y compris ceux
  générés en JS.
- Menu mobile : `aria-controls` / `aria-expanded` ; onglets carte :
  `aria-pressed` ; modales : `role="dialog"` / `aria-modal` ; contour de
  focus clavier visible (`:focus-visible`) ; focus automatique sur le
  premier champ de la modale commande.
- `&` non échappés dans le texte et les URL → `&amp;` (HTML valide).
- Ajout d'une **meta description** (SEO) et d'un **favicon** (avant :
  erreur 404 sur `/favicon.ico` à chaque visite).
- Polices Google Fonts chargées via `<link rel="preconnect">` +
  `<link rel="stylesheet">` au lieu de `@import` dans le CSS (chargement
  bloquant en cascade).
- Images sous la ligne de flottaison : `loading="lazy"`, `decoding="async"`,
  dimensions `width`/`height` (limite les sauts de mise en page).
- Cadre décoratif de la photo « La maison » (`z-index:-1` pouvant passer
  derrière le fond) → `isolation:isolate`.

---

## ⚠️ Limites connues (non corrigeables dans un fichier statique)

Ces points étaient déjà signalés comme « prototype » dans l'interface ;
ils restent **à traiter avant une vraie mise en ligne** :

1. **Données en `localStorage`** : commandes, réservations et planning
   vivent dans le navigateur du visiteur. Un client et le restaurant ne
   partagent donc pas les mêmes données. Il faut un serveur/base de
   données (le planning de démonstration pré-rempli ne fait que rendre la
   démo testable).
2. **Mot de passe admin en clair dans le code source** (visible par
   quiconque affiche la source de la page). L'authentification doit être
   faite côté serveur ; aucune rustine côté navigateur (hachage compris)
   ne sécuriserait réellement l'espace restaurant — le tableau de bord
   entier est de toute façon présent dans la page.
3. **Paiement Stripe non connecté** : la commande reste une « demande » en
   mode démonstration (déjà indiqué dans l'interface).
4. **Code mort** laissé en place pour limiter les risques : classes CSS
   `.brand-mark`, `.brand-name`, `.serif` (remplacées par les logos image).
   La photo burrata est aussi utilisée deux fois (section Maison + galerie).
5. Maintenance : la liste des horaires de service existe dans le HTML
   (deux `<select>`) et dans la constante JS `SERVICE_TIMES`. Si vous
   changez les horaires, mettez les trois à jour ensemble.

## Fichiers

- `index.html` : version corrigée (+ images à la racine du dépôt).
- `les-gourmands-paris.zip` : régénéré avec les fichiers corrigés
  (même contenu que l'archive d'origine).
