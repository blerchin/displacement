use <nutsnbolts/cyl_head_bolt.scad>
use <helpers.scad>
inch = 25.4;
wiggle = .3;
MOUNT_DIA = 1.66 * inch;
MOUNT_HEIGHT = inch/2;
MOUNT_SCREW_DIA = 1.3 * inch;
JOINT_HEIGHT = inch/8;
JOINT_DIA = inch;
CEIL_HEIGHT = inch / 4;
FLANGE_DIA = 1.25 * inch;
FLANGE_HEIGHT = inch / 8;
FLANGE_BASE_HEIGHT = inch / 4;
FLANGE_BASE_CLEARANCE = inch / 8;
NECK_DIA = (5/8) * inch + 1;
NECK_HEIGHT = inch/8;
HEX_HEIGHT = (5/8) * inch;
HEX_DIA = (3/4) * inch;
$fn = 256;
e = 0.01; //epsilon to avoid scad artifacts
2e = 0.02; //double epsilon to avoid scad artifacts

module hex_mount_top() {
  difference() {
    cylinder(d=MOUNT_DIA, h=MOUNT_HEIGHT);
    //CLAMP MOUNT
    translate([0, 0, MOUNT_HEIGHT + e])
      770_mount(height=MOUNT_HEIGHT + 2e);
    translate([0, 0, MOUNT_HEIGHT - JOINT_HEIGHT])
      770_mount(dia=inch/5, height = inch/4);
    translate([0, 0, MOUNT_HEIGHT - JOINT_HEIGHT/2])
      hexaprism(ri=JOINT_DIA/2 + wiggle, h=JOINT_HEIGHT + 2e);
    translate([0, 0, MOUNT_HEIGHT + e])
    rotate([0, 0, 0])
    place_mount_screws(MOUNT_SCREW_DIA, n=6) {
      hole_through(name="M3", l=20);
    }
  }
}
translate([MOUNT_DIA + 10, 0, 0])
  hex_mount_top();

module hex_mount_half() {
  half_height = NECK_HEIGHT + FLANGE_HEIGHT + HEX_HEIGHT + CEIL_HEIGHT;
  translate([0, 0, -half_height/2])
  difference() {
    union() {
      cylinder(d = MOUNT_DIA, h = half_height);
      translate([0, 0, half_height + JOINT_HEIGHT/2])
        hexaprism(ri=JOINT_DIA/2, h=JOINT_HEIGHT);
    }
    translate([0, 0, -e])
    union() {
      translate([-MOUNT_DIA/2, 0, 0])
        cube([MOUNT_DIA, MOUNT_DIA, half_height + JOINT_HEIGHT + 2e]);
      //NECK
      cylinder(d = NECK_DIA, h = NECK_HEIGHT + 2e);
      //FLANGE_BASE_CLEARANCE
      translate([0, 0, NECK_HEIGHT - FLANGE_BASE_HEIGHT])
        cylinder(d1 = NECK_DIA, d2 = NECK_DIA + 2 * FLANGE_BASE_CLEARANCE, h = FLANGE_BASE_HEIGHT + 2);
      //FLANGE
      translate([0, 0, NECK_HEIGHT])
        cylinder(d = FLANGE_DIA + wiggle, h = FLANGE_HEIGHT);
      //SOCKET
      translate([0, 0, NECK_HEIGHT + FLANGE_HEIGHT + HEX_HEIGHT/2])
      rotate([0, 0, 30])
        hexaprism(ri=HEX_DIA/2 + wiggle, h=HEX_HEIGHT + 2e);
      //TOP SCREWS
      translate([0, 0, half_height + 2e])
      rotate([0, 0, 0])
      place_mount_screws(MOUNT_SCREW_DIA, n=6) {
        hole_threaded(name="M3", l=20);
      }
    }
  }
}
//HALF WITH THREADED HOLES
difference() {
  rotate([-90, 0, 0])
    hex_mount_half();
  translate([0, 0, 40 -e])
  rotate([0, 0, 90])
  place_mount_screws(1.3 * inch, n=2) {
    rotate([0, 0, -45])
    translate([0, 0, -19])
      nutcatch_parallel(name="M3", l=10);
    hole_threaded(name="M3", l=40);
  }
}
//HALF WITH THROUGH HOLES
translate([-MOUNT_DIA - 10, 0, 0])
difference() {
  rotate([-90, 0, 0])
    hex_mount_half();
  translate([0, 0, 10 -e])
  rotate([0, 0, 90])
  place_mount_screws(1.3 * inch, n=2) {
    screw_neg("M3x20", head_height=10);
    //hole_through(name="M3", l=40);
  }
}
