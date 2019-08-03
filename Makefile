IMAGE := andrewthetechie/auto-annotator

test:
	true

build:
	docker build -t $(IMAGE) .

push-image:
	docker push $(IMAGE)


.PHONY: image push-image test