use <scad-utils/morphology.scad>

inch = 25.4;
WIDTH = 6 * inch;
DEPTH = 6 * inch;
HEIGHT = 6 * inch;
WALL_THICKNESS = 1;
BLADE_THICKNESS = 2;
FLANGE_DEPTH = 1 * inch;
FLANGE_THICKNESS = inch / 8;
SLOT_Z = inch / 4;

SCREW_OD = 6;
NUT_OD = inch / 2;


$fn = 256;

module elbow(d, thickness = BLADE_THICKNESS, depth=WALL_THICKNESS ) {
  difference(){
    rotate_extrude(convexity = 10)
      translate([d, 0, 0])
      square([thickness, depth]);
    translate([0, 0, -0.01])
      cube([d + thickness, d + thickness, depth + 0.02]);
    translate([-d - thickness, -d - thickness, -0.01])
      cube([2 * (d + thickness), d + thickness, depth + 0.02]);
  }
}

module slot(length, height = BLADE_THICKNESS, depth = WALL_THICKNESS, retract = 13) {
  od = depth + height;
  difference() {
    union() {
      cube([length, depth, height]);
      cube([height, depth, retract]);
    }
    translate([-0.01, -0.01, -0.1])
      cube([od + depth, depth - 0.02, od + depth]);
  }
  translate([od + depth, 0, 2 * height])
  rotate([90, 180, 180])
    elbow(height, depth=depth + 0.02);
}

module place_slots() {
  translate([0, 0, SLOT_Z])
  union() {
    translate([WIDTH, 0, 0])
    mirror([1, 0, 0])
      children();
    children();
  }
}

module bore(height, dia=WALL_THICKNESS) {
  linear_extrude(height)
    circle(r = dia / 2);
}

module bore_weave(height, dia=WALL_THICKNESS + 0.5, offset=WALL_THICKNESS / 2, seg_len = 30) {
  num_segments = floor(height / seg_len);
  last_seg = height - (seg_len * num_segments);
  for (i = [0:num_segments]) {
    off = i % 2 == 0 ? offset : -1 * offset;
    translate([0, off, i * seg_len])
      bore(seg_len, dia);
    //through hole
    if (i != 0) {
      translate([0, offset / 2, i * seg_len - 0.5])
        bore(1, dia = dia);
    }
  }
}

module bearing(id=6, od=12, h=4, flange_d = 13.5, flange_h = 0.8) {
  wiggle = 0.1;
  linear_extrude(flange_h)
    circle(r = (flange_d + wiggle) / 2);
  linear_extrude(h)
    circle(r = (od + wiggle) / 2);
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

module wall(width, height, thickness = WALL_THICKNESS, withMotor = false) {
  screw_pocket_width = 0.75 * inch;
  screw_pocket_depth = 0.85 * inch;
  screw_pocket_height = height;
  pocket_offset = -screw_pocket_depth / 2 + thickness / 2;

  difference() {
    union() {
      cube([width, thickness, height]);
      translate([width / 4, 0, SLOT_Z])
        double_fin(height - SLOT_Z);
      translate([3 * width / 4, 0, SLOT_Z])
        double_fin(height - SLOT_Z);
      translate([-FLANGE_DEPTH / 2, -FLANGE_DEPTH / 2, height])
        flange(width + FLANGE_DEPTH, withMotor=withMotor);
    }
    if (withMotor) {
      place_slots() {
        translate([thickness, -0.01, 0])
          slot(width / 2 - 2 *thickness, depth=thickness + 0.02);
      }
      translate([width / 2, thickness / 2, SLOT_Z])
        union(){
          bore_weave(height - SLOT_Z);
          translate([-2, 0, BLADE_THICKNESS / 2])
          rotate([0, 90, 0])
            bore(4);
        }

    }
  }
}


for (i =[0:3]) {
  deg = i % 2 == 0 ? 90 : 0;
  mirror_y = i == 2 || i == 1 ? 1 : 0;
  translate([i == 0 ? WIDTH : 0, i == 1 ? HEIGHT : 0, 0])
  rotate(deg)
  mirror([0, mirror_y, 0])
    wall(WIDTH, HEIGHT, withMotor = i % 2);
}
