FROM perl:5.22
ENV port=80 appdir=/root/app

RUN mkdir -p $appdir
ADD . $appdir/

EXPOSE $port
WORKDIR $appdir
RUN perl Makefile.PL && make clean && cpanm . --notest
ENTRYPOINT ["plackup", "-R lib/", "-p $port", "bin/app.psgi"]
