#!/bin/bash

# Setup Files
BASEDIR=$(dirname "$0")
RSA_PUBKEY="$BASEDIR/id_rsa.pub"

SSH_DIR_USER="$HOME/.ssh"
SSH_AUTH_KEYS_USER="$SSH_DIR/authorized_keys"

SSH_DIR_ROOT="/root/.ssh"
SSH_AUTH_KEYS_ROOT="$SSH_DIR_ROOT/.ssh/authorized_keys"

CERN_REPO="$BASEDIR/CERN-REPO-hgcwebsw.repo"
CERN_REPO_TARGET="/etc/yum.repos.d/CERN-REPO-hgcwebsw.repo"

LOG_IP_UNIT="$BASEDIR/log-ip.service"
LOG_IP_TARGET="/etc/systemd/system/log-ip.service"

# Verification functions

function verify_exists_file {
    if [ ! -f $1 ]; then
        echo "Missing file $1; Exiting..."
        exit 1
    fi
}

function verify_exists_directory {
    if [ ! -d $1 ]; then
        echo "Missing file $1; Exiting..."
        exit 1
    fi
}

# Verify validity of files

verify_exists_file $RSA_PUBKEY
verify_exists_file $CERN_REPO

# Install SSH keys

# User keys
if [ ! -d $SSH_DIR_USER ]; then
    echo "$SSH_DIR_USER does not exist. Creating..."
    mkdir $SSH_DIR_USER
    chmod 700 $SSH_DIR_USER
fi

if [ ! -f "$SSH_AUTH_KEYS_USER"]; then
    echo "User's SSH Authorized Keys file does not exist. Creating..."
    touch "$SSH_AUTH_KEYS_USER"
    chmod 644 "$SSH_AUTH_KEYS_USER"
fi

if [ grep -Fx -f "$RSA_PUBKEY" "$SSH_AUTH_KEYS_USER" ]; then
    echo "RSA Pubkey already present in user's authorized keys. Skipping..."
else
    echo "Installing RSA Pubkey to user's authorized keys."
    cat "$RSA_PUBKEY" | tee -a $SSH_AUTH_KEYS_USER
fi

# Root keys
if [ ! -d $SSH_DIR_ROOT ]; then
    echo "$SSH_DIR_ROOT does not exist. Creating..."
    mkdir $SSH_DIR_ROOT
    chmod 700 $SSH_DIR_ROOT
fi

if [ ! -f "$SSH_AUTH_KEYS_ROOT"]; then
    echo "Root SSH Authorized Keys file does not exist. Creating..."
    touch "$SSH_AUTH_KEYS_ROOT"
    chmod 644 "$SSH_AUTH_KEYS_ROOT"
fi

if [ grep -Fx -f "$RSA_PUBKEY" "$SSH_AUTH_KEYS_ROOT" ]; then
    echo "RSA Pubkey already present in root's authorized keys. Skipping..."
else
    echo "Installing RSA Pubkey to root's authorized keys."
    cat "$RSA_PUBKEY" | sudo tee -a $SSH_AUTH_KEYS_ROOT
fi

# Install dependencies
echo "Install dependencies..."
sudo dnf -y install epel-release
sudo dnf update

# devtoolset-10 is not a repo in AlmaLinux, repalce with gcc-toolset-13
sudo dnf -y --enablerepo=crb install cmake zeromq zeromq-devel cppzmq-devel libyaml libyaml-devel yaml-cpp yaml-cpp-devel boost boost-devel python3 python3-devel autoconf-archive pugixml pugixml-devel gcc-toolset-13

# Add CERN Repo
if [ -f $CERN_REPO_TARGET ]; then
    echo "CERN repo already present. Skipping..."
else
    echo "Installing CERN Repo..."
    sudo cp $CERN_REPO $CERN_REPO_TARGET 
fi

# Install fw-loader
echo "Installing fw-loader..."
sudo dnf update

sudo dnf -y install fw-loader hexaboard-hd-tester-v2p0-trophy-v3

# Install ipbus-software (hgcal-uio)
echo "Installing ipbus-software (hgcal-uio)"

sudo dnf -y install cactuscore*

# Install Hexactrl-sw
echo "Installing hexactrl-sw"

sudo dnf install hexactrl-sw-rocv3

# Install Python Modules
echo "Installing Python Dependencies..."

sudo pip3 install --upgrade pip
sudo pip3 -r /opt/hexactrl/ROCv3/ctrl/etc/requirements.txt

# Enable DAQ Client Service
echo "Enabling DAQ Client Service"
sudo systemctl daemon-reload
sudo systemctl enable daq-server.service
sudo systemctl enable i2c-service.service

# Install IP Logging service
if [ -f $LOG_IP_TARGET ]; then
    echo "IP Logger already present. Skipping..."
else
    echo "Installing IP Logger..."
    sudo cp "$LOG_IP_UNIT" "$LOG_IP_TARGET"
    sudo systemctl daemon-reload
    sudo systemctl enable log-ip
exit
