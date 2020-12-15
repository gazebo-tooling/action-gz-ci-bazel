#!/bin/sh -l

set -x
set -e

BAZEL_ARGS=$1
IGN_BAZEL_BRANCH=$2

echo ::group::Install tools: apt
apt update 2>&1
apt -y install \
  build-essential \
  cmake \
  cppcheck \
  curl \
  g++-8 \
  git \
  gnupg \
  lsb-release \
  python3-pip \
  wget

SYSTEM_VERSION=`lsb_release -cs`
SOURCE_DEPENDENCIES="`pwd`/.github/ci/dependencies.yaml"
SOURCE_DEPENDENCIES_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/dependencies.yaml"

apt-get update 2>&1
echo ::endgroup::

echo ::group::Install tools: pip
pip3 install -U pip vcstool colcon-common-extensions
echo ::endgroup::

echo ::group::Install tools: bazel 
curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list
apt update && apt install bazel
echo ::endgroup::

mkdir ~/ignition/
cd ~/ignition/

wget https://raw.githubusercontent.com/ignitionrobotics/ign-bazel/${IGN_BAZEL_BRANCH}/example/bazel.repos
vcs import . < bazel.repos

echo ::group::Install dependencies from binaries
apt -y install \
  $(sort -u $(find . -iname 'packages-'$SYSTEM_VERSION'.apt' -o -iname 'packages.apt') | tr '\n' ' ')
echo ::endgroup::

ln -sf ./ign_bazel/example/WORKSPACE.example ~/ignition/WORKSPACE
ln -sf ./ign_bazel/example/BUILD.example ~/ignition/BUILD.bazel
ln -sf ./ign_bazel/example/bazelrc.example ~/ignition/.bazelrc

bazel build $BAZEL_ARGS
bazel test $BAZEL_ARGS


