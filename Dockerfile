FROM mongooseim/mongooseim-docker

MAINTAINER Benjamin Kampmann <ben@create-build-execute.com>

ENV LOGLEVEL 5
ENV MONGOOSE_ROOT /usr/lib/mongooseim
ENV PATH $MONGOOSE_ROOT/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get -y --no-install-recommends install \
        python2.7 \
        python-jinja2 \
    && rm -rf /var/lib/apt/lists/*


COPY ejabberd.cfg.tpl $MONGOOSE_ROOT/etc/ejabberd.cfg.tpl
COPY ext_auth $MONGOOSE_ROOT/bin/ext_auth

COPY run $MONGOOSE_ROOT/bin/run

EXPOSE 5000 8080

CMD ["live"]
ENTRYPOINT ["run"]