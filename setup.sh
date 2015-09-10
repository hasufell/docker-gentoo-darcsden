#!/bin/bash

if [[ ${FIRST_RUN} == "yes" ]] ; then
	sudo -u redis /usr/sbin/redis-server /etc/redis.conf --daemonize yes
	sudo -u couchdb /usr/bin/couchdb -b -o /var/log/couchdb/out.txt -e /var/log/couchdb/err.txt

	sleep 3

	sudo -Eu darcsden sh -c 'cd && darcsden --install'
	sudo -Eu darcsden ssh-keygen -N "" -f /home/darcsden/.ssh/id_rsa

	sleep 3

	sudo -u redis /usr/bin/redis-cli shutdown
	kill -s SIGTERM $(cat /var/run/couchdb/couchdb.pid)

	sleep 3
fi

if [[ ! -f /home/darcsden/darcsden.conf ]] ; then
	cat << EOF > /home/darcsden/darcsden.conf
homeDir = /home/darcsden
accessLog = /var/log/darcsden/access.log
errorLog = /var/log/darcsden/error.log
hostname = ${VIRTUAL_HOST:-localhost}
httpPort = ${VIRTUAL_PORT:-8900}
sshPort = ${DARCSDEN_SSH_PORT:-22022}
baseUrl = https://${VIRTUAL_HOST:-localhost}/
EOF
else
	[[ ${VIRTUAL_HOST} ]] &&
		sed -i -e "s/^hostname =.*$/hostname = ${VIRTUAL_HOST}/" \
			/home/darcsden/darcsden.conf
	[[ ${VIRTUAL_PORT} ]] &&
		sed -i -e "s/^httpPort =.*$/httpPort = ${VIRTUAL_PORT}/" \
			/home/darcsden/darcsden.conf
	[[ ${DARCSDEN_SSH_PORT} ]] &&
		sed -i -e "s/^sshPort =.*$/sshPort = ${DARCSDEN_SSH_PORT}/" \
			/home/darcsden/darcsden.conf
fi
