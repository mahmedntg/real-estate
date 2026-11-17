alter table properties
    add column length_front_m numeric(6, 2),
    add column length_back_m numeric(6, 2),
    add column width_right_m numeric(6, 2),
    add column width_left_m numeric(6, 2);

update properties
set length_front_m = frontage_m,
    length_back_m = frontage_m,
    width_right_m = depth_m,
    width_left_m = depth_m
where frontage_m is not null or depth_m is not null;

alter table properties
    drop column frontage_m,
    drop column depth_m;
