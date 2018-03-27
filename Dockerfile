FROM debian:jessie

ENV EC2 false
ENV GCP true
ENV SOFTTIMER_TIMERFD true
ENV DEFAULT_PASSWORD 1234
ENV DEBIAN_FRONTEND noninteractive

# Note, the additional packages are installed for use case reasons:
# - xmlstarlet for XML manipulation via ENTRYPOINT
# - git for overly configuration from a git repository
# - vim for dev/test editing in the fs container
# - docker run -it --net=host --name freeswitch freeswitch

RUN apt-get update && apt-get -y install curl wget && \
      curl https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add - && \
      echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.6/ jessie main" > /etc/apt/sources.list.d/freeswitch.list && \
      apt-get -y update && apt-get -y upgrade && \
      apt-get -y install xmlstarlet git vim 



# manually get the code and compile it

RUN wget -O - https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add - && \
echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.6/ jessie main" > /etc/apt/sources.list.d/freeswitch.list && \
apt-get update && \
apt-get install -y --force-yes freeswitch-video-deps-most && \
#freeswitch-all freeswitch-all-dbg gdb && \
      rm -rf /var/lib/apt/lists/* && \

# then let's get the source. Use the -b flag to get a specific branch
cd /etc/  && \
git clone https://freeswitch.org/stash/scm/fs/freeswitch.git -bv1.6 freeswitch && \
cd freeswitch && \
 
# Because we're in a branch that will go through many rebases, it's
# better to set this one, or you'll get CONFLICTS when pulling (update).
git config pull.rebase true && \
 
# ... and do the build
./bootstrap.sh -j && \
./configure && \
make && \
make install 

   

VOLUME /etc/freeswitch
VOLUME /var/lib/freeswitch
VOLUME /var/log/freeswitch
VOLUME /usr/share/freeswitch

EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5066/tcp 7443/tcp
EXPOSE 8021/tcp

WORKDIR /usr/local/freeswitch/bin

# RTP port range
EXPOSE 16384-32768/udp

COPY entry.sh /opt/local/bin/entry.sh
COPY reload.sh /opt/local/bin/reload.sh

ENTRYPOINT ["/opt/local/bin/entry.sh"]

CMD ["/usr/local/freeswitch/bin/freeswitch", "-c", "-nf"]
