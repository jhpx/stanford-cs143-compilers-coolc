#!/bin/sh
chmod +x class/cs143/cool/bin/.i686/*
chmod +x class/cs143/cool/bin/* && chmod -x class/cs143/cool/bin/*.*
chmod +x class/cs143/cool/etc/* && chmod -x class/cs143/cool/etc/*.*
sudo apt-get install flex bison build-essential spim
sudo mkdir -p /usr/class/cs143/cool/lib/
sudo chown $USER /usr/class/cs143/cool/lib/
ln -s `pwd`/class/cs143/cool/lib/trap.handler /usr/class/cs143/cool/lib/trap.handler
