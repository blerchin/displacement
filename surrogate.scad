use <scad-utils/morphology.scad>

inch = 25.4;
WIDTH = 6 * inch;
DEPTH = 6 * inch;
HEIGHT = 4 * inch;
THICKNESS = 3;

FEATHER_WIDTH = 2.38 * inch;
FEATHER_DEPTH = 0.9 * inch;
FEATHER_HEIGHT = 1 * inch;
FEATHER_STANDOFF_DIA = 2.5;
FEATHER_STANDOFF_INSET = 0.1 * inch;

SOLAR_MOUNTING_BORE = 2.1;
SOLAR_MOUNTING_INSET = 8.4;
SOLAR_WIDTH = 113;
SOLAR_DEPTH = 89;
SOLAR_HEIGHT = 4.8;

DHT22_WIDTH = 15.1;
DHT22_DEPTH = 20;
DHT22_HEIGHT = 7.7;
DHT22_FLANGE_DEPTH = 5.1;
DHT22_FLANGE_HEIGHT = 2;
DHT22_MOUNTING_BORE = 3;
DHT22_MOUNTING_OUTSET = 1.6;
DHT22_CLEARANCE = DHT22_HEIGHT;

PHOTOCELL_DIA = 0.2 * inch;
PHOTOCELL_HEIGHT = 2;
PHOTOCELL_CHANNEL_DIA = 3;

ACCESS_WIDTH = SOLAR_WIDTH - 20;
ACCESS_DEPTH = SOLAR_DEPTH - 20;

$fn = 128;

module corner_holes(width, depth, inset, bore, height, number = 4) {
  in = inset + bore/2;
  w = width - in;
  d = depth - in;
  translate([width/2, depth/2, 0])
  for (i = [1:number + 1]) {
    da = (i%2 == 0) ? atan(w/d) : atan(d/w);
    a = i * (360/number) + da;
    dist = sqrt(pow(w/2, 2) + pow(d/2, 2));
    rotate([0, 0, a])
    translate([0, dist, 0])
      cylinder(d=bore, h=height);
  }
}

module photocell() {
  channel_depth = (DEPTH - ACCESS_DEPTH) / 4;
  channel_height = 20;
  channel_length = sqrt(pow(channel_depth, 2) + pow(channel_height, 2)) + 10;
  channel_angle = atan(channel_height / channel_depth);
  cylinder(d=PHOTOCELL_DIA, h=PHOTOCELL_HEIGHT);
  translate([0, channel_depth, - channel_height])
    rotate([channel_angle, 0, 0])
    translate([0, 0, -2])
    cylinder(d=PHOTOCELL_CHANNEL_DIA, h=channel_length + 2);
}


module dht22(withClearance = false) {
  cube([DHT22_WIDTH, DHT22_DEPTH, DHT22_HEIGHT]);
  translate([0, -DHT22_FLANGE_DEPTH+0.1, 0])
    cube([DHT22_WIDTH, DHT22_FLANGE_DEPTH, DHT22_FLANGE_HEIGHT]);
  translate([DHT22_WIDTH/2, -DHT22_MOUNTING_OUTSET, 0])
    cylinder(d=DHT22_MOUNTING_BORE, h=DHT22_HEIGHT + 0.02);
  if(withClearance) {
    translate([0, 0, -DHT22_CLEARANCE + 0.1])
      cube([DHT22_WIDTH, DHT22_DEPTH + 20.1, DHT22_CLEARANCE + 2]);
  }
}

module feather() {
  linear_extrude(FEATHER_HEIGHT)
    rounding(2)
    square([FEATHER_WIDTH, FEATHER_DEPTH]);
  translate([0, 0, -THICKNESS - 0.1])
    corner_holes(FEATHER_WIDTH, FEATHER_DEPTH, FEATHER_STANDOFF_INSET, FEATHER_STANDOFF_DIA, THICKNESS + 0.1);
}


module solar_panel() {
  linear_extrude(SOLAR_HEIGHT)
    rounding(5)
      square([SOLAR_WIDTH, SOLAR_DEPTH]);
  translate([0, 0, -THICKNESS])
    corner_holes(SOLAR_WIDTH, SOLAR_DEPTH, SOLAR_MOUNTING_INSET, SOLAR_MOUNTING_BORE, THICKNESS + 1);
}

module access_panel(thickness = THICKNESS + 0.1) {
  linear_extrude(thickness)
  rounding(5)
    square([ACCESS_WIDTH, ACCESS_DEPTH]);
}


difference() {
  cube([WIDTH, DEPTH, HEIGHT]);
  translate([(WIDTH - SOLAR_WIDTH)/2, (DEPTH - SOLAR_DEPTH)/2, HEIGHT + 0.01])
    solar_panel();
  translate([(WIDTH - ACCESS_WIDTH)/2, (DEPTH - ACCESS_DEPTH)/2, THICKNESS - 0.01])
    access_panel(HEIGHT);
  translate([(WIDTH - DHT22_WIDTH)/2, (DEPTH - ACCESS_DEPTH )/4 - DHT22_DEPTH/2, HEIGHT - DHT22_HEIGHT + 0.01])
    dht22(withClearance = true);
  translate([(WIDTH - DHT22_WIDTH) / 2 + 25, (DEPTH - ACCESS_DEPTH)/4, HEIGHT - PHOTOCELL_HEIGHT + 0.01])
    photocell();
  translate([(WIDTH-ACCESS_DEPTH)/2 + 12, (DEPTH - ACCESS_DEPTH)/2 + 5, THICKNESS+0.01])
    feather();
}
