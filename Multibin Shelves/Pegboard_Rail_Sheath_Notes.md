# Pegboard rail sheath / side-shim frame

This adapter is for the **previously printed 17 mm-wide Multipoint slots**, with the two-bump Pegboard Click option and 48 mm back height. Do not use it in the newer 15.1 mm rail-specific channels.

The supplied Fold-In Locked Lite Rail is a different interface (23.6 x 38.75 x 8.775 mm overall). This self-contained design borrows its connected-frame approach, but derives the actual mating surfaces from the standard Multipoint rail and the older shelf slot.

The frame is 16.8 x 34.5 x 0.8 mm. Its two tapered side strips fill the lateral space around the 14.8 mm-wide rail. A bridge sits below the rail, within the existing 2 mm bottom allowance. The open back leaves the shelf's two locking bumps exposed. This is a lateral shim, not an additional snap lock or a complete enclosing sleeve. The nominal combined horizontal clearances are approximately 0.4 mm, versus 2.2 mm at the widest section before adding the frame.

Print flat as exported. The thinnest side-strip section is approximately 0.46 mm wide; check that your slicer produces a continuous line there. At 0.2 mm layer height the frame is four layers thick. Infill is not significant for this thin part. Handle gently when removing it from the bed.

Slide the open ends upward around the standard rail's wide face, with the bridge below the rail's lower end. Hold it in place while sliding the shelf down over both. The tapered edges face the slot's narrowing opening. Use one frame per occupied slot. Try one before printing the rest.

`railClearance` and `shelfClearance` are horizontal per-side allowances, both 0.10 mm by default. `shimDepth` is 0.8 mm. Assertions prevent adjustments that leave less than 0.4 mm at the strip tip.

Validation checks the adapter against the supplied standard rail and the saved pre-tightening shelf model, allowing 0.02 mm off the slot's inner plane to avoid coincident-face numerical artifacts. These are static seated checks, not a physical insertion or retention test. Default and thinner/tighter variants are rendered and checked for closed, connected meshes.
