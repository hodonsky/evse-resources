FROM node:22.13.1 AS builder

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

COPY ./ /usr/src/app

RUN npm i && npm run build

FROM node:22.13.1

ARG EXPOSE_PORT
ENV NODE_ENV=local

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app /usr/src/app

EXPOSE ${EXPOSE_PORT}

CMD sleep 100 && npm start