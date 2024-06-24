#!/bin/bash

BASEDIR=$(dirname "$0")
BUILD_DIR="$BASEDIR/hexactrl-sw/build"
CI_COMMIT_REF_NAME="778279a3"

# Install dependencies
echo "Install dependencies..."
sudo yum install epel-release 
sudo yum update
sudo yum install pugixml pugixml-devel python3 python3-devel cmake zeromq zeromq-devel cppzmq-devel libyaml libyaml-devel yaml-cpp yaml-cpp-devel boost boost-devel root

# Taken from ci/templates/build-template.yml
echo "Creating Build Dir..."
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# Taken from ci/alma/9/x86_64/.gitlab-ci.yml
echo "Building..."
cmake -DBUILD_CLIENT=ON -DBRANCH_NAME=$CI_COMMIT_REF_NAME -DCMAKE_INSTALL_PREFIX=/opt/hexactrl/$CI_COMMIT_REF_NAME ../
make -j3
sudo make install
cpack

# Link files
echo "Linking to ROCv3"

folder=(/opt/hexactrl/*)
sudo ln -s "$folder/" /opt/hexactrl/ROCv3

# Install Python Modules
echo "Installing Python Dependencies..."

pip3 install --upgrade pip
pip3 install -r /opt/hexactrl/ROCv3/ctrl/etc/requirements.txt --user

# Link service
echo "Linking service file..."
sudo ln -s /opt/hexactrl/ROCv3/share/daq-client.service /etc/systemd/system/daq-client.service

# Enable DAQ Client Service
echo "Enabling DAQ Client Service..."
sudo systemctl daemon-reload
sudo systemctl enable daq-client.service
