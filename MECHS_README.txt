================================================================================
                         M E C H S   W E B K I T
                                  B E T A
================================================================================
                      PS4 WebKit Host | Firmware 14.02
                         Custom Dashboard & Diagnostics
================================================================================

WELCOME
-------
Mechs Webkit Beta is a locally hosted PS4 WebKit dashboard with payload selection
and diagnostic logging. It includes the supplied goldhen.bin and the existing
Afterglow-based launch sequence.

IMPORTANT: A successful loader message does not confirm GoldHEN initialized.
Firmware compatibility and successful execution are not guaranteed.


QUICK START  |  WINDOWS
----------------------
  1. Extract the entire "Mechs Webkit Beta" folder from the ZIP.
  2. Keep all project files together in that folder.
  3. Double-click serve.bat to start the local host.
  4. Find the access URL printed in the terminal (including ?key=...).
  5. Open that complete URL in the PS4 web browser on the same network.
  6. Use the dashboard to select a payload and launch the existing sequence.
  7. Leave the server terminal open to view diagnostic output.

QUICK START  |  LINUX / macOS
----------------------------
  Run serve.sh from the extracted project folder, then follow the printed
  access URL. Python 3 is required for the included server.


WHAT'S INCLUDED
---------------
  index.html                 Mechs Webkit dashboard
  server.py                  Local HTTP server, session and log endpoints
  serve.bat / serve.sh       Host launchers
  launch.html / jb-g.js      Existing WebKit launch flow
  afterglow-g.js             Existing Afterglow and payload-loading flow
  goldhen.bin                User-supplied payload
  MECHS_README.txt           This guide

Other files support the existing host and exploit workflow. Do not remove
files simply because they are not listed above.


DIAGNOSTIC GUIDE
----------------
  [KTABLE-DIAG]   Kernel offset-table information; not proof of exploit success
  [KINIT-DIAG]   Module import / launcher execution boundary markers
  [PDIAG]        Payload entry and thread-creation diagnostics
  [PBYTE-DIAG]   Read-only comparison of bytes before existing modifications
  [p]            Payload loading progress and loader return messages

Key distinctions:
  * HTTP 200 for a script means it was served, not necessarily executed.
  * "15 of 15 kernel patches" is the exploit's own reported status.
  * pthread_create rc=0 means thread creation succeeded; it does not confirm
    the payload reached or completed its initialization routine.
  * [PBYTE-DIAG] copyMatch=true checks copied bytes, NOT whether the loader's
    hard-coded patch offsets are correct for the payload.
  * The GoldHEN menu appearing is a useful visible sign of initialization;
    absent a payload-side acknowledgement, initialization remains unconfirmed.


TROUBLESHOOTING
---------------
  PAGE RETURNS 403
    Reopen the complete access-key URL printed by the server. An old bookmark
    or a redirect without the authenticated session may be rejected.

  BROWSER FREEZES
    Record the last diagnostic line from the terminal. Avoid repeated forced
    shutdowns. A received script is not evidence its next stage completed.

  LOADER REPORTS SUCCESS, BUT NO GOLDHEN MENU
    Treat initialization as unconfirmed. Capture [PDIAG], [PBYTE-DIAG] and [p]
    lines; thread creation alone is insufficient evidence of execution.

  NO LOGS APPEAR
    Confirm the PS4 can reach the host, the server remains running, and the
    full URL (including its access key) was opened.


PROJECT NOTES
-------------
  - This Beta build is intended for testing and diagnostics.
  - The existing exploit logic, payload, and hard-coded modifications have
    not been changed by this README update.
  - Keep backups of builds that reach known diagnostic checkpoints.
  - Only run binaries and hosts from sources you trust.

================================================================================
                       MECHS WEBKIT BETA  |  END OF GUIDE
================================================================================
