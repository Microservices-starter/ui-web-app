FROM node:12
WORKDIR /app
COPY . .
RUN npm install -g npm@latest
RUN npm install 
EXPOSE 8080
CMD ["npm","start"]