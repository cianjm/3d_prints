/*Created by Andy Levesque

This code is licensed Creative Commons 4.0 Attribution Non-Commercial Sharable with Attribution

Documentation available at https://handsonkatie.com/underware-2-0-the-made-to-measure-collection/
References to Multipoint are for the Multiboard ecosystem by Jonathan at Keep Making. The Multipoint mount system is licensed under https://www.multiboard.io/license.


Credit to 
    @David D on Printables for Multiconnect
    Jonathan at Keep Making for Multiboard
    @fawix on GitHub for her contributions on parameter descriptors
    @SnazzyGreenWarrior on GitHub for their contributions on the Multipoint-compatible mount


Change Log:
- 2024-12-06 
    - Initial release
- 2024-12-08 
    - Renamed depth and width
    - Multiconnect On-Ramps off by default
    - Multiconnect On-Ramps at 1/2 grid intervals for more contact points
    - Rounding added to edges
- 2024-12-10
    - Hexagon panel option
-2024-12-11
    - Updated on-ramp logic to prevent on-ramps every slot when half offset is disabled
    - Updated (in mm) to (by mm) for clarity
-2024-12-13
    -Ability to override slot distance from edge
-2025-05-02
    - Added dropdown for Multiconnect vs. Threaded Snap connections
    - Added dropdown for openGrid vs Multiboard mounting surfaces
    - Created threaded snap matching threaded snap profile of Underware (but also a teardrop for vertical printing)
    - Added 'backer only' option
    - Added 'Force Back Thickness' option to override the default back thickness of 6.5mm or 3.6mm depending on mounting style
    - Allowed mm adjustements to the tength of a mm
-2025-05-28
    - Added Clamshell move v0.1 (no independent customizations)
-2026-09-08
    - Added the measured 1-inch Pegboard Click rail slots used by the Multibin shelves
    - Added a 90-degree rail-slot rotation option

Notes:
- Slot test fit - For a slot test fit, set the following parameters
    - Internal_Height = 0
    - Internal_Depth = 25
    - Internal_Width = 0
    - wallThickness = 0
*/

include <BOSL2/std.scad>
include <BOSL2/walls.scad>
include <BOSL2/threading.scad>

/*[Mounting Options]*/
Mounting_Style = "Multipoint - 1 inch Rail"; //[Multiconnect, Multipoint - 1 inch Rail, Threaded Snap]
//Surface on which you are mounting (which determines grid spacing). Select Custom and define the grid spacing in 'Slot Customization'.
Mounting_Surface = "Multiboard"; //[Multiboard, openGrid, Custom]

/* [Internal Dimensions] */
//Depth (by mm): internal dimension along the Z axis of print orientation. Measured from the top to the base of the internal floor, equivalent to the depth of the item you wish to hold when mounted horizontally.
Internal_Depth = 50.0; //.1
//Width (by mm): internal dimension along the X axis of print orientation. Measured from left to right, equivalent to the width of the item you wish to hold when mounted horizontally.
Internal_Width = 60.0; //.1
//Height (by mm): internal dimension along the Y axis of print orientation. Measured from the front to the back, equivalent to the thickness of the item you wish to hold when mounted horizontally.
Internal_Height = 15.0; //.1

/*[Style Customizations]*/
//Edge rounding (by mm)
edgeRounding = 0.5; // [0:0.1:2]

/* [Front Cutout Customizations] */
//Cut out the front
frontCutout = true; 
//Distance upward (Z axis) from the bottom (by mm). This captures the bottom front of the item
frontLowerCapture = 7;
//Distance downward (Z axis) from the top (by mm). This captures the top front of the item. Use zero (0) for a cutout top. May require printing supports if used. 
frontUpperCapture = 0;
//Distance inward (X axis) from the sides (by mm) that captures the sides of the item
frontLateralCapture = 3;


