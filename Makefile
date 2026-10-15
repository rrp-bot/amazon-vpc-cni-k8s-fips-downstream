.PHONY: all image image-init image-metrics

CONTAINER_ENGINE ?= podman
VERSION ?= $(shell git -C upstream describe --tags --always 2>/dev/null || printf '%s' downstream)
SOURCE_REVISION ?= $(shell git -C upstream rev-parse HEAD 2>/dev/null || printf '%s' unknown)
SOURCE_URL ?= https://github.com/aws/amazon-vpc-cni-k8s
GOLANG_IMAGE ?= registry.access.redhat.com/ubi9/go-toolset:9.8-1791479310
BASE_IMAGE ?= registry.access.redhat.com/ubi9/ubi-minimal:9.8-1791765279

BUILD_ARGS = \
	--build-arg golang_image=$(GOLANG_IMAGE) \
	--build-arg base_image=$(BASE_IMAGE) \
	--build-arg SOURCE_URL=$(SOURCE_URL) \
	--build-arg SOURCE_REVISION=$(SOURCE_REVISION) \
	--build-arg VERSION=$(VERSION)

all: image image-init image-metrics

image:
	$(CONTAINER_ENGINE) build $(BUILD_ARGS) -f Containerfile -t amazon-vpc-cni-fips:$(VERSION) .

image-init:
	$(CONTAINER_ENGINE) build $(BUILD_ARGS) -f Containerfile.init -t amazon-vpc-cni-init-fips:$(VERSION) .

image-metrics:
	$(CONTAINER_ENGINE) build $(BUILD_ARGS) -f Containerfile.metrics -t amazon-cni-metrics-fips:$(VERSION) .
