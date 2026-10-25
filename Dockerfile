# Site statique servi par Nginx — utilisé si le service Render est de type
# "Web Service" avec l'environnement Docker.
# (Pour un service "Static Site", ce fichier est simplement ignoré.)
FROM nginx:stable-alpine

# Render impose le port d'écoute via la variable PORT (10000 par défaut).
ENV PORT=10000

# L'image Nginx officielle remplace automatiquement ${PORT} dans les
# fichiers *.template au démarrage (envsubst).
COPY docker/default.conf.template /etc/nginx/templates/default.conf.template

# Fichiers du site (page + images), à la racine du dépôt.
COPY index.html /usr/share/nginx/html/
COPY *.jpg *.png /usr/share/nginx/html/

EXPOSE 10000
