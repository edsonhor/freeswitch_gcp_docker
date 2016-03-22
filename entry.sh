#!/bin/sh -e

# Re-configuration

# Default password
xmlstarlet ed -L -u \
  "/include/X-PRE-PROCESS[@data = 'default_password=1234']/@data" \
  -v "default_password=$DEFAULT_PASSWORD" \
    /etc/freeswitch/vars.xml

# EC2 support
# https://freeswitch.org/confluence/display/FREESWITCH/Amazon+EC2
if [ "$EC2" = 'yes' ]; then
  # bind_server_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'bind_server_ip=auto']/@cmd" \
    -v "exec-set" \
      /etc/freeswitch/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'bind_server_ip=auto']/@data" \
    -v "bind_server_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /etc/freeswitch/vars.xml

  # external_rtp_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_rtp_ip=stun:stun.freeswitch.org']/@cmd" \
    -v "exec-set" \
      /etc/freeswitch/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_rtp_ip=stun:stun.freeswitch.org']/@data" \
    -v "external_rtp_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /etc/freeswitch/vars.xml

  # external_sip_ip
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_sip_ip=stun:stun.freeswitch.org']/@cmd" \
    -v "exec-set" \
      /etc/freeswitch/vars.xml
  xmlstarlet ed -L -u \
    "/include/X-PRE-PROCESS[@data = 'external_sip_ip=stun:stun.freeswitch.org']/@data" \
    -v "external_sip_ip=curl -s http://instance-data/latest/meta-data/public-ipv4" \
      /etc/freeswitch/vars.xml

  # sip_profiles/internal.xml modifications
  sed -i 's%<!--<param name="aggressive-nat-detection" value="true"/>-->%<param name="aggressive-nat-detection" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<!--<param name="multiple-registrations" value="contact"/>-->%<param name="multiple-registrations" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<param name="ext-rtp-ip" value="auto-nat"/>%<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<param name="ext-sip-ip" value="auto-nat"/>%<param name="ext-sip-ip" value="$${external_sip_ip}"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-received-in-nat-reg-contact" value="true"/>-->%<param name="NDLB-received-in-nat-reg-contact" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-force-rport" value="true"/>-->%<param name="NDLB-force-rport" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<!--<param name="NDLB-broken-auth-hash" value="true"/>-->%<param name="NDLB-broken-auth-hash" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<!--<param name="enable-timer" value="false"/>-->%<param name="enable-timer" value="false"/>%g' /etc/freeswitch/sip_profiles/internal.xml
  sed -i 's%<param name="auth-calls" value="$${internal_auth_calls}"/>%<param name="auth-calls" value="true"/>%g' /etc/freeswitch/sip_profiles/internal.xml

  # sip_profiles/external.xml
  sed -i 's%<!--<param name="aggressive-nat-detection" value="true"/>-->%<param name="aggressive-nat-detection" value="true"/>%g' /etc/freeswitch/sip_profiles/external.xml
  sed -i 's%<param name="ext-rtp-ip" value="auto-nat"/>%<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>%g' /etc/freeswitch/sip_profiles/external.xml
  sed -i 's%<param name="ext-sip-ip" value="auto-nat"/>%<param name="ext-sip-ip" value="$${external_sip_ip}"/>%g' /etc/freeswitch/sip_profiles/external.xml

  # todo: add this
  # <param name="NDLB-force-rport" value="true"/>

  # autoload_configs/switch.conf.xml
  sed -i 's%<!-- <param name="rtp-start-port" value="16384"/> -->%<param name="rtp-start-port" value="16384"/>%g' /etc/freeswitch/autoload_configs/switch.conf.xml
  sed -i 's%<!-- <param name="rtp-end-port" value="32768"/> -->%<param name="rtp-end-port" value="32768"/>%g' /etc/freeswitch/autoload_configs/switch.conf.xml
fi

freeswitch -c $ADDITIONAL_OPTS