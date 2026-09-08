/*Created by BlackjackDuck (Andy)
Credit to 
    @David D on Printables for Multiboard
    Jonathan at Keep Making for Multiconnect
    Zach at gridfinity.xyz for the Gridfinity standard
    Katie (and her community) at Hands on Katie on Youtube for advice
Licensed Creative Commons 4.0 Attribution Non-Commercial Sharable with Attribution
TODO: 
    - Add ability to tweak rim height
    - Ability to trim grid height (some versions lop off a tiny bit off the top)

Change Log:
- 2024-09-01 
    - Initial release
- 2025-04-08
    - New backs (Multipoint, openGrid, GOEWS)

*/
// Multibin shelf adaptation, September 2026.
// Reference: supplied 2x2x0.5 LU Topped Rail shell, measured 100 x 100 x 30 mm.
// Raised 50 mm locating grid engages the underside channels between shell feet.
// Drop-in fit, not a snap-lock: the shell lifts straight out.
// Self-contained: original slot profiles retained; back plate uses square edges.

/* [Slot Types] */
// Pegboard uses the original Multipoint slot profile with a 25.4 mm pitch.
Connection_Type = "Multipoint - 1 inch Pegboard"; // [Multipoint - 1 inch Pegboard, Multipoint, Multiconnect - Multiboard, Multiconnect - openGrid, Multiconnect - Custom Size, GOEWS]

/* [Parameters] */
// Render just the floor, locating grid and low rim for a fit-test print.
baseOnly = false;
// Nominal Multibin large units (LU), 50 mm per unit for the reference shell.
unitsWide = 2; // [1:1:10]
unitsDeep = 2; // [1:1:10]
multibinUnitSize = 50;
// Clearance PER SIDE around the complete nominal shell footprint.
shellClearance = 0.3; // [0:0.05:1]
rimThickness = 1.5;
// Rim height above the flat supporting surface.
additionalRimHeight = 2;
baseThickness = 2.4;
overrideBackHeight = false;
customBackHeight = 60;
// Remove the entire floor and low rim, leaving only the locating ridges below the shell.
removeBase = false;
bracketDepthPercentage = 50; // [0:1:100]
// Side brace thickness, matching the original Gridfinity design by default.
bracketThickness = 1.5;

/* [Multibin Locating Grid] */
// Horizontal gap PER SIDE along the measured groove profile.
grooveClearance = 0.10; // [0.05:0.05:0.6]
// Gap below the 5.4 mm groove roof. At least 0.3 also clears shallower crossings.
grooveRoofClearance = 0.3; // [0.3:0.05:1]
// Clearance normal to the diagonal corner faces and horizontally at notch tips.
locatorClearance = 0.10; // [0.05:0.05:0.5]

/* [Slot Customization] */
onRampHalfOffset = true;
customDistanceBetweenSlots = 25;
// Removes slots without shifting the remaining slots off their original grid.
subtractedSlots = 0;
// Multipoint modes: use two smaller upper bumps matching the Pegboard Click rail.
pegboardRailLock = true;
// Clearance for the rail's 0.4 mm-deep recesses (not the bin locating grid).
railLockClearance = 0.10; // [0.05:0.05:0.2]
// Minimum room below the seated 41 mm-long rail; back height increases as needed.
railEndClearance = 2;
// Overrides both locking options and removes all inward locking bumps.
slotQuickRelease = false;
dimpleScale = 1; // [0.5:0.05:1.5]
// Original Multiconnect control; Multipoint profiles keep their original size.
slotTolerance = 1.00; // [0.925:0.005:1.075]
slotDepthMicroadjustment = 0; // [-0.5:0.05:0.5]
onRampEnabled = true;
On_Ramp_Every_X_Slots = 1;
Multiconnect_Stop_Distance_From_Back = 13;

/* [GOEWS Customization] */
GOEWS_Cleat_position = "normal"; // [normal, top, bottom, custom]
GOEWS_Cleat_custom_height_from_top_of_back = 11.24;

