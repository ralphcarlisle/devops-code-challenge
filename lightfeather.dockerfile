FROM node:14-alpine
RUN mkdir -p /home/node/app
RUN chown -R node:node /home/node/app

WORKDIR /home/node/app
COPY --chown=node:node ./ ./
USER node
COPY --chown=node:node . .
EXPOSE 8080
EXPOSE 3000
WORKDIR /home/node/app/
CMD ["sh", "run_lightfeather.sh"]