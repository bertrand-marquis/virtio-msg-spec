# -*- Mode: makefile -*-
#
# Basic Makefile to aid automation of document building
#

.PHONY: all
all:
	./makeall.sh

.PHONY: html
html:
	./makehtml.sh

.PHONY: clean
clean:
	git clean -fd

.PHONY: help
help:
	@echo "Build the VIRTIO specification documents."
	@echo ""
	@echo "Possible operations are:"
	@echo
	@echo " $(MAKE)         Build everything"
	@echo " $(MAKE) html    Build local html"
	@echo " $(MAKE) clean   Remove all intermediate files"
