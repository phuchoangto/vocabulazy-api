# syntax=docker/dockerfile:1
ARG NODE_VERSION=20
ARG PORT=3000
ARG DEBUG=false

######################
# Development Stage
######################

FROM node:${NODE_VERSION}-alpine as development

# Set working directory
WORKDIR /app

# Install all dependencies (including devDependencies)
COPY --chown=node:node package.json package-lock.json ./
RUN npm ci

# Copy the application source code
COPY --chown=node:node . .

# Set non-root user
USER node

# Expose the port that the application listens on
EXPOSE ${PORT}

# Start the development server
RUN if [ "${DEBUG}" = "true" ]; then npm run start:debug; else npm run start:dev; fi

######################
# Build Stage
######################

FROM node:${NODE_VERSION}-alpine as build

# Set working directory
WORKDIR /app

# Install production dependencies
COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --only=production

# Copy the application source code
COPY --chown=node:node . .

# Set non-root user
USER node

# Build the application
RUN npm run build

######################
# Production Stage
######################

FROM node:${NODE_VERSION}-alpine as production

# Set working directory
WORKDIR /app

# Copy built application and dependencies
COPY --chown=node:node --from=build /app/dist ./dist
COPY --chown=node:node --from=build /app/node_modules ./node_modules

# Set non-root user
USER node

# Expose the port that the application listens on
EXPOSE ${PORT}

# Start the application
CMD ["node", "dist/main"]