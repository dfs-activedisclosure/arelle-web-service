FROM python:3.3-alpine

MAINTAINER Seosamh Cahill 

ENV GITHUB_ARELLE https://github.com/seocahill/Arelle.git

EXPOSE 8080

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  git \
  && rm -rf /var/cache/apk/*

RUN pip3 install --upgrade pip

RUN pip3 install lxml openPyXL rdflib

RUN mkdir app

WORKDIR app

RUN git clone --recursive $GITHUB_ARELLE . \
  && python3 setup.py install

COPY taxonomies .
COPY docker-setup.sh .

ENTRYPOINT ["/bin/sh"]

CMD ["docker-setup.sh"]
