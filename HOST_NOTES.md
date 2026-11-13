# Local WebKit host — PS4 14.02

This folder is the server root. Everything below is served over HTTP; the PS4
browser only needs the printed URL (including `?key=`).

## Start

Double-click **serve.bat** (it also accepts the `py` launcher), or:

```
py -3 server.py 9021
```

The terminal prints two links:

```
Admin panel  ->  http://<lan-ip>:9021/admin?ak=<admin-key>
PS4 browser  ->  http://<lan-ip>:9021/?key=<access-key>
```

Open the **PS4 browser** link on the console. Keep the terminal open; it shows
every `[AFTERGLOW]` log line live.

### Manual menu (recommended)

```
http://<lan-ip>:9021/start.html?key=<access-key>
```

`start.html` is now a **static menu**: nothing runs until you tap a card, and it
never auto-launches. Use the green **Jailbreak only — no payload** card first
after a **full console reboot**; it stops before the payload loader, so it cannot
crash. The other cards start a specific payload image.

The dashboard (`index.html`) also waits for a tap. An old restored URL such as
`index.html?auto=1...` is ignored on purpose, so the console cannot skip the menu.

The chain refuses a direct hit on `launch.html`: the referrer must be
`index.html` or `start.html`, otherwise it bounces back to the dashboard.
`launch.html` also rewrites its own history entry to `index.html?afterglow=done`
so a reboot restores the dashboard, not an armed chain.

- Server binds `0.0.0.0:9021`.
- If Windows Firewall prompts, allow private networks (or add an inbound rule
  for TCP 9021).
- The access key and admin key are regenerated on every server restart.

## What was changed for 14.02

| File | Change |
|---|---|
| `afterglow-g.js` | `swap_rbp` fallback set to the real gadget `0x0a81478` (the old `0x0a80f68` is compressed data on this build). The runtime `4e 95 c3` scan is unchanged. |
| `afterglow-g.js` | Kernel patch 15 (`delayed panic on suspend`) moved from `0x0628f6f` to the 14.02 site `0x062926f` and marked **advisory**. The old address is inside a `call rel32` here and corrupts it; the new site already holds `eb 00`, so the write is a no-op. |
| `afterglow-g.js` | Patch table is **fail-closed**: a site is written only when it already holds the target bytes, a known stock pattern, or the *same branch shape* with a different condition code. Anything else is reported and skipped — it never aborts the jailbreak, because these are payload-support patches the exploit does not use. |
| `afterglow-g.js` | `[8]` now reports **both** sides (`reference has 74\|75, this build has 76`) instead of only the observed bytes. |
| `afterglow-g.js` | `[OPEN-CHECK]` prints `errno` only when the syscall actually failed. A successful `mprotect` left a stale `errno=22` in the log and made a healthy run look broken. |
| `afterglow-g.js` | Payload loader now emits **synchronous** breadcrumbs (`[p] 1 fetch` … `[p] 8 pthread_create`) so the last line on screen names the step that faulted. |
| `afterglow-g.js` | `rawcopy=1` opt-in: skips the host's payload-byte patches and starts the payload at its own entry. Every bundled payload needs it on this build; without it the loader refuses at `0x1136`. |
| `afterglow-g.js` | `base=0x...` opt-in: maps the payload with `MAP_FIXED` at an absolute address. `goldhen.bin` is a flat loader linked at **0x926200000** with the kpayload embedded at +0x6480; it crashes if mapped at a random address. The host forces this base for any `goldhen*` payload. |
| `afterglow-g.js` | GoldHEN path now installs **`kpayload.elf`** — GoldHEN's own 14.02 kernel payload — instead of the 14.00 blob. Its symbol table carries `ksdk_offsets_1402`, `get_kbase`, `entry`, `install_fakeself_hooks` and `load_{ftp,payloader,klog}_server_module`; it is mapped at its link base `0x100000` (it keeps globals at absolute disp32 addresses up to `0x198420`) and `entry()` is called from ring 0 through the gate. The blob is only a fallback for a build that actually matched it. |
| `afterglow-g.js` | Before calling it, `kpayload.elf` must carry at least 3 of the 5 known 14.02 hook addresses, and `0x100000` must be free — the host bails rather than using `MAP_FIXED` over someone else's mapping. |
| `afterglow-g.js` | The standalone Debug Settings patch is skipped for GoldHEN (GoldHEN flips the same flags), can be forced with `debugmenu=1`, disabled with `debugmenu=0`, and reports `verified` only after a read-back. |
| `afterglow-g.js` | `pinCore()` now tries every allowed core instead of only the first and reports which one it got. |
| `patchset-1402.bin` | New 641-byte blob: `patchset.bin` with the `0x628f6f` displacement retargeted to `0x62926f` (one byte, offset `0xc5`). |
| `debug.bin` | Offset-table entry at `0xfc18`: `0x6272b0` → `0x627270`, matching `hen.bin` / `loader.bin` / `kpayload.elf`. Original kept as `debug.bin.orig`. |
| `start.html` / `index.html` | Launch URLs now add `rawcopy=1` for every payload and `base=0x926200000` for both GoldHEN images. |
| `server.py` | Serves scripts/payloads with `Cache-Control: no-cache, must-revalidate` so the console always revalidates (a stale `.js` otherwise replays a fixed bug). |
| `serve.bat` / `14.02 Jailbreak.bat` | Python detection now accepts the Windows `py` launcher. |
| `index.html` | Adds a **Jailbreak only — no payload** choice plus the two custom loader builds (`rawcopy=1`). Removed the auto-launch behavior. |
| `start.html` | Static **manual menu**; every card links straight to the chain, no countdown/auto-run. |
| `jb-g.js` | Referrer guard accepts `start.html` as well as `index.html`. |
| `launch.html` | Rewrites its history entry to `index.html?afterglow=done` before running. |

