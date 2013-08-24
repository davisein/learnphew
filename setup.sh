#!/bin/bash

# Install node.js (more recent than the Ubuntu one)
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs

# Install redis
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get install redis-server

# Install mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list
sudo apt-get update
sudo apt-get install mongodb-10gen

# Install derbyjs
npm install -g derby

