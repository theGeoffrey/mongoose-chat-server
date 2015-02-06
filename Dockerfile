FROM mongooseim/mongooseim-docker

MAINTAINER Benjamin Kampmann <ben@create-build-execute.com>

ADD ./vars.cfg /usr/lib/mongooseim/etc
ADD ./ext_auth /usr/bin

EXPOSE 80