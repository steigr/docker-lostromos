FROM quay.io/steigr/upx:v3.94 AS upx

FROM docker.io/library/golang:1.10.0-stretch AS lostromos-builder
COPY --from=upx /bin/upx /bin/upx

RUN  export CGO_ENABLED=0 \
            GOOS=linux \
            GOARCH=amd64 \
 &&  go get -v -d github.com/wpengine/lostromos \
 &&  cd /go/src/github.com/wpengine/lostromos \
 &&  sed -i 's|SetConfigName("lostromos\.yaml|SetConfigName("lostromos|' cmd/cmd.go \
 &&  make build \
 &&  install -m 0755 lostromos /go/bin/lostromos

ARG  UPX_ARGS="-9 --best --brute --ultra-brute" 
RUN  upx ${UPX_ARGS} /go/bin/lostromos

FROM docker.io/library/alpine:3.7 AS lostromos
RUN adduser -D lostromos
USER lostromos
COPY --from=lostromos-builder /go/bin/lostromos /usr/bin/lostromos
ENTRYPOINT ["lostromos"]
CMD ["start"]

ONBUILD COPY config.yaml /etc/lostromos.yaml
ONBUILD COPY chart /chart
