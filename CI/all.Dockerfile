ARG UBUNTU_VERSION=18.04
ARG COMPILER=gcc
ARG HDF5=1.10.4
# MOAB Commit: 9c96d17 (Merged commit of @pshriwise thread fix)
ARG MOAB=9c96d17


LABEL UBUNTU_VERSION=$UBUNTU_VERSION
LABEL COMPILER=$COMPILER
LABEL HDF5=$HDF5
LABEL MOAB=$MOAB

FROM ubuntu:${UBUNTU_VERSION} as base

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Update core packages
RUN apt-get -y update; \
    apt-get -y install autoconf clang cmake g++ gcc gfortran git libblas-dev \
                       libhdf5-dev liblapack-dev libpython2.7-dev libtool libeigen3-dev\
                       python-numpy python-pip python-setuptools wget; \
    pip install cython

# Copy scripts to docker image
RUN mkdir -p /root/etc/
COPY CI/ /root/etc/CI
ENV docker_env=/root/etc/CI/env.sh

ENV build_dir=/root/build_dir
ENV install_dir=/root/opt


FROM base as external_deps
# FROM ghcr.io/shimwell/dagmc-ci-ubuntu-${UBUNTU_VERSION}

#setting the COMPILER variable
ENV COMPILER=${COMPILER}

# Set Geant4 env variable
ENV geant4_build_dir=${build_dir}/geant4
ENV geant4_install_dir=${install_dir}/geant4

# Build Geant4
RUN /root/etc/CI/docker/build_geant4.sh

ENV double_down_build_dir=${build_dir}/double-down/
ENV double_down_install_dir=${install_dir}/double-down/

# Build Embree
RUN /root/etc/CI/docker/build_embree.sh



FROM external_deps as hdf5
# FROM ghcr.io/shimwell/dagmc-ci-ubuntu-${UBUNTU_VERSION}-${COMPILER}-ext

# Set HDF5 env variable
ENV hdf5_build_dir=${build_dir}/hdf5
ENV hdf5_install_dir=${install_dir}/hdf5

# Build HDF5
# HDF5 argument possible value: 1.10.4 or system
ENV HDF5_VERSION=${HDF5}
RUN /root/etc/CI/docker/build_hdf5.sh



FROM hdf5 as moab
# FROM ghcr.io/shimwell/dagmc-ci-ubuntu-${UBUNTU_VERSION}-${COMPILER}-ext-hdf5_${HDF5}

# Set MOAB env variable
ENV moab_build_dir=${build_dir}/moab
ENV moab_install_dir=${install_dir}/moab


ENV MOAB_VERSION ${MOAB}
RUN if [ "${MOAB_VERSION}" != "master" ] && [ "${MOAB_VERSION}" != "develop" ]; then \
        /root/etc/CI/docker/build_moab.sh; \
    fi;