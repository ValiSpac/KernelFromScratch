# KFS — Concepts Revision Sheet

A consolidated reference of every concept used in this kernel — x86 assembly, NASM, the boot process, and OS-level primitives.

---

## 1. The Boot Process

### BIOS → GRUB → Kernel

1. **BIOS** runs power-on self-test, reads the first sector (MBR) of the boot device.
2. **GRUB** (stage 1.5 / 2) is loaded by the MBR, parses `grub.cfg`, locates the kernel ELF.
3. GRUB scans the **first 8 KiB** of the ELF file for the **Multiboot magic** `0x1BADB002`.
4. GRUB sets up:
   - **Protected mode** (32-bit, paging off, A20 line on)
   - **CS = flat 0–4 GiB code segment** (a temporary GDT)
   - `EAX = 0x2BADB002` (signals "loaded by multiboot")
   - `EBX = pointer to multiboot info struct`
5. GRUB jumps to the entry point we declared (`_start`).

### Multiboot Header (v1)

Three 32-bit fields, must be 4-byte aligned, in the first 8 KiB of the file:

| Field     | Value                                   |
|-----------|-----------------------------------------|
| magic     | `0x1BADB002`                            |
| flags     | `0` (no extra requests)                 |
| checksum  | `-(magic + flags)` so the sum mod 2³² = 0 |

Placed in its own `.multiboot` section so the linker can put it early in the file.

---

## 2. x86 Real vs Protected Mode

| Feature        | Real mode (BIOS) | Protected mode (us)    |
|----------------|------------------|------------------------|
| Word size      | 16 bit           | 32 bit                 |
| Address space  | 1 MiB (segments) | 4 GiB (flat with GDT)  |
| Privilege      | Ring 0 only      | Rings 0–3              |
| Memory layout  | `seg:off` (×16)  | Linear via descriptors |

GRUB hands us protected mode already. We never touch real mode.

---

## 3. The GDT (Global Descriptor Table)

A table of **8-byte segment descriptors** describing memory regions and their access rules.

### Why
- The CPU **requires** segment registers (`cs`, `ds`, `ss`, …) to point to valid descriptors before executing.
- It separates **kernel** (ring 0) from **user** (ring 3) code/data.
- Even when using a flat memory model, the GDT is mandatory.

### Descriptor Layout (8 bytes)

```
| 7      | 6 5 | 4 | 3 2 1 0 ||| 7         0 ||| 7         0 ||| 7         0 |
| limit_high (low nibble) | flags (4b) | base[31:24] | base[23:16] | access | base[15:0] | limit[15:0] |
```

| Field     | Meaning                                                 |
|-----------|---------------------------------------------------------|
| `base`    | Linear start address of the segment (32 bit)            |
| `limit`   | Size of segment (20 bit, scaled by `granularity`)       |
| `access`  | Present / DPL / type / executable / RW / accessed       |
| `flags`   | Granularity (1=4 KiB pages) / D/B (1=32-bit) / L (0=32) |

### Access byte (one common combo)

`0x9A = 1001 1010` → present, ring 0, code, readable
`0x92 = 1001 0010` → present, ring 0, data, writable
`0xFA / 0xF2`      → same but ring 3

### Our GDT (7 entries, at `0x00000800`)

```
0x00 NULL
0x08 Kernel Code  base=0  limit=0xFFFFF  flags=0xC  access=0x9A
0x10 Kernel Data  ... 0x92
0x18 Kernel Stack ... 0x92
0x20 User Code    ... 0xFA
0x28 User Data    ... 0xF2
0x30 User Stack   ... 0xF2
```

Selectors are `index × 8` because each entry is 8 bytes (`KERNEL_CS = 0x08`).

### Loading the GDT

```nasm
gdtr:
    dw  gdt_end - gdt_start - 1   ; limit (size − 1)
    dd  gdt_start                  ; linear base address

lgdt [gdtr]                        ; tells CPU where the GDT is
jmp KERNEL_CS:.flush_cs            ; far jump → reloads CS
mov ax, KERNEL_DS
mov ds, ax  ; reload all data segs
mov es, ax
mov fs, ax
mov gs, ax
mov ax, KERNEL_SS
mov ss, ax
```

The far jump is mandatory: the CPU caches the previous CS descriptor, the only way to refresh it is `jmp far`.

---

## 4. The Stack & Calling Convention (cdecl)

### What the stack is
A region of memory `esp` points into, growing **downward** (`push` decrements `esp`).

```
| ... older ...      |
| arg 3              | [ebp+16]
| arg 2              | [ebp+12]
| arg 1              | [ebp+8]
| return address     | [ebp+4]
| saved ebp          | [ebp]      ← ebp
| local vars         |
| ...                | ← esp (top, lowest address)
```

### cdecl (used by `printk`, `shell`, etc.)

