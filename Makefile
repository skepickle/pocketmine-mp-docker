NS = skepickle
VERSION ?= latest

REPO = pocketmine-mp-docker
NAME = pocketmine-mp
INSTANCE = default

PORTS = -p 19132:19132/tcp -p 19132:19132/udp
VOLUMES = -v $(shell pwd)/pm_data:/pm_data
ENV = -e LOCAL_USER_ID=$(shell id -u ${USER})

.PHONY: build push shell run start stop rm release

build:
	docker build -t $(NS)/$(REPO):$(VERSION) .

push:
	docker push $(NS)/$(REPO):$(VERSION)

shell:
	docker run           --name $(NAME)-$(INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION) /bin/bash

run:
	docker run           --name $(NAME)-$(INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION)

start:
	docker run -d        --name $(NAME)-$(INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION)

attach:
	docker attach --sig-proxy=true $(NAME)-$(INSTANCE)

logs:
	docker logs $(NAME)-$(INSTANCE)

stop:
	docker stop $(NAME)-$(INSTANCE)

rm:
	docker rm   $(NAME)-$(INSTANCE)

release: build
	make push -e VERSION=$(VERSION)

default: build

