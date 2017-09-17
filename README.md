# Packer templates for CentOS

### Overview

This repository contains Packer templates for creating CentOS Vagrant boxes.

## Current Boxes

64-bit boxes:

* [CentOS 7.4 (64-bit)](https://app.vagrantup.com/boxcutter/boxes/centos7)
* [CentOS 7.4 Desktop (64-bit)](https://atlas.hashicorp.com/boxcutter/boxes/centos7-desktop)
* [CentOS 6.9 (64-bit)](https://app.vagrantup.com/boxcutter/boxes/centos6)
* [CentOS 6.9 Desktop (64-bit)](https://atlas.hashicorp.com/boxcutter/boxes/centos6-desktop)
* [CentOS 5.11 (64-bit)](https://app.vagrantup.com/boxcutter/boxes/centos5)

## Building the Vagrant boxes with Packer

To build all the boxes, you will need [VirtualBox](https://www.virtualbox.org/wiki/Downloads),
[VMware Fusion](https://www.vmware.com/products/fusion)/[VMware Workstation](https://www.vmware.com/products/workstation) and
[Parallels](http://www.parallels.com/products/desktop/whats-new/) installed.

Parallels requires that the
[Parallels Virtualization SDK for Mac](http://www.parallels.com/downloads/desktop)
be installed as an additional prerequisite.

We make use of JSON files containing user variables to build specific versions of CentOS.
You tell `packer` to use a specific user variable file via the `-var-file=` command line
option.  This will override the default options on the core `centos.json` packer template,
which builds CentOS 7 by default.

For example, to build CentOS 7, use the following:

    $ packer build -var-file=centos7.json centos.json

If you want to make boxes for a specific desktop virtualization platform, use the `-only`
parameter.  For example, to build CentOS 7 for VirtualBox:

    $ packer build -only=virtualbox-iso -var-file=centos7.json centos.json

The boxcutter templates currently support the following desktop virtualization strings:

* `parallels-iso` - [Parallels](http://www.parallels.com/products/desktop/whats-new/) desktop virtualization (Requires the Pro Edition - Desktop edition won't work)
* `virtualbox-iso` - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) desktop virtualization
* `vmware-iso` - [VMware Fusion](https://www.vmware.com/products/fusion) or [VMware Workstation](https://www.vmware.com/products/workstation) desktop virtualization

## Building the Vagrant boxes with the box script

We've also provided a wrapper script `bin/box` for ease of use, so alternatively, you can use
the following to build CentOS 7 for all providers:

    $ bin/box build centos7

Or if you just want to build CentOS 7 for VirtualBox:

    $ bin/box build centos7 virtualbox

## Building the Vagrant boxes with the Makefile

A GNU Make `Makefile` drives a complete basebox creation pipeline with the following stages:

* `build` - Create basebox `*.box` files
* `assure` - Verify that the basebox `*.box` files produced function correctly
* `deliver` - Upload `*.box` files to [Artifactory](https://www.jfrog.com/confluence/display/RTF/Vagrant+Repositories), [Atlas](https://atlas.hashicorp.com/) or an [S3 bucket](https://aws.amazon.com/s3/)

The pipeline is driven via the following targets, making it easy for you to include them
in your favourite CI tool:

    make build   # Build all available box types
    make assure  # Run tests against all the boxes
    make deliver # Upload box artifacts to a repository
    make clean   # Clean up build detritus

### Proxy Settings

The templates respect the following network proxy environment variables
and forward them on to the virtual machine environment during the box creation
process, should you be using a proxy:

* http_proxy
* https_proxy
* ftp_proxy
* rsync_proxy
* no_proxy

### Tests

The tests are written in [Serverspec](http://serverspec.org) and require the
`vagrant-serverspec` plugin to be installed with:

    vagrant plugin install vagrant-serverspec

The `Makefile` has individual targets for each box type with the prefix
`test-*` should you wish to run tests individually for each box.  For example:

    make test-virtualbox/centos66-nocm.box

Similarly there are targets with the prefix `ssh-*` for registering a
newly-built box with vagrant and for logging in using just one command to
do exploratory testing.  For example, to do exploratory testing
on the VirtualBox training environmnet, run the following command:

    make ssh-virtualbox/centos66-nocm.box

Upon logout `make ssh-*` will automatically de-register the box as well.

## Contributing


1. Fork and clone the repo.
2. Create a new branch, please don't work in your `master` branch directly.
3. Add new [Serverspec](http://serverspec.org/) or [Bats](https://blog.engineyard.com/2014/bats-test-command-line-tools) tests in the `test/` subtree for the change you want to make.  Run `make test` on a relevant template to see the tests fail (like `make test-virtualbox/centos65`).
4. Fix stuff.  Use `make ssh` to interactively test your box (like `make ssh-virtualbox/centos65`).
5. Run `make test` on a relevant template (like `make test-virtualbox/centos65`) to see if the tests pass.  Repeat steps 3-5 until done.
6. Update `README.md` and `AUTHORS` to reflect any changes.
7. If you have a large change in mind, it is still preferred that you split them into small commits.  Good commit messages are important.  The git documentation project has some nice guidelines on [writing descriptive commit messages](http://git-scm.com/book/ch5-2.html#Commit-Guidelines).
8. Push to your fork and submit a pull request.
9. Once submitted, a full `make test` run will be performed against your change in the build farm.  You will be notified if the test suite fails.

### Would you like to help out more?

Contact moujan@annawake.com

### Acknowledgments

[Parallels](http://www.parallels.com/) provides a Business Edition license of
their software to run on the basebox build farm.

<img src="http://www.parallels.com/fileadmin/images/corporate/brand-assets/images/logo-knockout-on-red.jpg" width="80">

[SmartyStreets](http://www.smartystreets.com) is providing basebox hosting for the boxcutter project.

<img src="https://d79i1fxsrar4t.cloudfront.net/images/brand/smartystreets.65887aa3.png" width="320">
