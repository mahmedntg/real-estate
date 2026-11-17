-- The four plot sides are named after the direction they face, not after length
-- and width. The old front/back pair becomes south/north (front was drawn at the
-- bottom of the plot diagram, back at the top), and right/left becomes east/west.
alter table properties rename column length_front_m to south_side_m;
alter table properties rename column length_back_m to north_side_m;
alter table properties rename column width_right_m to east_side_m;
alter table properties rename column width_left_m to west_side_m;
