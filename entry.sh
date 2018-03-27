#!/bin/bash -e

# Re-configuration

# Default password
echo 'Updating default_password'
xmlstarlet ed -L -u \
  "/include/X-PRE-PROCESS[@data = 'default_password=1234']/@data" \
  -v "default_password=$DEFAULT_PASSWORD" \
    /usr/local/freeswitch/conf/vars.xml

# timerfd support
# https://wiki.freeswitch.org/wiki/Mod_timerfd
if [ "$SOFTTIMER_TIMERFD" = 'true' ]; then
  echo 'Enabling softtimer-timerfd'
  sed -i 's%<!-- <param name="enable-softtimer-timerfd" value="true"/> -->%<param name="enable-softtimer-timerfd" value="true"/>%g' /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
fi


# GCP support

if [ "$GCP" = 'true' ]; then
  echo 'Updating configuration for GCP VM'
  
  # vars.xml modification
  gcp_external_ip=$(curl --header "Metadata-Flavor : Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  sed -i 's@<X-PRE-PROCESS cmd="set" data="domain=$${local_ip_v4}"/>@<X-PRE-PROCESS cmd="set" data="domain='"$gcp_external_ip"'"/>@' /usr/local/freeswitch/conf/vars.xml

  # sip_profiles/internal.xml modifications
   
   sed -i 's@<param name="ext-rtp-ip" value="auto-nat"/>@<param name="ext-rtp-ip" value="autonat:'"$gcp_external_ip"'"/>@' /usr/local/freeswitch/conf/sip_profiles/internal.xml
   sed -i 's@<param name="ext-sip-ip" value="auto-nat"/>@<param name="ext-sip-ip" value="autonat:'"$gcp_external_ip"'"/>@' /usr/local/freeswitch/conf/sip_profiles/internal.xml   

fi







# EC2 support
# https://freeswitch.org/confluence/display/FREESWITCH/Amazon+EC2
if [ "$EC2" = 'true' ]; then
  echo 'Updating configuration for EC2'
  # bind_server_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'bind_server_ip=auto']/@cmd" \
    -v "exec-set" \
      /usr/local/freeswitch/conf/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'bind_server_ip=auto']/@data" \
    -v "bind_server_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /usr/local/freeswitch/conf/vars.xml

  # external_rtp_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_rtp_ip=stun:stun.freeswitch.org']/@cmd" \
    -v "exec-set" \
      /usr/local/freeswitch/conf/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_rtp_ip=stun:stun.freeswitch.org']/@data" \
    -v "external_rtp_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /usr/local/freeswitch/conf/vars.xml

  # external_sip_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_sip_ip=stun:stun.freeswitch.org']/@cmd" \
    -v "exec-set" \
      /usr/local/freeswitch/conf/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_sip_ip=stun:stun.freeswitch.org']/@data" \
    -v "external_sip_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /usr/local/freeswitch/conf/vars.xml

  # sip_profiles/internal.xml modifications
  sed -i 's%<!--<param name="aggressive-nat-detection" value="true"/>-->%<param name="aggressive-nat-detection" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<!--<param name="multiple-registrations" value="contact"/>-->%<param name="multiple-registrations" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<param name="ext-rtp-ip" value="auto-nat"/>%<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<param name="ext-sip-ip" value="auto-nat"/>%<param name="ext-sip-ip" value="$${external_sip_ip}"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-received-in-nat-reg-contact" value="true"/>-->%<param name="NDLB-received-in-nat-reg-contact" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-force-rport" value="true"/>-->%<param name="NDLB-force-rport" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-broken-auth-hash" value="true"/>-->%<param name="NDLB-broken-auth-hash" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<!--<param name="enable-timer" value="false"/>-->%<param name="enable-timer" value="false"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml
  sed -i 's%<param name="auth-calls" value="$${internal_auth_calls}"/>%<param name="auth-calls" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/internal.xml

  # sip_profiles/external.xml
  sed -i 's%<!--<param name="aggressive-nat-detection" value="true"/>-->%<param name="aggressive-nat-detection" value="true"/>%g' /usr/local/freeswitch/conf/sip_profiles/external.xml
  sed -i 's%<param name="ext-rtp-ip" value="auto-nat"/>%<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>%g' /usr/local/freeswitch/conf/sip_profiles/external.xml
  sed -i 's%<param name="ext-sip-ip" value="auto-nat"/>%<param name="ext-sip-ip" value="$${external_sip_ip}"/>%g' /usr/local/freeswitch/conf/sip_profiles/external.xml

  # todo: add this
  # <param name="NDLB-force-rport" value="true"/>

  # autoload_configs/switch.conf.xml
  sed -i 's%<!-- <param name="rtp-start-port" value="16384"/> -->%<param name="rtp-start-port" value="16384"/>%g' /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
  sed -i 's%<!-- <param name="rtp-end-port" value="32768"/> -->%<param name="rtp-end-port" value="32768"/>%g' /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
fi

# overlay configuration
if [ ! -z "$CONFIG_OVERLAY_GIT_URI" ]; then
  echo 'Overlaying custom configuration repository'
  if [ ! -z "$CONFIG_OVERLAY_GIT_PRIVATE_KEY" ]; then
    mkdir -p /root/.ssh
    echo "$CONFIG_OVERLAY_GIT_PRIVATE_KEY" > /root/.ssh/id_rsa
    chmod 400 /root/.ssh/id_rsa
  fi

  # Create known_hosts
  touch /root/.ssh/known_hosts

  # this is not secure, but lets do for common defaults
  # Add bitbucket's key
  ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts
  # Add github's key
  ssh-keyscan github.com >> /root/.ssh/known_hosts

  # clone the repository or pull if already existing
  mkdir -p /root/src
  if [ -e /root/src/fs-custom ]; then
    echo 'Performing a pull on existing clone'
    pushd "/root/src/fs-custom"
      git pull
    popd
  else
    echo 'Performing fresh clone'
    pushd "/root/src"
      git clone "$CONFIG_OVERLAY_GIT_URI" fs-custom
    popd
  fi

  # currently, we'll only support copying from etc
  cp -Rvf /root/src/fs-custom/etc/* /etc/
fi

echo executing: "$@"
exec "$@"
