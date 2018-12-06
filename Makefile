.PHONY: install build publish

STACK_NAME = scheme-runtime

build/runtime/racket:
	mkdir -p build/runtime
	docker run \
	  -v $$(pwd)/build/runtime:/build \
	  -w /build \
	  --rm \
	  amazonlinux \
	    sh -c \
	    'curl -o /tmp/racket.sh https://mirror.racket-lang.org/installers/7.1/racket-minimal-7.1-x86_64-linux.sh \
	    && chmod +x /tmp/racket.sh \
	    && echo yes | /tmp/racket.sh --in-place --dest racket'

install: build/runtime/racket

build: install
	rm -f build/runtime.zip
	(cd build/runtime && zip $(PWD)/build/runtime.zip -q -r .)
	zip build/runtime.zip runtime.scm bootstrap

publish: build
	aws lambda publish-layer-version --layer-name scheme-runtime --zip-file fileb://build/runtime.zip

deploy: build
	aws cloudformation package --template-file template.yml --output-template-file packaged-template.yml --s3-bucket $(S3_BUCKET)
	aws cloudformation deploy --template-file packaged-template.yml --stack-name $(STACK_NAME)