/* [Hidden] */
epsilon = 0.02;
// With no floor, put the ridge roots directly on the print bed.
floorHeight = removeBase ? 0 : baseThickness;
measuredGrooveWidth = 6.4;
measuredEntryChamfer = 0.4;
measuredTaperStart = 3.6;
measuredGrooveDepth = 5.4;
// Measured from the supplied STL at the straight section of each bottom foot.
measuredCornerSetback = 5.447764;
measuredNotchHeight = 2.3;
measuredNotchFlatHalfWidth = 2.27817;
footHalfWidth = (multibinUnitSize-measuredGrooveWidth)/2;
ridgeWidth = measuredGrooveWidth - 2*grooveClearance;
ridgeRootWidth = ridgeWidth + 2*measuredEntryChamfer;
ridgeHeight = measuredGrooveDepth - grooveRoofClearance;
ridgeTopWidth = ridgeWidth - 2*(ridgeHeight-measuredTaperStart);
$fa = 6;
$fs = 0.6;
pegboardMode = Connection_Type == "Multipoint - 1 inch Pegboard";
requestedBackHeight = overrideBackHeight ? customBackHeight : 15 + 15*unitsDeep;
onRampEveryXSlots = On_Ramp_Every_X_Slots;
distanceBetweenSlots = pegboardMode ? 25.4 :
    Connection_Type == "Multiconnect - openGrid" ? 28 :
    Connection_Type == "Multiconnect - Custom Size" ? customDistanceBetweenSlots :
    Connection_Type == "GOEWS" ? 42 : 25;
Connection_Standard = pegboardMode || Connection_Type == "Multipoint" ? "Multipoint" :
    Connection_Type == "GOEWS" ? "GOEWS" :
    Connection_Type == "Multiconnect - Multiboard" ||
    Connection_Type == "Multiconnect - openGrid" ||
    Connection_Type == "Multiconnect - Custom Size" ? "Multiconnect" : "Unknown";
railMountMode = pegboardRailLock && Connection_Standard == "Multipoint";
// Rail end centres are 25 mm apart, with 8 mm beyond each centre: 41 mm overall.
// Its upper centre seats at backHeight - stop distance; bottom is 33 mm below it.
minimumRailBackHeight = Multiconnect_Stop_Distance_From_Back + 33 + railEndClearance;
backHeight = railMountMode ? max(requestedBackHeight,minimumRailBackHeight) : requestedBackHeight;
railBumpProjection = 0.2 + 0.4 - railLockClearance;
shellWidth = unitsWide*multibinUnitSize;
shellDepth = unitsDeep*multibinUnitSize;
bayWidth = shellWidth + 2*shellClearance;
bayDepth = shellDepth + 2*shellClearance;
minimumWidth = bayWidth + 2*rimThickness;
// Compact width: usable bay plus the two side walls; no pegboard pitch padding.
totalWidth = minimumWidth;
sideMargin = rimThickness;
totalDepth = bayDepth + rimThickness;
totalHeight = backHeight;
bracketDepth = totalDepth*bracketDepthPercentage/100;
backThickness = Connection_Standard == "Multipoint" ? 4.8 : Connection_Standard == "GOEWS" ? 7 : 6.5;
// Keep one pitch of edge margin for slotted backs: three centred slots on 2x2.
// A narrow one-slot back remains supported. GOEWS keeps its original cleat count.
allSlots = Connection_Standard == "GOEWS" ? floor(totalWidth/distanceBetweenSlots + 0.000001) :
    max(1,floor(totalWidth/distanceBetweenSlots + 0.000001)-1);
slotCount = allSlots-subtractedSlots;
// Centre the full slot pattern. Removing slots preserves surviving positions.
firstSlot = (totalWidth-(allSlots-1)*distanceBetweenSlots)/2 + floor(subtractedSlots/2)*distanceBetweenSlots;

