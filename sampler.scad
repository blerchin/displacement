use <scad-utils/morphology.scad>

inch = 25.4;
WIDTH = 6 * inch;
DEPTH = 6 * inch;
HEIGHT = 6 * inch;
WALL_THICKNESS = 1;
BLADE_THICKNESS = 1;
FLANGE_DEPTH = 1 * inch;
FLANGE_THICKNESS = WALL_THICKNESS;

SCREW_OD = 6;
NUT_OD = inch / 2;


$fn = 256;

module elbow(d) {
  difference(){
    rotate_extrude(angle = 90, convexity = 10)
      translate([d, 0, 0])
      square([BLADE_THICKNESS, WALL_THICKNESS]);
    translate([0, -d * 2, -WALL_THICKNESS + 0.01])
      cube([d * 2, d * 2, WALL_THICKNESS * 2]);
    translate([-d * 1.99, -d * 2, -WALL_THICKNESS + 0.01])
      cube([d * 2, d * 4, WALL_THICKNESS * 2]);
  }
}

module slot(length, height = BLADE_THICKNESS, depth = WALL_THICKNESS, retract = 13) {
  od = depth + height;
  difference() {
    union() {
      cube([length, depth, height]);
      cube([height, depth, retract]);
    }
    translate([-0.01, -0.01, -0.01])
      cube([od, depth + 0.02, depth]);
  }
  translate([od, 0, od])
  rotate([90, 90, 180])
    elbow(depth);
}

module place_slots() {
  translate([0, 0.5, inch / 4])
  union() {
    translate([WIDTH, 0, 0])
    mirror([1, 0, 0])
      children();
    children();
  }
}

module bearing(id=6, od=12, h=4, flange_d = 13.5, flange_h = 0.8) {
  wiggle = 0.1;
  linear_extrude(flange_h)
    circle(r = (flange_d + wiggle) / 2);
  linear_extrude(h)
    circle(r = (od + wiggle) / 2);
}

module xrail_groove(length, screw_clearance = 2) {
  wiggle = 0.1;
  d_major = 0.325 * inch + wiggle;
  h_minor = (0.540 * inch) - d_major + screw_clearance + wiggle;
  w_minor = 0.245 * inch + wiggle;
  translate([-d_major / 2, 0, 0])
  union() {
    cube([d_major, d_major, length]);
    translate([(d_major - w_minor) / 2, d_major, 0])
      cube([w_minor, h_minor, length]);
  }
  translate([0, d_major / 2, 0])
    bearing();
  translate([0, d_major / 2, length + FLANGE_THICKNESS])
  rotate([0, 180, 0])
    bearing();
}

module fin(height, depth = FLANGE_DEPTH / 2, thickness=WALL_THICKNESS) {
  translate([0, -depth, 0])
  rotate([0, 270, 0])
  linear_extrude(thickness)
  scale([1, depth / height, 1])
  difference() {
    square(height);
    circle(r=height);
  }
}
module double_fin(height) {
  fin(height);
  mirror([0, 1, 0])
    fin(height);
}

module 770_mount(height = inch / 4, dia = 0.135 * inch) {
  dist = 0.770 * inch;
  translate([0, 0, -height / 2])
  linear_extrude(height)
  for(a = [45:90:315]) {
    rotate(a)
    translate([0, dist / 2, 0])
      circle(r = dia / 2);
  }
}

module flange(width, depth = FLANGE_DEPTH, withMotor = false, thickness=FLANGE_THICKNESS) {
  difference() {
    linear_extrude(thickness)
    rounding(10)
    square([width, depth]);
    if (withMotor) {
      translate([width / 2, depth / 2, 0.01])
        770_mount();
    }
  }
}

module wall(width, height, thickness = WALL_THICKNESS, withScrew = false) {
  screw_pocket_width = 0.75 * inch;
  screw_pocket_depth = 0.85 * inch;
  screw_pocket_height = height;
  pocket_offset = -screw_pocket_depth / 2 + thickness / 2;

  difference() {
    union() {
      cube([width, thickness, height]);
      translate([width / 4, 0, 0])
        double_fin(height);
      translate([3 * width / 4, 0, 0])
        double_fin(height);
      translate([-FLANGE_DEPTH / 2, -FLANGE_DEPTH / 2, height])
        flange(width + FLANGE_DEPTH, withMotor=withScrew);
      if (withScrew) {
        *translate([(width - screw_pocket_width) / 2, pocket_offset, (height - screw_pocket_height) / 2])
          linear_extrude(screw_pocket_height)
          rounding(r=2)
            square([screw_pocket_width, screw_pocket_depth]);
      }
    }
    if (withScrew) {
      place_slots() {
        translate([thickness, -0.01, 0])
          slot(width / 2 - 2 *thickness, depth=thickness + 0.02);
      }
      translate([width / 2, pocket_offset / 2, (height - screw_pocket_height) / 2 - 0.1])
        *xrail_groove(screw_pocket_height + 0.2);
    }
  }
}


for (i =[0:3]) {
  deg = i % 2 == 0 ? 90 : 0;
  mirror_y = i == 2 || i == 1 ? 1 : 0;
  translate([i == 0 ? WIDTH : 0, i == 1 ? HEIGHT : 0, 0])
  rotate(deg)
  mirror([0, mirror_y, 0])
    wall(WIDTH, HEIGHT, withScrew = i % 2);
}