/*[Bottom Cutout Customizations]*/
//Cut out the bottom 
bottomCutout = false;
//Distance inward (Y axis) from the front (by mm). This captures the bottom front of the item
bottomFrontCapture = 3;
//Distance inward (Y axis) from the back (by mm). That captures the bottom back of the item
bottomBackCapture = 3;
//Distance inward (X axis) from the sides (by mm) that captures the bottom side of the item
bottomSideCapture = 3;

/*[Cord Cutout Customizations]*/
//Cut out a slot on the bottom and through the front for a cord to connect to the device
cordCutout = false;
//Diameter/width of cord cutout
cordCutoutDiameter = 10;
//Move the cord cutout laterally (X axis), left is positive and right is negative (by mm)
cordCutoutLateralOffset = 0;
//Move the cord cutout depth (Y axis), forward is positive and back is negative (by mm)
cordCutoutDepthOffset = 0;

/* [Right Cutout Customizations] */
rightCutout = false; 
//Distance upward (Z axis) from the bottom (by mm) that captures the bottom right of the item
rightLowerCapture = 7;
//Distance downward (Z axis) from the top (by mm) that captures the top right of the item. Use zero (0) for a cutout top. May require printing supports if used. 
rightUpperCapture = 0;
//Distance inward (Y axis) from the sides (by mm) that captures the right sides of the item
rightLateralCapture = 3;


/* [Left Cutout Customizations] */
leftCutout = false; 
//Distance upward (Z axis) from the bottom (by mm) that captures the bottom left of the item
leftLowerCapture = 7;
//Distance downward (Z axis) from the top (by mm) that captures the top left of the item. Use zero (0) for a cutout top. May require printing supports if used. 
leftUpperCapture = 0;
//Distance inward (Y axis) from the sides (by mm) that captures the left sides of the item
leftLateralCapture = 3;

/*[BETA - Clamshell mode]*/
//NOT COMPATIBLE WITH THREADED SNAPS YET. Clamshell mode is when you want to enclose the item with two separate holders. This calculates the distance between the two holders while also aligning with the mounting points.
ClamShell_Mode = true;
//total width of the item to be mounted
total_item_width = 150;
//Extra room between the two holders (total between the two sides). Recommended to be at least 0.3mm. 
item_slop = 0.3;
//Minimum distance the center of a mount point can be from the edge of the item holder (by mm). Decreasing less than 10 may cause the slot to clip out the edge (which is usually fine).
Minimum_Safe_Mount_Clearance_From_Edge = 13;

/* [Additional Customization] */
//Thickness of item holder walls (by mm)
wallThickness = 2; //.1
//Thickness of item holder base (by mm)
baseThickness = 3; //.1

/*[Advanced]*/
Backer_Only_Mode = false;
Backer_Negatives_Only = false; //If true, the backer will be negative space. If false, the backer will be positive space.
//Set to 0 to use the default thickness of the back. Set to a number to force the back to be that thickness.
Force_Back_Thickness = 0; //0.1


/*[Slot Customization]*/
//Rotate the 1-inch rail slots by 90 degrees. False = vertical slots; true = horizontal slots.
Rotate_Rail_Slots_90_Degrees = false;
//Offset the multiconnect on-ramps to be between grid slots rather than on the slot
onRampHalfOffset = true;
//Change slot orientation, when enabled slots to come from the top of the back, when disabled slots come from the bottom
Slot_From_Top = true;
//Distance between Multiconnect slots on the back (25mm is standard for MultiBoard)
Custom_Distance_Between_Slots = 25;
//QuickRelease removes the small indent in the top of the slots that lock the part into place
slotQuickRelease = false;
//Dimple scale tweaks the size of the dimple in the slot for printers that need a larger dimple to print correctly
dimpleScale = 1; //[0.5:.05:1.5]
//Scale the size of slots in the back (1.015 scale is default for a tight fit. Increase if your finding poor fit. )
slotTolerance = 1.00; //[0.925:0.005:1.075]
//Move the slot (Y axis) inwards (positive) or outwards (negative)
slotDepthMicroadjustment = 0; //[-.5:0.05:.5]
//Enable a slot on-ramp for easy mounting of tall items
onRampEnabled = false;
//Frequency of slots for on-ramp. 1 = every slot; 2 = every 2 slots; etc.
On_Ramp_Every_X_Slots = 1;
//Distance from the back of the item holder to where the multiconnect stops (i.e., where the dimple is) (by mm)
Multiconnect_Stop_Distance_From_Back = 13;

