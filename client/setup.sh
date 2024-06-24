#!/bin/bash

# Setup Files
BASEDIR=$(dirname "$0")
RSA_PUBKEY="$BASEDIR/id_rsa.pub"
RSA_PRIVKEY="$BASEDIR/id_rsa"

SSH_DIR="$HOME/.ssh"
RSA_PUBKEY_TARGET="$SSH_DIR/id_rsa.pub"
RSA_PRIVKEY_TARGET="$SSH_DIR/id_rsa"

CERN_REPO="$BASEDIR/CERN-REPO-hgcwebsw.repo"
CERN_REPO_TARGET="/etc/yum.repos.d/CERN-REPO-hgcwebsw.repo"

GUI_LOCATION="/opt/hgcal-module-testing-gui"
GUI_REPO="https://gitlab.cern.ch/acrobert/hgcal-module-testing-gui.git"
GUI_CONFIG="$BASEDIR/configuration.yaml"
GUI_CONFIG_TARGET="$GUI_LOCATION/configuration.yaml"
GUI_REQUIREMENTS="$BASEDIR/requirements.txt"

GUI_VENV="$GUI_LOCATION/venv"

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
verify_exists_file $RSA_PRIVKEY
verify_exists_file $CERN_REPO
verify_exists_file $GUI_CONFIG
verify_exists_file $GUI_REQUIREMENTS

# Install SSH keys
if [ ! -d $SSH_DIR ]; then
    echo "$SSH_DIR does not exist. Creating..."
    mkdir $SSH_DIR
    chmod 700 $SSH_DIR
fi

# Check for existing keys
if [ -f "$RSA_PUBKEY_TARGET" -o -f "$RSA_PRIVKEY_TARGET" ]; then
    # Check if a result of this script
    if cmp -s -- "$RSA_PUBKEY" "$RSA_PUBKEY_TARGET"; then
        if cmp -s -- "$RSA_PRIVKEY" "$RSA_PRIVKEY_TARGET"; then
            echo "RSA public/private keypair already present. Skipping..."
        else
            echo "ERROR: RSA Public key does not match private key! Exiting..."
            exit 1
        fi
    else
        # Not part of this script, warn users
        echo "Skipping installation of RSA public/private keypair as one already exists."
        echo "WARNING: Present keypair may not be authorized on the FPGAs."
    fi
else
    # No keys installed, so install ours
    cp "$RSA_PUBKEY" "$RSA_PUBKEY_TARGET"
    chmod 644 $RSA_PUBKEY_TARGET

    cp "$RSA_PRIVKEY" "$RSA_PRIVKEY_TARGET"
    chmod 600 $RSA_PRIVKEY_TARGET
fi

# Install dependencies
# echo "Install dependencies..."
# sudo yum install epel-release 
# sudo yum update

# devtoolset-10 is not a repo in AlmaLinux, repalce with gcc-toolset-13
# sudo yum install pugixml pugixml-devel python3 python3-devel cmake zeromq zeromq-devel cppzmq-devel libyaml libyaml-devel yaml-cpp yaml-cpp-devel boost boost-devel root


# Add CERN Repo
if [ -f CERN_REPO_TARGET ]; then
    echo "CERN repo already present. Skipping..."
else
    echo "Installing CERN Repo..."
    sudo cp $CERN_REPO $CERN_REPO_TARGET 
fi

# Install Hexactrl-sw
# echo "Installing Hexactrl-sw..."
# sudo yum update

# sudo yum install hexactrl-sw-rocv3
#
# # Install Python Modules
# echo "Installing Python Dependencies..."
#
# pip3 install --upgrade pip
# pip3 install -r /opt/hexactrl/ROCv3/ctrl/etc/requirements.txt --user
#
# # Enable DAQ Client Service
# echo "Enabling DAQ Client Service"
# sudo systemctl daemon-reload
# sudo systemctl enable daq-client.service

# Install GUI Prereqs
echo "Installing Client GUI Prerequisites"
sudo dnf -y install libpq-devel python3-devel python3-tkinter

# Clone GUI
if [ ! -d $GUI_LOCATION ]; then
    echo "Cloning GUI..."
    sudo mkdir $GUI_LOCATION
    sudo chmod 777 $GUI_LOCATION
    git clone "$GUI_REPO" "$GUI_LOCATION"
else
    echo "GUI Already Cloned, Skipping..."
fi

# Create VirtualEnv
if [ ! -d $GUI_VENV ]; then
    echo "Creating GUI Virtual Environment..."
    python3 -m venv "$GUI_VENV"
    $GUI_VENV/bin/pip3 install -r "$GUI_REQUIREMENTS"
else
    echo "Virtual Environment already exists. Skipping..."
fi

# Add Config
if [ ! -f $GUI_CONFIG_TARGET ]; then
    echo "Copying GUI Config..."
    cp "$GUI_CONFIG" "$GUI_CONFIG_TARGET"
else
    echo "GUI Config already exists, skipping..."
fi