`patchset.bin` is **not** run as-is. The 14.02 form is `patchset-1402.bin`,
and the GoldHEN path applies and verifies it before starting the payload. The
14.00 mis-patch described in `PS4-14.02-PORT-SPEC.md` §4 is exactly what the
retarget removes. `patchset.bin` itself was not modified; a copy of it is kept
as `patchset.bin.orig`. The original `debug.bin` is saved as `debug.bin.orig`.

## Payloads

Bundled and selectable in the dashboard:

| Name | Note |
|---|---|
| `hen-1402.bin` | **Primary 14.02 payload** (502,400 B, `ps4-hen` rebuilt for 14.02). Entry gate `4.74-14.02`, 4 `cmp ax,1402` kernel-branch sites. Loaded through the pre-flight + GOT pre-fill path. Installs HEN and starts **FTP on 2121**. |
| `binloader.bin` | Firmware-independent receiver (4,482 B, raw syscalls only). Listens on **TCP 9020**, takes raw (`E9`) and ELF64 payloads, re-listens after each one. The host probes 9020 after starting it. |
| `hen.bin` | 14.02 `ps4-hen` rebuild — byte-identical to `hen-1402.bin` (502,400 B). Same path. |
| `goldhen.bin` | GoldHEN loader + zlib kpayload (297,496 B). Installs `kpayload.elf` (14.02 kernel payload) first, then starts the loader at `0x926200000`. |
| `payload.bin` | Original ps4-hen-style payload (297,931 B). No FW gate, so the pre-flight refuses it honestly. |
| `debug.bin` | Debug payload. Its offset-table entry at `0xfc18` was aligned with `hen.bin` (`0x627270`). Not replaced by the 14.02 archives (theirs is a different, 3.5 KB file). |
| `hello.bin` / `hello.elf` | Test payloads. `hello.elf` is meant to be **sent to TCP 9020**, not loaded by the host. |
| `goldhen-custom.bin` | Your `goldhen.bin` = `loader.bin` (25,396 B) + zlib kpayload. Same path as `goldhen.bin`. |
| `hen-custom.bin` | Your older `hen.bin` (501,152 B). Kept; the 14.02 rebuild supersedes it. |

Every replaced payload has a `.orig` backup next to it (`hen.bin.orig`,
`goldhen.bin.orig`, `payload.bin.orig`).

`hen.bin`/`hen-1402.bin` need **no loader byte patches** — they carry their own
per-firmware offset tables and ring-0 patch loop. The old hardcoded debug.bin
patches (`0x1068`, `0x1136`, `0x3490`) were removed because they landed
mid-instruction on this build; that was the freeze.

Your build inputs are also copied to `payloads/` for reference (`loader.bin`,
`loader.elf`, `kpayload.elf`, linker scripts). They are reachable at
`/payloads/<name>` but not wired into the dashboard.

