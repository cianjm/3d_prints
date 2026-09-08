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
// Optional open grid floor; retains supporting strips at each LU boundary.
removeBase = false;
// Width of support strips when removeBase is true.
supportWidth = 12;
bracketDepthPercentage = 50; // [0:1:100]
// Side brace thickness, matching the original Gridfinity design by default.
bracketThickness = 1.5;

/* [Multibin Locating Grid] */
// Horizontal gap PER SIDE along the measured groove profile.
grooveClearance = 0.15; // [0.1:0.05:0.6]
// Gap below the 5.4 mm groove roof. At least 0.3 also clears shallower crossings.
grooveRoofClearance = 0.3; // [0.3:0.05:1]

/* [Slot Customization] */
onRampHalfOffset = true;
customDistanceBetweenSlots = 25;
// Removes slots without shifting the remaining slots off their original grid.
subtractedSlots = 0;
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
measuredGrooveWidth = 6.4;
measuredEntryChamfer = 0.4;
measuredTaperStart = 3.6;
measuredGrooveDepth = 5.4;
ridgeWidth = measuredGrooveWidth - 2*grooveClearance;
ridgeRootWidth = ridgeWidth + 2*measuredEntryChamfer;
ridgeHeight = measuredGrooveDepth - grooveRoofClearance;
ridgeTopWidth = ridgeWidth - 2*(ridgeHeight-measuredTaperStart);
$fa = 6;
$fs = 0.6;
pegboardMode = Connection_Type == "Multipoint - 1 inch Pegboard";
backHeight = overrideBackHeight ? customBackHeight : 15 + 15*unitsDeep;
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
assert(distanceBetweenSlots >= 25, "Slot pitch must be at least 25 mm for these profiles.");
assert(subtractedSlots >= 0 && subtractedSlots == floor(subtractedSlots) && slotCount >= 1, "Keep at least one mounting slot; reduce subtractedSlots.");
assert(backHeight >= 25 && backHeight > baseThickness+additionalRimHeight, "Increase back height above the floor and rim, and to at least 25 mm.");
assert(Multiconnect_Stop_Distance_From_Back >= 12 && Multiconnect_Stop_Distance_From_Back < backHeight, "Slot stop distance must be at least 12 mm and less than back height.");
assert(On_Ramp_Every_X_Slots >= 1 && On_Ramp_Every_X_Slots == floor(On_Ramp_Every_X_Slots), "On-ramp frequency must be a positive integer.");
assert(bracketDepthPercentage >= 0 && bracketDepthPercentage <= 100, "Bracket depth must be between 0 and 100 percent.");
assert(bracketThickness > 0 && bracketThickness <= sideMargin, "Side brace thickness must be positive and fit within the side margin.");
assert(!removeBase || (supportWidth >= 8 && supportWidth < multibinUnitSize), "Open-floor strips must be at least 8 mm wide and narrower than one LU.");
assert(grooveClearance > 0 && ridgeWidth > 0 && ridgeWidth < multibinUnitSize, "Groove clearance must be positive and leave a ridge narrower than one LU.");
assert(grooveRoofClearance >= 0.3 && ridgeHeight > measuredTaperStart && ridgeHeight <= measuredGrooveDepth-0.3, "Roof clearance must be at least 0.3 mm and leave ridge engagement above 3.6 mm; crossings are shallower than the main groove.");
assert(ridgeTopWidth > 0 && ridgeRootWidth < multibinUnitSize, "Reduce groove clearance to retain a positive ridge top; unit size must exceed root width.");
assert(!removeBase || supportWidth > ridgeRootWidth, "Open-floor support strips must be wider than the locating ridge roots.");
echo(overall_width_mm=totalWidth, usable_bay_mm=[bayWidth,bayDepth], slot_pitch_mm=distanceBetweenSlots, slot_centres_from_left_mm=[for(i=[0:slotCount-1]) firstSlot+i*distanceBetweenSlots]);

// Installed orientation: shell rests at Z=baseThickness. Flat floor at Z=0.
intersection() {
translate([-totalWidth/2,-totalDepth/2,0]) shelf();
translate([-25,-25.75,2.4]) union() {
    for(x=[0,50],y=[0,50]) translate([x,y,0]) {
        translate([0,0,0.0001]) linear_extrude(height=0.3999,scale=43.6/42.8002) square(42.8002,center=true);
        translate([-21.8,-21.8,0.4]) cube([43.6,43.6,3.2]);
        translate([0,0,3.6]) linear_extrude(height=1.55,scale=46.7/43.6) square(43.6,center=true);
    }
    translate([-25,-25,5.15]) cube([100,100,24.85]);
}
}


module shelf() {
    union() {
        makebackPlate(totalWidth, backHeight, distanceBetweenSlots, backThickness);
        locatingGrid();
        difference() {
            cube([totalWidth,totalDepth,baseThickness]);
            if(removeBase)
                for(x=[0:unitsWide-1], y=[0:unitsDeep-1])
                    translate([sideMargin+shellClearance+x*multibinUnitSize+supportWidth/2,
                               shellClearance+y*multibinUnitSize+supportWidth/2,-epsilon])
                        cube([multibinUnitSize-supportWidth,multibinUnitSize-supportWidth,baseThickness+2*epsilon]);
        }
        // Thin side walls enclose the bay, without extra lateral padding.
        for(x=[0,totalWidth-sideMargin])
            translate([x,0,0]) cube([sideMargin,totalDepth,baseThickness+additionalRimHeight]);
        translate([0,bayDepth,0]) cube([totalWidth,rimThickness,baseThickness+additionalRimHeight]);
        if(bracketDepthPercentage > 0)
            for(x=[sideMargin,totalWidth-sideMargin+bracketThickness])
                translate([x,0,backHeight])
                    shelfBracket(backHeight-baseThickness,bracketDepth,bracketThickness);
    }
}

// Grid lines are registered to the shell's nominal 50 mm cells, independently
// of the mounting pitch.
module locatingGrid() {
    intersection() {
        translate([0,0,baseThickness-epsilon])
            cube([totalWidth,totalDepth,ridgeHeight+2*epsilon]);
        union() {
            for(x=[0:unitsWide])
                translate([sideMargin+shellClearance+x*multibinUnitSize,0,baseThickness])
                    ridgeAlongY(totalDepth);
            for(y=[0:unitsDeep])
                translate([totalWidth,shellClearance+y*multibinUnitSize,baseThickness])
                    rotate([0,0,90]) ridgeAlongY(totalWidth);
        }
    }
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
                for(z = [1:On_Ramp_Every_X_Slots:totalHeight/distanceBetweenSlots ])
                {
                    // Catch-point dimple at this pitch index.
                    yMultipointSlotDimples(z, slotBaseRadius, distanceBetweenSlots, distanceOffset);
                }
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
