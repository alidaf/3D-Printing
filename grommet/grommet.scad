// =======================================================================================
//
// Customisable double-sided grommet.
//
// Copyright Darren Faulke January 2022
// 
// This source code is from https://github.com/alidaf/3D-Printing/grommet
//
// Please read the license agreement for this code and all media created by it's use at
// https://github.com/alidaf/3D-Printing
//
// In summary, this source code is covered by the GPLv3 license and all media produced
// by it's use is covered by the Attribution-NonCommercial-ShareAlike 4.0 International 
// license (CC BY-NC-SA 4.0)
// 
// =======================================================================================

// Needs the threads library https://github.com/rcolyer/threads-scad
// Copy the library to your local user library.
use <threads-scad/threads.scad>

// Dimensions ----------------------------------------------------------------------------

// ***** Common dimensions *****
//
// Ethernet:
// d_plug  = 16.0;
// d_cable =  6.0;
//
// Prusa i3 MK3 kettle lead:
// d_plug  = 30.0;
// d_cable =  8.0;
//
// IKEA Platsa back panel:
// l_body  = 3.0;
// tl_body = 3.0;
// l_grip  = 3.0;
//
// IKEA Platsa side wall:
// l_body  = 18.0;
// tl_body = 5.0;
// l_grip  = 3.0;
//
// IKEA Platsa top wall / shelf:
// l_body = 22.0;
// tl_body = 5.0;
// l_grip  = 3.0;
//
// *****************************

// Main
d_plug  = 16.0; // Size of plug that needs to pass through grommet
d_cable =  6.0; // Diameter (x) of cable (0 makes a blind grommet)
x_cable =  0.0; // Additional slot length for cable hole (0 = circular hole)

// Body
t_body  =  1.4; // Wall thicknesses of grommet body
l_body  = 22.0; // Length of grommet body (thickness of walls to use on!)

// Body threads
tl_body = 5.0; // Thread length on grommet body (<= l_body)
th_body = 0.6; // Thread height (height of teeth!)
tp_body = 1.0; // Thread pitch on main body

// Ends
t_ends  = 1.4; // Thickness of ends
s_ends  = 2 * t_body; // Clamp length of ends (radial)
chamfer = 1.0; // Chamfer size on ends

// End threads
tp_ends = 1.0; // Thread pitch around front end
th_ends = 0.6; // Thread height around front end

// Grips
r_grip = 0.6; // Maximum radial size of grip
t_grip = 0.4; // Thickness (circumferential) of plug grip
l_grip = 6.0; // Vertical size of grip
n_grip =  12; // Number of plug grips around plug

// Tolerances
tol_body = 0.0; // Fit tolerance between bodies
tol_seal = 0.1; // Fit tolerance between seal and body
tol_seat = 0.4; // Fit tolerance for seal seating depth

// Seals (supported above inner thread)
t_seal = (t_ends - tol_seat) / 2; // Thickness of seals

d_hole = d_plug + 2 * (t_body + th_body) + 2 * (t_body + th_ends);
echo("Diameter of drill hole = ", d_hole);
echo(" -> adjust parameters to achieve an appropriate size.");
echo(" -> d_plug    Diameter of plug passing through the grommet.");
echo(" -> t_body    Wall thickness of the grommet body.");
echo(" -> th_body   Thread height on grommet body");
echo(" -> th_ends   Thread height on grommet end (for cap)");

// Checks
echo("================================================================================");

echo(" Seal thickness is ", t_seal);
echo(" -> adjust tol_seat to make it a multiple of nozzle height.");
echo("");

assert(tl_body <= l_body, "Length of thread, tl_body must be less than length of grommet body, l_body:");

echo("Length of thread compared to body should be ok:")
echo("tl_body = ", tl_body);
echo("l_body = ", l_body);
echo("");

assert(l_grip <= l_body, "Length of grip, l_grip must be less than length of grommet body, l_body:");

echo("Length of grip compared to body should be ok:")
echo("l_grip = ", tl_body);
echo("l_body = ", l_body);
echo("");

// ***** Could probably do with more checks *****
echo("================================================================================");

