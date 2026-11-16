create table countries (
    code varchar(2) primary key,
    name_en varchar(80) not null,
    name_ar varchar(80) not null,
    currency_code varchar(3) not null,
    currency_symbol_en varchar(10) not null,
    currency_symbol_ar varchar(10) not null,
    tagline_en varchar(160) not null,
    tagline_ar varchar(160) not null,
    active boolean not null default true
);

create table governorates (
    id bigint generated always as identity primary key,
    country_code varchar(2) not null references countries (code),
    code varchar(40) not null,
    name_en varchar(80) not null,
    name_ar varchar(80) not null,
    sort_order integer not null default 0,
    constraint uk_governorates_country_code unique (country_code, code)
);

create index idx_governorates_country on governorates (country_code, sort_order);

create table areas (
    id bigint generated always as identity primary key,
    governorate_id bigint not null references governorates (id) on delete cascade,
    code varchar(60) not null,
    name_en varchar(80) not null,
    name_ar varchar(80) not null,
    sort_order integer not null default 0,
    constraint uk_areas_governorate_code unique (governorate_id, code)
);

create index idx_areas_governorate on areas (governorate_id, sort_order);

insert into countries (code, name_en, name_ar, currency_code, currency_symbol_en, currency_symbol_ar, tagline_en, tagline_ar) values
    ('KW', 'Kuwait', 'الكويت', 'KWD', 'KD', 'د.ك',
     'Find your next home in Kuwait', 'اعثر على منزلك القادم في الكويت'),
    ('EG', 'Egypt', 'مصر', 'EGP', 'EGP', 'ج.م',
     'Find your next home in Egypt', 'اعثر على منزلك القادم في مصر');

insert into governorates (country_code, code, name_en, name_ar, sort_order) values
    ('KW', 'CAPITAL', 'Capital', 'العاصمة', 10),
    ('KW', 'HAWALLI', 'Hawalli', 'حولي', 20),
    ('KW', 'FARWANIYA', 'Farwaniya', 'الفروانية', 30),
    ('KW', 'MUBARAK_AL_KABEER', 'Mubarak Al-Kabeer', 'مبارك الكبير', 40),
    ('KW', 'AHMADI', 'Ahmadi', 'الأحمدي', 50),
    ('KW', 'JAHRA', 'Jahra', 'الجهراء', 60),
    ('EG', 'CAIRO', 'Cairo', 'القاهرة', 10),
    ('EG', 'GIZA', 'Giza', 'الجيزة', 20),
    ('EG', 'ALEXANDRIA', 'Alexandria', 'الإسكندرية', 30),
    ('EG', 'QALYUBIA', 'Qalyubia', 'القليوبية', 40),
    ('EG', 'SHARKIA', 'Sharqia', 'الشرقية', 50),
    ('EG', 'DAKAHLIA', 'Dakahlia', 'الدقهلية', 60),
    ('EG', 'BEHEIRA', 'Beheira', 'البحيرة', 70),
    ('EG', 'GHARBIA', 'Gharbia', 'الغربية', 80),
    ('EG', 'MENOUFIA', 'Menoufia', 'المنوفية', 90),
    ('EG', 'KAFR_EL_SHEIKH', 'Kafr El-Sheikh', 'كفر الشيخ', 100),
    ('EG', 'DAMIETTA', 'Damietta', 'دمياط', 110),
    ('EG', 'PORT_SAID', 'Port Said', 'بورسعيد', 120),
    ('EG', 'ISMAILIA', 'Ismailia', 'الإسماعيلية', 130),
    ('EG', 'SUEZ', 'Suez', 'السويس', 140),
    ('EG', 'NORTH_SINAI', 'North Sinai', 'شمال سيناء', 150),
    ('EG', 'SOUTH_SINAI', 'South Sinai', 'جنوب سيناء', 160),
    ('EG', 'FAYOUM', 'Fayoum', 'الفيوم', 170),
    ('EG', 'BENI_SUEF', 'Beni Suef', 'بني سويف', 180),
    ('EG', 'MINYA', 'Minya', 'المنيا', 190),
    ('EG', 'ASSIUT', 'Assiut', 'أسيوط', 200),
    ('EG', 'SOHAG', 'Sohag', 'سوهاج', 210),
    ('EG', 'QENA', 'Qena', 'قنا', 220),
    ('EG', 'LUXOR', 'Luxor', 'الأقصر', 230),
    ('EG', 'ASWAN', 'Aswan', 'أسوان', 240),
    ('EG', 'RED_SEA', 'Red Sea', 'البحر الأحمر', 250),
    ('EG', 'NEW_VALLEY', 'New Valley', 'الوادي الجديد', 260),
    ('EG', 'MATROUH', 'Matrouh', 'مطروح', 270);