## Reading a failed run

The chain logs to `/ag_log`; the dashboard polls `/ag_status`.

- `[9] jailbroken, uid 0` — kernel stage reached ring 0.
- `[10] kernel interface is live` / `handles defused` — the kernel side is fine.
- `[EARLY-RETURN] ... reason=kernel-already-open action=reboot-required` — the
  kernel is still patched from an earlier successful attempt **on this boot**.
  Nothing was run this time. Power the console fully off (not rest mode), then
  power on and launch again. One successful kernel run per boot.
- `[HOST-DIAG] no script output after 10s` — the browser did not execute the
  ES module (`jb-g.js`). Nothing ran; that build's browser lacks module support.
- `[p] N ...` — the loader step. **The last `[p] N` line is the step that
  panicked**; those emits are synchronous.
- `[PSIG-DIAG] status=blocked` — the default loader refused the payload because
  `0x1136` is not the expected `E8` kernel-entry call. For loader-composite
  images use `rawcopy=1`; for anything else the patch offsets for that payload
  are unknown and the host deliberately refuses rather than guess.

Notes:

- `thread rc=0` only means `pthread_create` returned success; it is not proof
  the payload initialized.
- A `goldhen.bin` loader must be mapped at `0x926200000` (`base` parameter), or
  its absolute references and embedded kpayload land in the wrong place and the
  console crashes. The host forces this base for `goldhen*` and logs
  `[p] fixed base requested ...`, then `[p] mmap did not honor fixed base` if
  the address is unavailable.
- `[g] patch set verified N of 56 sites` is the gate for GoldHEN. A lower number
  means the kernel patch set did not take; the host then logs
  `refusing to start ... without a verified kernel patch set` and starts nothing.
- `[8] ... reference has X, this build has Y -- different code, left untouched`
  means the fixed 14.00-derived text offset does not point at the same code on
  this console. Those sites are now **skipped, not fatal**: the exploit and the
  ring 0 interface do not need them, so the run continues to `[9]`/`[10]`.
- `[8] ... same branch, applying` means the build encodes the same test with a
  different condition code (e.g. `76` where the reference had `74`/`75`). The
  host only rewrites a conditional branch into an unconditional one when the
  branch width and displacement match, so it cannot land mid-instruction.
- `[g] kpayload.elf carries N/5 of the 14.02 hook addresses` is the build check.
  Fewer than 3 means the payload is not this firmware's build and is not called.
- `[g] calling GoldHEN entry 0x... in ring 0` then `[g] GoldHEN kernel payload
  returned` means the kernel side installed. FTP (2121) and the BinLoader /
  PayLoader server (9090) are opened by the userland half that runs next.
- `[g] 0x100000 was not available for the kernel payload` means the address the
  payload was linked for was taken. The host deliberately does **not** force it;
  a `MAP_FIXED` there would overwrite whatever is mapped. Cold boot and retry.
- The kernel patch lives until reboot. A successful run requires a cold boot
  before the next attempt. A failed run counts too: `mprotect` succeeding on the
  next attempt (`[OPEN-CHECK] ... mprotect=0`) means the kernel is still patched
  from the previous run, and the host returns `kernel-already-open` until the
  console is fully powered off and on again.
- `prison0` / `rootvnode` are BSS values and cannot be verified from the kernel
  image; `prison0` is left at the table value because the observed 14.02 run
  passes `[9]` with it.

## Known limits

- WebKit gadget/module offsets for 14.02 are still *assumed* identical to
  13.52 — the kernel dump cannot verify userland module RVAs.
- There are no stock 14.02 kernel bytes on this host. The patch table's
  origin-byte checks therefore use inferred branch opcodes (`74`/`75`,
  `0f85`/`0f84`); a site whose bytes match none of them is left untouched and
  aborts the run.
- The `0x1257xx` block inside `patchset-1402.bin` does not disassemble as
  linear code, but its writes match the post-patch dump exactly. Its meaning is
  unverified; it is kept because GoldHEN's own loader accepts it.
- The write at `0x1102d88` stores `LSTAR + 0x8f4`, a runtime value, so it is
  the one site the read-back cannot check.
- This is still a beta/diagnostic build. Only run payloads and hosts you trust,
  on hardware you own.