// Quality
$fn = 99;
// ---------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------
module make_front(d_plug   = 0, // Diameter of plug
                  t_body   = 0, // Thickness of body
                  l_body   = 0, // Length of body
                  tl_body  = 0, // Thread length of body
                  th_body  = 0, // Thread height of body
                  t_seal   = 0, // Seal thickness
                  tol_seal = 0, // Tolerance on seal diameter for fit
                  tol_seat = 0, // Tolerance on seal seating depth
                  t_ends   = 0, // Thickness of ends
                  s_ends   = 0, // Support length of ends
                  th_ends  = 0, // Thread height of ends
                  r_grip   = 0, // Grip height
                  l_grip   = 0, // Grip length
                  t_grip   = 0, // Grip thickness
                  n_grip   = 0) // Number of grips around body
{
    seal_pocket_depth = 2 * t_seal + tol_seat;
    
    di_body = d_plug + 2 * (t_body + th_body);
    do_body = di_body + 2 * (t_body + th_body);
    
    do_head = do_body + 2 * t_body;

    d_threaded = do_body + 2 * s_ends;
    d_ends = d_threaded + 2 * (t_ends + th_body); // Ensure min wall thickness

    d_seal = di_body + 2 * tol_seal;

    difference()
    {
        // Plug internal thread
        ScrewHole(outer_diam = di_body,
        height = tl_body + t_ends + l_body + 1, // Needs to be all the way through!
        position = [0, 0, t_ends],
        pitch = tp_body,
        tooth_height = th_body)
        {
            union()
            {
                // Head outer thread 
                ScrewThread(outer_diam = d_threaded,
                            height = t_ends + tol_seat,
                            pitch = tp_ends,
                            tooth_height = th_ends)

                // Head - this gets threaded!
                cylinder(h = t_ends, r = d_ends / 2); // 
                
                // Plug
                translate([0, 0, t_ends])
                cylinder(h = l_body, r = do_body / 2);
                
                // Grip profile (x-y plane)
                grip_points = [[do_body / 2, 0],
                               [do_body / 2 + r_grip, 0],
                               [do_body / 2, l_grip],
                               [do_body / 2, l_grip]];

                // Grips
                make_grips(points = grip_points,
                           position = [0, 0, t_ends],
                           t = t_grip,
                           n = n_grip);
            }
        }

        // Seal pocket
        translate([0, 0, -0.1]) // Avoid ininitely thin artefacts!
        cylinder(h = seal_pocket_depth + 0.1, r = d_seal / 2 + tol_seal);

        // Unthreaded section removal
        translate([0, 0, t_ends + tl_body])
        cylinder(h = l_body - tl_body + 0.1, r = di_body / 2 + th_body + tol_body);

        // Seal lugs
        for (i = [0 : 3])
        {
            rotate([0, 0, i * 90])
            translate([-d_seal / 2, 0, -0.1])
            cylinder(h = seal_pocket_depth + 0.1, r = 1 + tol_seal);
        }
    }
    
}
// ---------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------
module make_rear(d_plug  = 0, // Diameter of plug
                 l_body  = 0, // Length of body
                 t_body  = 0, // Thickness of body
                 th_body = 0, // Thread height of body
                 tl_body = 0, // Thread length of body
                 t_ends  = 0, // Thickness of ends
                 s_ends  = 0, // Support length on ends
                 tp_body = 0, // Thread pitch on body
                 chamfer = 0) // Side length of chamfer
{

    di_body = d_plug;
    do_body = di_body + 2 * (t_body + th_body);

    di_main = d_plug + 2 * (t_body + th_body);
    do_main = di_main + 2 * (t_body + th_body);

    d_threaded = do_main + 2 * s_ends;
    d_ends = d_threaded + 2 * (t_ends + th_body); // Ensure min wall thickness

    difference()
    {
        union()
        {
            // Chamfered section of end
            cylinder(h = chamfer, r1 = d_ends / 2 - chamfer, r2 = d_ends / 2);

            // Straight section of end
            translate([0, 0, chamfer])
            cylinder(h = t_ends - chamfer, r = d_ends / 2);

            // Unthreaded section of plug
            translate([0, 0, t_ends])
            cylinder(h = l_body - tl_body, r = do_body / 2);
            translate([0, 0, t_ends + l_body - tl_body])

            // Threaded section of plug
            ScrewThread(outer_diam = do_body,
                        height = tl_body,
                        pitch = tp_body,
                        tooth_height = th_body);
        }
        // Bore
        translate([0, 0, -0.1])
        cylinder(h = t_ends + l_body + 0.2, r = d_plug / 2);
    }
}
// ---------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------
module make_cover(d_plug   = 0, // Diameter of plug
                  t_body   = 0, // Thickness of body
                  th_body  = 0, // Thread height of body
                  s_ends   = 0, // Support length on ends
                  t_ends   = 0, // Thickness of ends
                  tp_ends  = 0, // Thread pitch on ends
                  chamfer  = 0, // Side length of chamfer
                  tol_seat = 0) // Tolerance on seal seating depth
{
    di_body = d_plug + 2 * (t_body + th_body);
    do_body = di_body + 2 * (t_body + th_body);

    d_threaded = do_body + 2 * s_ends;
    d_ends = d_threaded + 2 * (t_ends + th_body); // Ensure min wall thickness

    ScrewHole(outer_diam = d_threaded,
              height = t_ends + 1,
              position = [0, 0, t_ends],
              pitch = tp_ends,
              tooth_height = th_body)
    
    difference()
    {
        union()
        {
            cylinder(h = chamfer, r1 = d_ends / 2 - chamfer, r2 = d_ends / 2);
            translate([0, 0, chamfer])
            cylinder(h = t_ends - chamfer, r = d_ends / 2);
            translate([0, 0, t_ends])
            cylinder(h = t_ends + tol_seat, r = d_ends / 2);
        }
        translate([0, 0, -1])
        cylinder(h = t_ends + 2, r = d_plug / 2);
    }   
}
// ---------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------
module make_seal(d_plug  = 0, // Plug diameter
                 t_body  = 0, // Body wall thickness
                 th_body = 0, // Thread height of body
                 t_seal  = 0, // Seal thickness
                 x_cable = 0, // Additional slot length for cable hole (0 = circular hole)
                 d_cable = 0) // Diameter of cable
{
//    di_body = d_plug + 2 * (t_body + th_body);
//    d_seal = di_body + 2 * tol_seal;
    
    di_seal = d_plug + 2 * (t_body + th_body);

    difference()
    {
        union()
        {
            // Seal
            cylinder(h = t_seal, r = di_seal / 2);
            
            // Lugs
            for (i = [0 : 3])
            {
                rotate([0, 0, i * 90])
                translate([-di_seal / 2, 0, 0])
                cylinder(h = t_seal, r = 1);
            }
        }

        // Slot
        rotate([0, 0, 45])
        hull()
        {
            translate([-x_cable, 0, - 1])
            cylinder(h = t_seal + 2, r = d_cable / 2);
            translate([di_seal, 0, - 1])
            cylinder(h = t_seal + 2, r = d_cable / 2);
        }
    }
}
// ---------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------
module make_grips(points = [[0, 0], [0, 0], [0, 0], [0, 0]], // Profile in X-Y plane
                  position = [[0, 0], [0, 0], [0, 0]],       // Position
                  t = 0,                                     // Thickness of grip
                  n = 0)                                     // Number of grips
{
    d = points[0][0];
    i_angle = 360 / n;
    translate(position)
    rotate([0, 0, i_angle / 2])
    {
        for(i = [0: (n - 1)])
        {
            rotate([0, 0, i * i_angle])
            rotate_extrude(angle = 2 * asin(t / d))
            polygon(points);
        }
    }
}
// ---------------------------------------------------------------------------------------

