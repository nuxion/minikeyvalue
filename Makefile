.EXPORT_ALL_VARIABLES:
VERSION := $(shell git describe --tags)
BUILD := $(shell git rev-parse --short HEAD)
PROJECTNAME := $(shell basename "$(PWD)")

LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"
STDERR := /tmp/.$(PROJECTNAME)-stderr.txt
export CGO_ENABLED=0
# If the first argument is "run"...
ifeq (cert,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

cert:
	echo $(CNAME)
	openssl req -x509 -newkey rsa:4096\
		-keyout certs/$(CNAME)-key.pem \
		-out certs/$(CNAME)-cert.pem -days 365 \
		-nodes -subj '/CN=$(CNAME)'
.PHONY: serve
serve: volumes
	./mkv -port 3000 -volumes localhost:3001,localhost:3002,localhost:3003 -db /tmp/indexdb/ server

.PHONY: mkv
mkv:
	go run src/main.go src/lib.go src/server.go src/rebalance.go src/rebuild.go $@

.PHONY: build-mkv
build-mkv:
	cd src;\
	go build $(LDFLAGS) -o ../bin/mkv

.PHONY: tar
tar:
	tar cvfz releases/mkv-$(VERSION).tgz bin/

.PHONY: docker
docker:
	docker build -t nuxion/mkv .

.PHONY: docker-nginx
docker-nginx:
	docker build -t nuxion/mkv-nginx -f Dockerfile.nginx .

.PHONY: volumes
volumes:
	docker run --rm -e PORT=3001 -p 127.0.0.1:3001:3001 nuxion/mkv-nginx volume &
	docker run --rm -e PORT=3002 -p 127.0.0.1:3002:3002 nuxion/mkv-nginx volume &
	docker run --rm -e PORT=3003 -p 127.0.0.1:3003:3003 nuxion/mkv-nginx volume &

.PHONY: release
release:
	docker build -t ${PROJECTNAME} .
