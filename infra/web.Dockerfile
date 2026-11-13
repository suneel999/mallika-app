# Builds the reception desk and puts it inside the Caddy image.
# The build context is ../admin (see docker-compose.yml).

FROM node:22-alpine AS desk
WORKDIR /desk
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# The desk is served from the same name as the API, so a path is enough.
ENV VITE_API_BASE_URL=/api/v1
RUN npm run build

FROM caddy:2-alpine
COPY --from=desk /desk/dist /srv/desk
