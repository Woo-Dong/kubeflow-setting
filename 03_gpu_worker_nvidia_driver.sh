#!/bin/bash
sudo add-apt-repository -y ppa:graphics-drivers/ppa # type ENTER

sudo apt update && sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall
sudo reboot
