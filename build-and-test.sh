#!/usr/bin/env bash

set -xe

# Let's replace the "." by a "-" with some bash magic
export BRANCH_VARIANT=`echo "$VARIANT" | sed 's/\./-/g'`

# Let's build the "slim" image.
docker build -t thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} --build-arg PHP_VERSION=${PHP_VERSION} --build-arg GLOBAL_VERSION=${BRANCH} -f Dockerfile.slim.${VARIANT} .

# Post build unit tests

# Let's check that the extensions can be built using the "ONBUILD" statement
docker build -t test/slim_onbuild --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/slim_onbuild
# This should run ok (the sudo disable environment variables but call to composer proxy does not trigger PHP ini file regeneration)
docker run --rm test/slim_onbuild php -m | grep sockets
docker run --rm test/slim_onbuild php -m | grep pdo_pgsql
docker run --rm test/slim_onbuild php -m | grep pdo_sqlite
docker rmi test/slim_onbuild

# Post build unit tests
if [[ $VARIANT == cli* ]]; then CONTAINER_CWD=/usr/src/app; else CONTAINER_CWD=/var/www/html; fi
# Root user is 0
RESULT=`docker run --rm thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} id -ur`
[[ "$RESULT" = "0" ]]

# Let's check that mbstring is enabled by default (they are compiled in PHP)
docker run --rm thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} php -m | grep mbstring
docker run --rm thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} php -m | grep PDO
#docker run --rm thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} php -m | grep pdo_sqlite

if [[ $VARIANT == apache* ]]; then
    # Test if environment variables are passed to PHP
    # DOCKER_CID=`docker run --rm -e MYVAR=foo -p "81:80" -d -v $(pwd):/var/www/html thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}`

    # Let's wait for Apache to start
    # sleep 5

    # RESULT=`curl http://localhost:81/tests/test.php`
    # [[ "$RESULT" = "foo" ]]
    # docker stop $DOCKER_CID


    # Test Apache document root (relative)
    DOCKER_CID=`docker run --rm -e MYVAR=foo -p "81:80" -d -v $(pwd):/var/www/html -e APACHE_DOCUMENT_ROOT=tests thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}`
    # Let's wait for Apache to start
    sleep 5
    RESULT=`curl http://localhost:81/test.php`
    [[ "$RESULT" = "foo" ]]
    docker stop $DOCKER_CID

    # Test Apache document root (absolute)
    DOCKER_CID=`docker run --rm -e MYVAR=foo -p "81:80" -d -v $(pwd):/var/www/foo -e APACHE_DOCUMENT_ROOT=/var/www/foo/tests thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}`
    # Let's wait for Apache to start
    sleep 5
    RESULT=`curl http://localhost:81/test.php`
    [[ "$RESULT" = "foo" ]]
    docker stop $DOCKER_CID

    # Test Apache HtAccess
    DOCKER_CID=`docker run --rm -p "81:80" -d -v $(pwd)/tests/testHtAccess:/foo -e APACHE_DOCUMENT_ROOT=/foo thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}`
    # Let's wait for Apache to start
    sleep 5
    RESULT=`curl http://localhost:81/`
    [[ "$RESULT" = "foo" ]]
    docker stop $DOCKER_CID
fi

if [[ $VARIANT == fpm* ]]; then
    # Test if environment starts without errors
    DOCKER_CID=`docker run --rm -p "9000:9000" -d -v $(pwd):/var/www/html thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT}`

    # Let's wait for FPM to start
    sleep 5

    # If the container is still up, it will not fail when stopping.
    docker stop $DOCKER_CID
fi

# Tests that disable_functions is commented in php.ini cli
RESULT=`docker run --rm thecodingmachine/php:${PHP_VERSION}-${BRANCH}-slim-${BRANCH_VARIANT} php -i | grep "disable_functions"`
[[ "$RESULT" = "disable_functions => no value => no value" ]]

#################################
# Let's build the "fat" image
#################################
docker build -t thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT} --build-arg PHP_VERSION=${PHP_VERSION} --build-arg GLOBAL_VERSION=${BRANCH} -f Dockerfile.${VARIANT} .

# Let's check that mbstring cannot extension cannot be disabled
set +e
docker run --rm -e PHP_EXTENSION_MBSTRING=0 thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT} php -i
[[ "$?" = "1" ]]
set -e

# Let's check that the extensions are enabled when composer is run
docker build -t test/composer_with_gd --build-arg PHP_VERSION="${PHP_VERSION}" --build-arg BRANCH="$BRANCH" --build-arg BRANCH_VARIANT="$BRANCH_VARIANT" tests/composer

# This should run ok (the sudo disables environment variables but call to composer proxy does not trigger PHP ini file regeneration)
docker run --rm test/composer_with_gd sudo composer update
docker rmi test/composer_with_gd

#################################
# Let's build the "node" images
#################################
docker build -t thecodingmachine/php:${PHP_VERSION}-${BRANCH}-${BRANCH_VARIANT}-node12 --build-arg PHP_VERSION=${PHP_VERSION} --build-arg GLOBAL_VERSION=${BRANCH} -f Dockerfile.${VARIANT}.node12 .

echo "Tests passed with success"
