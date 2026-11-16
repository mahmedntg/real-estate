create table users (
    id uuid primary key,
    full_name varchar(120) not null,
    email varchar(160) not null unique,
    phone varchar(30),
    password_hash varchar(100) not null,
    role varchar(20) not null,
    created_at timestamptz not null
);

create table properties (
    id uuid primary key,
    owner_id uuid not null references users (id),
    title_en varchar(160) not null,
    title_ar varchar(160) not null,
    description_en varchar(2000) not null,
    description_ar varchar(2000) not null,
    property_type varchar(20) not null,
    listing_type varchar(20) not null,
    governorate varchar(30) not null,
    area_name varchar(120),
    price numeric(14, 3) not null,
    area_sqm numeric(10, 2),
    bedrooms integer,
    bathrooms integer,
    furnished boolean not null default false,
    latitude double precision,
    longitude double precision,
    created_at timestamptz not null,
    updated_at timestamptz not null
);

create index idx_properties_created_at on properties (created_at desc);
create index idx_properties_owner on properties (owner_id);
create index idx_properties_filters on properties (listing_type, property_type, governorate);
create index idx_properties_price on properties (price);

create table property_images (
    id uuid primary key,
    property_id uuid not null references properties (id) on delete cascade,
    url varchar(500) not null,
    sort_order integer not null default 0
);

create index idx_property_images_property on property_images (property_id, sort_order);

create table favorites (
    id uuid primary key,
    user_id uuid not null references users (id) on delete cascade,
    property_id uuid not null references properties (id) on delete cascade,
    created_at timestamptz not null,
    constraint uk_favorites_user_property unique (user_id, property_id)
);

create index idx_favorites_user on favorites (user_id, created_at desc);

create table conversations (
    id uuid primary key,
    property_id uuid not null references properties (id) on delete cascade,
    renter_id uuid not null references users (id),
    owner_id uuid not null references users (id),
    created_at timestamptz not null,
    last_message_at timestamptz not null,
    constraint uk_conversations_property_renter unique (property_id, renter_id)
);

create index idx_conversations_renter on conversations (renter_id, last_message_at desc);
create index idx_conversations_owner on conversations (owner_id, last_message_at desc);

create table messages (
    id uuid primary key,
    conversation_id uuid not null references conversations (id) on delete cascade,
    sender_id uuid not null references users (id),
    body varchar(2000) not null,
    is_read boolean not null default false,
    created_at timestamptz not null
);

create index idx_messages_conversation on messages (conversation_id, created_at desc);
create index idx_messages_unread on messages (conversation_id) where is_read = false;
