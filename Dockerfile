FROM perl:5.22
ENV port=80 appdir=/root/app/

RUN mkdir -p $appdir
ADD . $appdir

EXPOSE $port
WORKDIR $appdir
RUN cpan .
ENTRYPOINT plackup -R lib/ -p $PORT bin/app.psgi
