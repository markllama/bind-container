#!/bin/bash
#
# This script uses buildah to compose a container image with a BIND 9 nameserver
#
MAINTAINER="Mark Lamourine <markllama@gmail.com>"

CONTAINER_NAME=$1
IMAGE_NAME=$2

#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=registry.fedoraproject.org/fedora-minimal:36
DNF=microdnf

RPMS=(systemd bind)
SERVICES=(named)

function main() {
    set_container_metadata
    install_and_configure_systemd_services
    finalize_container_image
}


# A shortcut for commands that run inside the container
function buildah_run() {
    buildah run ${CONTAINER_NAME} $*
}

# This function replaces a file or directory in the container with a link to a
# location in an imported volume
function replace_with_link() {
    local FILE=$1
    local LINK=$2

    buildah_run rm -rf ${FILE}
    buildah_run ln -s ${LINK} ${FILE}
}

# ==================================================================================
#
# ==================================================================================

function set_container_metadata() {
    # Set container metadata
    buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
    buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}
    buildah config --volume /data ${CONTAINER_NAME}
}

function install_and_configure_systemd_services() {
    # Install service packages
    buildah_run ${DNF} -y install ${RPMS[@]}
    buildah_run ${DNF} -y clean all

    # replace the systemd service to one set for root
    buildah copy ${CONTAINER_NAME} named.service /usr/lib/systemd/system/named.service
    buildah copy ${CONTAINER_NAME} named.conf /etc/named.conf
    
    # The remaining input is mounted on /data
    # Replace the stock config files with symlinks to the import directory: /opt
    replace_with_link /etc/sysconfig/named /opt/named.env
    replace_with_link /etc/rndc.conf /opt/rndc.conf

    buildah copy --chown root:root --chmod 644 ${CONTAINER_NAME} named-root.service /usr/lib/systemd/system/named-root.service
    buildah copy --chown root:root --chmod 755 ${CONTAINER_NAME} named-root.sh /usr/libexec/named-root.sh

    # Named runs as root in the container to avoid additional user namespace mapping
    buildah_run chown -R root:root /var/named
#    buildah_run chown -R root:root /var/run/named

    # Enable services inside the container
    buildah_run systemctl enable ${SERVICES[@]}
    # Start with systemd
    buildah config --cmd '["/usr/sbin/init"]' ${CONTAINER_NAME}
}

function finalize_container_image() {
    #
    # Finalize the new container image
    #
    buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}
    buildah unmount ${CONTAINER_NAME}
}

# ----------------------------------------------------------------------------------------------
# Execute the main function
main $*
