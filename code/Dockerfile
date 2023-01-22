FROM perl:5.36.0

RUN cpanm Path::Tiny@0.144
RUN cpanm JSON::Validator@5.13
RUN cpanm LWP::UserAgent@6.67
RUN cpanm LWP::Protocol::https@6.10
RUN cpanm XML::Simple@2.25

COPY . /app/

WORKDIR /app/

CMD perl -I/app/lib/ /app/bin/app.pl