1. **Caller** pushes args **right-to-left**, then `call`s.
2. `call` pushes the return address.
3. **Callee** prologue: `push ebp` / `mov ebp, esp` / save `ebx esi edi` (callee-saved).
4. Callee accesses args via `[ebp+8], [ebp+12], …`.
5. Callee returns value in `eax`.
6. Callee epilogue: restore saved regs / `pop ebp` / `ret`.
7. **Caller** cleans args: `add esp, 4*N`.

| Caller-saved | Callee-saved |
|--------------|--------------|
| eax ecx edx  | ebx esi edi ebp |

### Stack walking (`stack_dump`)
Each `push ebp; mov ebp, esp` builds a linked list:
- `[ebp]`     → previous `ebp`
- `[ebp+4]`   → return address
- We follow the chain until `ebp == 0` or unaligned.

---

## 5. VGA Text Mode

| Property        | Value                                       |
|-----------------|---------------------------------------------|
| Memory address  | `0xB8000` (linear)                          |
| Resolution      | 80 columns × 25 rows = 2000 cells           |
| Cell size       | 2 bytes — `[ASCII char][color attribute]`   |
| Color byte      | `bg(4) | fg(4)` — bits 7..4 = bg, 3..0 = fg |
| Cell offset     | `0xB8000 + (row × 80 + col) × 2`            |

### Hardware cursor (separate from displayed glyphs)

Programmed via I/O ports `0x3D4` (index) and `0x3D5` (data):
- Reg `0x0A` / `0x0B` → enable + scanline range
- Reg `0x0E` / `0x0F` → cursor position high / low byte

### Scrolling
Copy rows 1..24 into rows 0..23 (`rep movsw`), then blank row 24.

---

## 6. PS/2 Keyboard (Polling)

| Port  | Direction | Meaning                                   |
|-------|-----------|-------------------------------------------|
| `0x64`| read      | status register; bit 0 = output buffer full |
| `0x60`| read      | data register (next scancode)             |

### Scancode set 1
- **Press**: scancode (e.g. `0x1E` = A)
- **Release**: scancode `| 0x80` (e.g. `0x9E`)
- **Extended** keys: `0xE0` prefix, then real scancode (arrows, right-ctrl, …)

### State machine
- `shift_state` set by `0x2A`/`0x36` press, cleared on release
- `caps_state` toggled with XOR on each `0x3A` press
- `ext_pending` set by `0xE0`, consumed on next byte

### Case rule
```
letter:  uppercase ⇔ (shift XOR caps)
symbol:  shifted form ⇔ shift held
```

---

## 7. NASM Specifics

| Directive       | Effect                                                          |
|-----------------|-----------------------------------------------------------------|
| `BITS 32`       | Emit 32-bit instructions                                         |
| `section .x`    | Place following code/data into named section                     |
| `global / extern` | Export / import symbol across object files                     |
| `equ`           | Compile-time constant (no memory)                                |
| `%define`       | Preprocessor text macro (like C `#define`)                       |
| `%macro`        | Multi-line parameterized template (we use it for `gdt_entry`)    |
| `%include`      | Textual include of another `.asm` file                           |
| `db / dw / dd / dq` | Define byte / word / dword / qword (initialized data)        |
| `resb / resw / resd` | Reserve uninitialized bytes/words/dwords (only in `.bss`)   |
| `times N x`     | Repeat `x` `N` times                                             |
| `align N`       | Pad to next `N`-byte boundary                                    |

### Sections we use

| Section      | Purpose                                              |
|--------------|------------------------------------------------------|
| `.multiboot` | The Multiboot header (placed early by linker)        |
| `.text`      | Executable code                                      |
| `.rodata`    | Read-only constants (strings, prefixes)              |
| `.data`      | Initialized writable data (`screen_color`, buffers)  |
| `.bss`       | Zero-initialized writable data (cursor pos, stack)   |
| `.gdt`       | Custom — placed at `0x800` by `linker.ld`            |

---

## 8. The Linker Script (`linker.ld`)

```ld
ENTRY(_start)               /* entry symbol given to GRUB     */

SECTIONS {
    . = 0x00000800;         /* GDT must live here per KFS-2  */
    .gdt : { *(.gdt) }

    . = 1M;                 /* standard for x86 kernels       */
    .multiboot : { *(.multiboot) }
    .text      : { *(.text)    }
    .rodata    : { *(.rodata)  }
    .data      : { *(.data)    }
    .bss       : { *(.bss) *(COMMON) }
}
```

- `. = ADDR` sets the location counter (output VMA).
- Two `LOAD` segments are emitted: one for the GDT, one for the kernel image.
- Multiboot header lands within the first 8 KiB of the file (file offset `0x1000`).

---

## 9. Important x86 Instructions Used

