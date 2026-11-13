Mechs WebKit 14.02 — Non-invasive payload diagnostics

[PDIAG] entry-inspect reads the raw x86 E9 near jump at file offset zero and checks the relative target is inside the file. This does not validate payload ABI or firmware support.
[PDIAG] entry-ready reports the existing mapping base and explicitly notes that the existing loader patches payload bytes and bypasses a kernel entry call. No new patching added.
[PDIAG] thread-return reports pthread_create return code and thread handle. Thread state is unknown; no join, wait, or polling is performed.
[PDIAG] initialization always reports acknowledgement unavailable: the payload has no verified callback/handshake.
Dashboard and /ag_status expose these diagnostics. Existing kernel operations and loader patches are unchanged.
