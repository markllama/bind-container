#!/bin/bash
set -x
MAINTAINER='markllama@gmail.com'
CONTAINER_NAME=$1
#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=registry.fedoraproject.org/fedora-minimal:36
IMAGE_NAME=$2

RPMS=(bind bind-utils)
SERVICES=(named)

# from fedora
buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}
#buildah config --env INTERFACE=eno1 ${CONTAINER_NAME}

buildah run ${CONTAINER_NAME} microdnf -y install ${RPMS[@]}
buildah run ${CONTAINER_NAME} microdnf clean all

# copy entrypoint.sh
buildah copy ${CONTAINER_NAME} entrypoint.sh /opt/entrypoint.sh
buildah config --entrypoint '/opt/entrypoint.sh' ${CONTAINER_NAME}

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}
