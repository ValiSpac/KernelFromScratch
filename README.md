# KFS — Kernel From Scratch (1 + 2)

A minimal x86 kernel written entirely in **NASM assembly**, bootable via **GRUB** (Multiboot v1), targeting the **i386** architecture.

Covers **KFS-1** (boot, screen, I/O) and **KFS-2** (GDT, stack).

---

## Features

### KFS-1 — Mandatory
- GRUB Multiboot v1 boot (magic `0x1BADB002`)
- ASM bootstrap (`boot.asm`) — sets up stack, calls `kmain`
- Custom linker script (`linker.ld`)
- Makefile with `nasm` + `ld`
- VGA text-mode driver (80×25 @ `0xB8000`)
- Displays `"42"` on screen
- Binary < 10 MB (~20 KB)

### KFS-1 — Bonus
- **Scroll** — auto line-scroll at row 25
- **Cursor** — visible blinking hardware cursor, synced to write position
- **Colors** — 16-color VGA, foreground/background per character (`vga_make_color`)
- **`printk`** — printf-style with `%c %s %d %x` (cdecl variadic)
- **Keyboard** — PS/2 polling, full US QWERTY, Shift / CapsLock / extended (`0xE0`) keys, backspace
- **Multi-screen** — 3 virtual TTYs with independent VGA buffer + cursor + color theme, switch with **F1 / F2 / F3**

### KFS-2 — Mandatory
- **GDT** at physical address `0x00000800` (verified via `nm`)
- 7 entries: null + Kernel CS/DS/SS + User CS/DS/SS
- Loaded into BIOS via `lgdt` and segment registers reloaded via far jump
- **Stack-dump tool** — walks frame chain (`ebp`-linked), prints frames + raw words via `printk`
- Triggered by **F4** key or `stack` shell command

### KFS-2 — Bonus
- **Mini shell** with commands:
  - `help` — list commands
  - `stack` — dump kernel stack
  - `clear` — clear screen
  - `halt` — `cli` + `hlt` loop
  - `reboot` — PS/2 controller reset (`0xFE -> 0x64`)

---

## Build & Run

```bash
make            # assemble + link -> build/kfs.elf
make run        # boot via QEMU (direct kernel)
make iso        # build a GRUB-bootable ISO
make run-iso    # boot the ISO with QEMU
make debug      # boot with GDB stub on :1234
make check      # verify Multiboot header
make mem-check  # show GDT/section layout
make re         # full rebuild
```

**Requirements:** `nasm`, `binutils` (`ld`), `qemu-system-i386`, `grub-mkrescue` (for ISO).

A `Dockerfile` + `docker-compose.yml` are provided for hosts without GRUB tools.

---

## Project Layout

```
kfs/
├── Makefile
├── linker.ld                   # places .gdt at 0x800, kernel at 1 MiB
├── iso/boot/grub/grub.cfg
├── src/
│   ├── boot.asm                # multiboot header + _start
│   ├── kernel.asm              # kmain + globals + module includes
│   ├── gdt.asm                 # GDT (.gdt section), gdtr, gdt_re_load
│   ├── terminal.asm            # putchar / putstr / scroll / clear / cursor
│   ├── keyboard.asm            # PS/2 scancode -> ASCII, shift, caps, F-keys
│   ├── window.asm              # 3 virtual screens (save/load/switch)
│   ├── colors.asm              # VGA 4-bit color helpers
│   ├── shell.asm               # mini shell dispatcher
│   ├── stack_dump.asm          # frame-walker for the kernel stack
│   ├── printk.asm              # variadic %c %s %d %x
│   ├── print_utils/            # print_dec, print_hex32, print_log
│   └── libasm/                 # ft_strcmp, ft_strlen, ft_strcpy, ft_is*
└── build/                      # output (kfs.elf, .iso, .o)
```

---

## Keymap

| Key            | Action                                  |
|----------------|-----------------------------------------|
| `F1` / `F2` / `F3` | Switch to virtual screen 0 / 1 / 2  |
| `F4`           | Dump the kernel stack                   |
| Arrows         | Debug `printk` demo (proves `%d %c %s %x`) |
| Shift / Caps   | Standard case + symbol shifting          |
| Backspace      | Erase last character                     |
| Enter          | Submit current line to the shell         |

### Shell commands
```
help    stack    clear    halt    reboot
```

---

## Verifying Compliance

```bash
make mem-check
# -> gdt_start at 0x00000800, gdt_end at 0x00000838
# -> .gdt / .multiboot / .text sections present

readelf -l build/kfs.elf
# -> first LOAD segment contains .gdt @ vaddr 0x800
# -> second LOAD segment contains .multiboot + kernel @ 1 MiB
```

---

## License

42 school project.
