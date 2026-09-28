FROM alpine:3.24.2

RUN apk add --no-cache \
    bash \
    iputils \
    mariadb-client \
    tzdata

ENV TZ=Europe/Berlin

WORKDIR /app

COPY netwatch.sh .
COPY targets.conf .

RUN chmod +x netwatch.sh

CMD ["./netwatch.sh"]
