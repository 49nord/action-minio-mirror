FROM minio/mc:latest

ENTRYPOINT [ "/entrypoint.sh" ]

FROM alpine:latest

RUN apk add --no-cache bash
COPY --from=0  /usr/bin/mc /usr/bin/mc
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/entrypoint.sh"]