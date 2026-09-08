# Historical Pegboard Click rail check — superseded

The findings below describe the legacy four-bump design before the rail-lock option was added. The CURRENT shelf enables `pegboardRailLock = true` by default, with two correctly shaped bumps and a minimum 48 mm back. Its seated intersection checks pass in both Multipoint modes with `slotQuickRelease = false`. Both full-shelf STLs and `Pegboard_Rail_Fit_Coupon.stl` have been regenerated with that configuration. See `Multibin_Shelf_Notes.md` for current controls. The user has physically confirmed the attachment fits their pegboard.

The supplied `Pegboard Click - Multipoint Rail (Supported).stl` was compared with the current shelf's centre slot in both Multipoint modes. No shelf design settings were changed by this inspection.

- The default `slotQuickRelease = false` produces four intersections with the rail at the locking bumps at the tested insertion depth. Pulling the rail farther out to clear those bumps instead caused interference at the retaining lips/end profile.
- `slotQuickRelease = true` removes those bumps. The seated rail then produced an empty intersection with the complete shelf in both 25 mm and 25.4 mm modes. Rail face clearance to the deepest slot plane was 0.2 mm in the tested placement.
- The attachment's pre-modelled support projecting beyond the rail face (X below -3 mm and Z below 0.601 mm in its supplied orientation) was excluded from the fit check. Remove sacrificial printing supports from a physical part before assembly.
- These are static CAD checks, not a physical slide, retention or load test. The setting removes the bump-based locking action.

`Pegboard_Rail_Fit_Coupon.stl` is a one-slot test plate using the passing quick-release configuration. Its back lies flat on the print bed and its channel opens upwards. The existing full-shelf STL still uses the original default locking bumps; set `slotQuickRelease = true` and export again if choosing this configuration.

The designer identifies the attachment as a two-Multihole rail whose Pegboard Click fits Multiboard tiles, not as a verified standard 1-inch pegboard attachment:
https://thangs.com/designer/MultiBuild/3d-model/Pegboard%20Click%20-%20Multipoint%20Rail%20%28Supported%29-1470823

The attachment click centres are 25 mm apart. The shelf's 1-inch option changes spacing between separate rails to 25.4 mm; it does not change the attachment's own click spacing or establish compatibility with a different board's hole size/thickness.
