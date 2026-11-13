# Firmware 14.02 kernel dump address audit

Kernel dump SHA-256: `a1522676dabb9cb51a1f94ebced0e725b1d605202a87f6c07aad2625c169a704`
ELF virtual base: `0xffffffff96810000`

This is an **address-range and raw-byte inspection**, not semantic verification of exploit offsets. No kernel RVAs have been promoted to verified.

## The dump is a post-patch image (confirmed on hardware)

Every patch row below already holds the *target* byte of its patch (`eb`,
`90 e9`, `eb 04`, `eb 00`). A stock kernel would hold a conditional branch
(`74`/`75`, `0f 85`/`0f 84`) at those sites. This image therefore records the
kernel **after** a patch pass, and it can never prove what stock code looks
like.

The real console settles it. Reading the same RVAs on a stock 14.02 machine
returns different bytes at 13 of the 14 sites, for example:

| site | reference (this dump) | real 14.02 console |
|---|---|---|
| bcopy `0xacd` | `eb` | `76` (jbe — same branch, different condition) |
| memcpy `0x2bd85d` | `eb` | `5b` (pop rbx — not a branch) |
| copyin `0x2bda4d` | `eb` | `00` |
| dlsym first check `0x1b7a43` | `eb 04` | `48 8b` |
| dlsym nop/jump `0x1b7a73` | `90 e9` | `7d c0` (short jge) |
| dlsym open `0x1b7ab8` | `90 e9 3c 01` | `83 fe 01 75` |
| self verification `0x628684` | `eb 00` | `03 02` |

A constant rebase does not explain this: searching the dump for the observed
multi-byte sequences finds no shared delta. Firmware 14.02 keeps the same
function *addresses* as 14.00 (`memcpy` is `0x2bd850` in both, per the published
14.02 offset set) but Sony changed the code *inside* those functions.

Consequence: the fixed text-patch offsets cannot be trusted on a stock 14.02
console. The host now proves each site before writing and skips the ones it
cannot prove.

| afterglow-g.js reference | RVA | ELF mapping | First bytes | Segment |
|---|---:|---|---|---|
| anchor | `0xe6c30` | mapped | `55 48 89 e5 48 8d 15 7a` | RX |
| swap_rbp | `0xa80f68` | mapped | `d3 1c 1c f3 67 64 f3 98` | RX |
| prison0 | `0x111fa18` | unmapped | `` |  |
| rootvnode | `0x2136e90` | memory-only | `` |  |
| patch: bcopy | `0xacd` | mapped | `eb 17 49 89 ea 49 83 c2` | RX |
| patch: bzero | `0x2bd79d` | mapped | `eb 04 00 00 00 44 89 f9` | RX |
| patch: pagezero | `0x2bd7e1` | mapped | `eb ff 44 89 e6 ba 04 00` | RX |
| patch: memcpy | `0x2bd85d` | mapped | `eb 41 5c 41 5d 41 5e 41` | RX |
| patch: pagecopy | `0x2bd8a1` | mapped | `eb 8a e9 ed ff 49 89 c0` | RX |
| patch: copyin | `0x2bda4d` | mapped | `eb 08 00 00 48 8d 15 b0` | RX |
| patch: copyinstr | `0x2bdefd` | mapped | `eb 00 00 00 00 c3 66 66` | RX |
| patch: copystr | `0x2bdfcd` | mapped | `eb e6 00 4c 89 81 d0 00` | RX |
| patch: dlsym, first check | `0x1b7a43` | mapped | `eb 04 4b 10 48 83 b9 50` | RX |
| patch: dlsym, second check | `0x1b7a53` | mapped | `eb 04 44 8b 3e 4c 8b a0` | RX |
| patch: dlsym, nop and jump | `0x1b7a73` | mapped | `90 e9 41 ff cf e8 c3 bd` | RX |
| patch: load_prx | `0x1b7504` | mapped | `90 e9 89 de 44 89 fa e8` | RX |
| patch: dlsym, open it to every caller | `0x1b7ab8` | mapped | `90 e9 3c 01 31 48 8d 4d` | RX |
| patch: self verification | `0x628684` | mapped | `eb 00 be 70 00 00 00 c7` | RX |
| patch: delayed panic on suspend | `0x628f6f` | mapped | `eb 00 63 f3 48 8d 3d ef` | RX |

The last row is the clearest post-patch artefact: `kernel_1402.bin` was captured
with the blob already applied, so `eb 00` at `0x628f6f` is the patch's own
output, not stock code. On 14.02 that offset is the last displacement byte of a
`call rel32` (`e8 90 40 14 00`), so the `eb` turns a near call into a jump far
outside the text. `patchset-1402.bin` retargets this one write to `0x62926f`,
which is instruction aligned and already holds `eb 00`.

**Important:** An RVA mapping to bytes does not prove that it identifies the intended kernel symbol or safe patch site. Data symbols and kernel patch locations require independent disassembly and cross-reference verification. The dump is not injected.

Because the image is post-patch, the verification tools that compare
`PATCHSET_SITES` against it are checking the table against its own expected
output, not against stock. They still guard the blob's internal consistency
(56 sites, 54 mapped, 0 mismatches) but they are **not** evidence that the
offsets are correct for a stock 14.02 kernel.

The data offsets are a different matter: `prison0` and `rootvnode` are read on
hardware and the credential escalation succeeds, so those RVAs are confirmed.
Only the *text* patch offsets are unverified on this build.
