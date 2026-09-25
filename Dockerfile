# ---- build stage: install production dependencies only ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
 
# ---- runtime stage: minimal, patched, non-root ----
FROM node:22-alpine
RUN apk upgrade --no-cache \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx /opt/yarn* /usr/local/bin/yarn*
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY app.js package.json ./
USER node
EXPOSE 8080
CMD ["node", "app.js"]

