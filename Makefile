NAME = kfs.elf
BUILD_DIR = build
ASM_SRC = src/boot.asm src/kernel.asm src/gdt.asm
ASM_OBJ = $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/gdt.o

ISO = $(BUILD_DIR)/kernel.iso
AS = nasm
LD = ld
ASFLAGS = -f elf32 -I src/
LDFLAGS = -m elf_i386 -T linker.ld

QEMU_DISPLAY ?=
QEMU = qemu-system-i386
QEMU_FLAGS = $(if $(QEMU_DISPLAY),-display $(QEMU_DISPLAY))

all: $(BUILD_DIR)/$(NAME)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/boot.o: src/boot.asm | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/gdt.o: src/gdt.asm | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/kernel.o: src/kernel.asm | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/$(NAME): $(ASM_OBJ)
	$(LD) $(LDFLAGS) -o $@ $(ASM_OBJ)

# verify multiboot header
check: $(BUILD_DIR)/$(NAME)
	grub-file --is-x86-multiboot $(BUILD_DIR)/$(NAME) && echo "[OK] multiboot v1 header"

# direct kernel boot
run: $(BUILD_DIR)/$(NAME)
	$(QEMU) $(QEMU_FLAGS) -kernel $(BUILD_DIR)/$(NAME)

# builds a GRUB-bootable ISO
# iso: $(BUILD_DIR)/$(NAME)
# 	mkdir -p iso/boot/grub
# 	cp $(BUILD_DIR)/$(NAME) iso/boot/kfs.elf
# 	grub-mkrescue -o $(ISO) iso


# boot via the GRUB ISO
# run-iso: iso
# 	$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO)

# direct kernel boot under GDB stub
# debug: $(BUILD_DIR)/$(NAME)
# 	$(QEMU) $(QEMU_FLAGS) -kernel $(BUILD_DIR)/$(NAME) -s -S

# same as run-iso but exposes the QEMU monitor on stdio
# run-monitor: iso
# 	$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO) -monitor stdio

# GDT placed at 0x800 + multiboot present
mem-check: $(BUILD_DIR)/$(NAME)
	@nm $(BUILD_DIR)/$(NAME) | grep -E "gdt_start|gdt_end|gdtr|KERNEL|USER"
	@objdump -h $(BUILD_DIR)/$(NAME) | grep -E "\.gdt|\.text|\.multiboot"
	@nm -n $(BUILD_DIR)/$(NAME) | grep -E "gdt_start|gdt_end|gdtr|_start"

clean:
	rm -rf $(BUILD_DIR)

fclean: clean
	rm -f iso/boot/kfs.elf

re: fclean all

.PHONY: all check run mem-check clean fclean re # iso debug run-iso run-monitor
