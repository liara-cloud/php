#!/bin/bash

set -e

if [[ "$APACHE_DOCUMENT_ROOT" == /* ]]; then
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="$APACHE_DOCUMENT_ROOT"
else
  export ABSOLUTE_APACHE_DOCUMENT_ROOT="/var/www/html/$APACHE_DOCUMENT_ROOT"
fi

/usr/local/bin/apache-expose-envvars.sh;
exec "$@";
