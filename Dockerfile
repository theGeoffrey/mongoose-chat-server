from mongooseim/mongooseim-docker/

maintainer Benjamin Kampmann <ben@create-build-execute.com>

ONBUILD ADD *.cfg /usr/lib/mongooseim/etc
ONBUILD ADD ext_auth /usr/bin

EXPOSE 80