# --- Builder Stage ---
FROM node:16.17.0-alpine AS builder

WORKDIR /app

# Set faster DNS and configure Yarn registry
RUN npm config set registry https://registry.npmjs.org/ \
 && yarn config set registry https://registry.npmjs.org/

# Install dependencies first to leverage caching
COPY package.json yarn.lock ./
RUN yarn install --network-timeout 600000

# Copy remaining source code
COPY . .

# Inject API keys at runtime (avoid secrets during build)
ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

RUN yarn build

# --- Final Stage ---
FROM nginx:stable-alpine

WORKDIR /usr/share/nginx/html

# Clean default static content
RUN rm -rf ./*

# Copy built files from builder
COPY --from=builder /app/dist .

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
