FROM node:22-alpine AS build

WORKDIR /app

COPY dashboard/package.json dashboard/package-lock.json ./
RUN npm ci

COPY dashboard/ ./
RUN npm run build

FROM node:22-alpine AS runtime

WORKDIR /app

COPY dashboard/package.json dashboard/package-lock.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist

ENV PORT=5173
EXPOSE 5173

CMD ["npm", "run", "start"]
