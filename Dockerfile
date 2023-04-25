FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY docker/start.sh /app/start.sh
COPY example-service /app/example-service
COPY services.sh /app/services.sh
COPY test.sh /app/test.sh

RUN bash services.sh || true

CMD ./start.sh
