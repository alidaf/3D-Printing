// =============================================================================
//
// DIN Cleat
//
// Copyright Darren Faulke June 2023
//
// Code licensed under the GPL 3.0
// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Version 1.0
//
// 1.0
//  Initial Code
// 
// =============================================================================

// =============================================================================
// User defined parameters
// =============================================================================

// Define the cleat
// Multiple stops and main sections can be defined by specifying the type and
// length of each within a list.
// The total length is the cumalative sum of all the section lengths.
// cleat = [
//          ["main" or "stop", length],
//          [...],
//          ];
// 
cleat = [
         ["stop", 2],
         ["main", 76],
         ["stop", 2],
         ];

// Slot sizes - adjust as necessary
slot_d1 =  3.0; // Screw size
slot_d2 =  6.0; // Screw cap size
slot_h2 =  3.0; // Hole cap height
slot_l  = 10.0; // Hole length (can be 0 for circular holes)
slot_n  =    4; // Number of slots (can be 0 for blank cleat)

slots = [slot_n, [slot_d1, slot_d2, slot_h2, slot_l]];

// =============================================================================
// Geometry
// =============================================================================

// The edge profiles are based on the GPL 3.0 licensed model at
// https://github.com/MotorDynamicsLab/LDOVoron0/blob/v02/STLs/DIN_Mounts/DIN%20Screw%20Cleat_x2.stl
//
// These values should typically not be changed
//
w_outer = 35.0;     // Outer width
w_inner = 32.0;     // Inner width
w_lip   = 33.8;     // Width to lip
h_lip   = 1.10;     // Lip height
h_total = 4.60;     // Total height
t_lip   = 1.00;     // Lip taper
t_edge  = 0.40;     // Edge taper

// =============================================================================
// Profiles
// =============================================================================

// Points that define main profile
c0 = [0, 0];
c1 = [w_outer / 2 - t_edge, 0];
c2 = [w_outer / 2, t_edge];
c3 = [c2.x, h_lip];
c4 = [w_lip / 2, c3.y];
c5 = [c4.x - t_lip, c4.y + t_lip];
c6 = [c5.x, h_total - t_edge];
c7 = [c6.x - t_edge, h_total];
c8 = [0, c7.y];

// Points that define stop profile
s0 = c0;
s1 = c1;
s2 = c2;
s3 = [c2.x, c6.y];
s4 = [c1.x, c7.y];
s5 = c8;

// Profiles
prof_c = [c0, c1, c2, c3, c4, c5, c6, c7, c8];
prof_s = [s0, s1, s2, s3, s4, s5];

// =============================================================================
// Functions
// =============================================================================

// -----------------------------------------------------------------------------
// Determines cleat length at index
// -----------------------------------------------------------------------------
function cleat_length(list, n, c = 0) =
    c < n - 1?
    list[c][1] + cleat_length(list, n, c + 1)
    :
    list[c][1];
// -----------------------------------------------------------------------------

// =============================================================================
// Modules
// =============================================================================

// -----------------------------------------------------------------------------
// Creates a cleat end stop
// -----------------------------------------------------------------------------
module create_stop(h)
{
    linear_extrude(h, convexity = 3)
    {
        polygon(prof_s);
        mirror([1, 0, 0])
        polygon(prof_s);
    }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Creates a cleat main section
// -----------------------------------------------------------------------------
module create_main(h)
{
    linear_extrude(h, convexity = 3)
    {
        polygon(prof_c);
        mirror([1, 0, 0])
        polygon(prof_c);
    }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Creates the cleat
// -----------------------------------------------------------------------------
module create_cleat(c)
{
    for (i = [0 : len(c) - 1])
    {
        z = (i == 0)? 0 : cleat_length(list = c, n = i);
        t = c[i][0];
        l = c[i][1];

        translate([0, 0, z])
        if (t == "stop")
            create_stop(l);
        else
        if (t == "main")
            create_main(l);
        else;
    }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Creates a single screw hole
// -----------------------------------------------------------------------------
module create_screw_hole(s)
{
    rotate([-90, 0, 0])
    {
        translate([0, 0, -0.1])
        cylinder(d = s[0], h = h_total + 0.2, $fn = 360);
    }
}

// -----------------------------------------------------------------------------
// Creates a single screw cap hole
// -----------------------------------------------------------------------------
module create_cap_hole(s)
{
    rotate([-90, 0, 0])
    {
        translate([0, 0, -0.1])
        cylinder(d = s[1], h = s[2] + 0.1, $fn = 360);
    }
}

// -----------------------------------------------------------------------------
// Creates a single slot
// -----------------------------------------------------------------------------
module create_slot(s)
{
    hull()
    {
        create_screw_hole(s);
        translate([0, 0, s[3]])
        create_screw_hole(s);
    }

    hull()
    {
        create_cap_hole(s);
        translate([0, 0, s[3]])
        create_cap_hole(s);
    }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module create_slots(s, c)
{
    if (s[0] > 0)
    {
        l = cleat_length(list = c, n = len(c));
        gap = l / s[0];

        for (i = [0 : s[0] - 1])
        {
            off = (gap - s[1][3]) / 2 + gap * i;
            translate([0, 0, off])
            create_slot(s[1]);
        }
    }
}
// -----------------------------------------------------------------------------

// =============================================================================
// Main
// =============================================================================

off = cleat_length(list = cleat, n = len(cleat)) / 2;

translate([off, 0, 0])
rotate([-90, 0, 90])
difference()
{
    create_cleat(cleat);
    create_slots(slots, cleat);
}

// =============================================================================