assert(unitsWide >= 1 && unitsWide == floor(unitsWide) && unitsDeep >= 1 && unitsDeep == floor(unitsDeep), "LU counts must be positive integers.");
assert(multibinUnitSize > 0 && shellClearance >= 0, "Unit size must be positive and clearance nonnegative.");
assert(rimThickness > 0 && baseThickness > 0 && additionalRimHeight >= 0, "Wall and floor thickness must be positive; rim height must be nonnegative.");
assert(Connection_Standard != "Unknown", "Select a supported Slot Type.");
assert(!railMountMode || (railLockClearance >= 0.05 && railLockClearance <= 0.2), "Rail lock clearance must be between 0.05 and 0.2 mm.");
assert(!railMountMode || railEndClearance >= 0.5, "Allow at least 0.5 mm below the rail; 2 mm is the default.");
assert(distanceBetweenSlots >= 25, "Slot pitch must be at least 25 mm for these profiles.");
assert(subtractedSlots >= 0 && subtractedSlots == floor(subtractedSlots) && slotCount >= 1, "Keep at least one mounting slot; reduce subtractedSlots.");
assert(backHeight >= 25 && backHeight > baseThickness+additionalRimHeight, "Increase back height above the floor and rim, and to at least 25 mm.");
assert(Multiconnect_Stop_Distance_From_Back >= 12 && Multiconnect_Stop_Distance_From_Back < backHeight, "Slot stop distance must be at least 12 mm and less than back height.");
assert(On_Ramp_Every_X_Slots >= 1 && On_Ramp_Every_X_Slots == floor(On_Ramp_Every_X_Slots), "On-ramp frequency must be a positive integer.");
assert(bracketDepthPercentage >= 0 && bracketDepthPercentage <= 100, "Bracket depth must be between 0 and 100 percent.");
assert(bracketThickness > 0 && bracketThickness <= sideMargin, "Side brace thickness must be positive and fit within the side margin.");
assert(grooveClearance > 0 && ridgeWidth > 0 && ridgeWidth < multibinUnitSize, "Groove clearance must be positive and leave a ridge narrower than one LU.");
assert(grooveRoofClearance >= 0.3 && ridgeHeight > measuredTaperStart && ridgeHeight <= measuredGrooveDepth-0.3, "Roof clearance must be at least 0.3 mm and leave ridge engagement above 3.6 mm; crossings are shallower than the main groove.");
assert(ridgeTopWidth > 0 && ridgeRootWidth < multibinUnitSize, "Reduce groove clearance to retain a positive ridge top; unit size must exceed root width.");
assert(locatorClearance > 0 && locatorClearance < 1, "Locator clearance must be positive and below 1 mm.");
assert(footHalfWidth > measuredCornerSetback+measuredNotchFlatHalfWidth+measuredNotchHeight, "Increase unit size to leave space between corner and midpoint locators.");
echo(overall_width_mm=totalWidth, usable_bay_mm=[bayWidth,bayDepth], slot_pitch_mm=distanceBetweenSlots, slot_centres_from_left_mm=[for(i=[0:slotCount-1]) firstSlot+i*distanceBetweenSlots]);
echo(back_height_mm=backHeight, pegboard_rail_lock=railMountMode, rail_bottom_clearance_mm=railMountMode ? backHeight-Multiconnect_Stop_Distance_From_Back-33 : undef);

// Installed orientation: shell datum is floorHeight; printable geometry starts at Z=0.
color("orange") multmatrix([[1,0,0,0],[0,0,-1,-totalDepth/2-2.37],[0,1,0,backHeight-Multiconnect_Stop_Distance_From_Back-34.5],[0,0,0,1]]) import("E:/OneDrive/My Actual Documents/3D Printer/SCAD Projects/Multibin Shelves/Pegboard_Rail_Sheath.stl");color("steelblue") multmatrix([[0,0,1,-7.4],[-1,0,0,-totalDepth/2-5.55],[0,1,0,backHeight-Multiconnect_Stop_Distance_From_Back],[0,0,0,1]])
    difference() {
        import("E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Board Connections/Pegboard Click - Multipoint Rail (Supported).stl");
        // Remove only the pre-modelled support projecting beyond rail face X=-3.
        translate([-100,-100,-100]) cube([96.9999,200,100.601]);
    }

