##
## Supermodel
## A Sega Model 3 Arcade Emulator.
## Copyright 2003-2022 The Supermodel Team
##
## This file is part of Supermodel.
##
## Supermodel is free software: you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation, either version 3 of the License, or (at your option)
## any later version.
##
## Supermodel is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
## more details.
##
## You should have received a copy of the GNU General Public License along
## with Supermodel.  If not, see <http://www.gnu.org/licenses/>.
##

#
# Makefile.UNIX
#
# Makefile for UNIX/Linux systems.
#
#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITPRO)/libnx/switch_rules

###############################################################################
# Build Options
###############################################################################

DELETE = rm -d -r -f


###############################################################################
# Platform Configuration
#
# Edit library and include paths as needed.
###############################################################################

#
# Must be included first
#
include Makefiles/Options.inc

#
# Toolchain
#
CC = aarch64-none-elf-gcc
CCC = gcc.exe
CXX = aarch64-none-elf-g++
LD = aarch64-none-elf-gcc

#
# SDL
#

SDL2_CFLAGS = `sdl2-config --cflags`
SDL2_LIBS = `sdl2-config --libs`

#
#	UNIX-specific
#

PLATFORM_CXXFLAGS = $(SDL2_CFLAGS) -O3 -lGLESv2
PLATFORM_LDFLAGS = $(SDL2_LIBS) -lnx -lz -lm -lstdc++ -lGLESv2 -lSDL2_net -specs=$(DEVKITPRO)/libnx/switch.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS	:= -lnx -lEGL

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(PORTLIBS) $(LIBNX)


###############################################################################
# Core Makefile
###############################################################################

include Makefiles/Rules.inc

clean:
	$(SILENT)echo Cleaning up \"$(BIN_DIR)\" and \"$(OBJ_DIR)\"...
	$(SILENT)$(DELETE) $(BIN_DIR)
	$(SILENT)$(DELETE) $(OBJ_DIR)
