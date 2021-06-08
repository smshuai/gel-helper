tag=$1
docker build -t smshuai/gel-helper:$tag .
docker push smshuai/gel-helper:$tag