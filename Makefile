SHELL=/bin/bash -o pipefail

GO ?= go
DOCKER ?= docker
KIND ?= kind
HELM ?= helm
PWD=$(shell pwd)

FALCO_VERSION=0.20.0
FALCO_GIT=https://github.com/falcosecurity/falco.git
HELM_CHART_VERSION=
BPF_INSTALL_PATH=/lib/modules/falco-bpf-probe.o

build/falco/build:
	mkdir -p build && rm -rf build/falco
	cd build && git clone https://github.com/falcosecurity/falco.git && cd falco && git checkout ${FALCO_VERSION}
	mkdir -p build/falco/build
	cd build/falco/build && \
		cmake -DSYSDIG_VERSION=be1ea2d9482d0e6e2cb14a0fd7e08cbecf517f94 -DBUILD_BPF=ON ..

build/falco/build/driver/bpf/probe.o:
	cd build/falco/build && make bpf

build/falco/build/driver/probe.o:
	cd build/falco/build && make driver


.PHONY: install/driver/bpf
install/bpf: build/falco/build/driver/bpf/probe.o
	sudo cp build/falco/build/driver/bpf/probe.o ${BPF_INSTALL_PATH}

.PHONY: install/driver
install/driver: build/falco/build
	cd build/falco/build && sudo make install_driver

.PHONY: deploy/falco
deploy/falco:
	$(HELM) install falco stable/falco -f ./falco/values.yaml 

.PHONY: kind/cluster
kind/cluster:
	$(KIND) create cluster --config=./kind/extra-mount.yaml
