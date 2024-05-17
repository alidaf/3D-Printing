// =============================================================================
//
// Curved SVG Images
//
// This library allows the wrapping of multiple 2D SVG images around a curved,
// essentially cylindrical surface. Images can scaled, rotated, flipped and
// positioned around a radius at an angular position and height.
// Since SVG images scale losslessly I use a convention where the longest side
// is 50mm so that I can always gauge the amount of scaling needed.
// 
// Copyright Darren Faulke (Autistech) May 2024
//  darren@autistech.org.uk
// With credit to Justin Lin for the example used as the basis of the code
//  https://openhome.cc/eGossip/OpenSCAD/2DtoCylinder.html
//
// Version 1.0
//
// =============================================================================

// =============================================================================
// License: GNU General Public License V2
// =============================================================================
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free 
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.
// 
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
// 
// You should have received a copy of the GNU General Public License along with
// this program; if not, write to the Free Software Foundation, Inc., 
// 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
// =============================================================================

// -----------------------------------------------------------------------------
// Customisation
// -----------------------------------------------------------------------------

svg_thick  = 0.4; // SVG image thickness

// Quality settings
qual_svg   = 32;    // Can be implemented in import function
qual_crv   = 90;    // Number of curve segments for each image

// Note: The above settings can be set independently foe each image imported

// -----------------------------------------------------------------------------
// Images
// -----------------------------------------------------------------------------

// SVG images format
// svgs = [ filename,
//         [img x (mm), img y (mm)],     
//         [radius, z position, theta, rot, flip=true/false],
//         [x scale, y scale],
//          depth,
//          [svg quality, curve quality ($fn)]],
//         [...],
//          ...];

// Some examples

svgs = [
        ["Images/Dragon.svg",
         [90, 50], 
         [17, 25, 0, 0, false],
         [1.4, 1.0],
         svg_thick,
         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 0, 0, 30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 0, 90, 30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 0, 180, 30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 0, 270, 30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 20, 0, -30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 20, 90, -30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 20, 180, -30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
//        ["Images/Heart Outline.svg",
//         [50, 50], 
//         [15, 20, 270, -30, false],
//         [0.52, 0.52],
//         svg_thick,
//         [qual_svg, qual_crv]],
        ];

// =============================================================================
// Modules
// =============================================================================

// -----------------------------------------------------------------------------
// SVG IMAGES
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Locate the imported SVG
// -----------------------------------------------------------------------------
module locate_svg(svg)
{
    file = svg[0];
    size = svg[1];
    pos  = svg[2];
    scl  = svg[3];
    thk  = svg[4];
    qual = svg[5];

    flip = (pos[4] == true)? [0, 180, pos[3]] : [0, 0, pos[3]];

    rotate([0, 0, 90])
    translate([0, 0, thk])
    linear_extrude(thk, convexity = 3)
    rotate(flip)
    scale([scl[0], scl[1], 1])
        import(file, center = true, $fn = qual[0]);
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Adds a single curved SVG image
// -----------------------------------------------------------------------------
module add_svg(svg)
{
    file = svg[0];
    size = svg[1];
    pos  = svg[2];
    scl  = svg[3];
    thk  = svg[4];
    qual = svg[5];

    // Calculate segment angle
    arc_a = size[0] * scl[0] / (PI * 2 * pos[0]) * 360;
    seg_a = arc_a / qual[1];

    // effective chord length of rotational increment
    chord = 2 * pos[0] * tan(seg_a / 2);
    sagitta = pos[0] - sqrt(pos[0]^2 - (chord^2) / 4);

    // Calculate effective height of image accounting for rotation
    rot = pos[3];
    
//    h = cos(abs(rot)) * size[0] + sin(abs(rot)) * size[1];
    h = abs(size[0] * scl[0] * sin(rot)) +
        abs(size[1] * scl[1] * cos(rot));

    ypos = pos[0] * sin(seg_a / 2);

    // z position
    translate([0, 0, pos[1]])
    // Angular position
    rotate([0, 0, pos[2]])

    // Rotational increments
    for (i = [-qual[1] / 2 : qual[1] / 2])
    {
        intersection()
        {
            // Rotate to segment
            rotate([0, 0, seg_a * i])
            // Locate perimeter
            translate([pos[0] - (thk + sagitta),
                       -(2 * ypos * i + ypos), 0])

            // Flip vertically
            rotate([0, 90, 0])
            locate_svg(svg);

            translate([0, 0, -h / 2])
            cylinder(h = h,
                     r = pos[0] + thk,
                     $fn = qual[1] * 360 / arc_a);
        }
    }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Adds all SVG images
// -----------------------------------------------------------------------------
module add_svgs(svgs = [])
{
    if (len(svgs) > 0)
    {
        for (i = [0 : len(svgs) - 1])
        {
            add_svg(svgs[i]);
        }
    }
}
// -----------------------------------------------------------------------------

// =============================================================================
// MAIN
// =============================================================================

// Comment out as needed

// -----------------------------------------------------------------------------
// Images only
// -----------------------------------------------------------------------------
   add_svgs(svgs);
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Embossed cylinder example
// -----------------------------------------------------------------------------
//render(convexity = 3)
//union()
//{
//    cylinder(h = 50, r = 15, $fn = 360);
//    add_svgs(svgs);
//}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Debossed cylinder example
// -----------------------------------------------------------------------------
//render(convexity = 3)
//difference()
//{
//    cylinder(h = 50, r = 15.3, $fn = 360);
//    add_svgs(svgs);
//}
// -----------------------------------------------------------------------------

// =============================================================================
