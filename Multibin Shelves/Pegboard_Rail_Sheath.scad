// Open-backed adapter for the previously printed, original-width Multipoint shelf.
// Reference: supplied Pegboard Click Multipoint Rail (Supported), 14.8 x 41 mm.
// Connected-frame concept informed by the supplied Fold-In Locked Lite Rail.
// This is a new measured adapter, not a copy of the Fold-In mating profile.
// Print flat as exported. Fit the frame around the wide rail face, bridge below
// the lower end, then slide the shelf down over the rail and frame together.
/* [Fit] */
// Horizontal clearance PER SIDE to the 14.8 mm rail.
railClearance = 0.10; // [0.05:0.05:0.2]
// Horizontal clearance PER SIDE to the original 17 mm Multipoint channel.
shelfClearance = 0.10; // [0.05:0.05:0.2]
// Thickness perpendicular to the wide face. Avoid the channel's narrow waist.
shimDepth = 0.8; // [0.6:0.1:0.8]
/* [Hidden] */
railHalfWidth=7.4;
channelHalfWidth=8.5;
channelTaperStart=0.2;
channelTaperSlope=(8.5-6.875)/2.2;
lengthBelowUpperCentre=34.5;
bridgeLength=1;
inner=railHalfWidth+railClearance;
outer=channelHalfWidth-shelfClearance;
outerTip=outer-(shimDepth-channelTaperStart)*channelTaperSlope;
assert(railClearance>=0.05 && shelfClearance>=0.05,"Use positive mating clearances of at least 0.05 mm.");
assert(shimDepth>=0.6 && shimDepth<=0.8,"Keep shim depth between 0.6 and 0.8 mm.");
assert(outerTip-inner>=0.4,"Less than 0.4 mm remains at the strip tip; reduce clearances or shim depth.");
module adapter() {
    union() {
        for(side=[-1,1]) scale([side,1,1])
            translate([0,lengthBelowUpperCentre,0]) rotate([90,0,0])
                linear_extrude(height=lengthBelowUpperCentre)
                    polygon([[inner,0],[outer,0],[outer,channelTaperStart],
                             [outerTip,shimDepth],[inner,shimDepth]]);
        translate([-inner-0.02,0,0]) cube([2*inner+0.04,bridgeLength,shimDepth]);
    }
}
echo(width_mm=2*outer,length_mm=lengthBelowUpperCentre,depth_mm=shimDepth,
     minimum_side_strip_mm=outerTip-inner);
adapter();
