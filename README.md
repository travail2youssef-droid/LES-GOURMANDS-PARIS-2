# Les Gourmands Paris — site vitrine

Site **statique** : un seul fichier `index.html` (HTML/CSS/JS intégrés) + les
images à la racine du dépôt. Aucun build, aucun serveur requis.

- Rapport d'audit et corrections : [`RAPPORT_CORRECTIONS.md`](./RAPPORT_CORRECTIONS.md)
- Archive d'origine (régénérée avec la version corrigée) : `les-gourmands-paris.zip`

## Tester en local

Ouvrir `index.html` dans un navigateur, ou :

```bash
python3 -m http.server 8000
# puis ouvrir http://localhost:8000
```

## Déployer sur Render

> ⚠️ **Prérequis indispensable** : la branche déployée doit contenir
> `index.html` à la racine. À ce jour, `main` ne contient que le ZIP :
> **merger d'abord la pull request** qui apporte les fichiers du site
> (ou choisir la branche de cette PR dans les réglages Render).

### Méthode 1 — Blueprint (automatique, recommandée)

Le fichier [`render.yaml`](./render.yaml) à la racine configure tout :

1. Render → **New +** → **Blueprint**
2. Connecter ce dépôt GitHub → Render détecte `render.yaml`
3. **Apply** : le site statique est créé et déployé.

### Méthode 2 — Static Site (manuel)

1. Render → **New +** → **Static Site** (⚠️ **pas** « Web Service »)
2. Connecter ce dépôt, branche **`main`** (après merge de la PR)
3. **Build Command** : laisser **vide**
4. **Publish Directory** : `.` (un simple point)
5. **Create Static Site**

## Erreurs fréquentes

| Symptôme                                      | Cause                                           | Solution                                     |
|-----------------------------------------------|-------------------------------------------------|----------------------------------------------|
| Déploiement en échec / page 404               | Branche `main` sans `index.html` (que le ZIP)   | Merger la PR, ou déployer la branche de la PR |
| « Build failed », cherche une commande start  | Service créé en **Web Service** au lieu de Static Site | Supprimer le service, recréer en **Static Site** |
| Échec du build (`npm run build` introuvable…) | Build Command pré-remplie à tort                | Vider le champ **Build Command**             |
| 404 alors que le déploiement « réussit »      | Publish Directory = `dist`, `build`, `public`…  | Mettre **`.`**                               |
| Images cassées                                | Publish Directory pointant sur un sous-dossier  | Mettre **`.`** (les images sont à la racine) |
