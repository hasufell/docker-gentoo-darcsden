FROM       hasufell/gentoo-amd64-paludis:latest
MAINTAINER Julian Ospald <hasufell@gentoo.org>

##### PACKAGE INSTALLATION #####

# copy paludis config
COPY ./config/paludis /etc/paludis

# update world with our USE flags
RUN chgrp paludisbuild /dev/tty && cave resolve -c world -x

# temporary workaround bug #561436
RUN chgrp paludisbuild /dev/tty && cave resolve -z -1 \
	sys-devel/autoconf-archive -x

# install darcsden dependencies
RUN chgrp paludisbuild /dev/tty && cave resolve -c darcsden \
	-F 'mail-mta/ssmtp' -x

# install tools set
RUN chgrp paludisbuild /dev/tty && cave resolve -c tools -x

# update etc files... hope this doesn't screw up
RUN etc-update --automode -5

################################


## configure mailer
COPY config/mailer.conf /etc/ssmtp/ssmtp.conf

RUN useradd --system -m -d /home/darcsden \
	--shell /bin/bash --user-group darcsden

# update cabal package list
RUN sudo -u darcsden cabal update

# install darcs
RUN sudo -u darcsden cabal install --force-reinstalls darcs

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

CMD /setup.sh && exec /usr/bin/supervisord -n -c /etc/supervisord.conf