/* [1-inch Rail Customization] */
//Horizontal clearance PER SIDE around the measured Pegboard Click rail channel.
railSlotClearance = 0.11; // [0.05:0.01:0.4]
//Additional seating depth into the back plate.
railRecessDepth = 0.80; // [0:0.05:0.9]
//Clearance for the rail's locking recesses.
railLockClearance = 0.10; // [0.05:0.05:0.2]
//Minimum free space beyond the 41 mm-long rail.
railEndClearance = 2;

/* [Hidden] */
Wall_Type = "Solid"; //["Hex","Solid"]

distanceBetweenSlots = 
    Mounting_Style == "Multipoint - 1 inch Rail" ? 25.4 :
    Mounting_Surface == "Multiboard" ? 25 : 
    Mounting_Surface == "openGrid" ? 28 : 
    Custom_Distance_Between_Slots;


onRampEveryXSlots = 
    onRampHalfOffset ? On_Ramp_Every_X_Slots : 
    On_Ramp_Every_X_Slots == 1 ? 2 : On_Ramp_Every_X_Slots;

debugItemRepresentation = false;

railMountMode = Mounting_Style == "Multipoint - 1 inch Rail";
railSlotInset = railMountMode ? railRecessDepth : 0;
railBumpProjection = 0.2 + 0.4 - railLockClearance;
epsilon = 0.02;

assert(!railMountMode || (railLockClearance >= 0.05 && railLockClearance <= 0.2), "Rail lock clearance must be between 0.05 and 0.2 mm.");
assert(!railMountMode || (railSlotClearance >= 0.05 && railSlotClearance <= 0.4), "Rail slot clearance must be between 0.05 and 0.4 mm.");
assert(!railMountMode || (railRecessDepth >= 0 && railRecessDepth <= 0.9 && 2.35-slotDepthMicroadjustment-railRecessDepth >= 1.4), "Keep rail recess between 0 and 0.9 mm and at least 1.4 mm behind the slot.");
assert(!railMountMode || railEndClearance >= 0.5, "Allow at least 0.5 mm beyond the rail; 2 mm is the default.");

///*[Small Screw Profile]*/
//Distance (in mm) between threads
Pitch_Sm = 3;
//Diameter (in mm) at the outer threads
Outer_Diameter_Sm = 6.747;
//Angle of the one side of the thread
Flank_Angle_Sm = 60;
//Depth (in mm) of the thread
Thread_Depth_Sm = 0.5;
//Diameter of the hole down the middle of the screw (for strength)
Inner_Hole_Diameter_Sm = 3.3;
//Slop in thread. Increase to make threading easier. Decrease to make threading harder.
Slop = 0.075;

if(debugItemRepresentation){
    %up(item_slop) cuboid([total_item_width, Internal_Height,  Internal_Width], anchor=FRONT+RIGHT, orient=RIGHT);
}

//Calculated
totalDepth = Backer_Only_Mode ? Internal_Depth : Internal_Depth+baseThickness;
totalHeight = Backer_Only_Mode ? Internal_Height : Internal_Height + wallThickness;
totalWidth = Backer_Only_Mode ? Internal_Width : Internal_Width + wallThickness*2;
totalCenterX = Internal_Width/2;


