# if Makefile.local exists, include it
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

CENTOS59_X86_64 ?= http://mirror.symnds.com/distributions/CentOS-vault/5.9/isos/x86_64/CentOS-5.9-x86_64-bin-DVD-1of2.iso
CENTOS59_I386 ?= http://mirror.symnds.com/distributions/CentOS-vault/5.9/isos/i386/CentOS-5.9-i386-bin-DVD-1of2.iso
CENTOS510_X86_64 ?= http://mirror.stanford.edu/yum/pub/centos/5.10/isos/x86_64/CentOS-5.10-x86_64-bin-DVD-1of2.iso
CENTOS510_I386 ?= http://mirrors.kernel.org/centos/5.10/isos/i386/CentOS-5.10-i386-bin-DVD-1of2.iso
CENTOS64_X86_64 ?= http://mirror.symnds.com/distributions/CentOS-vault/6.4/isos/x86_64/CentOS-6.4-x86_64-bin-DVD1.iso
CENTOS64_I386 ?= http://mirror.symnds.com/distributions/CentOS-vault/6.4/isos/i386/CentOS-6.4-i386-bin-DVD1.iso
CENTOS65_X86_64 ?= http://mirrors.kernel.org/centos/6.5/isos/x86_64/CentOS-6.5-x86_64-bin-DVD1.iso
CENTOS65_I386 ?= http://mirrors.kernel.org/centos/6.5/isos/i386/CentOS-6.5-i386-bin-DVD1.iso

# Possible values for CM: (nocm | chef | chefdk | salt | puppet)
CM ?= nocm
# Possible values for CM_VERSION: (latest | x.y.z | x.y)
CM_VERSION ?=
ifndef CM_VERSION
	ifneq ($(CM),nocm)
		CM_VERSION = latest
	endif
endif
# Packer does not allow empty variables, so only pass variables that are defined
ifdef CM_VERSION
	PACKER_VARS := -var 'cm=$(CM)' -var 'cm_version=$(CM_VERSION)'
else
	PACKER_VARS := -var 'cm=$(CM)'
endif
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION).box
endif
BUILDER_TYPES := vmware virtualbox
TEMPLATE_FILENAMES := $(wildcard *.json)
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), box/$(builder)/$(box_filename)))
TEST_BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), test-box/$(builder)/$(box_filename)))
VMWARE_BOX_DIR := box/vmware
VIRTUALBOX_BOX_DIR := box/virtualbox
VMWARE_OUTPUT := output-vmware-iso
VIRTUALBOX_OUTPUT := output-virtualbox-iso
VMWARE_BUILDER := vmware-iso
VIRTUALBOX_BUILDER := virtualbox-iso
CURRENT_DIR = $(shell pwd)
SOURCES := script/fix-slow-dns.sh script/sshd.sh script/vagrant.sh script/vmtool.sh script/cmtool.sh script/cleanup.sh

.PHONY: all list clean

all: $(BOX_FILES)

test: $(TEST_BOX_FILES)

###############################################################################
# Target shortcuts
define SHORTCUT

vmware/$(1): $(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-vmware/$(1): test-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

virtualbox/$(1): $(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-virtualbox/$(1): test-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

$(1): vmware/$(1) virtualbox/$(1)

test-$(1): test-vmware/$(1) test-virtualbox/$(1)

endef

SHORTCUT_TARGETS := centos65 centos65-desktop centos64 centos64-desktop centos510 centos59 centos65-i386 centos64-i386 centos510-i386 centos59-i386
$(foreach i,$(SHORTCUT_TARGETS),$(eval $(call SHORTCUT,$(i))))
###############################################################################

# Generic rule - not used currently
#$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-vmware-iso
#	mkdir -p $(VMWARE_BOX_DIR)
#	packer build -only=vmware-iso $(PACKER_VARS) $<

$(VMWARE_BOX_DIR)/centos65$(BOX_SUFFIX): centos65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VMWARE_BOX_DIR)/centos65-desktop$(BOX_SUFFIX): centos65-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VMWARE_BOX_DIR)/centos64$(BOX_SUFFIX): centos64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VMWARE_BOX_DIR)/centos64-desktop$(BOX_SUFFIX): centos64-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VMWARE_BOX_DIR)/centos510$(BOX_SUFFIX): centos510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_X86_64)" $<

$(VMWARE_BOX_DIR)/centos59$(BOX_SUFFIX): centos59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_X86_64)" $<

$(VMWARE_BOX_DIR)/centos65-i386$(BOX_SUFFIX): centos65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_I386)" $<

$(VMWARE_BOX_DIR)/centos64-i386$(BOX_SUFFIX): centos64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_I386)" $<

$(VMWARE_BOX_DIR)/centos510-i386$(BOX_SUFFIX): centos510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_I386)" $<

$(VMWARE_BOX_DIR)/centos59-i386$(BOX_SUFFIX): centos59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_I386)" $<

# Generic rule - not used currently
#$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-virtualbox-iso
#	mkdir -p $(VIRTUALBOX_BOX_DIR)
#	packer build -only=virtualbox-iso $(PACKER_VARS) $<
	
$(VIRTUALBOX_BOX_DIR)/centos65$(BOX_SUFFIX): centos65.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-desktop$(BOX_SUFFIX): centos65-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-docker$(BOX_SUFFIX): centos65-docker.json $(SOURCES) script/kernel-docker.sh script/docker.sh
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos64$(BOX_SUFFIX): centos64.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos64-desktop$(BOX_SUFFIX): centos64-desktop.json $(SOURCES) script/desktop.sh http/ks6-desktop.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos510$(BOX_SUFFIX): centos510.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos59$(BOX_SUFFIX): centos59.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/centos65-i386$(BOX_SUFFIX): centos65-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS65_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos64-i386$(BOX_SUFFIX): centos64-i386.json $(SOURCES) http/ks6.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS64_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos510-i386$(BOX_SUFFIX): centos510-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS510_I386)" $<

$(VIRTUALBOX_BOX_DIR)/centos59-i386$(BOX_SUFFIX): centos59-i386.json $(SOURCES) http/ks5.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(CENTOS59_I386)" $<

list:
	@echo "Prepend 'vmware/' or 'virtualbox/' to build only one target platform:"
	@echo "  make vmware/centos65"
	@echo ""
	@echo "Targets:"
	@for shortcut_target in $(SHORTCUT_TARGETS) ; do \
		echo $$shortcut_target ; \
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
	
ssh-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb
	
ssh-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb	
