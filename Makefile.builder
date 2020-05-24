ifeq ($(DIST),gentoo)
    GENTOO_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := gentoo
    BUILDER_MAKEFILE = $(GENTOO_PLUGIN_DIR)Makefile.gentoo
    TEMPLATE_SCRIPTS = $(GENTOO_PLUGIN_DIR)scripts
endif

# vim: ft=make
