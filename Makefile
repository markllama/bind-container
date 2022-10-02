#!make

IMAGE_REPO=quay.io
REPO_USER=markllama
IMAGE_NAME=bind
CONTAINER_NAME=named
BUILD_CONTAINER_NAME=bind-build
DATADIR=$(shell pwd)/data

$(IMAGE_NAME)-oci.tgz: build
	podman save --format oci-archive ${IMAGE_NAME} --output $(IMAGE_NAME)-oci.tgz

build:
	buildah unshare ./build.sh $(BUILD_CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-rm $(IMAGE_NAME)-oci.tgz
	-buildah delete $(BUILD_CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

run:
	+podman run -d --privileged --name ${CONTAINER_NAME} --net=host \
		--volume ${DATADIR}:/opt:Z \
	  $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

cli:
	+podman run -it --rm --privileged --init --name ${CONTAINER_NAME} --net=host \
	  --volume ${DATADIR}:/opt:Z \
	  --entrypoint=/bin/bash \
	  ${IMAGE_REPO}/${REPO_USER}/${IMAGE_NAME}

stop:
	-podman stop ${CONTAINER_NAME}
	-podman rm ${CONTAINER_NAME}

tag:
	podman tag ${IMAGE_NAME} ${IMAGE_REPO}/${REPO_USER}/${IMAGE_NAME}

push:
	podman push $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

$(DATADIR)/etc/rndc.key:
	mkdir -p $(DATADIR)/etc/sysconfig
	mkdir -p $(DATADIR)/named/dynamic
	rndc-confgen -a -c $(DATADIR)/etc/rndc.key -k rndc-key
