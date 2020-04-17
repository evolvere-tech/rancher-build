#!/bin/bash
apt-get -y update
apt-get -y install curl
apt-get -y install docker.io

sudo bash <(curl -s http://example.com/install-trend.sh)
