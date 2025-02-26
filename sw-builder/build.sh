#!/bin/bash

BASEDIR=$(dirname "$0")
BUILD_DIR="$BASEDIR/hexactrl-sw/build"
CI_COMMIT_REF_NAME="778279a3"

# Clone Repo
if [! -d "$BASEDIR/hexactrl-sw" ]; then
    git clone --recursive ssh://git@gitlab.cern.ch:7999/hgcal-daq-sw/hexactrl-sw.git "$BASEDIR/hexactrl-sw"
fi


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
MACHINE_TYPE=`uname -m`

if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    cmake -DBUILD_CLIENT=ON -DBRANCH_NAME=$CI_COMMIT_REF_NAME -DCMAKE_INSTALL_PREFIX=/opt/hexactrl/$CI_COMMIT_REF_NAME ../
else
    cmake -DBRANCH_NAME=$CI_COMMIT_REF_NAME -DCMAKE_INSTALL_PREFIX=/opt/hexactrl/$CI_COMMIT_REF_NAME ../
fi

make -j3
sudo make install
sudo cpack

# Link files
echo "Linking to ROCv3"

folder=(/opt/hexactrl/*)
sudo ln -s "$folder/" /opt/hexactrl/ROCv3

# Install Python Modules
echo "Installing Python Dependencies..."

pip3 install --upgrade pip
pip3 install -r /opt/hexactrl/ROCv3/etc/requirements.txt --user

# Link service
echo "Linking service file..."
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    sudo ln -s /opt/hexactrl/ROCv3/share/daq-client.service /etc/systemd/system/daq-client.service
else
    sudo ln -s /opt/hexactrl/ROCv3/share/daq-server.service /etc/systemd/system/daq-server.service
    sudo ln -s /opt/hexactrl/ROCv3/share/i2c-server.service /etc/systemd/system/i2c-server.service
fi

# Enable DAQ Client Service
echo "Enabling DAQ Client Service..."
sudo systemctl daemon-reload

if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    sudo systemctl enable daq-client.service
else
    sudo systemctl enable daq-server.service
    sudo systemctl enable i2c-server.service
fi