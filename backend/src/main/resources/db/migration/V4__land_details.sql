alter table properties
    add column land_kind varchar(20),
    add column area_qirats numeric(10, 2),
    add column frontage_m numeric(6, 2),
    add column depth_m numeric(6, 2),
    add column street_width_m numeric(5, 2),
    add column building_permit boolean,
    add column negotiable boolean not null default false;
