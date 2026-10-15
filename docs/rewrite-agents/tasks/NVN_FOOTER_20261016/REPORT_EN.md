# Map footer and feedback control

Issue: `quiz_master-nvn`. Production reproduction: Country483 at 361 x 738,
with French Southern and Antarctic Territories selected. The global feedback
control painted over the long country name in the map footer.

The map footer used its whole width despite the global feedback overlay.
Reserve trailing space in the existing scroll view, inside its existing safe
area. This keeps the name, search and exit controls away from the button;
text and feedback remain available. No dependency, content or API change.

The integration regression loads the real application shell and catalog,
selects the reported country through search, and compares the rendered footer
name with the actual feedback button. It failed before the fix (overlap true).
Afterward all 18 feedback and Quizipedia tests passed, including 1x and 2x text
at 361 x 738 with 24 px right/bottom safe insets. Focused analysis passed.

The actual Flutter debug target ran on loopback port 19094. Root sent `r`
through terminal session 25474 after the browser connected; Flutter reported
`Reloaded application in 1,600ms.` Root viewed the mobile and desktop PNGs.
Browser actions exercised search, long-name selection, focus/zoom, feedback
dialog open/cancel and exit; the browser error list was empty. No feedback was
submitted. This is local Flutter Web evidence, not a production or Android test.

Harness limitations are retained: the npm shim reported 0.37.1 while its native
binary/daemon was 0.39.1. Initial open returned EOF although the page opened.
Subsequent checks used the installed official native binary with a consistent
version. A separate DevTools navigation aborted and its own blank tab was
closed. Official browser close returned timeout exit 1; Root then verified the
captured named daemon's PID, command and native/CIM creation times, stopped
only that daemon and verified all 12 captured identities inactive. Flutter
quit normally with exit 0. The initial audit correctly refused while the
daemon was still alive; its later successful cleanup receipt is retained.

Status: source fix verified locally. Production is still Country483 / Helm 64.
The issue stays in progress until a new candidate passes release gates and the
same interaction is verified after publication. No Android, Wasm, full content
fact certification or production update is claimed by these checks.
