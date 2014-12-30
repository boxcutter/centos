# if Makefile.local exists, include it
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

ifndef PACKER
    PACKER := packer
endif

PACKER_VERSION = $(shell packer --version | sed 's/^.* //g' | sed 's/^.//')
ifneq (0.5.0, $(word 1, $(sort 0.5.0 $(PACKER_VERSION))))
$(error Packer version less than 0.5.x, please upgrade)
endif

CENTOS59_X86_64 ?= http://mirror.symnds.com/distributions/CentOS-vault/5.9/isos/x86_64/CentOS-5.9-x86_64-bin-DVD-1of2.iso
CENTOS59_I386 ?= http://mirror.symnds.com/distributions/CentOS-vault/5.9/isos/i386/CentOS-5.9-i386-bin-DVD-1of2.iso
CENTOS510_X86_64 ?= http://mirror.stanford.edu/yum/pub/centos/5.10/isos/x86_64/CentOS-5.10-x86_64-bin-DVD-1of2.iso
CENTOS510_I386 ?= http://mirrors.kernel.org/centos/5.10/isos/i386/CentOS-5.10-i386-bin-DVD-1of2.iso
CENTOS511_X86_64 ?= http://mirrors.kernel.org/centos/5.11/isos/x86_64/CentOS-5.11-x86_64-bin-DVD-1of2.iso
CENTOS511_I386 ?= http://mirrors.kernel.org/centos/5.11/isos/i386/CentOS-5.11-i386-bin-DVD-1of2.iso
CENTOS64_X86_64 ?= http://mirror.symnds.com/distributions/CentOS-vault/6.4/isos/x86_64/CentOS-6.4-x86_64-bin-DVD1.iso
CENTOS64_I386 ?= http://mirror.symnds.com/distributions/CentOS-vault/6.4/isos/i386/CentOS-6.4-i386-bin-DVD1.iso
CENTOS65_X86_64 ?= http://mirrors.kernel.org/centos/6.5/isos/x86_64/CentOS-6.5-x86_64-bin-DVD1.iso
CENTOS65_I386 ?= http://mirrors.kernel.org/centos/6.5/isos/i386/CentOS-6.5-i386-bin-DVD1.iso
CENTOS66_X86_64 ?= http://mirrors.kernel.org/centos/6.6/isos/x86_64/CentOS-6.6-x86_64-bin-DVD1.iso
CENTOS66_I386 ?= http://mirrors.kernel.org/centos/6.6/isos/i386/CentOS-6.6-i386-bin-DVD1.iso
CENTOS70_X86_64 ?= http://mirrors.sonic.net/centos/7.0.1406/isos/x86_64/CentOS-7.0-1406-x86_64-DVD.iso

# Possible values for CM: (nocm | chef | chefdk | salt | puppet)
CM ?= nocm
# Possible values for CM_VERSION: (latest | x.y.z | x.y)
CM_VERSION ?=
ifndef CM_VERSION
	ifneq ($(CM),nocm)
		CM_VERSION = latest
	endif
endif
SSH_USERNAME ?= vagrant
SSH_PASSWORD ?= vagrant
INSTALL_VAGRANT_KEY ?= true
BOX_VERSION ?= $(shell cat VERSION)
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM)-$(BOX_VERSION).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION)-$(BOX_VERSION).box
endif
# Packer does not allow empty variables, so only pass variables that are defined
PACKER_VARS_LIST = 'cm=$(CM)' 'headless=$(HEADLESS)' 'update=$(UPDATE)' 'version=$(BOX_VERSION)' 'ssh_username=$(SSH_USERNAME)' 'ssh_password=$(SSH_PASSWORD)' 'install_vagrant_key=$(INSTALL_VAGRANT_KEY)'
ifdef CM_VERSION
	PACKER_VARS_LIST += 'cm_version=$(CM_VERSION)'
endif
PACKER_VARS := $(addprefix -var , $(PACKER_VARS_LIST))
ifdef PACKER_DEBUG
	PACKER := PACKER_LOG=1 $(PACKER) --debug