module shelf() {
    union() {
        if(!baseOnly)
            makebackPlate(totalWidth, backHeight, distanceBetweenSlots, backThickness);
        locatingGrid();
        if(!removeBase) {
            cube([totalWidth,totalDepth,baseThickness]);
            // Thin side walls enclose the bay, without extra lateral padding.
            for(x=[0,totalWidth-sideMargin])
                translate([x,0,0]) cube([sideMargin,totalDepth,baseThickness+additionalRimHeight]);
            translate([0,bayDepth,0]) cube([totalWidth,rimThickness,baseThickness+additionalRimHeight]);
        }
        if(!baseOnly && bracketDepthPercentage > 0)
            for(x=[sideMargin,totalWidth-sideMargin+bracketThickness])
                translate([x,0,backHeight])
                    shelfBracket(backHeight-floorHeight,bracketDepth,bracketThickness);
    }
}

// Grid lines are registered to the shell's nominal 50 mm cells, independently
// of the mounting pitch.
module locatingGrid() {
    intersection() {
        translate([0,0,max(0,floorHeight-epsilon)])
            cube([totalWidth,totalDepth,ridgeHeight+2*epsilon]);
        union() {
            for(x=[0:unitsWide])
                translate([sideMargin+shellClearance+x*multibinUnitSize,0,floorHeight])
                    ridgeAlongY(totalDepth);
            for(y=[0:unitsDeep])
                translate([totalWidth,shellClearance+y*multibinUnitSize,floorHeight])
                    rotate([0,0,90]) ridgeAlongY(totalWidth);
            for(x=[0:unitsWide-1],y=[0:unitsDeep-1])
                translate([sideMargin+shellClearance+(x+0.5)*multibinUnitSize,
                           shellClearance+(y+0.5)*multibinUnitSize,floorHeight])
                    for(angle=[0:90:270]) rotate([0,0,angle]) {
                        cornerLocator();
                        midpointLocator();
                    }
        }
    }
}

// Plane x+y=C tracks the shell's diagonal face through both vertical chamfers.
function cornerPlane(z) = 2*footHalfWidth-measuredCornerSetback +
    sqrt(2)*(min(max(z,0),measuredEntryChamfer)-measuredEntryChamfer+
             max(z-measuredTaperStart,0)+locatorClearance);
function cornerSection(z) = let(p=multibinUnitSize/2,c=cornerPlane(z))
    [[p,p],[c-p,p],[p,c-p]];

module cornerLocator() {
    levels=[-epsilon,0,measuredEntryChamfer,measuredTaperStart,ridgeHeight];
    for(i=[0:len(levels)-2])
        loftSection(cornerSection(levels[i]),cornerSection(levels[i+1]),levels[i],levels[i+1]);
}

// The midpoint notch is a three-sided relief. Its centre rises at 45 degrees;
// the flanks move by sqrt(2)*Z and the relief closes at Z=2.3 mm.
function notchSection(z) = let(
    p=multibinUnitSize/2,
    tip=footHalfWidth-measuredNotchHeight+max(z,0)+locatorClearance,
    diagonal=footHalfWidth-measuredNotchHeight-measuredNotchFlatHalfWidth+
             sqrt(2)*(max(z,0)+locatorClearance),
    inner=tip-diagonal,outer=p-diagonal)
    [[tip,-inner],[p,-outer],[p,outer],[tip,inner]];

module midpointLocator() {
    loftSection(notchSection(0),notchSection(measuredNotchHeight),-epsilon,measuredNotchHeight);
}

