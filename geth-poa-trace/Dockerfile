# syntax=docker/dockerfile:1
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache gcc musl-dev linux-headers git make gcc-go

RUN go install github.com/go-delve/delve/cmd/dlv@latest

COPY ../go.mod /go-ethereum/
COPY ../go.sum /go-ethereum/
RUN --mount=type=cache,target=/root/.cache/go-build cd /go-ethereum &&  go mod download

ADD .. /go-ethereum
RUN --mount=type=cache,target=/root/.cache/go-build cd /go-ethereum && go run build/ci.go install -static ./cmd/geth

FROM alpine:latest

RUN apk add --no-cache jq

COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/
COPY --from=builder /go/bin/dlv /usr/local/bin/dlv


COPY geth-poa-trace/genesis.json /genesis.json

COPY geth-poa-trace/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8545 6060 6066 8080

ENTRYPOINT ["/entrypoint.sh"] 
