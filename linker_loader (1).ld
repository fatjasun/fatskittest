/*
 * linker_loader.ld - the loader's flat image.
 *
 * The exploit copies the loader to 0x926200000 and jumps to its base, so the
 * image is linked at that address with the entry point first.  Everything the
 * loader addresses - GOT slots, the firmware word, the embedded kpayload - is
 * an absolute literal outside this image (kernel.h, globals.h, loader.h), so
 * the image only holds code and its own read-only data.
 *
 * The image must stay below 0x6480 bytes: the embedded kpayload starts at
 * 0x926206480.
 */
ENTRY(entry_stub)
SECTIONS
{
    . = 0x926200000;

    .text : {
        *(.text.entry_stub)
        *(.text*)
    }

    . = ALIGN(16);
    .rodata : { *(.rodata*) }

    . = ALIGN(16);
    .data : {
        *(.data*)
        *(.got*)
    }

    . = ALIGN(16);
    .bss : {
        *(.bss*)
        *(COMMON)
    }

    /DISCARD/ : {
        *(.eh_frame*)
        *(.comment*)
        *(.note*)
        *(.llvm*)
    }
}
