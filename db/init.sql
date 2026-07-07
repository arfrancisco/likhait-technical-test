-- This used to also define `categories`/`expenses` tables and seed data, but
-- that schema had drifted from the real one (a `payer_name` column that no
-- longer exists, no `date` column at all). Since Rails migrations create
-- tables with `if_not_exists: true`, having both meant migrations would
-- silently skip creating the correct columns whenever this file ran first,
-- leaving `docker compose up` permanently on the wrong schema.
--
-- All schema/seed responsibility is now consolidated into the backend:
-- table structure lives in backend/db/migrate (see backend/db/schema.rb for
-- the current definitive state -- every column/index that mattered from the
-- old schema here, e.g. the created_at index, was ported over as an index
-- on `date` instead, since that's the column actually queried post-BUG-001)
-- and seed data lives in backend/db/seeds.rb. This file's only remaining
-- job is provisioning the test database, which the app's MySQL user isn't
-- otherwise granted access to.
CREATE DATABASE IF NOT EXISTS expense_system_test CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON expense_system_test.* TO 'expense_user'@'%';
FLUSH PRIVILEGES;