//calculate total working space, respecting minimum mounting value.
//The mounting points should be 'inside' the total width. Therefore, we are rounding down to the next mounting points on both sides
mount_point_distance = quantdn(total_item_width+baseThickness*2+item_slop*2-(Minimum_Safe_Mount_Clearance_From_Edge)*2, distanceBetweenSlots);
echo(str("Mount Point Distance: ", mount_point_distance));
//new_mount_point_inward_adjustement = (total_item_width - mount_point_distance+item_slop*2 )/2;
new_mount_point_inward_adjustement = (total_item_width - mount_point_distance + item_slop*2 + baseThickness*2)/2;
echo(str("New Mount Point Inward Adjustment: ", new_mount_point_inward_adjustement));
echo(str("Grid spaces apart: ",  mount_point_distance/distanceBetweenSlots));

//move to center
union(){
translate(v = [-Internal_Width/2,0,0]) 
    if(!Backer_Only_Mode)
        basket();
    //slotted back
    if(Mounting_Style == "Multiconnect" || railMountMode)
        translate([0,0.02,totalDepth/2-baseThickness]) 
            rotate([0,Slot_From_Top ? 180 : 0,0])
                translate([-totalWidth/2,0,-totalDepth/2])//center
                    if(railMountMode)
                        multipointRailBack(
                            backWidth = totalWidth,
                            backHeight = totalDepth,
                            distanceBetweenSlots = distanceBetweenSlots,
                            slotStopFromBack = ClamShell_Mode ? new_mount_point_inward_adjustement : Multiconnect_Stop_Distance_From_Back
                        );
                    else
                        multiconnectBack(
                            backWidth = totalWidth, 
                            backHeight = totalDepth, 
                            distanceBetweenSlots = distanceBetweenSlots, 
                            slotStopFromBack = ClamShell_Mode ? new_mount_point_inward_adjustement : Multiconnect_Stop_Distance_From_Back
                        );
    else
        translate([0,0.02,-baseThickness])
            threadedSnapBack(backWidth = totalWidth, backHeight= totalDepth, distanceBetweenSlots = distanceBetweenSlots, anchor=BOT+BACK);
}


if(ClamShell_Mode)
up(total_item_width+item_slop*2) zflip() //rot([0,180,0])
union(){
translate(v = [-Internal_Width/2,0,0]) 
    if(!Backer_Only_Mode)
        basket();
    //slotted back
    if(Mounting_Style == "Multiconnect" || railMountMode)
        translate([0,0.02,totalDepth/2-baseThickness]) 
            rotate([0,Slot_From_Top ? 180 : 0,0])
                translate([-totalWidth/2,0,-totalDepth/2])//center
                    if(railMountMode)
                        multipointRailBack(
                            backWidth = totalWidth,
                            backHeight = totalDepth,
                            distanceBetweenSlots = distanceBetweenSlots,
                            slotStopFromBack = ClamShell_Mode ? new_mount_point_inward_adjustement : Multiconnect_Stop_Distance_From_Back
                        );
                    else
                        multiconnectBack(
                            backWidth = totalWidth, 
                            backHeight = totalDepth, 
                            distanceBetweenSlots = distanceBetweenSlots, 
                            slotStopFromBack = ClamShell_Mode ? new_mount_point_inward_adjustement : Multiconnect_Stop_Distance_From_Back
                        );
    else
        translate([0,0.02,-baseThickness])
            threadedSnapBack(backWidth = totalWidth, backHeight= totalDepth, distanceBetweenSlots = distanceBetweenSlots, anchor=BOT+BACK);
}

