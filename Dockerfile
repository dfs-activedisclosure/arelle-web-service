FROM python:3.5.5-alpine3.4

LABEL AUTHOR="James White"

ENV DFS_ARELLE https://github.com/dfs-activedisclosure/Arelle
ENV DFS_EDGARRENDER https://github.com/dfs-activedisclosure/EdgarRenderer
ENV RENDERER_BRANCH edgr181
EXPOSE 8080

COPY pip.requirements.txt /pip.requirements.txt

RUN apk add --update \
  build-base \
  gcc \
  git \
  libxml2-dev \
  libxslt-dev \
  freetype-dev libpng-dev \
  && rm -rf /var/cache/apk/*

RUN pip3 install --upgrade pip

RUN pip3 install -r pip.requirements.txt

RUN mkdir app

WORKDIR app

RUN git clone --recursive $DFS_ARELLE . \
  && git clone -b $RENDERER_BRANCH --recursive --single-branch $DFS_EDGARRENDER ./arelle/plugin/EdgarRenderer

RUN python3 setup.py install

COPY taxonomies .
COPY docker-setup.sh .

ENTRYPOINT ["/bin/sh"]

CMD ["docker-setup.sh"]
