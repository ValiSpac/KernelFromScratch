CC      = i686-elf-gcc
AS      = i686-elf-as
CFLAGS  = -fno-builtin -fno-exceptions -fno-stack-protector -nostdlib -nodefaultlibs -ffreestanding -O2 -Wall -Wextra

all: kfs-1.iso

boot.o: boot.s
	$(AS) boot.s -o boot.o

kernel.o: kernel.c
	$(CC) -c kernel.c -o kernel.o $(CFLAGS)

kfs-1.bin: boot.o kernel.o
	$(CC) -T linker.ld -o kfs-1.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

kfs-1.iso: kfs-1.bin
	cp kfs-1.bin boot/kfs-1.bin
	grub-mkrescue -o kfs-1.iso .

clean:
	rm -f *.o kfs-1.bin kfs-1.iso boot/kfs-1.bin
