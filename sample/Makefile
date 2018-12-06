STACK_NAME = scheme-sample

deploy:
	aws cloudformation package --template-file template.yml --output-template-file packaged-template.yml --s3-bucket $(S3_BUCKET)
	aws cloudformation deploy --template-file packaged-template.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM
