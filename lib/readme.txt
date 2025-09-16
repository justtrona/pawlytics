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

CREATE TABLE campaigns (
    id BIGSERIAL PRIMARY KEY,
    program VARCHAR(100) NOT NULL,           -- Rescue, Vaccination, Spay/Neuter, etc.
    category VARCHAR(50) NOT NULL,           -- Urgent, Medical, Shelter, Food
    fundraising_goal DECIMAL(12,2) NOT NULL, -- Target fundraising amount
    currency VARCHAR(10) NOT NULL DEFAULT 'PHP',
    deadline DATE NOT NULL,
    description TEXT,
    notify_at_75 BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
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

//for anon user or sample sa

CREATE POLICY "Allow insert for anon"
ON campaigns
FOR INSERT
TO anon
WITH CHECK (true);


// for more security, authenticated nani sya
-- allow any authenticated user to insert into campaigns
CREATE POLICY "Allow insert for authenticated users"
ON campaigns
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY "Allow anon insert on campaigns" ON campaigns;

CREATE POLICY "Allow authenticated insert on campaigns"
ON campaigns
FOR INSERT
TO authenticated
WITH CHECK (true);


// if gikan anon, delete ang policy 

DROP POLICY "Allow insert for anon" ON campaigns;

If you also want anon users to read campaigns:

CREATE POLICY "Allow anon select campaigns"
ON campaigns
FOR SELECT
TO anon
USING (true);


// katong mag log in new user then para makaadd new table

-- make sure RLS is enabled
alter table campaigns enable row level security;

-- allow anon (public, not logged in) to insert
create policy "Public can insert campaigns"
on campaigns
for insert
to anon
with check (true);

-- allow public to select campaigns
create policy "Public can view campaigns"
on campaigns
for select
to anon
using (true);



