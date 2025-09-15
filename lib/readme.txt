-- add paging for every get started, do add function like "dot()"
-- color text -- color: Colors.blueGrey[900]
-- add error handling



9/11/25
- pet management
- create na table
- kulang pet image sa profile

9/13/25
- donation 

@immutable means once you create a donation object,
the field cannot be changed at all which means it is final
and makes it more safer and predictable

Future-proof (has toMap/fromMap for API use later).



// donation query

CREATE TABLE donations (
    id BIGSERIAL PRIMARY KEY,          -- auto increment id
    donor_name VARCHAR(255) NOT NULL,  -- donor name
    donor_phone VARCHAR(50) NOT NULL,  -- phone as string
    donation_date TIMESTAMP NOT NULL,  -- when donation was made
    type VARCHAR(10) NOT NULL,         -- "cash" or "inKind"

    -- cash fields
    payment_method VARCHAR(100),       -- e.g., Bank Transfer, Card
    amount DECIMAL(12,2),              -- store money safely

    -- in-kind fields
    item VARCHAR(255),
    quantity INT,
    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);


// This links a donation 
to any purpose (general, utilities, pets, campaigns).
// dire ma identify kung para asa ang donation

CREATE TABLE donation_allocations (
    id BIGSERIAL PRIMARY KEY,
    donation_id BIGINT NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
    utility_id BIGINT REFERENCES utilities(id),
    pet_id BIGINT REFERENCES pets(id),
    campaign_id BIGINT REFERENCES campaigns(id),
    allocated_amount DECIMAL(12,2),
    allocated_quantity INT
);

CREATE TABLE donation_allocations (
    id BIGSERIAL PRIMARY KEY,
    donation_id BIGINT NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
    utility_id BIGINT REFERENCES utilities(id),
    pet_id UUID REFERENCES pet_profiles(id),
    campaign_id BIGINT REFERENCES campaigns(id),
    allocated_amount DECIMAL(12,2),
    allocated_quantity INT
);



//campaign queryy

create table campaigns (
    id bigserial primary key,
    title text not null,
    description text,
    image_url text,
    goal numeric(12,2) not null check (goal > 0),
    raised numeric(12,2) not null default 0 check (raised >= 0),
    deadline date not null,
    status text not null check (status in ('active', 'ended')) default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- keep `updated_at` fresh on row update
create trigger update_campaigns_updated_at
before update on campaigns
for each row
execute function set_updated_at();

//for  set update
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;


// utilities

create table if not exists utilities (
    id bigserial primary key,
    type text not null,                -- Water, Electricity, etc.
    amount numeric(12,2) not null,     -- Goal amount
    due_date date not null,            -- Due date
    status text not null,              -- Paid, Due, Stocked

    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);




