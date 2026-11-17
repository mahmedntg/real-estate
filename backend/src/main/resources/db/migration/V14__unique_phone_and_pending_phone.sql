update users
set phone = regexp_replace(phone, '[^0-9+]', '', 'g'),
    whatsapp = regexp_replace(whatsapp, '[^0-9+]', '', 'g')
where phone is not null;

create unique index ux_users_phone on users (phone) where phone is not null;

alter table users
    add column pending_phone varchar(30),
    add column pending_phone_code_hash varchar(100),
    add column pending_phone_expires_at timestamptz;
