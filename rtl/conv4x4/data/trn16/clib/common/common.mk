RED  =\033[0;31m
NC   =\033[0m # No Color

TARGET   ?= simple-conv
GCCOPT   ?= O2
OPTIM    ?= 0
ARCH     ?= rv32im_zicsr
MEM_SIZE ?= 65536
SRCDIR   ?= $(CURDIR)/../src

COMMDIR  ?= $(CURDIR)/common

CC 		= riscv64-elf-gcc
OBJDUMP = riscv64-elf-objdump
OBJCOPY = riscv64-elf-objcopy

HEADERS = $(INCFILES) $(wildcard ${COMMDIR}/include/*.h)

CFLAGS  = -march=$(ARCH) -mabi=ilp32 -Wall -std=c23 -I${COMMDIR}/include $(INCFLAGS) -$(GCCOPT) -DOPTIM=$(OPTIM)
LDFLAGS = --specs=nano.specs -march=$(ARCH) -mabi=ilp32 -nostartfiles -T ${COMMDIR}/link.ld

# $(info CFLAGS $(CFLAGS))

CCSRC = $(SRCFILES) $(wildcard ${COMMDIR}/*.c)
CCOBJ = $(patsubst %.c, %.o, $(CCSRC))

ASSRC = $(wildcard ${COMMDIR}/*.S)
ASOBJ = $(patsubst %.S,%.o, $(ASSRC))

all: $(TARGET).bin $(TARGET).lst

$(TARGET).bin: $(TARGET).elf
	@printf "${RED}Generating %s...${NC}\n" "$@"
	@$(OBJCOPY) $< $@ -O binary

$(TARGET).lst: $(TARGET).elf
	@printf "${RED}Generating %s...${NC}\n" "$@"
	@$(OBJDUMP) -S $< > $@

$(TARGET).elf: $(CCOBJ) $(ASOBJ)
	@printf "${RED}Linking %s...${NC}\n" "$@"
	@$(CC) $(CCOBJ) $(ASOBJ) -Wl,-Map=$(TARGET).map -N -o $@ $(LDFLAGS)


%.o: %.S
	@printf "${RED}Assemblying %s...${NC}\n" "$<"
	@$(CC) -c $< -o $@ $(CFLAGS) -march=$(ARCH) -DMEM_SIZE=$(MEM_SIZE)

%.o: %.c $(HEADERS)
	@printf "${RED}Compiling %s...${NC}\n" "$<"
	@$(CC) -c $< -o $@ $(CFLAGS)

clean:
	@printf "Cleaning up\n"
	@find $(ROOTDIR) -name "*.o" -type f -delete
	@rm -rf $(COMMDIR)/*.o
	@rm -rf *.bin
	@rm -rf *.map
	@rm -rf *.lst
	@rm -rf *.elf

.PHONY: clean
