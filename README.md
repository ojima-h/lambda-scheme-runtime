# lambda-scheme-runtime

## Publish scheme runtime layer

```
make build
aws lambda publish-layer-version --layer-name scheme-runtime --zip-file fileb://build/runtime.zip
```

or, using SAM template:

```
make build
aws cloudformation package --template-file template.yml --output-template-file packaged-template.yml --s3-bucket YOUR_S3_BUCKET
aws cloudformation deploy --template-file packaged-template.yml --stack-name scheme-runtime
```

## Deploy sample function

```
aws cloudformation package --template-file template.yml --output-template-file packaged-template.yml --s3-bucket YOUR_S3_BUCKET
aws cloudformation deploy --template-file packaged-template.yml --stack-name scheme-runtime-sample --capabilities CAPABILITY_IAM
```

## Test sample function

```
curl https://API_GATEWAY_ENDPOINT/Prod/pythagorean-triples?length=3

#=> {"result":[[3,4,5],[6,8,10],[5,12,13]]}
```
