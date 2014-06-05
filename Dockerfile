# Nagios and Pnp4Nagios docker file
#
# Version 0.1

FROM itoshkov/docker-ubuntu:14.04

MAINTAINER Ivan Toshkov <ivan@toshkov.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -y pnp4nagios nagios-plugins runit libxml2-dev libxml-libxml-perl libconfig-general-perl make libyaml-perl libfile-searchpath-perl libjson-perl libtest-lwp-useragent-perl libmodule-find-perl libnagios-plugin-perl libsys-sigaction-perl libterm-clui-perl libterm-shellui-perl libterm-size-perl

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

# download and build Crypth::Blowfish_PP
ADD http://mirror.sbb.rs/CPAN/authors/id/M/MA/MATTBM/Crypt-Blowfish_PP-1.12.tar.gz /root/

RUN tar -xvf /root/Crypt-Blowfish_PP-1.12.tar.gz -C /root
RUN cd /root/Crypt-Blowfish_PP-1.12 && perl Makefile.PL
RUN cd /root/Crypt-Blowfish_PP-1.12 && make
RUN cd /root/Crypt-Blowfish_PP-1.12 && make test
RUN cd /root/Crypt-Blowfish_PP-1.12 && make install

# download jmx4perl
ADD http://search.cpan.org/CPAN/authors/id/R/RO/ROLAND/jmx4perl-1.07.tar.gz /root/

# extract jmx4perl
RUN tar -xvf /root/jmx4perl-1.07.tar.gz -C /root

# change default values for the list of features to install
RUN awk '/\$msg,"y"/{c+=1;done=0}{if(done==0 && (c>2 && c != 4) ){sub("\"y\"","\"n\"",$0);done=1};print}' /root/jmx4perl-1.07/Build.PL > /root/jmx4perl-1.07/BuildAnswered.PL

# install jmx4perl and j4psh
RUN cd /root/jmx4perl-1.07 ; PERL_MM_USE_DEFAULT=1 perl /root/jmx4perl-1.07/BuildAnswered.PL
RUN cd /root/jmx4perl-1.07 ; /root/jmx4perl-1.07/Build test
RUN cd /root/jmx4perl-1.07 ; /root/jmx4perl-1.07/Build install

# fix perl bizarre bug http://osdir.com/ml/network.nagios.devel/2007-07/msg00031.html
RUN sed -i s/+epn/-epn/g /usr/local/bin/check_jmx4perl

ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80

CMD ["/usr/bin/runsvdir", "/etc/sv"]