### Data movement
| Inst        | Effect                                            |
|-------------|---------------------------------------------------|
| `mov`       | Copy reg/mem/imm                                  |
| `movzx`     | Move + zero-extend (e.g. byte → dword)            |
| `lea`       | Load effective address (does NOT dereference)     |
| `lodsb`     | `al = [esi]; esi++`                               |
| `movsw`     | `[edi] = [esi]; esi+=2; edi+=2`                   |
| `rep`       | Repeat string op `ecx` times                      |
| `cld / std` | Clear/Set direction flag (controls `lods/movs`)   |

### Arithmetic / logic
| Inst   | Effect                                                |
|--------|-------------------------------------------------------|
| `add / sub`     | Plain integer add/sub                        |
| `inc / dec`     | ±1                                            |
| `imul reg, N`   | Signed multiply in place                     |
| `div ebx`       | `eax = edx:eax / ebx`, `edx = remainder`     |
| `shl / shr / sar` | Logical/arith shifts                       |
| `xor a, a`      | Zero a register (smallest encoding)          |
| `and / or / not / test` | Bitwise / set flags only             |

### Control flow
| Inst   | Effect                                                |
|--------|-------------------------------------------------------|
| `jmp`  | Unconditional jump                                     |
| `je / jne / jl / jle / jg / jge / jb / jbe / ja / jae` | Conditional |
| `jz / jnz` | Jump on ZF (`test`-friendly)                       |
| `loop label` | `ecx--; if ecx≠0 jmp label` (⚠ wraps if ecx=0)   |
| `call / ret` | Push EIP / Pop EIP                                |
| `push / pop` | Stack save/restore                                |
| `cli / sti`  | Disable / enable maskable interrupts              |
| `hlt`        | Halt CPU until next interrupt                     |
| `lgdt [m]`   | Load GDT register from memory                     |
| `in / out`   | I/O port read/write                                |

### Flag conventions
| Flag | Set by                                      | Tested by               |
|------|---------------------------------------------|-------------------------|
| ZF   | result == 0                                 | `je / jne / jz / jnz`   |
| CF   | unsigned overflow                           | `jb / jae`              |
| SF   | sign of result                              | `js / jns`              |
| OF   | signed overflow                             | `jo / jno`              |
| DF   | `cld` / `std`                               | implicit in `lodsb` etc.|

`test a, a` is the idiomatic way to check zero (`AND` without writing back, just sets flags).

---

## 10. Register Conventions (informal, used in this kernel)

| Reg | Typical use here                                              |
|-----|---------------------------------------------------------------|
| `eax` / `al` | return value, primary scratch, char + color packing  |
| `ah` | high byte — color attr, extended scancode marker (`0xE0`)    |
| `ebx` | callee-saved scratch, variadic-arg pointer in `printk`      |
| `ecx` | loop counter (`loop`, `rep`)                                |
| `edx` | I/O port number for `in`/`out`, division remainder          |
| `esi` | source pointer (`lodsb`, `movsw`)                           |
| `edi` | destination pointer (VGA, `movsw`)                          |
| `ebp` | stack frame base (`printk`, `stack_dump`)                   |
| `esp` | stack pointer                                                |

---

## 11. The cursor / `printk` / `stack_dump` Pipeline

```
keyboard_poll → scancode_to_ascii → apply_case →
    terminal_putchar → update_cursor (VGA index ports)
                  ↘ on '\n' or wrap → terminal_scroll
shell ← keyboard_poll ‘Enter’
    ├─ help    → printk
    ├─ stack   → stack_dump (walks ebp chain via printk)
    ├─ clear   → terminal_clear
    ├─ halt    → cli; hlt loop
    └─ reboot  → out 0x64, 0xFE  (PS/2 reset line)
```

---

## 12. Things to be Ready to Defend at Eval

- **Why `cli` first thing**: there's no IDT yet, an interrupt would triple-fault.
- **Why `xor ebp, ebp`**: clean frame chain, terminator for `stack_dump`.
- **Why far-jump after `lgdt`**: refresh the cached `CS` descriptor.
- **Why GDT at `0x800`**: subject requirement (could in principle live anywhere).
- **Why selectors are multiples of 8**: each descriptor is 8 bytes; bottom 3 bits are TI + RPL.
- **Why a separate `.multiboot` section**: linker places it within the first 8 KiB so GRUB can find the magic.
- **Why `rep movsw` (not `movsb`) for VGA**: each cell is 2 bytes — one word per copy.
- **Why polling and not IRQ**: no IDT/PIC programming yet (KFS-3+ territory).
- **Why `cdecl`**: the "default" C ABI on i386, simplest to call from ASM.
- **Why custom linker file**: must not depend on host's `/usr/lib/ld.script` (forbidden by subject).
- **Why three GDT data entries (DS/SS) when they could share one**: subject explicitly asks for *Kernel Stack* and *User Stack* segments.
