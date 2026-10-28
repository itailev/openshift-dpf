ARG BASE_IMAGE=quay.io/openshift/ci:ci_nested-podman_latest
FROM docker.io/alpine/helm:3 as helm-cli
FROM quay.io/openshift/origin-cli:4.22 as oc-cli
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Red Hat Ecosystem Engineering"

USER root

# Copying oc binary
COPY --from=oc-cli /usr/bin/oc /usr/bin/oc
RUN ln -s /usr/bin/oc /usr/bin/kubectl

RUN dnf install -y --allowerasing findutils gettext git golang jq make openssh-clients \
      python3.12 python3.12-pip python3.12-devel rsync && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/bin/pip3 && \
    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    dnf install -y --repofrompath='cs9-appstream,https://mirror.stream.centos.org/9-stream/AppStream/$basearch/os/' \
      --setopt=cs9-appstream.gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official \
      libvirt-client virt-install && \
    dnf clean all

# Copying helm binary
COPY --from=helm-cli /usr/bin/helm /usr/bin/helm

# Install aicli
RUN pip3 install aicli

ENV HOME=/root/dpf-ci

WORKDIR /root/dpf-ci

COPY . .

# Make workspace writable for OpenShift's arbitrary user IDs
RUN chmod 777 /root/dpf-ci -R
