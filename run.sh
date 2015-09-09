#!/bin/bash

# wait for couchdb and redis to start
sleep 5

if [[ ${FIRST_RUN} ]] ; then
	sudo -u darcsden ssh-keygen -N "" -f /home/darcsden/.ssh/id_rsa
	sudo -u darcsden sh -c 'cd && darcsden --install'
fi

sudo -u darcsden sh -c 'cd && darcsden-ssh --config ~/darcsden.conf' &
sudo -u darcsden sh -c 'cd && darcsden --config ~/darcsden.conf'