//Create Basket
module basket() {
    difference() {
        union() {
            //bottom
            translate([-wallThickness,0,-baseThickness])
                if (bottomCutout == true || Wall_Type == "Solid") //cutouts are not compatible with hex panels at this time. Need to build a frame first. 
                    cuboid([Internal_Width + wallThickness*2, Internal_Height + wallThickness,baseThickness], anchor=FRONT+LEFT+BOT, rounding=edgeRounding, edges = [BOTTOM+LEFT,BOTTOM+RIGHT,BOTTOM+BACK,LEFT+BACK,RIGHT+BACK]);
                else    
                     fwd(wallThickness)hex_panel([Internal_Width + wallThickness*2,Internal_Height+wallThickness*2, baseThickness], strut = 1, spacing = 5, frame= wallThickness, anchor=FRONT+LEFT+BOT);

            //left wall
            translate([-wallThickness,0,0])
                if (leftCutout == true || Wall_Type == "Solid") //cutouts are not compatible with hex panels at this time. Need to build a frame first. 
                    cuboid([wallThickness, Internal_Height + wallThickness, Internal_Depth], anchor=FRONT+LEFT+BOT, rounding=edgeRounding, edges = [TOP+LEFT,TOP+BACK,BACK+LEFT]);
                else    
                     fwd(wallThickness)hex_panel([Internal_Depth, Internal_Height + wallThickness*2,wallThickness], strut = 1, spacing = 7, frame= wallThickness, orient=RIGHT, anchor=FRONT+RIGHT+BOT);

            //right wall
            translate([Internal_Width,0,0])
                if (rightCutout == true || Wall_Type == "Solid") //cutouts are not compatible with hex panels at this time. Need to build a frame first. 
                    cuboid([wallThickness, Internal_Height + wallThickness, Internal_Depth], anchor=FRONT+LEFT+BOT, rounding=edgeRounding, edges = [TOP+RIGHT,TOP+BACK,BACK+RIGHT]);
                else    
                     fwd(wallThickness)hex_panel([Internal_Depth, Internal_Height + wallThickness*2,wallThickness], strut = 1, spacing = 7, frame= wallThickness, orient=RIGHT, anchor=FRONT+RIGHT+BOT);

            //front wall            
            translate([0,Internal_Height,0])
                if (frontCutout == true || Wall_Type == "Solid") //cutouts are not compatible with hex panels at this time. Need to build a frame first. 
                    cuboid([Internal_Width,wallThickness,Internal_Depth], anchor=FRONT+LEFT+BOT, rounding=edgeRounding, edges = [TOP+BACK]);
                else    
                    back(wallThickness)zrot(-90) hex_panel([Internal_Depth,Internal_Width,wallThickness], strut = 1, spacing = 7, frame= wallThickness,orient=RIGHT, anchor=FRONT+RIGHT+BOT);
        }

        //frontCaptureDeleteTool for item holders
            if (frontCutout == true)
                translate([frontLateralCapture,Internal_Height-1,frontLowerCapture])
                    cube([Internal_Width-frontLateralCapture*2,wallThickness+2,Internal_Depth-frontLowerCapture-frontUpperCapture+0.01]);
            if (bottomCutout == true)
                translate(v = [bottomSideCapture,bottomBackCapture,-baseThickness-1]) 
                    cube([Internal_Width-bottomSideCapture*2,Internal_Height-bottomFrontCapture-bottomBackCapture,baseThickness+2]);
            if (rightCutout == true)
                translate([-wallThickness-1,rightLateralCapture,rightLowerCapture])
                    cube([wallThickness+2,Internal_Height-rightLateralCapture*2,Internal_Depth-rightLowerCapture-rightUpperCapture+0.01]);
            if (leftCutout == true)
                translate([Internal_Width-1,leftLateralCapture,leftLowerCapture])
                    cube([wallThickness+2,Internal_Height-leftLateralCapture*2,Internal_Depth-leftLowerCapture-leftUpperCapture+0.01]);
            if (cordCutout == true) {
                translate(v = [Internal_Width/2+cordCutoutLateralOffset,Internal_Height/2+cordCutoutDepthOffset,-baseThickness-1]) {
                    union(){
                        cylinder(h = baseThickness + frontLowerCapture + 2, r = cordCutoutDiameter/2);
                        translate(v = [-cordCutoutDiameter/2,0,0]) cube([cordCutoutDiameter,Internal_Width/2+wallThickness+1,baseThickness + frontLowerCapture + 2]);
                    }
                }
            }
    }
    
}


