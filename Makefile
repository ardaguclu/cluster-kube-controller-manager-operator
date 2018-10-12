GOFLAGS :=
DOCKER_ORG ?= openshift

all build:
	go build $(GOFLAGS) ./cmd/cluster-kube-controller-manager-operator
.PHONY: all build

verify-govet:
	go vet $(GOFLAGS) ./...
.PHONY: verify-govet

verify: verify-govet
	hack/verify-gofmt.sh
	hack/verify-codegen.sh
	hack/verify-generated-bindata.sh
.PHONY: verify

test test-unit:
ifndef JUNITFILE
	go test $(GOFLAGS) -race ./...
else
ifeq (, $(shell which gotest2junit 2>/dev/null))
$(error gotest2junit not found! Get it by `go get -u github.com/openshift/release/tools/gotest2junit`.)
endif
	go test $(GOFLAGS) -race -json ./... | gotest2junit > $(JUNITFILE)
endif
.PHONY: test-unit

images:
	imagebuilder -f Dockerfile -t $(DOCKER_ORG)/origin-cluster-kube-controller-manager-operator .
.PHONY: images

clean:
	$(RM) ./cluster-kube-controller-manager-operator
.PHONY: clean

, := ,
IMAGES ?= cluster-kube-controller-manager-operator
QUOTED_IMAGES=\"$(subst $(,),\"$(,)\",$(IMAGES))\"

origin-release:
	docker pull registry.svc.ci.openshift.org/openshift/origin-release:v4.0
	bash -c 'docker build -f <(sed "s/DOCKER_ORG/$(DOCKER_ORG)/g;s/IMAGES/$(QUOTED_IMAGES)/g" hack/lib/Dockerfile-origin-release) -t "$(DOCKER_ORG)/origin-release:latest" hack'
	docker push $(DOCKER_ORG)/origin-release:latest
	@echo
	@echo "To install:"
	@echo
	@echo "  DOCKER_ORG=$(DOCKER_ORG) make images"
	@echo "  docker push $(DOCKER_ORG)/origin-cluster-kube-controller-manager-operator"
	@echo "  OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=docker.io/$(DOCKER_ORG)/origin-release:latest bin/openshift-install cluster --log-level=debug"
