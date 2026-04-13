# Steam Deck Runtime Note

## Current tested result

- Proton 9: unsupported for the current Windows build
  - installation/startup path fails
- Proton 10: required/tested working path
  - install works
  - launch works
  - Steam runtime features work

## Likely reason

This is a runtime compatibility issue, not a rendering-complexity issue.
The current Windows build depends on:
- fused LOVE 11.5 executable
- custom native Steam bridge
- Steamworks init and user stats
- Steam Input manifest/config handling

That stack is compatible on Proton 10 and not reliably compatible on Proton 9.

## Current launch posture

- Shipped Windows build on Steam Deck should be treated as Proton-10-tested.
- Native Linux / Steam Deck build remains a separate workstream.