//BEGIN MODULES
//Threaded back
module threadedSnapBack(backWidth, backHeight, distanceBetweenSlots, anchor=BOT, orient=UP, spin=0){
    diff()
    tag(Backer_Negatives_Only ? "remove" : "")
    cuboid(size = [backWidth, Force_Back_Thickness == 0 ? 3.59 : Force_Back_Thickness, backHeight], rounding=edgeRounding, except_edges=BACK, anchor=anchor, orient=orient, spin=spin){ 
        tag(Backer_Negatives_Only ? "keep" : "remove")
        attach(FRONT, BOT, inside=true, shiftout=0.01)
            grid_copies(size = [backWidth - Outer_Diameter_Sm*2, backHeight - Outer_Diameter_Sm*2], spacing = distanceBetweenSlots)
                trapezoidal_threaded_rod(d=Outer_Diameter_Sm, l=3.6, pitch=Pitch_Sm, flank_angle = Flank_Angle_Sm, thread_depth = Thread_Depth_Sm, $fn=50, internal=true, bevel2 = true, blunt_start=false, teardrop=true, anchor=TOP, $slop=Slop);
        children();
    };
}

// 1-inch Pegboard Click rail back, ported from the Multibin shelf model.
// Vertical slots are spaced across X; rotated slots are spaced across Z.
module multipointRailBack(backWidth, backHeight, distanceBetweenSlots, slotStopFromBack = 13)
{
    backThickness = Force_Back_Thickness == 0 ? 4.8 : Force_Back_Thickness;
    patternSpan = Rotate_Rail_Slots_90_Degrees ? backHeight : backWidth;
    travelSpan = Rotate_Rail_Slots_90_Degrees ? backWidth : backHeight;
    slotCount = max(1, floor(patternSpan/distanceBetweenSlots));
    firstSlot = (patternSpan-(slotCount-1)*distanceBetweenSlots)/2;

    // The measured rail is 41 mm overall: 8 mm past each of two centres 25 mm apart.
    assert(travelSpan >= slotStopFromBack+33+railEndClearance,
        str("The rail needs at least ", slotStopFromBack+33+railEndClearance,
            " mm along its travel direction. Increase the back dimension or reduce the stop distance."));
    assert(patternSpan >= 16,
        "The back needs at least 16 mm across the rail-slot spacing direction.");

    diff() {
        tag(Backer_Negatives_Only ? "remove" : "")
            translate([0,-backThickness,0])
                cuboid([backWidth,backThickness,backHeight], rounding=edgeRounding,
                    except_edges=BACK, anchor=FRONT+LEFT+BOT);

        for(slotNum=[0:slotCount-1]) {
            slotPosition = firstSlot+slotNum*distanceBetweenSlots;
            force_tag(Backer_Negatives_Only ? "keep" : "remove")
                if(Rotate_Rail_Slots_90_Degrees)
                    translate([backWidth-slotStopFromBack,
                        -2.35+slotDepthMicroadjustment+railSlotInset,
                        slotPosition])
                        rotate([0,90,0]) pegboardRailSlotTool(backWidth);
                else
                    translate([slotPosition,
                        -2.35+slotDepthMicroadjustment+railSlotInset,
                        backHeight-slotStopFromBack])
                        pegboardRailSlotTool(backHeight);
        }
    }
}

// Measured supported rail: 14.8 mm wide, 8 mm end radius and 45-degree taper.
// The continuous guide accepts the rail from the open end of the channel.
module pegboardRailSlotTool(length) {
    difference() {
        pegboardRailChannel(length);
        if(!slotQuickRelease)
            pegboardRailBumps();
    }
}

module pegboardRailChannel(length) {
    c = railSlotClearance;
    d = 1.216152;
    cutDepth = 2.5+railSlotInset+max(0,slotDepthMicroadjustment);
    taperEnd = min(cutDepth,2.746152);
    profile = [[0,0],[7.4+c,0],[7.4+c,d],
               [7.4+c-(taperEnd-d),taperEnd],
               [7.4+c-(taperEnd-d),cutDepth],[0,cutDepth]];

