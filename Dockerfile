FROM docker.io/library/golang:1.10.0-stretch AS kubectl-builder
RUN  export DEBIAN_FRONTEND=noninteractive \
 &&  curl -Lo /root/libucl.deb http://ftp.de.debian.org/debian/pool/main/u/ucl/libucl1_1.03+repack-4_amd64.deb \
 &&  curl -Lo /root/upx.deb http://ftp.de.debian.org/debian/pool/main/u/upx-ucl/upx-ucl_3.94+git20171222-1_amd64.deb \
 &&  dpkg -i /root/*.deb

RUN  export DEBIAN_FRONTEND=noninteractive \
 &&  apt-get update \
 &&  apt-get install -y rsync

RUN  export CGO_ENABLED=0 \
            GOOS=linux \
            GOARCH=amd64 \
 &&  go get -v -d github.com/kubernetes/kubernetes/cmd/kubectl \
 &&  cd /go/src/github.com/kubernetes/kubernetes \
 &&  make kubectl \
 &&  install -m 0755 $(find _output/local -name kubectl | grep $GOOS/$GOARCH | head -1) /go/bin/kubectl

ARG  UPX_ARGS=-6
RUN  upx ${UPX_ARGS} /go/bin/kubectl

FROM docker.io/library/golang:1.10.0-stretch AS lostromos-builder
RUN  export DEBIAN_FRONTEND=noninteractive \
 &&  curl -Lo /root/libucl.deb http://ftp.de.debian.org/debian/pool/main/u/ucl/libucl1_1.03+repack-4_amd64.deb \
 &&  curl -Lo /root/upx.deb http://ftp.de.debian.org/debian/pool/main/u/upx-ucl/upx-ucl_3.94+git20171222-1_amd64.deb \
 &&  dpkg -i /root/*.deb

RUN  export CGO_ENABLED=0 \
            GOOS=linux \
            GOARCH=amd64 \
 &&  go get -v -d github.com/wpengine/lostromos \
 &&  cd /go/src/github.com/wpengine/lostromos \
 &&  sed -i 's|SetConfigName("lostromos\.yaml|SetConfigName("lostromos|' cmd/cmd.go \
 &&  make build \
 &&  install -m 0755 lostromos /go/bin/lostromos

ARG  UPX_ARGS=-6
RUN  upx ${UPX_ARGS} /go/bin/lostromos

FROM docker.io/library/alpine:3.7 AS lostromos
RUN adduser -D lostromos
USER lostromos
COPY --from=kubectl-builder /go/bin/kubectl /usr/bin/kubectl
COPY --from=lostromos-builder /go/bin/lostromos /usr/bin/lostromos
ENTRYPOINT ["lostromos"]

ONBUILD COPY chart /chart
ONBUILD COPY config.yaml /etc/lostromos.yaml
ONBUILD CMD ["start"]
