FROM mhart/alpine-node:10
MAINTAINER Pablo "support@hashingsystems.com"

COPY index.js package.json /tmp/
WORKDIR /tmp/
RUN yarn install
CMD node index.js $ARG0 $ARG1 $ARG2 $ARG3