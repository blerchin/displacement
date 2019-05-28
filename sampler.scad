use <scad-utils/morphology.scad>

inch = 25.4;
WIDTH = 6 * inch;
DEPTH = 6 * inch;
HEIGHT = 6 * inch;
WALL_THICKNESS = 1/8 * inch;
BLADE_THICKNESS = 2;
FLANGE_DEPTH = 1 * inch;
FLANGE_THICKNESS = inch / 8;
SLOT_Z = 2 * inch;
ROLLER_DIA = 3;

SCREW_OD = 6;
NUT_OD = inch / 2;


$fn = 64;

module elbow(d, thickness = BLADE_THICKNESS, depth=WALL_THICKNESS ) {
  translate([d + thickness, 0, 2 * d])
  rotate([90, 180, 180])
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

module slot(length, height = BLADE_THICKNESS, depth = WALL_THICKNESS, retract = HEIGHT/2) {
  od = depth + height;
  elbow_dia = 5 * height;
  elbow_size = elbow_dia + height - 0.01;
  translate([elbow_size, 0, 0])
    cube([length - elbow_dia, depth, height]);
  translate([0, 0, elbow_dia + height])
    cube([height, depth, retract - elbow_size]);
  translate([0, 0, -elbow_dia+height])
    elbow(elbow_dia, depth=depth, thickness=height);
}

module place_slots() {
  translate([-WALL_THICKNESS/2, 0, SLOT_Z])
  union() {
    translate([WIDTH, 0, 0])
    mirror([1, 0, 0])
      children();
    translate([WALL_THICKNESS, 0, 0])
      children();
  }
}

module bevel_extrude(height, delta) {
  hull() {
    translate([0, 0, height])
    linear_extrude(0.01)
    offset(delta=delta)
      children();
    linear_extrude(0.01)
      children();
  }
}

module bore_top(dia=(3/16) * inch, length=inch, angle=35) {
  guide_thickness = dia + 2 * WALL_THICKNESS;
  translate([0, cos(angle)*length/2 - dia/2, 0])
  rotate([angle, 0, 0])
    linear_extrude(length + dia)
      circle(r = dia / 2);
}

module bore_bottom(dia=(1/8) * inch, width=(3/4) * inch, thickness = WALL_THICKNESS, angle=25) {
  translate([-width/2, 0, 0])
  union() {
    translate([(7/8) * width, 2*thickness, 0])
    rotate([90, 0, -angle])
    linear_extrude(4 * thickness)
      circle(r = dia / 2);
    translate([width/8, 2*thickness, 0])
    rotate([90, 0, angle])
    linear_extrude(4 * thickness)
      circle(r = dia / 2);
  }
}

module bore_roller(dia=ROLLER_DIA) {
  translate([0, -0.01, 0])
  rotate([-90, 0, 0])
    cylinder(r=dia/2, h=WIDTH + 0.02);
}


module fin(height, depth, thickness) {
  translate([thickness/2, -depth, 0])
  rotate([0, 270, 0])
  linear_extrude(thickness)
  scale([1, depth / height, 1])
  difference() {
    square(height);
    circle(r=height);
  }
}
module double_fin(height, depth=FLANGE_DEPTH/2, thickness=WALL_THICKNESS/2) {
  fin(height, depth, thickness);
  mirror([0, 1, 0])
    fin(height, depth, thickness);
}

module place_fins(width, height, num_fins=6, padding=WALL_THICKNESS/2) {
  dist = (width - 2 * padding) / (num_fins - 1);
  for(x = [padding:dist:width-padding]) {
    translate([x, 0, 0])
    double_fin(height);
  }
  translate([width / 2 , 0, 0]) {
    double_fin(height, thickness = dist);
  }
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

module stake_profile(width, height, depth) {
  polygon(points= [
    [0, height],
    [depth/2, 0],
    [depth, height]
  ]);
}

module stake(width, height=SLOT_Z, depth=WALL_THICKNESS) {
  difference() {
    translate([0, 0, 0])
    rotate([90, 0, 90])
    linear_extrude(width)
      stake_profile(width, height, depth);
    translate([depth/2, depth, height+0.01])
    rotate([90, 180, 0])
    linear_extrude(depth)
      stake_profile(width, height, depth);
    translate([width + depth/2, depth, height+0.01])
    rotate([90, 180, 0])
    linear_extrude(depth)
      stake_profile(width, height, depth);
  }
}

module wall(width, height, thickness = WALL_THICKNESS, withMotor = false) {
  screw_pocket_width = 0.75 * inch;
  screw_pocket_depth = 0.85 * inch;
  screw_pocket_height = height;
  pocket_offset = -screw_pocket_depth / 2 + thickness / 2;

  difference() {
    union() {
      translate([0, 0, SLOT_Z])
        cube([width, thickness, height]);
      translate([0, 0, -0.01])
      stake(width, height=SLOT_Z);
      translate([0, 0, SLOT_Z])
      place_fins(width, height) {
        double_fin();
      }
      translate([-FLANGE_DEPTH / 2, -FLANGE_DEPTH / 2, height + SLOT_Z])
        flange(width + FLANGE_DEPTH, withMotor=withMotor);
    }
    if (withMotor) {
      translate([width / 2, 0, SLOT_Z])
        bore_bottom();
      translate([WALL_THICKNESS, 0, SLOT_Z])
          bore_roller();
      translate([WIDTH - WALL_THICKNESS, 0, SLOT_Z])
          bore_roller();
    } else {
      translate([0, ROLLER_DIA, SLOT_Z])
      rotate([0, 0, -90])
      scale([1, 1, 2])
        bore_roller(dia=ROLLER_DIA);

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
