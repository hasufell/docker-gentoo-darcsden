#!/bin/bash

if [[ ${FIRST_RUN} ]] ; then
	sudo -u redis /usr/sbin/redis-server /etc/redis.conf --daemonize yes
	sudo -u couchdb /usr/bin/couchdb -b -o /var/log/couchdb/out.txt -e /var/log/couchdb/err.txt

	sleep 3

	sudo -u darcsden sh -c 'cd && darcsden --install'
	sudo -u darcsden ssh-keygen -N "" -f /home/darcsden/.ssh/id_rsa

	sleep 3

	sudo -u redis /usr/bin/redis-cli shutdown
	kill -s SIGTERM $(cat /var/run/couchdb/couchdb.pid)

	sleep 3
fi

