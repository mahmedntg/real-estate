alter table countries add column sort_order integer not null default 0;

update countries set sort_order = 10 where code = 'KW';
update countries set sort_order = 20 where code = 'EG';