// Join corresponding vertices of two counter-clockwise convex sections.
module loftSection(bottom,top,z0,z1) {
    n=len(bottom);
    polyhedron(
        points=concat([for(p=bottom) [p[0],p[1],z0]], [for(p=top) [p[0],p[1],z1]]),
        faces=concat([[for(i=[n-1:-1:0]) i]], [[for(i=[0:n-1]) n+i]],
                     [for(i=[0:n-1]) [i,(i+1)%n,(i+1)%n+n,i+n]]),convexity=4);
}

module ridgeAlongY(length) {
    // Extrusion maps local profile Y to installed Z and extends in positive Y.
    translate([0,length,0]) rotate([90,0,0])
        linear_extrude(height=length)
            // Match the 0.4 mm entry chamfer, straight channel, and upper 45-degree
            // taper. Horizontal clearance is subtracted once on each side.
            polygon([[-ridgeRootWidth/2,-epsilon], [ridgeRootWidth/2,-epsilon],
                     [ridgeRootWidth/2,0],
                     [ridgeWidth/2,measuredEntryChamfer],
                     [ridgeWidth/2,measuredTaperStart],
                     [ridgeTopWidth/2,ridgeHeight],
                     [-ridgeTopWidth/2,ridgeHeight],
                     [-ridgeWidth/2,measuredTaperStart],
                     [-ridgeWidth/2,measuredEntryChamfer],
                     [-ridgeRootWidth/2,0]]);
}

module shelfBracket(bracketHeight, bracketDepth, rimThickness) {
    rotate([-90,0,90]) linear_extrude(height=rimThickness)
        polygon([[0,0],[0,bracketHeight],[bracketDepth,bracketHeight]]);
}

module makebackPlate(backWidth, backHeight, distanceBetweenSlots, backThickness) {
    cleatDrop = GOEWS_Cleat_position == "normal" ? 11.24 : GOEWS_Cleat_position == "top" ? 0 : GOEWS_Cleat_position == "bottom" ? backHeight-13.15 : GOEWS_Cleat_custom_height_from_top_of_back;
    assert(Connection_Standard != "GOEWS" || (cleatDrop >= 0 && cleatDrop <= backHeight-13.15), "GOEWS cleat must stay within the back height.");
    difference() {
        union() {
            // Small overlap with the floor/rim ensures a single connected body.
            translate([0,-backThickness,0]) cube([backWidth,backThickness+epsilon,backHeight]);
            if(Connection_Standard == "GOEWS")
                for(i=[0:slotCount-1])
                    translate([firstSlot+i*distanceBetweenSlots,-backThickness+epsilon,backHeight-cleatDrop]) GOEWSCleatTool(totalHeight);
        }
        for(i=[0:slotCount-1]) {
            x = firstSlot+i*distanceBetweenSlots;
            if(Connection_Standard != "GOEWS")
                translate([x,-2.35+slotDepthMicroadjustment,backHeight-Multiconnect_Stop_Distance_From_Back]) {
                    if(Connection_Standard == "Multipoint") multiPointSlotTool(totalHeight);
                    else multiConnectSlotTool(totalHeight);
                }
            else {
                translate([x,epsilon,backHeight+0.46-cleatDrop+11.24]) rotate([90,0,0]) cylinder(h=backThickness+2*epsilon,r=7,$fn=96);
                translate([x,-4,backHeight+0.46-cleatDrop+11.24]) rotate([-90,0,0]) cylinder(h=4+2*epsilon,r=10,$fn=96);
            }
        }
    }
}

//Create GOEWS cleats
module GOEWSCleatTool(totalHeight) {
    difference() {
        // main profile
        rotate(a = [180,0,0]) 
            linear_extrude(height = 13.15) 
                let (cleatProfile = [[0,0],[15.1,0],[17.6,2.5],[15.1,5],[0,5]])
                union(){
                    polygon(points = cleatProfile);
                    mirror([1,0,0])
                        polygon(points = cleatProfile);
                };
        // angled slice off bottom
        translate([-17.6, -8, -26.3])
            rotate([45, 0, 0])
                translate([0, 5, 0])
                    cube([35.2, 10, 15]);
        // cutout
        translate([0, -0.005, 2.964])
            rotate([90, 0, 0])
                cylinder(h = 6, r = 9.5, $fn = 256);
    }
}

