alter table users
    add column email_verified boolean not null default true,
    add column verification_code_hash varchar(100),
    add column verification_expires_at timestamptz;
