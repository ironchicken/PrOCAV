FROM debian:sid
MAINTAINER Richard Lewis, richard@rjlewis.me.uk

RUN apt-get update && apt-get install -y \
    && apt-get install -y apt-utils debconf-utils \
    && echo mysql-server-5.7 mysql-server/root_password password mysql | debconf-set-selections \
    && echo mysql-server-5.7 mysql-server/root_password_again password mysql | debconf-set-selections \
    && apt-get install -y mysql-server-5.7 -o pkg::Options::="--force-confdef" -o pkg::Options::="--force-confold" --fix-missing \
    && apt-get install -y net-tools --fix-missing

RUN apt-get install -y perl \
    build-essential \
    cpanminus \
    apache2

RUN apt-get install -y locales \
    && locale-gen en_US.UTF-8 en_us \
    && dpkg-reconfigure locales && \
    dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get install -y \
    libxml2 \
    libxml2-dev \
    zlib1g \
    zlib1g-dev \
    swish-e \
    swish-e-dev \
    libspreadsheet-xlsx-perl \
    libexcel-writer-xlsx-perl \
    libapache2-request-perl \
    libapache2-mod-perl2 \
    libdbd-mysql-perl \
    libxml-sax-machines-perl \
    libxml-generator-perl \
    libxml-filter-xslt-perl \
    libfile-spec-native-perl \
    libarray-utils-perl \
    libyaml-syck-perl \
    libpath-class-file-stat-perl \
    libdata-dump-perl \
    libclass-inspector-perl \
    libclass-accessor-perl \
    libclass-isa-perl \
    libsub-uplevel-perl \
    libtest-warn-perl \
    libmodule-install-perl \
    libmime-types-perl \
    librose-object-perl \
    librose-datetime-perl \
    libxml-simple-perl \
    libmodule-pluggable-perl \
    libdata-transformer-perl \
    libconfig-general-perl \
    libdata-uuid-perl

RUN cpanm --verbose \
    Text::Sprintf::Named \
    XML::Generator::PerlData \
    File::Rules \
    Rose::ObjectX::CAF \
    Encoding::FixLatin \
    SWISH::Prog::Indexer

COPY schema/procav-schema.sql /tmp/procav-schema.sql
RUN service mysql start \
    && mysqladmin -u root -pmysql create pcda \
    && mysql -u root -pmysql pcda < /tmp/procav-schema.sql

COPY web/apache.conf /etc/apache2/sites-available/pcda.conf
RUN a2enmod perl \
    && a2dissite 000-default.conf \
    && a2ensite pcda.conf \
    && service apache2 stop

VOLUME ["/var/www/pcda"]
EXPOSE 80
EXPOSE 3306

RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log

ENTRYPOINT cd /var/www/pcda/perl \
	   && service mysql start \
   	   && mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'mysql';" \
	   && service mysql stop \
	   && /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --sql-mode=NO_ENGINE_SUBSTITUTION --log-error=/var/log/mysql/error.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --bind-address=0.0.0.0 --port=3306 --log-syslog=1 --log-syslog-facility=daemon --log-syslog-tag=mysql \
	   & /usr/sbin/apache2ctl -D FOREGROUND