//Create Slot Tool
module multiConnectSlotTool(totalHeight) {
    //In slotTool, added a new variable distanceOffset which is set by the option:
    distanceOffset = onRampHalfOffset ? distanceBetweenSlots / 2 : 0;
    scale(v = slotTolerance)
    //slot minus optional dimple with optional on-ramp
    let (slotProfile = [[0,0],[10.15,0],[10.15,1.2121],[7.65,3.712],[7.65,5],[0,5]])
    difference() {
        union() {
            //round top
            rotate(a = [90,0,0,]) 
                rotate_extrude($fn=50) 
                    polygon(points = slotProfile);
            //long slot
            translate(v = [0,0,0]) 
                rotate(a = [180,0,0]) 
                linear_extrude(height = totalHeight+1) 
                    union(){
                        polygon(points = slotProfile);
                        mirror([1,0,0])
                            polygon(points = slotProfile);
                    }
            //on-ramp
            if(onRampEnabled)
                for(y = [1:onRampEveryXSlots:totalHeight/distanceBetweenSlots])
                    //then modify the translate within the on-ramp code to include the offset
                    translate(v = [0,-5,(-y*distanceBetweenSlots)+distanceOffset])
                        rotate(a = [-90,0,0]) 
                            cylinder(h = 5, r1 = 12, r2 = 10.15);
        }
        //dimple
        if (slotQuickRelease == false)
            scale(v = dimpleScale) 
            rotate(a = [90,0,0,]) 
                rotate_extrude($fn=50) 
                    polygon(points = [[0,0],[0,1.5],[1.5,0]]);
    }
}

module multiPointSlotTool(totalHeight) {
    slotBaseRadius = 17.0 / 2.0;  // wider width of the inner part of the channel
    slotSkinRadius = 13.75 / 2.0;  // narrower part of the channel near the skin of the model
    slotBaseCatchDepth = .2;  // innermost before the chamfer, base to chamfer height
    slotBaseToSkinChamferDepth = 2.2;  // middle part of the chamfer
    slotSkinDepth = .1;  // top or skinmost part of the channel
    distanceOffset = onRampHalfOffset ? distanceBetweenSlots / 2 : 0;
    octogonScale = 1/sin(67.5);  // math convenience function to convert an octogon hypotenuse to the short length
    let (slotProfile = [
        [0,0],
        [slotBaseRadius,0],
        [slotBaseRadius, slotBaseCatchDepth],
        [slotSkinRadius, slotBaseCatchDepth + slotBaseToSkinChamferDepth],
        [slotSkinRadius, slotBaseCatchDepth + slotBaseToSkinChamferDepth + slotSkinDepth],
        [0, slotBaseCatchDepth + slotBaseToSkinChamferDepth + slotSkinDepth]
    ])
    union() {
        //octagonal top. difference on union because we need to support the dimples cut in.
        difference(){
            //union of top and rail.
            union(){
                scale([octogonScale,1,octogonScale])
                rotate(a = [90,67.5,0,]) 
                    rotate_extrude($fn=8) 
                        polygon(points = slotProfile);
                //long slot
                translate(v = [0,0,0]) 
                    rotate(a = [180,0,0]) 
                    linear_extrude(height = totalHeight+1) 
                        union(){
                            polygon(points = slotProfile);
                            mirror([1,0,0])
                                polygon(points = slotProfile);
                        }
            }
            //dimples on each catch point
            if (!slotQuickRelease){
                if(railMountMode)
                    pegboardRailBumps();
                else
                    for(z = [1:On_Ramp_Every_X_Slots:totalHeight/distanceBetweenSlots ])
                        yMultipointSlotDimples(z, slotBaseRadius, distanceBetweenSlots, distanceOffset);
            }
        }
        //on-ramp
        if(onRampEnabled)
            union(){
                for(y = [1:On_Ramp_Every_X_Slots:totalHeight/distanceBetweenSlots])
                {
                    // create the main entry hexagons
                    translate(v = [0,-5,(-y*distanceBetweenSlots)+distanceOffset])
                    scale([octogonScale,1,octogonScale])
                        rotate(a = [-90,67.5,0]) 
                            cylinder(h=5, r=slotBaseRadius, $fn=8);
                    
                // make the required "pop-in" locking channel dimples.
                xSlotDimples(y, slotBaseRadius, distanceBetweenSlots, distanceOffset);
                mirror([1,0,0])
                     xSlotDimples(y, slotBaseRadius, distanceBetweenSlots, distanceOffset);
                }
            }
    }
}

