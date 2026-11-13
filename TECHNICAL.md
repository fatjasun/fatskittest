# How it works

The kernel bug, the reclaim, the ring 0 bootstrap and the handle teardown are
the same as in the Lua version of afterglow and are not repeated here.

This file covers what is specific to running it out of the browser.

## The two stages

The browser host does not reach the kernel by itself. It runs in two stages:

1. **`jb.js`** — the raw13g host. It builds the in-process primitive from
   WebKit and hands over four things, and only these four:

   | | |
   |---|---|
   | `sc(num, ...args)` | syscall with an arbitrary number, returns `{lo, hi, i32}` |
   | `bufAddr(arrayBuffer)` | address of a backing store |
   | `p.read1/4/8`, `p.write1/4/8`, `p.readInto` | memory in this process |
   | `keepAlive` | an array, so buffers survive the collector |

2. **`afterglow.js`** — the kernel exploit, which uses nothing else. There is
   no requirement for a way to call native code: the only `native.fcall` in the
   exploit enters a stub that is itself `SYS_syscall(11, body)`, which a host
   with a syscall primitive issues directly.

That boundary is why the same exploit drives both hosts. Anything offering the
four above can carry it.

`probeAfterglow()` fires nothing and answers whether the current process can
carry the exploit at all; `runAfterglow()` is the live chain.

## Which loader, decided by content

There are two forms of enabler image, and from the outside they look alike:

| Form | How it is recognised | Path taken |
|---|---|---|
| raw payload | begins with `e9` (jmp rel32) | map it, start a thread |
| composite image | exactly 964,440 bytes | patch chain, trampoline, padding RW |

`loadEnabler` in `afterglow.js` decides on the content, **not** on the file
name. Deciding by name sends a raw payload down the composite path, where the
length check rejects it.

## The kernel patch set

GoldHEN expects to find a patched kernel. afterglow's own fifteen JS patches
cover only part of what it needs; the remainder — one block around `0x125791`
and three singles — are exactly the ones GoldHEN's code looks for.

`patchset-1402.bin` (641 bytes, position independent, ends in `ret`) is the
14.02 form and runs before **every** GoldHEN payload, in both image forms:

* `runPatchSet()` copies the blob into the ring-0 body area and enters it
  through the gate, i.e. as `SYS_syscall(11, body)`.
* The blob derives the kernel base with `rdmsr`, lifts write protection once,
  performs 57 absolute writes (56 file-backed sites plus the runtime
  `LSTAR + 0x8f4` slot at `0x1102d88`), restores WP and returns.
* `verifyPatchSet()` then reads all 56 constant sites back. GoldHEN is started
  only when every one matches; otherwise the host logs the missing sites and
  refuses to launch (fail-closed).

The 14.00 write at `0x0628f6f` falls inside a `call rel32` on 14.02
(`e8 90 40 14 00`), so writing there corrupts the call and panics. In
`patchset-1402.bin` only that displacement is retargeted, to `0x062926f`, which
is instruction aligned and already holds `eb 00`; the write becomes a harmless
no-op. Exactly one byte differs from `patchset.bin` (`8f` → `92` at offset
`0xc5`), so the instruction stream and the 641-byte length are unchanged.

The blob was decoded with a small emulator (57 writes) and checked against
`kernel_1402.bin`, the post-patch 14.02 dump: all 54 file-backed sites match
byte for byte; the three data slots at `0x1102d80`, `0x1102d88` and `0x1102dac`
lie outside the dump's file mappings. The dump therefore proves the blob applies
as intended; it cannot show stock bytes, because it was captured after the
patch.

## Two guards

* **The referrer guard.** The run page arms the chain only when it was reached
  from `index.html` in the same directory. The console's browser restores the
  last page it had open; without this, a page left on the armed chain would run
  it again with nobody in front of the screen. The guard sits in `jb.js`, not
  in the server, so it holds however the files are served.
* **`no-store` on every response.** The console's browser holds on to modules,
  and a corrected file would otherwise never arrive. `serve.sh` sets it; any
  other server used instead has to do the same.

## The ps4-hen offset

`kpayload/source/offsets/1400.c` gives `sceSblPfsSetKeys_addr = 0x006272B0`.
The function starts at `0x00627270`.

* The two call sites ps4-hen hooks itself (`mountpfs__sceSblPfsSetKeys_hook1`
  at `0x06a39f9`, `hook2` at `0x06a3c2a`) contain `call` instructions whose
  target is `0x0627270`.
* Three calls in the kernel point at `0x0627270`, none at `0x006272B0`.
* `0x0627270` begins `55 48 89 e5`; `0x006272B0` is `89 45 d0`, mid function.

The hook replaces both call sites and then calls the "original" 64 bytes past
its entry, on every PFS mount — that is, on every application launch.

The bundled `debug.bin` carries the same offset table as `hen.bin`, but at file
offset `0xfc18` it held `0x006272B0` while `hen.bin`, `loader.bin`,
`goldhen.bin` and `kpayload.elf` all carry `0x00627270` in the same slot. The
entry was changed to match the rest of the family (one byte, `b0` → `70`);
`debug.bin.orig` keeps the original. (The 14.02 dump places `0x627270` inside a
switch-thunk table, so it cannot confirm the address; the family consistency is
the evidence.)

`RsaesPkcs1v15Dec2048CRT_addr = 0x0021BFC0` has no prologue either (nearest at
`0x0021BD20`), but it is never called directly, so this is unconfirmed.

## Scope

The kernel patch lives until the console reboots. Nothing here persists.
