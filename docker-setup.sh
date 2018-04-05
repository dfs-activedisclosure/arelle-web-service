#! /bin/sh

# load up required taxonomies
# http://localhost:8080/rest/configure?packages=UK-ALL-2009-09-01-package.zip|ie-all-2012-12-01.zip
# localhost:8080/rest/configure?packages=show
# localhost:8080/rest/xbrl/validation?file=/taxonomies/vincent-ruane-builders-ltd-current-year-xbrl.html&media=json

# run the server
python3 arelleCmdLine.py --webserver 0.0.0.0:8080
