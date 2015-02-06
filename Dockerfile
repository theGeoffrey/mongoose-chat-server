FROM mongooseim/mongooseim-docker

MAINTAINER Benjamin Kampmann <ben@create-build-execute.com>

ONBUILD ADD ./vars.cfg /usr/lib/mongooseim/etc
ONBUILD ADD ./ext_auth /usr/bin

EXPOSE 80