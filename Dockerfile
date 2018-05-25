FROM docker.io/library/golang:1.10.2-alpine AS lostromos-builder	
# install dependencies
RUN  apk add --no-cache curl upx git make tar
ENV  CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN  go get -v github.com/golang/dep/cmd/dep
WORKDIR /go/src/github.com/wpengine/lostromos
RUN  curl -sL https://github.com/wpengine/lostromos/archive/v1.2.0.tar.gz | tar -x -z --strip-components=1
RUN  PATH=$PATH:/go/bin dep ensure -v
# build
RUN  make build
RUN  install -m 0755 lostromos /go/bin/lostromos

# compress
ARG  UPX_ARGS="-9 --best --brute --ultra-brute" 
RUN  upx ${UPX_ARGS} /go/bin/lostromos

# the final image
FROM docker.io/library/alpine:3.7 AS lostromos
RUN adduser -D lostromos
USER lostromos
COPY --from=lostromos-builder /go/bin/lostromos /usr/bin/lostromos
ENTRYPOINT ["lostromos"]
CMD ["start"]

ONBUILD COPY config.yaml /etc/lostromos.yaml
ONBUILD COPY chart /chart
