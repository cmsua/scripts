# Hexaboard Testing Lab Setup Scripts

This repository consists of several scripts designed to install or build software on computers in the UA Hexaboard Testing Lab.

Each script is designed for compatability with a fresh installation of CERN AlmaLinux 9. CentOS 7 is not supported.

## Software Builder (Hexacontroller, Client)

Under the `sw-builder` repository is a script designed to build and compile the [hexacontroller software](https://gitlab.cern.ch/hgcal-daq-sw/hexactrl-sw). As the repository's metadata does not properly update, package managers such as `yum` and `dnf` cannot locate the latest builds of nessecary packages. This leads to the system attempting to install outdated packages built against old versions of libraries. As AlmaLinux's repositories do not contain out-of-date packages, the installation fails. As such, it is nessecary to compile and install the software from source.

To run this script, the software must be cloned from CERN GitLab into the `sw-builder/hexactrl-sw` folder. A CERN Account will be required.

```bash
git clone --recurse-submodules https://gitlab.cern.ch/hgcal-daq-sw/hexactrl-sw.git
```

Afterwards, the script may be ran using `./build.sh`. The script will do the following:

- Build and install the `hexactrl-sw` software for the client/server, depending on the architecture of the machine
- Create a symlink from `/opt/hexactrl/ROCv3` to `/opt/hexactrl/commit-hash`
- Snylink the relevant systemd files from `/opt/hexactrl/ROCv3/share` and enable the services at boot

## Client Setup (Client)

Under the `client` folder is a script designed to setup a testing computer for use in the lab. The lab's RSA keys should be placed under `/client/id_rsa` and `/client/id_rsa.pub`. Afterwards, run `./setup.sh`.

This script will do the following:

- Install the lab's SSH keys
- Install testing dependencies (Redis)
- 