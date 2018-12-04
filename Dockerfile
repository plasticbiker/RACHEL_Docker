FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
ENV KIWIX_VER 0.9

ENV USER "rachel"
ENV PASS "rachel"
ENV HOSTNAME "rachel"

#COPY ka-lite-bundle_0.17.5-0ubuntu1_all.deb /tmp/


ENV RUNTIME_PKGS "apache2 ca-certificates php-cgi php-common php-sqlite3 php-curl php-dev php-pear pdftk make git git-core git-man " \ 
                 "liberror-perl python-m2crypto sqlite3 gcc-multilib gcc-4.8-base gcj-4.8-jre-lib libgcj14 libgcj-common libasound2 " \ 
                 "exfat-fuse exfat-utils python2.7 python-pip  python-pkg-resources net-tools curl bzip2 supervisor perl "

RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
#RUN { \
#        echo debconf debconf/frontend select Noninteractive; \
#        echo mysql-community-server mysql-community-server/data-dir select ''; \
#        echo mysql-community-server mysql-community-server/root-pass password 'RachelProject'; \
#        echo mysql-community-server mysql-community-server/re-root-pass password 'RachelProject'; \
#        echo mysql-community-server mysql-community-server/remove-test-db select true; \
#    } | debconf-set-selections \

RUN apt-get update && apt-get install -y --no-install-recommends ${RUNTIME_PKGS} 
RUN set -x \
 && mkdir /var/log/rachel/ \
 && rm /var/www/html/index.html \
 && cd /tmp/ \
 && useradd -ms /bin/bash rachel \
 && echo "===> Downloading RachelpiOS files..." \
 && git clone https://github.com/rachelproject/rachelpiOS.git \ 
 #
 && echo "===> Installing Rachel ContentShell..." \
 && git clone https://github.com/rachelproject/contentshell.git \
 && mv /tmp/contentshell/* /var/www/html/ \
 #
 && echo "===> Installing KA-Lite...." \
 #&& wget https://learningequality.org/r/deb-bundle-installer-0-17 \
 #&& dpkg -i /tmp/ka-lite-bundle_0.17.5-0ubuntu1_all.deb \
 #&& apt-get install -f \
 && pip install ka-lite-static \
 # Yes for continue and install as root
 # No for download content
 #     No for Do you have content
 # No for Starting the server
 && printf '\nyes\nno\nno\nno\n' | kalite manage setup --username=${USER} --password=${PASS} --hostname=${HOSTNAME} --description=${HOSTNAME} \
 && echo "\n" \
 && mkdir -p /etc/ka-lite \
 && echo root > /etc/ka-lite/username \
 && /usr/local/bin/kalite --version > /etc/kalite-version \
 && echo "\n" \
 # 
 && echo "===> Installing kwiki..." \
 && cd /tmp/ \
 && curl -o kiwix-${KIWIX_VER}-linux-x86_64.tar.bz2 -L "http://downloads.sourceforge.net/project/kiwix/${KIWIX_VER}/kiwix-${KIWIX_VER}-linux-x86_64.tar.bz2" \
 && tar -jxf "kiwix-${KIWIX_VER}-linux-x86_64.tar.bz2" \
 && mv /tmp/kiwix /var/ \
 && cp /tmp/rachelpiOS/files/kiwix-sample.zim /var/kiwix/sample.zim \
 && cp /tmp/rachelpiOS/files/kiwix-sample-library.xml /var/kiwix/sample-library.xml \
 && cp /tmp/rachelpiOS/files/rachel-kiwix-start.pl /var/kiwix/bin/rachel-kiwix-start.pl \
 && chmod +x /var/kiwix/bin/rachel-kiwix-start.pl \
 && echo "${KIWIX_VER}" > /etc/kiwix-version \
 #
 && echo "===> Cleaning up..." \
 && rm -rf /tmp/* \
 && rm -rf /var/lib/apt/lists/* 

 COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf


 EXPOSE 80/tcp
 CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
 

