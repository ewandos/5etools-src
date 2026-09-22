# syntax=docker/dockerfile:1
# Eigenes Dockerfile (eigener Pfad => keine Merge-Konflikte mit dem Upstream-Dockerfile)

# ---------- Build-Stage: Service Worker bauen ----------
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Service Worker muss nach jeder Code-Änderung neu gebaut werden
RUN npm run build:sw:prod \
 && rm -rf node_modules data img

# ---------- Runtime: nginx ----------
FROM nginx:alpine

# Layer 1: Content (groß, ändert sich nur bei Upstream-Updates)
# -> bleibt bei reinen Code-Änderungen gecacht, das NAS lädt ihn nicht neu
COPY data/ /usr/share/nginx/html/data/

# Layer 2: Code + gebauter Service Worker (klein, ändert sich bei deinen Features)
COPY --from=build /app/ /usr/share/nginx/html/

# Bilder kommen NICHT ins Image, sondern als Volume nach /usr/share/nginx/html/img
EXPOSE 80
