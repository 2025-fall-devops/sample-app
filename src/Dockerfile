FROM node:21.7

WORKDIR /home/node/app

COPY *.json .

COPY *.js .

RUN npm ci --only=production

EXPOSE 8080

USER node

CMD ["npm", "start"]