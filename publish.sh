set -ex

PHP_VERSION=7.2 BRANCH=v3 VARIANT=apache ./build-and-test.sh
PHP_VERSION=7.3 BRANCH=v3 VARIANT=apache ./build-and-test.sh
PHP_VERSION=7.4 BRANCH=v3 VARIANT=apache ./build-and-test.sh

echo '> Tagging images...'
docker tag thecodingmachine/php:7.2-v3-apache-node12 liaracloud/php:7.2-apache-node12
docker tag thecodingmachine/php:7.3-v3-apache-node12 liaracloud/php:7.3-apache-node12
docker tag thecodingmachine/php:7.4-v3-apache-node12 liaracloud/php:7.4-apache-node12

docker push liaracloud/php:7.2-apache-node12
docker push liaracloud/php:7.3-apache-node12
docker push liaracloud/php:7.4-apache-node12
