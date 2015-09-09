## Getting the images

Just pull them:
```sh
docker pull hasufell/gentoo-darcsden
```

Or build them yourself:
```sh
docker build -t hasufell/gentoo-darcsden .
```

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

Now we start the real thing:
```sh
docker run -ti -d \
	--volumes-from darcsden-volumes \
	-e FIRST_RUN=yes \
	-p 8900:8900 \
	-p 22022:22022 \
	hasufell/gentoo-darcsden
```

Whenever you run it at a later time with the same data volumes,
omit `-e FIRST_RUN=yes`.

## Configuration

If you want to change the configuration, alter `darcsden.conf` and
rebuild the image or just mount it in from the host
via `-v "$(pwd)"/darcsden.conf:/home/darcsden/darcsden.conf`.
