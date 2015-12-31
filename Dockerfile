FROM perl:5.22
ENV port=5000 appdir=/root/app

RUN mkdir -p $appdir
ADD . $appdir/

EXPOSE $port
WORKDIR $appdir
RUN perl Makefile.PL && make clean && cpanm . --notest
ENTRYPOINT ["plackup", "-R lib/", "-p 5000", "bin/app.psgi"]
