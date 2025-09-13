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
