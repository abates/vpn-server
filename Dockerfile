FROM python:3.10-alpine

RUN apk update && apk upgrade &&\
    apk add openvpn dnsmasq

EXPOSE 1194/udp 1194/tcp

ENTRYPOINT ["/bin/ash"]
