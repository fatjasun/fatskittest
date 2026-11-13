/*
 * linker_kpayload.ld - the kpayload ELF.
 *
 * The decompiled sources address their data by absolute address in the
 * 0x111xxx..0x199xxx range, which is image base 0x100000: the original payload
 * was linked there and loaded by the loader's ELF mapper with relative
 * relocations.  Linking at the same base keeps those literals meaningful.
 *
 * The .data/.bss window is reserved out to 0x199800 so every absolute
 * reference falls inside the image.  The contents at those addresses come from
 * the original payload image, not from this compile - see docs in README.
 */
ENTRY(entry)
SECTIONS
{
    . = 0x100000;

    .text : { *(.text*) }

    . = ALIGN(0x1000);
    .rodata : { *(.rodata*) }

    . = ALIGN(0x1000);
    .data : { *(.data*) *(.got*) }

    . = ALIGN(0x1000);
    .bss : {
        *(.bss*)
        *(COMMON)
    }

    /* Reserve the absolute-data window the decompiled literals address. */
    . = 0x199800;

    /DISCARD/ : {
        *(.eh_frame*)
        *(.comment*)
        *(.note*)
        *(.llvm*)
    }
}
