#!/bin/bash

if [[ ${FIRST_RUN} == "yes" ]] ; then
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

if [[ ! -f /home/darcsden/darcsden.conf ]] ; then
	cat << EOF > /home/darcsden/darcsden.conf
homeDir = /home/darcsden
accessLog = /var/log/darcsden/access.log
errorLog = /var/log/darcsden/error.log
hostname = ${VIRTUAL_HOST:-localhost}
httpPort = ${VIRTUAL_PORT:-8900}
sshPort = ${DARCSDEN_SSH_PORT:-22022}
baseUrl = https://${VIRTUAL_HOST:-localhost}/
sendEmail = ${DARCSDEN_SEND_EMAIL:-darcsden@${VIRTUAL_HOST:-localhost}}
adminEmail = ${DARCSDEN_ADMIN_EMAIL:-admin@${VIRTUAL_HOST:-localhost}}
EOF
fi

# set privliges for darcsden-ssh to bind to ports <1024
setcap 'cap_net_bind_service=+ep' /usr/local/bin/darcsden-ssh


if [[ -n ${MAIL_HUB} ]] ; then
	sed -i \
		-e "s/^mailhub=.*$/mailhub=${MAIL_HUB}/" \
		/etc/ssmtp/ssmtp.conf
fi

if [[ -n ${MAIL_AUTHUSER} ]] ; then
	sed -i \
		-e "s/^AuthUser=.*$/AuthUser=${MAIL_AUTHUSER}/" \
		/etc/ssmtp/ssmtp.conf
fi

if [[ -n ${MAIL_AUTHPASS} ]] ; then
	sed -i \
		-e "s/^AuthPass=.*$/AuthPass=${MAIL_AUTHPASS}/" \
		/etc/ssmtp/ssmtp.conf
fi
