TARGET   ?= standard
OPTIM    ?= 0
GCCOPT   ?= O2
ARCH     ?= rv32im_zicsr
MEM_SIZE ?= 65536


# search for general files (common, lib and main)
ROOTDIR  ?= $(realpath $(CURDIR)/../../)
COMMFILE = $(ROOTDIR)/common/common.mk
COMMDIR  = $(ROOTDIR)/common/

# add src files
SRCPATH  = $(ROOTDIR)/lib 
SRCFILES = $(ROOTDIR)/main/$(TARGET).c $(foreach dir,$(SRCPATH),$(wildcard $(dir)/*.c))

# add headers, data is parent (project) or children (RS5 repo)
INCPATH  = $(ROOTDIR)/lib/include $(realpath $(CURDIR)/../../data) $(realpath $(CURDIR)/data) 
INCFILES = $(foreach dir,$(INCPATH),$(wildcard $(dir)/*.h))
INCFLAGS = $(foreach dir,$(INCPATH),-I$(dir))

include $(COMMFILE)
