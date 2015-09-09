## Getting the images

Just pull them:
```sh
docker pull hasufell/gentoo-darcsden
```

Or build them yourself:
```sh
docker build -t hasufell/gentoo-darcsden .
```

## Configuration

If you provide `/home/darcsden/darcsden.conf` (e.g. via mounting), then
that will be used, otherwise the following defaults will be used:
```
homeDir = /home/darcsden
accessLog = /var/log/darcsden/access.log
errorLog = /var/log/darcsden/error.log
hostname = localhost
httpPort = 8900
sshPort = 22022
baseUrl = https://localhost/
```

Additionally, you can pass the following environment variables:
* VIRTUAL_HOSTNAME (sets hostname for nginx front proxy and changes `hostname`)
* VIRTUAL_PORT (sets port for nginx front proxy and changes `httpPort`)
* DARCSDEN_SSH_PORT (changes `sshPort`)

## Running for the first time

Create the volumes:
```sh
docker run \
	--name=darcsden-volumes \
	-v /var/lib/couchdb \
	-v /var/lib/redis \
	-v /home/darcsden/users \
	-v /home/darcsden/.ssh \
	hasufell/gentoo-darcsden \
	echo darcsden-volumes
```

Now we start the front proxy.

Keep in mind that the certificates must be named according to the hostname
of the darcsden instance (e.g. if you access it via `https://darcsden.foo.com`,
then you name them `darcsden.foo.crt` and `darcsden.foo.key`).
```sh
docker pull hasufell/gentoo-nginx-proxy

docker run -ti -d \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <path-to-nginx-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/gentoo-nginx-proxy
```

Now we can start the darcsden instance:
```sh
docker run -ti -d \
	--volumes-from darcsden-volumes \
	-e FIRST_RUN=yes \
	-e DARCSDEN_SSH_PORT=<sshport> \
	-e VIRTUAL_HOSTNAME=<hostname> \
	-e VIRTUAL_PORT=<host-port> \
	-p <sshport>:<sshport> \
	hasufell/gentoo-darcsden
```

Whenever you run it at a later time with the same data volumes,
omit `-e FIRST_RUN=yes`.
