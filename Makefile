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

.PHONY: release
release:
	docker build -t ${PROJECTNAME} .
