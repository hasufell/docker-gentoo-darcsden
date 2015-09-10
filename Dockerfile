FROM       hasufell/gentoo-amd64-paludis:latest
MAINTAINER Julian Ospald <hasufell@gentoo.org>

# global flags
RUN echo -e "*/* acl bash-completion ipv6 kmod openrc pcre readline unicode \
zlib pam ssl sasl bzip2 urandom crypt tcpd \
-acpi -cairo -consolekit -cups -dbus -dri -gnome -gnutls -gtk -gtk2 -gtk3 \
-ogg -opengl -pdf -policykit -qt3support -qt5 -qt4 -sdl -sound -systemd \
-truetype -vim -vim-syntax -wayland -X" \
	>> /etc/paludis/use.conf

# per-package flags
# check these with "cave show <package-name>"
RUN mkdir /etc/paludis/use.conf.d && \
	echo -e "dev-lang/ghc binary gmp" \
	>> /etc/paludis/use.conf.d/darcsden.conf

RUN mkdir /etc/paludis/keywords.conf.d && \
	echo -e "~dev-lang/ghc-7.8.4 ~amd64 \
\ndev-haskell/* ~amd64 \
\ndev-db/redis ~amd64 \
\ndev-db/couchdb ~amd64 \
" \
	>> /etc/paludis/keywords.conf.d/darcsden.conf

# install ghc, cabal and system darcsden dependencies
RUN chgrp paludisbuild /dev/tty && \
	cave resolve -z --favour 'mail-mta/sendmail' \
	dev-lang/ghc \
	dev-haskell/cabal \
	dev-haskell/cabal-install \
	mail-mta/sendmail \
	virtual/mta \
	dev-db/couchdb \
	dev-db/redis \
	-x

# install tools
RUN chgrp paludisbuild /dev/tty && \
	cave resolve -z \
	app-admin/sudo \
	app-admin/supervisor \
	sys-process/htop \
	-x

RUN useradd --system -m -d /home/darcsden \
	--shell /bin/bash --user-group darcsden

# update cabal package list
RUN sudo -u darcsden cabal update

# install darcs
RUN sudo -u darcsden cabal install darcs

# add ~/.cabal/bin to PATH
RUN sudo -u darcsden echo 'export PATH="~/.cabal/bin:$PATH"' >> /home/darcsden/.bashrc

# install darcsden
RUN sudo -u darcsden sh -c "cd && ~/.cabal/bin/darcs get http://hub.darcs.net/simon/darcsden"
RUN sudo -u darcsden sh -c "cd ~/darcsden && \
	cabal install happy hsx2hs && cabal install -fssh"
RUN cp /home/darcsden/.cabal/bin/* /usr/local/bin/
RUN mkdir /var/log/darcsden && chown darcsden:darcsden /var/log/darcsden && \
	mkdir /home/darcsden/users/ && chown darcsden:darcsden /home/darcsden/users/

# fix couchdb permissions
RUN chown couchdb /var/run/couchdb/

# supervisor config
COPY ./supervisord.conf /etc/supervisord.conf

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

EXPOSE 8900

CMD /setup.sh && /usr/bin/supervisord -n -c /etc/supervisord.conf
