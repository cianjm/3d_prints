# Multibin shelf

Open `MultiConnect_Multibin.scad` to customize the shelf. `MultiConnect_Multibin.stl` is the default 2 × 2 LU version. The original Gridfinity source is preserved.

The supplied 2 × 2 × 0.5 LU topped-rail shell measures 100 × 100 × 30 mm. The shelf now has a **raised locating grid on 50 mm centres** that enters the underside channels between the shell's feet. Each foot sits in its own pocket, resisting movement in both horizontal directions, including when smaller shells share a larger shelf. The shell lifts straight out; this is a drop-in locating interface, not a snap-lock.

The ridges follow the measured groove profile: a 0.4 mm entry chamfer, straight walls from 0.4 to 3.6 mm, and a 45-degree upper taper toward the 5.4 mm-deep groove roof. Default horizontal clearance is **0.10 mm per side**, reduced from 0.15 mm after the first physical fit test felt slightly loose. Default ridge height is **5.1 mm**, leaving 0.3 mm below the main groove roof and space below shallower crossings. The floor supports the feet, so the ridge tops do not carry the shell's weight. Perimeter grid lines also locate a single 1 × 1 shell.

| Height above floor | Measured groove width | Ridge width |
|---|---|---|
| 0 mm | 7.2 mm | 7.0 mm |
| 0.4–3.6 mm | 6.4 mm | 6.2 mm |
| 5.1 mm | 3.4 mm | 3.2 mm |
| 5.4 mm | 2.8 mm, groove roof | No ridge; vertical clearance |

The 0.10 mm clearance is measured horizontally, including along the sloped faces. The taper retains its measured 45-degree angle. This is a snug-fit starting allowance for FDM; adjust after a fit print if necessary.

The outer bay is 100.6 × 100.6 mm, with a 2 mm-high rim and 1.5 mm-thick side walls and braces. The braces stay above the shelf and match the original Gridfinity brace thickness. No extra width is added outside the side walls. Bay clearance is separate from the ridge-to-groove clearance.

## Pegboard layout

Select **Multipoint - 1 inch Pegboard** (the default). Horizontal slot spacing is 25.4 mm. With `pegboardRailLock = true`, the channels fit the supplied Pegboard Click rail specifically. With it disabled, the original Multipoint profile and repeated entry/catch spacing are retained. It requires compatible Multipoint-to-pegboard mounting hardware; the shelf itself has slots rather than integral pegboard hooks.

The compact 2 × 2 shelf is **103.6 mm wide** and has **three vertical slots**, centred at 26.4, 51.8 and 77.2 mm from the left edge. Their spacing remains 25.4 mm. Slotted backs reserve approximately one pitch at each edge when calculating the automatic count; a 1 × 1 shelf has one slot. Subtracting slots preserves the surviving positions.

This layout follows the revised request to remove the width padding and retain supports above the shelf. The 100.6 mm bay plus two 1.5 mm walls determines the width directly. Because 103.6 mm is not a whole pegboard pitch, identical shelves mounted on the same hole grid no longer sit flush: their next non-overlapping position is 127 mm apart, leaving a 23.4 mm gap.

## Useful controls

- `baseOnly`: set to `true` to omit the back plate and tall supports for a fit test. Combine with `removeBase = true` to print only the ridge grid; otherwise it includes the floor and low rim.
- `unitsWide`, `unitsDeep`: capacity in 50 mm LU for the supplied shell family.
- `shellClearance`: gap per side, adjustable for printed fit.
- `grooveClearance`: ridge-to-channel gap per side; reduce it for less lateral play or increase it for easier insertion.
- `locatorClearance`: fit allowance for the added corner and midpoint locators, default 0.10 mm. Corner clearance is normal to the diagonal face; notch-tip clearance is horizontal. This does not increase the straight ridge width.
- `grooveRoofClearance`: vertical gap below the groove roof, default 0.3 mm. Height and taper are derived from the measured profile. This replaces the earlier independent `ridgeHeight` and `ridgeTopChamfer` controls.
- `additionalRimHeight`, `baseThickness`, `rimThickness`: rim and material dimensions.
- `bracketThickness`: thickness of the supports above the shelf, default 1.5 mm; must fit within the side walls.
- `removeBase`: set to `true` to remove the entire floor, supporting strips and low rim, leaving the connected locating ridges. Ridge roots start at Z = 0. With `baseOnly = false`, the back plate and tall side supports remain. The default `false` keeps the solid floor.
- `Connection_Type`: retains Multipoint, Multiconnect and GOEWS options.
- `pegboardRailLock`: enabled by default for both Multipoint modes. Uses a closer-fitting continuous rail channel and replaces the legacy four bumps with one upper pair shaped for the supplied Pegboard Click rail recesses. Insert from below; generic pop-in ramps are omitted in this mode. Other mounting standards are unaffected.
- `railSlotClearance`: horizontal allowance per side, default 0.11 mm. The supplied rail is 14.8 mm wide; the new channel is 15.02 mm at its widest section, versus the original 17 mm. The channel follows the measured 45-degree taper, with 0.20 mm face clearance. This control affects only rail mode. Increase to 0.20 mm if the coupon binds.
- `railRecessDepth`: default 0.80 mm additional depth into the back plate. Moves the fitted channel and its locks inward together, with 0.11 mm side clearance. Zero restores the previous seating depth. The cutter extends through the rear face so there is no thin membrane over the opening.
- `railLockClearance`: default 0.10 mm. The new bumps project 0.50 mm from the slot's inner plane, with 0.20 mm to the rail face and 0.30 mm engagement into its 0.40 mm recesses.
- `railEndClearance`: default 2 mm below the seated rail. The rail option raises back height to at least stop distance + 33 mm + this clearance, even if a smaller custom height is requested.
- `slotQuickRelease`: overrides either locking-bump layout and removes inward bumps. Leave it `false` to use the new pair; set `pegboardRailLock = false` to restore the legacy layout.

