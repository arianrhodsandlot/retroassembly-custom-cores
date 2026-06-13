.PHONY: all

CORES ?= a5200 prosystem stella2014 mupen64plus_next

all: build_cores archive

build_cores:
	./scripts/build-cores.sh $(CORES)

archive:
	./scripts/archive.sh
