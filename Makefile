PROJECT = Test

CC      = $(GCC_BIN)arm-none-eabi-gcc
CPP     = $(GCC_BIN)arm-none-eabi-g++
LD      = $(GCC_BIN)arm-none-eabi-gcc
OBJCOPY = $(GCC_BIN)arm-none-eabi-objcopy
OBJDUMP = $(GCC_BIN)arm-none-eabi-objdump
SIZE    = $(GCC_BIN)arm-none-eabi-size 

CPU = -mcpu=cortex-m3 -mthumb 

CC_FLAGS = $(CPU) -c -fno-common -fmessage-length=0 -Wall -Wextra -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer -MMD -MP

CC_SYMBOLS = -DTARGET_FF_ARDUINO -DTARGET_NUCLEO_F103RB -DTOOLCHAIN_GCC -DTARGET_FF_MORPHO -DTARGET_LIKE_CORTEX_M3 -DTARGET_CORTEX_M -DTARGET_LIKE_MBED -DTARGET_STM32F1 -D__MBED__=1 -DARM_MATH_CM3 -DMBED_BUILD_TIMESTAMP=1463831794.11 -DTARGET_STM -DTOOLCHAIN_GCC_ARM -D__CORTEX_M3 -DTARGET_M3 -DTARGET_STM32F103RB -D STM32F103xB -std=c99

LD_FLAGS = $(CPU) -Wl,--gc-sections --specs=nano.specs -Wl,-Map=$(BINDIR)/$(PROJECT).map,-cref
LD_SYS_LIBS = -lgcc

DRIVERSDIR = ./Drivers
HALDIR = $(DRIVERSDIR)/STM32F1xx_HAL_Driver
CMSISDIR = $(DRIVERSDIR)/CMSIS
CMSIS_DEVICEDIR = $(CMSISDIR)/Device/ST/STM32F1xx
STARTUP_SRC = $(DRIVERSDIR)/startup_stm32f103xb.s
STARTUP_OBJ = startup.o

OBJDIR=./obj

USR_SRCDIR = ./Src
HAL_SRCDIR = $(HALDIR)/Src

BINDIR = ./bin

SRCS   = 	\
		$(wildcard $(USR_SRCDIR)/*.c)	\
$(wildcard $(HAL_SRCDIR)/*.c)

SYS_OBJECTS = 	$(addprefix $(OBJDIR)/, $(notdir $(SRCS:.c=.o)))\
		$(OBJDIR)/$(STARTUP_OBJ)

INCLUDEDIRS =   -I ./Inc							\
	 	-I $(shell cd  $(HALDIR)/Inc&& pwd)						\
		-I $(shell cd  $(CMSISDIR)/Include&& pwd)						\
		-I $(shell cd  $(CMSIS_DEVICEDIR)/Include&& pwd)	\
	-I./Drivers/CMSIS/Device/ST/STM32F1xx/Include/

LINKER_SCRIPT = $(DRIVERSDIR)/STM32F103RBTx_FLASH.ld

$(OBJDIR)/%.o: $(USR_SRCDIR)/%.c 
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(OBJDIR)/%.o: $(HAL_SRCDIR)/%.c
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<


all: $(BINDIR)/$(PROJECT).bin $(BINDIR)/$(PROJECT).hex size

clean:
	rm -f $(PROJECT).bin $(PROJECT).elf $(PROJECT).hex $(PROJECT).map $(PROJECT).lst $(OBJDIR) $(BINDIR) -rf

$(OBJDIR)/$(STARTUP_OBJ): $(STARTUP_SRC)
	$(CC) $(CPU) -c -x assembler-with-cpp -o $@ $<

$(OBJDIR)/%.o: $(USR_SRCDIR)/%.c 
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(OBJDIR)/%.o: $(HAL_SRCDIR)/%.c
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(BINDIR)/$(PROJECT).elf: $(SYS_OBJECTS)
	-mkdir -p $(BINDIR)
	$(LD) $(LD_FLAGS) -T $(LINKER_SCRIPT) $(LIBRARY_PATHS) -o $@ $^ -Wl,--start-group $(LIBRARIES) $(LD_SYS_LIBS) -Wl,--end-group

$(BINDIR)/$(PROJECT).bin: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

$(BINDIR)/$(PROJECT).hex: $(BINDIR)/$(PROJECT).elf
	@$(OBJCOPY) -O ihex $< $@

$(BINDIR)/$(PROJECT).lst: $(BINDIR)/$(PROJECT).elf
	@$(OBJDUMP) -Sdh $< > $@

size: $(BINDIR)/$(PROJECT).elf
	$(SIZE) $(BINDIR)/$(PROJECT).elf
