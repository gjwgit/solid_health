########################################################################
#
# Generic Makefile
#
# Time-stamp: <Tuesday 2024-07-09 20:17:01 +1000 Graham Williams>
#
# Copyright (c) Graham.Williams@togaware.com
#
# License: Creative Commons Attribution-ShareAlike 4.0 International.
#
########################################################################

# App is often the current directory name.
#
# App version numbers
#   Major release
#   Minor update
#   Trivial update or bug fix

APP=$(shell pwd | xargs basename)
VER=
DATE=$(shell date +%Y-%m-%d)

# Identify a destination used by install.mk

DEST=/var/www/html/$(APP)

########################################################################
# Supported Makefile modules.

# Often the support Makefiles will be in the local support folder, or
# else installed in the local user's shares.

INC_BASE=$(HOME)/.local/share/make
INC_BASE=support

# Specific Makefiles will be loaded if they are found in
# INC_BASE. Sometimes the INC_BASE is shared by multiple local
# Makefiles and we want to skip specific makes. Simply define the
# appropriate INC to a non-existant location and it will be skipped.

INC_DOCKER=skip
INC_MLHUB=skip
INC_WEBCAM=skip

# Load any modules available.

INC_MODULE=$(INC_BASE)/modules.mk

ifneq ("$(wildcard $(INC_MODULE))","")
  include $(INC_MODULE)
endif

########################################################################
# HELP
#
# Help for targets defined in this Makefile.

define HELP
$(APP):

  local	     Install to $(HOME)/.local/share/$(APP)
    tgz	     Upload the installer to solidcommunity.com
  apk	     Upload the installer to solidcommunity.com

endef
export HELP

help::
	@echo "$$HELP"

########################################################################
# LOCAL TARGETS

#
# Manage the production install on the remote server.
#

clean::
	rm -f README.html

# Android: Upload to Solid Community installers for general access.

apk::
	rsync -avzh --exclude *~ installers/$(APP)*.apk solidcommunity.au:/var/www/html/installers/
	ssh solidcommunity.au chmod -R go+rX /var/www/html/installers/
	ssh solidcommunity.au chmod go=x /var/www/html/installers/

# Linux: Install locally.

local: tgz
	tar zxvf installers/$(APP).tar.gz -C $(HOME)/.local/share/

# Linux: Upload to Solid Community installers for general access.

tgz::
	rsync -avzh installers/$(APP)*.tar.gz solidcommunity.au:/var/www/html/installers/
	ssh solidcommunity.au chmod -R go+rX /var/www/html/installers/
	ssh solidcommunity.au chmod go=x /var/www/html/installers/