    module guide(guideLength) {
        rotate([180,0,0]) linear_extrude(height=guideLength)
            union() {
                polygon(profile);
                mirror([1,0,0]) polygon(profile);
            }
    }

    union() {
        guide(length+1);
        intersection() {
            scale([1/sin(67.5),1,1/sin(67.5)])
                rotate([90,67.5,0])
                    rotate_extrude($fn=8)
                        polygon([[0,0],[8+c,0],[8+c,0.616152],
                                 [8+c-(taperEnd-0.616152),taperEnd],
                                 [8+c-(taperEnd-0.616152),cutDepth],[0,cutDepth]]);
            translate([0,0,10]) guide(20);
        }
    }
}

// Two measured locking recesses at the closed end of each channel.
module pegboardRailBumps() {
    for(side=[-1,1]) scale([side,1,1])
        rotate([90,0,0]) intersection() {
            r = 5.2-railLockClearance;
            a = 1.9+railLockClearance;
            p = railBumpProjection;
            translate([0,0,-epsilon])
                cylinder(h=p+epsilon,r1=r+epsilon,r2=r-p,$fn=96);
            railLoftSection(
                [[a-epsilon,a-epsilon],[6,a-epsilon],[6,6],[a-epsilon,6]],
                [[a+p,a+p],[6,a+p],[6,6],[a+p,6]],
                -epsilon,p);
        }
}

module railLoftSection(bottom,top,z0,z1) {
    n = len(bottom);
    polyhedron(
        points=concat([for(p=bottom) [p[0],p[1],z0]],
                      [for(p=top) [p[0],p[1],z1]]),
        faces=concat([[for(i=[n-1:-1:0]) i]],
                     [[for(i=[0:n-1]) n+i]],
                     [for(i=[0:n-1]) [i,(i+1)%n,(i+1)%n+n,i+n]]),
        convexity=4);
}

//Slotted back Module
module multiconnectBack(backWidth, backHeight, distanceBetweenSlots, slotStopFromBack = 13)
{
    //slot count calculates how many slots can fit on the back. Based on internal width for buffer. 
    //slot width needs to be at least the distance between slot for at least 1 slot to generate
    let (backWidth = max(backWidth,distanceBetweenSlots), backHeight = max(backHeight, 25),slotCount = floor(backWidth/distanceBetweenSlots), backThickness = Force_Back_Thickness == 0 ? 6.5 : Force_Back_Thickness){
        diff() {
            tag(Backer_Negatives_Only ? "remove" : "")
                translate(v = [0,-backThickness,0]) 
                    cuboid(size = [backWidth,backThickness,backHeight], rounding=edgeRounding, except_edges=BACK, anchor=FRONT+LEFT+BOT);
            //Loop through slots and center on the item
            //Note: I kept doing math until it looked right. It's possible this can be simplified.
            for (slotNum = [0:1:slotCount-1]) {
                force_tag(Backer_Negatives_Only ? "keep" : "remove")    
                    translate(v = [distanceBetweenSlots/2+(backWidth/distanceBetweenSlots-slotCount)*distanceBetweenSlots/2+slotNum*distanceBetweenSlots,-2.35+slotDepthMicroadjustment + (Force_Back_Thickness == 0 ? 0 : 6.5 - Force_Back_Thickness),backHeight-slotStopFromBack]){
                        if(Backer_Negatives_Only)
                            back_half(y=-4.15, s=backHeight * 2 + 20)
                                slotTool(backHeight);
                        else 
                            slotTool(backHeight);
                    }
            }
        }
    }
    //Create Slot Tool
    module slotTool(totalDepth) {
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
                    linear_extrude(height = totalDepth+1) 
                        union(){
                            polygon(points = slotProfile);
                            mirror([1,0,0])
                                polygon(points = slotProfile);
                        }
                //on-ramp
                if(onRampEnabled)
                    for(y = [1:onRampEveryXSlots:totalDepth/distanceBetweenSlots])
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
}