insert into areas (governorate_id, code, name_en, name_ar, sort_order)
select g.id, v.code, v.name_en, v.name_ar, v.sort_order
from (values
    ('KW', 'CAPITAL', 'KUWAIT_CITY', 'Kuwait City', 'مدينة الكويت', 10),
    ('KW', 'CAPITAL', 'SHARQ', 'Sharq', 'الشرق', 20),
    ('KW', 'CAPITAL', 'DASMA', 'Dasma', 'الدسمة', 30),
    ('KW', 'CAPITAL', 'QADSIYA', 'Qadsiya', 'القادسية', 40),
    ('KW', 'CAPITAL', 'SHAMIYA', 'Shamiya', 'الشامية', 50),
    ('KW', 'CAPITAL', 'KAIFAN', 'Kaifan', 'كيفان', 60),
    ('KW', 'HAWALLI', 'SALMIYA', 'Salmiya', 'السالمية', 10),
    ('KW', 'HAWALLI', 'JABRIYA', 'Jabriya', 'الجابرية', 20),
    ('KW', 'HAWALLI', 'SALWA', 'Salwa', 'سلوى', 30),
    ('KW', 'HAWALLI', 'MISHREF', 'Mishref', 'مشرف', 40),
    ('KW', 'HAWALLI', 'SHAAB', 'Shaab', 'الشعب', 50),
    ('KW', 'HAWALLI', 'RUMAITHIYA', 'Rumaithiya', 'الرميثية', 60),
    ('KW', 'HAWALLI', 'BAYAN', 'Bayan', 'بيان', 70),
    ('KW', 'HAWALLI', 'HAWALLY', 'Hawally', 'حولي', 80),
    ('KW', 'FARWANIYA', 'FARWANIYA', 'Farwaniya', 'الفروانية', 10),
    ('KW', 'FARWANIYA', 'KHAITAN', 'Khaitan', 'خيطان', 20),
    ('KW', 'FARWANIYA', 'RIGGAE', 'Riggae', 'الرقعي', 30),
    ('KW', 'FARWANIYA', 'ARDIYA', 'Ardiya', 'العارضية', 40),
    ('KW', 'FARWANIYA', 'JLEEB_AL_SHUYOUKH', 'Jleeb Al-Shuyoukh', 'جليب الشيوخ', 50),
    ('KW', 'MUBARAK_AL_KABEER', 'SABAH_AL_SALEM', 'Sabah Al-Salem', 'صباح السالم', 10),
    ('KW', 'MUBARAK_AL_KABEER', 'QURAIN', 'Qurain', 'القرين', 20),
    ('KW', 'MUBARAK_AL_KABEER', 'ADAN', 'Adan', 'عدن', 30),
    ('KW', 'MUBARAK_AL_KABEER', 'FNAITEES', 'Fnaitees', 'الفنيطيس', 40),
    ('KW', 'AHMADI', 'FINTAS', 'Fintas', 'الفنطاس', 10),
    ('KW', 'AHMADI', 'FAHAHEEL', 'Fahaheel', 'الفحيحيل', 20),
    ('KW', 'AHMADI', 'MANGAF', 'Mangaf', 'المنقف', 30),
    ('KW', 'AHMADI', 'ABU_HALIFA', 'Abu Halifa', 'أبو حليفة', 40),
    ('KW', 'AHMADI', 'MAHBOULA', 'Mahboula', 'المهبولة', 50),
    ('KW', 'JAHRA', 'JAHRA', 'Jahra', 'الجهراء', 10),
    ('KW', 'JAHRA', 'SAAD_AL_ABDULLAH', 'Saad Al-Abdullah', 'سعد العبدالله', 20),
    ('KW', 'JAHRA', 'TAIMA', 'Taima', 'تيماء', 30),
    ('KW', 'JAHRA', 'SULAIBIYA', 'Sulaibiya', 'الصليبية', 40),
    ('EG', 'CAIRO', 'NEW_CAIRO', 'New Cairo', 'القاهرة الجديدة', 10),
    ('EG', 'CAIRO', 'NASR_CITY', 'Nasr City', 'مدينة نصر', 20),
    ('EG', 'CAIRO', 'HELIOPOLIS', 'Heliopolis', 'مصر الجديدة', 30),
    ('EG', 'CAIRO', 'MAADI', 'Maadi', 'المعادي', 40),
    ('EG', 'CAIRO', 'ZAMALEK', 'Zamalek', 'الزمالك', 50),
    ('EG', 'CAIRO', 'DOWNTOWN', 'Downtown', 'وسط البلد', 60),
    ('EG', 'CAIRO', 'SHOROUK', 'Shorouk', 'الشروق', 70),
    ('EG', 'CAIRO', 'REHAB', 'Rehab', 'الرحاب', 80),
    ('EG', 'GIZA', 'SHEIKH_ZAYED', 'Sheikh Zayed', 'الشيخ زايد', 10),
    ('EG', 'GIZA', 'OCTOBER_6', '6th of October', '6 أكتوبر', 20),
    ('EG', 'GIZA', 'MOHANDESSIN', 'Mohandessin', 'المهندسين', 30),
    ('EG', 'GIZA', 'DOKKI', 'Dokki', 'الدقي', 40),
    ('EG', 'GIZA', 'HARAM', 'Haram', 'الهرم', 50),
    ('EG', 'GIZA', 'FAISAL', 'Faisal', 'فيصل', 60),
    ('EG', 'ALEXANDRIA', 'SMOUHA', 'Smouha', 'سموحة', 10),
    ('EG', 'ALEXANDRIA', 'SIDI_GABER', 'Sidi Gaber', 'سيدي جابر', 20),
    ('EG', 'ALEXANDRIA', 'MIAMI', 'Miami', 'ميامي', 30),
    ('EG', 'ALEXANDRIA', 'MONTAZAH', 'Montazah', 'المنتزه', 40),
    ('EG', 'ALEXANDRIA', 'AGAMI', 'Agami', 'العجمي', 50),
    ('EG', 'RED_SEA', 'HURGHADA', 'Hurghada', 'الغردقة', 10),
    ('EG', 'RED_SEA', 'EL_GOUNA', 'El Gouna', 'الجونة', 20),
    ('EG', 'RED_SEA', 'SAFAGA', 'Safaga', 'سفاجا', 30),
    ('EG', 'RED_SEA', 'MARSA_ALAM', 'Marsa Alam', 'مرسى علم', 40),
    ('EG', 'MATROUH', 'NEW_ALAMEIN', 'New Alamein', 'العلمين الجديدة', 10),
    ('EG', 'MATROUH', 'MARSA_MATROUH', 'Marsa Matrouh', 'مرسى مطروح', 20),
    ('EG', 'SOUTH_SINAI', 'SHARM_EL_SHEIKH', 'Sharm El-Sheikh', 'شرم الشيخ', 10),
    ('EG', 'SOUTH_SINAI', 'DAHAB', 'Dahab', 'دهب', 20),
    ('EG', 'PORT_SAID', 'PORT_FOUAD', 'Port Fouad', 'بورفؤاد', 10),
    ('EG', 'LUXOR', 'KARNAK', 'Karnak', 'الكرنك', 10),
    ('EG', 'LUXOR', 'NEW_LUXOR', 'New Luxor', 'الأقصر الجديدة', 20),
    ('EG', 'ASWAN', 'NILE_CORNICHE', 'Nile Corniche', 'كورنيش النيل', 10)
) as v(country_code, governorate_code, code, name_en, name_ar, sort_order)
join governorates g on g.country_code = v.country_code and g.code = v.governorate_code;

alter table properties add column governorate_id bigint;
alter table properties add column area_id bigint;

update properties p
set governorate_id = g.id
from governorates g
where g.country_code = 'KW' and g.code = p.governorate;

update properties p
set area_id = a.id
from areas a
join governorates g on g.id = a.governorate_id
where g.id = p.governorate_id and lower(a.name_en) = lower(p.area_name);

alter table properties alter column governorate_id set not null;
alter table properties add constraint fk_properties_governorate
    foreign key (governorate_id) references governorates (id);
alter table properties add constraint fk_properties_area
    foreign key (area_id) references areas (id);

drop index if exists idx_properties_filters;
alter table properties drop column governorate;
alter table properties drop column area_name;

create index idx_properties_filters on properties (listing_type, property_type, governorate_id);
create index idx_properties_area on properties (area_id);