endif
BUILDER_TYPES := vmware virtualbox parallels
TEMPLATE_FILENAMES := $(wildcard *.json)
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
TEST_BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), test-box/$(builder)/$(box_filename)))
VMWARE_BOX_DIR := box/vmware
VIRTUALBOX_BOX_DIR := box/virtualbox
PARALLELS_BOX_DIR := box/parallels
VMWARE_BOX_FILES := $(foreach box_filename, $(BOX_FILENAMES), $(VMWARE_BOX_DIR)/$(box_filename))
VIRTUALBOX_BOX_FILES := $(foreach box_filename, $(BOX_FILENAMES), $(VIRTUALBOX_BOX_DIR)/$(box_filename))
PARALLELS_TEMPLATE_FILENAMES = centos510-i386.json centos510.json centos511-i386.json centos511.json
PARALLELS_BOX_FILENAMES := $(PARALLELS_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
PARALLELS_BOX_FILES := $(foreach box_filename, $(PARALLELS_BOX_FILENAMES), box/parallels/$(box_filename))
BOX_FILES := $(VMWARE_BOX_FILES) $(VIRTUALBOX_BOX_FILES) $(PARALLELS_BOX_FILES)
VMWARE_OUTPUT := output-vmware-iso
VIRTUALBOX_OUTPUT := output-virtualbox-iso
PARALLELS_OUTPUT := output-parallels-iso
VMWARE_BUILDER := vmware-iso
VIRTUALBOX_BUILDER := virtualbox-iso
PARALLELS_BUILDER := parallels-iso
CURRENT_DIR = $(shell pwd)
SOURCES := $(wildcard script/*.sh)

.PHONY: list

all: $(BOX_FILES)

test: $(TEST_BOX_FILES)

###############################################################################
# Target shortcuts
define SHORTCUT

vmware/$(1): $(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-vmware/$(1): test-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-vmware/$(1): ssh-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

virtualbox/$(1): $(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-virtualbox/$(1): test-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-virtualbox/$(1): ssh-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

parallels/$(1): $(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-parallels/$(1): test-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-parallels/$(1): ssh-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

$(1): vmware/$(1) virtualbox/$(1) parallels/$(1)

test-$(1): test-vmware/$(1) test-virtualbox/$(1) test-parallels/$(1)

s3cp-$(1): s3cp-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX) s3cp-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX) s3cp-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-vmware/$(1): s3cp-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-virtualbox/$(1): s3cp-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

s3cp-parallels/$(1): s3cp-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

endef

SHORTCUT_TARGETS := $(basename $(TEMPLATE_FILENAMES))
$(foreach i,$(SHORTCUT_TARGETS),$(eval $(call SHORTCUT,$(i))))
###############################################################################

# Generic rule - not used currently
#$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-vmware-iso
#	mkdir -p $(VMWARE_BOX_DIR)
#	packer build -only=vmware-iso $(PACKER_VARS) $<

$(VMWARE_BOX_DIR)/centos70$(BOX_SUFFIX): centos70.json $(SOURCES) http/ks7.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VMWARE_BOX_DIR)/centos70-docker$(BOX_SUFFIX): centos70-docker.json $(SOURCES) http/ks7.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VMWARE_BOX_DIR)/centos70-desktop$(BOX_SUFFIX): centos70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VMWARE_BOX_DIR)/centos66$(BOX_SUFFIX): centos66.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VMWARE_BOX_DIR)/centos66-desktop$(BOX_SUFFIX): centos66-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VMWARE_BOX_DIR)/centos66-docker$(BOX_SUFFIX): centos66-docker.json $(SOURCES) script/desktop.sh
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VMWARE_BOX_DIR)/centos65$(BOX_SUFFIX): centos65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VMWARE_BOX_DIR)/centos65-desktop$(BOX_SUFFIX): centos65-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VMWARE_BOX_DIR)/centos65-docker$(BOX_SUFFIX): centos65-docker.json $(SOURCES) script/desktop.sh
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VMWARE_BOX_DIR)/centos64$(BOX_SUFFIX): centos64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VMWARE_BOX_DIR)/centos64-desktop$(BOX_SUFFIX): centos64-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VMWARE_BOX_DIR)/centos511$(BOX_SUFFIX): centos511.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_X86_64)" $<

$(VMWARE_BOX_DIR)/centos510$(BOX_SUFFIX): centos510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_X86_64)" $<

$(VMWARE_BOX_DIR)/centos59$(BOX_SUFFIX): centos59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_X86_64)" $<

$(VMWARE_BOX_DIR)/centos66-i386$(BOX_SUFFIX): centos66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_I386)" $<

$(VMWARE_BOX_DIR)/centos65-i386$(BOX_SUFFIX): centos65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_I386)" $<

$(VMWARE_BOX_DIR)/centos64-i386$(BOX_SUFFIX): centos64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_I386)" $<

$(VMWARE_BOX_DIR)/centos511-i386$(BOX_SUFFIX): centos511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_I386)" $<

$(VMWARE_BOX_DIR)/centos510-i386$(BOX_SUFFIX): centos510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_I386)" $<

$(VMWARE_BOX_DIR)/centos59-i386$(BOX_SUFFIX): centos59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_I386)" $<

# Generic rule - not used currently
#$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-virtualbox-iso
#	mkdir -p $(VIRTUALBOX_BOX_DIR)
#	packer build -only=virtualbox-iso $(PACKER_VARS) $<

$(VIRTUALBOX_BOX_DIR)/centos70$(BOX_SUFFIX): centos70.json $(SOURCES) http/ks7.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos70-docker$(BOX_SUFFIX): centos70-docker.json $(SOURCES)
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos70-desktop$(BOX_SUFFIX): centos70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos66$(BOX_SUFFIX): centos66.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos66-desktop$(BOX_SUFFIX): centos66-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos66-docker$(BOX_SUFFIX): centos66-docker.json $(SOURCES)
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65$(BOX_SUFFIX): centos65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-desktop$(BOX_SUFFIX): centos65-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-docker$(BOX_SUFFIX): centos65-docker.json $(SOURCES)
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos64$(BOX_SUFFIX): centos64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos64-desktop$(BOX_SUFFIX): centos64-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos511$(BOX_SUFFIX): centos511.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos510$(BOX_SUFFIX): centos510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos59$(BOX_SUFFIX): centos59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos66-i386$(BOX_SUFFIX): centos66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-i386$(BOX_SUFFIX): centos65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos64-i386$(BOX_SUFFIX): centos64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos511-i386$(BOX_SUFFIX): centos511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos510-i386$(BOX_SUFFIX): centos510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos59-i386$(BOX_SUFFIX): centos59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_I386)" $<

# Generic rule - not used currently
#$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-parallels-iso
#	mkdir -p $(PARALLELS_BOX_DIR)
#	packer build -only=parallels-iso $(PACKER_VARS) $<

$(PARALLELS_BOX_DIR)/centos70$(BOX_SUFFIX): centos70.json $(SOURCES) http/ks7.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos70-docker$(BOX_SUFFIX): centos70-docker.json $(SOURCES)
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos70-desktop$(BOX_SUFFIX): centos70-desktop.json $(SOURCES) http/ks7-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS70_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos66$(BOX_SUFFIX): centos66.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos66-desktop$(BOX_SUFFIX): centos66-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos66-docker$(BOX_SUFFIX): centos66-docker.json $(SOURCES)
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos65$(BOX_SUFFIX): centos65.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos65-desktop$(BOX_SUFFIX): centos65-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos65-docker$(BOX_SUFFIX): centos65-docker.json $(SOURCES)
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos64$(BOX_SUFFIX): centos64.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos64-desktop$(BOX_SUFFIX): centos64-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos511$(BOX_SUFFIX): centos511.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos510$(BOX_SUFFIX): centos510.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos59$(BOX_SUFFIX): centos59.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_X86_64)" $<

$(PARALLELS_BOX_DIR)/centos66-i386$(BOX_SUFFIX): centos66-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS66_I386)" $<

$(PARALLELS_BOX_DIR)/centos65-i386$(BOX_SUFFIX): centos65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_I386)" $<

$(PARALLELS_BOX_DIR)/centos64-i386$(BOX_SUFFIX): centos64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_I386)" $<

$(PARALLELS_BOX_DIR)/centos511-i386$(BOX_SUFFIX): centos511-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS511_I386)" $<

$(PARALLELS_BOX_DIR)/centos510-i386$(BOX_SUFFIX): centos510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_I386)" $<

$(PARALLELS_BOX_DIR)/centos59-i386$(BOX_SUFFIX): centos59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	$(PACKER) build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_I386)" $<

list:
	@echo "Prepend 'vmware/', 'virtualbox/', or 'parallels/' to build only one target platform:"
	@echo "  make vmware/centos66"
	@echo ""
	@echo "Targets:"
	@for shortcut_target in $(SHORTCUT_TARGETS) ; do \
		echo $$shortcut_target ; \
	done

validate:
	@for template_filename in $(TEMPLATE_FILENAMES) ; do \
		echo Checking $$template_filename ; \
		packer validate $$template_filename ; \
	done

clean: clean-builders clean-output clean-packer-cache

clean-builders:
	@for builder in $(BUILDER_TYPES) ; do \
		if test -d box/$$builder ; then \
			echo Deleting box/$$builder/*.box ; \
			find box/$$builder -maxdepth 1 -type f -name "*.box" ! -name .gitignore -exec rm '{}' \; ; \
		fi ; \
	done

clean-output:
	@for builder in $(BUILDER_TYPES) ; do \
		echo Deleting output-$$builder-iso ; \
		echo rm -rf output-$$builder-iso ; \
	done

clean-packer-cache:
	echo Deleting packer_cache
	rm -rf packer_cache

test-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb || exit

test-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb || exit

test-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb || exit

ssh-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb

ssh-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb

ssh-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb

S3_STORAGE_CLASS ?= REDUCED_REDUNDANCY
S3_ALLUSERS_ID ?= uri=http://acs.amazonaws.com/groups/global/AllUsers

s3cp-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(VMWARE_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(VIRTUALBOX_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	aws --profile $(AWS_PROFILE) s3 cp $< $(PARALLELS_S3_BUCKET) --storage-class $(S3_STORAGE_CLASS) --grants full=$(S3_GRANT_ID) read=$(S3_ALLUSERS_ID)

s3cp-vmware: $(addprefix s3cp-,$(VMWARE_BOX_FILES))
s3cp-virtualbox: $(addprefix s3cp-,$(VIRTUALBOX_BOX_FILES))
s3cp-parallels: $(addprefix s3cp-,$(PARALLELS_BOX_FILES))