The source is self-contained; BOSL2 is no longer required. Back-plate edge rounding was replaced with square edges. Original author credits and license wording are retained in the source header.

Default overall dimensions are **103.6 × 106.9 × 48 mm**, including the back plate. The 41 mm rail spans Z = 2 to 43 mm, leaving 2 mm below it and 5 mm above it to the back-plate edge. The slot's closed top is approximately 0.15 mm above the rail. The part starts at Z = 0. Inspect channel overhangs in the slicer. The previous rail connection fitted physically but felt loose. This tighter channel needs a new fit print; the bin locating geometry is unchanged from the successful fit print.

## Validation

The new rail lock passes static intersection checks against the supplied attachment in both Multipoint modes (`validation/check_pegboard_rail.py`). `validation/check_rail_options.py` validates default, short requested height, extra end clearance, quick-release, legacy and no-base variants, and confirms unchanged base-only geometry. The regenerated `Pegboard_Rail_Fit_Coupon.stl` contains one channel with the two-bump lock and 48 mm height. Test insertion/removal before a full print; CAD clearance does not establish insertion force or retention strength.

### Octagonal corners and midpoint locators

Each cell now has four 45-degree corner locators matching the supplied foot's approximately 5.45 mm corner setback. The corner planes follow the foot's lower and upper vertical chamfers. Four additional protrusions per cell fit the midpoint notches. These protrusions taper out at 2.3 mm above the foot datum, matching the measured notch closure height, rather than continuing to the top of the ridge. Shared ridges have a protrusion on each side.

The existing groove clearance remains 0.10 mm; the straight ridge is still nominally 6.20 mm wide. This update adds the corner and notch locating geometry without thickening the straight sections.

Run `validation/check_locators.py` for the current feature checks. It clips the actual supplied STL triangles against every new convex locator volume, checking all four cells and their four orientations. No intersections were found at 0.10 or 0.05 mm locator clearance. The four delivery meshes and smaller/larger variants passed connectedness and closed-surface checks. The user has confirmed the locator fit is snug and easy to remove.

Ridge-only exports: `Multibin_Ridge_Only_Fit_Test.stl` combines both flags; `MultiConnect_Multibin_No_Base.stl` retains the back plate and supports. Both rendered as a single closed mesh. The default 2 × 2 ridge-only test is 5.1 mm tall with four open cells. The solid-floor geometry was verified unchanged. Without a floor, the shell is supported by the ridge interface rather than resting its feet on a solid surface.

OpenSCAD validation covers the default and eleven parameter variants: smaller dimensions, an open floor, thicker walls and increased clearance, zero rim/brace settings with a removed slot, tighter and looser groove fits, and every existing mounting option. Mesh checks require closed surfaces and a single connected body. Negative shell clearance and insufficient groove roof clearance must trigger assertions.

A tapered conservative shell envelope is checked against the supplied mesh. Each triangle below 5.15 mm is clipped at the 0.4 and 3.6 mm profile transitions, and its vertices are checked against the sloped foot bounds in each band. The full shell envelope is used above 5.15 mm. Boolean checks against the shelf exclude only the intentional floor contact plane by 0.0001 mm. They cover both default and tighter ridge settings. The supplied shell is also positioned in the shelf for visual inspection. These are digital checks, not a physical fit test. Validation scripts, logs and previews are in `validation/`.

## Latest printed-fit adjustment

The previous 0.30 mm recess still left the rail 0.5 mm proud, so the default is now 0.80 mm. The successful 99.5% coupon corresponds to 15.1 x 0.995 = 15.0245 mm at the widest channel section; reducing per-side clearance to 0.11 mm gives 15.02 mm. This approximates the successful channel width without scaling the shelf, bin grid, lock positions or mounting pitch. Print the updated coupon at 100%.

The deeper opening also stops tapering at the measured rail neck envelope (11.74 mm plus clearance) so it does not pinch the neck. Default remaining wall behind the channel is 1.55 mm. CAD checks cannot confirm final flushness until another fit print.
