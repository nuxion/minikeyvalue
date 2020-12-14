FROM golang:1.15.6-alpine as builder
RUN apk add --update --no-cache make git
RUN mkdir /build
ADD . /build/
WORKDIR /build
RUN go mod download
RUN make build-mkv
ENV GOARCH=amd64
ENV CGO_ENABLED=0
ENV GOOS=linux

FROM alpine
#RUN adduser -S -D -H -h /app appuser
#USER appuser
# TODO -> adduser and binaries to /usr/local/bin path
COPY --from=builder /build/ /app/
#EXPOSE 5443/tcp
WORKDIR /app
#ENTRYPOINT ["/app/bin/"]
CMD ["/app/bin/mkv"]
