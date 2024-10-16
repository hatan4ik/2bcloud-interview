FROM node:18

WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies only if package.json exists
RUN if [ -f package.json ]; then npm install; fi

# Copy the rest of the application code
COPY . .

EXPOSE 3000

CMD ["node", "index.js"]