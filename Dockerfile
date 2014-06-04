# Nagios and Pnp4Nagios docker file
#
# Version 0.1

FROM itoshkov/docker-ubuntu:14.04

MAINTAINER Ivan Toshkov <ivan@toshkov.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -y pnp4nagios nagios-plugins runit

RUN htpasswd -c -b /etc/nagios3/htpasswd.users nagiosadmin nagios
RUN ln -sf /etc/pnp4nagios/nagios.cfg /etc/nagios3/conf.d/pnp4nagios.cfg
RUN ln -sf /etc/pnp4nagios/apache.conf /etc/apache2/conf-available/pnp4nagios.conf
RUN cd /etc/apache2/conf-enabled && ln -sf ../conf-available/pnp4nagios.conf .

ADD overrides/etc/nagios3/commands.cfg /etc/nagios3/commands.cfg
ADD overrides/etc/nagios3/nagios.cfg /etc/nagios3/nagios.cfg

RUN mkdir -p /etc/sv/nagios && mkdir -p /etc/sv/apache && rm -rf /etc/sv/getty-5 && mkdir -p /etc/sv/postfix && mkdir /etc/sv/npcd
ADD nagios.init /etc/sv/nagios/run
ADD apache.init /etc/sv/apache/run
ADD postfix.init /etc/sv/postfix/run
ADD postfix.stop /etc/sv/postfix/finish
ADD npcd.init /etc/sv/npcd/run

ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80

CMD ["/usr/bin/runsvdir", "/etc/sv"]