// =======================================================================================

// Clipping plane to preview

//module make_bodies()
//{
//make_front();
//
//translate([0, 0, (t_ends + l_body) * 2 + 10])
////translate([0, 0, 14.6])
//rotate([180, 0, 0])
//make_rear();
//
//translate([0, 0, -10])  
////make_seal();
//
//translate([0, 0, -20])
//rotate([0, 0, 180])
//make_seal();
//
//translate([0, 0, -32])
//make_cover();
//}
//
//difference()
//{
//    make_bodies();
//    translate([0, -100, -100])
//    cube(200);
//}

make_front(d_plug   = d_plug,
           t_body   = t_body,
           l_body   = l_body,
           tl_body  = tl_body,
           th_body  = th_body,
           t_seal   = t_seal,
           tol_seal = tol_seal,
           tol_seat = tol_seat,
           t_ends   = t_ends,
           s_ends   = s_ends,
           th_ends  = th_ends,
           r_grip   = r_grip,
           l_grip   = l_grip,
           t_grip   = t_grip,
           n_grip   = n_grip);

translate([0, 0, (t_ends + l_body) * 2 + 10])
rotate([180, 0, 0])
make_rear(d_plug  = d_plug,
          l_body  = l_body,
          t_body  = t_body,
          th_body = th_body,
          tl_body = tl_body,
          t_ends  = t_ends,
          s_ends  = s_ends,
          tp_body = tp_body,
          chamfer = chamfer);

translate([0, 0, -10])  
make_seal(d_plug  = d_plug,
          t_body  = t_body,
          th_body = th_body,
          t_seal  = t_seal,
          x_cable = x_cable,
          d_cable = d_cable);

translate([0, 0, -20])
rotate([0, 0, 180])
make_seal(d_plug  = d_plug,
          t_body  = t_body,
          t_seal  = t_seal,
          th_body = th_body,
          x_cable = x_cable,
          d_cable = d_cable);

translate([0, 0, -32])
make_cover(d_plug   = d_plug,
           t_body   = t_body,
           th_body  = th_body,
           s_ends   = s_ends,
           t_ends   = t_ends,
           tp_ends  = tp_ends,
           chamfer  = chamfer,
           tol_seat = tol_seat);

// =======================================================================================
