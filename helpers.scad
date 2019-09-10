inch = 25.4;

module place_mount_screws(dist, n = 4) {
  i = 360/n;
  for(a = [0:i:360]) {
    rotate(a)
    translate([0, dist / 2, 0])
      children();
  }
}

module 770_mount(height = inch / 4, dia = 0.135 * inch) {
  dist = 0.770 * inch;
  translate([0, 0, -height])
  linear_extrude(height)
  rotate([0, 0, 45])
  place_mount_screws(dist) {
      circle(r = dia / 2);
  }
}
