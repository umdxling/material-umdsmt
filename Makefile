# This Makefile is used inside the Docker container to build MarianNMT,
# and other tools (e.g. moses, subword-nmt, sentencepiece, etc). It also
# includes steps to make it quicker to rerun the docker build and docker run
# commands themselves.

#expose environment variables for docker build and run in this Makefile
include configs/env_build.sh
export $(shell sed 's/=.*//' configs/env_build.sh)


all: tools systems

# docker
docker-build:
	docker build -t umd-smt:${DOCKER_VERSION} -f Dockerfile .

docker-save:
	docker save umd-smt:$(DOCKER_VERSION) > umd-smt:$(DOCKER_VERSION).tar

#other tools
tools: tools/moses tools/moses-scripts tools/uroman

tools/moses:
	wget -q $(MOSES_BIN_URL) && tar -zxf $(MOSES_BIN_NAME)
tools/moses-scripts:
	git clone $(MOSES_REPO_URL) -b $(MOSES_BRANCH_NAME) $@
tools/uroman:
	git clone $(UROMAN_REPO_URL) -b $(UROMAN_BRANCH_NAME) $@

.PHONY: all systems.$(MODEL_VERSION) tools