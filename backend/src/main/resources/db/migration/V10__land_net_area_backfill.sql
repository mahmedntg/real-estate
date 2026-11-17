update properties
set area_sqm = round(
        ((length_front_m + length_back_m) / 2) * ((width_right_m + width_left_m) / 2), 2)
where length_front_m is not null
  and length_back_m is not null
  and width_right_m is not null
  and width_left_m is not null;
