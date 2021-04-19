FROM alpine

USER root
RUN apk add bash skopeo
COPY ./run-skopeo.sh /
ENTRYPOINT [ "/run-skopeo.sh"]