// Measured rail recesses: at the rail face, radius 5 mm and two straight edges
// 2.1 mm from the upper centre; all three walls taper inward at 45 degrees to
// a 0.4 mm depth. Rail face is 0.2 mm away from the slot's innermost plane.
// Keep only the upper pair, once per slot, independent of ramp pitch/offset.
module pegboardRailBumps() {
    for(side=[-1,1]) scale([side,1,1])
        rotate([90,0,0]) intersection() {
            r=5.2-railLockClearance;
            a=1.9+railLockClearance;
            p=railBumpProjection;
            translate([0,0,-epsilon])
                cylinder(h=p+epsilon,r1=r+epsilon,r2=r-p,$fn=96);
            loftSection([[a-epsilon,a-epsilon],[6,a-epsilon],[6,6],[a-epsilon,6]],
                        [[a+p,a+p],[6,a+p],[6,6],[a+p,6]],-epsilon,p);
        }
}

module xSlotDimples(y, slotBaseRadius, distanceBetweenSlots, distanceOffset){
    //Multipoint dimples are truncated (on top and side) pyramids
    //this function makes one pair of them
    dimple_pitch = 4.5 / 2; //distance between locking dimples
    difference(){
        translate(v = [slotBaseRadius-0.01,0,(-y*distanceBetweenSlots)+distanceOffset+dimple_pitch])
            rotate(a = [90,45,90]) 
            rotate_extrude($fn=4) 
                polygon(points = [[0,0],[0,1.5],[1.7,0]]);
        translate(v = [slotBaseRadius+.75, -2, (-y*distanceBetweenSlots)+distanceOffset-1])
                cube(4);
        translate(v = [slotBaseRadius-2, 0.01, (-y*distanceBetweenSlots)+distanceOffset-1])
                cube(7);
        }
        difference(){
        translate(v = [slotBaseRadius-0.01,0,(-y*distanceBetweenSlots)+distanceOffset-dimple_pitch])
            rotate(a = [90,45,90]) 
            rotate_extrude($fn=4) 
                polygon(points = [[0,0],[0,1.5],[1.7,0]]);
        translate(v = [slotBaseRadius+.75, -2.01, (-y*distanceBetweenSlots)+distanceOffset-3])
                cube(4);
        translate(v = [slotBaseRadius-2, 0.01, (-y*distanceBetweenSlots)+distanceOffset-5])
                cube(10);
        }
}
module yMultipointSlotDimples(z, slotBaseRadius, distanceBetweenSlots, distanceOffset){
    //This creates the multipoint point out dimples within the channel.
    octogonScale = 1/sin(67.5);
    difference(){
        translate(v = [0,0.01,((-z+.5)*distanceBetweenSlots)+distanceOffset])
            scale([octogonScale,1,octogonScale])
                rotate(a = [-90,67.5,0]) 
                    rotate_extrude($fn=8) 
                        polygon(points = [[0,0],[0,-1.5],[5,0]]);
        translate(v = [0,0,((-z+.5)*distanceBetweenSlots)+distanceOffset])
            cube([10,3,3], center=true);
        translate(v = [0,0,((-z+.5)*distanceBetweenSlots)+distanceOffset])
           cube([3,3,10], center=true);
    }
}   
