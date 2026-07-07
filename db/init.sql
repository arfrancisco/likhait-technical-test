-- This used to also define `categories`/`expenses` tables and seed data, but
-- that schema had drifted from the real one (a `payer_name` column that no
-- longer exists, no `date` column at all). Since Rails migrations create
-- tables with `if_not_exists: true`, having both meant migrations would
-- silently skip creating the correct columns whenever this file ran first,
-- leaving `docker compose up` permanently on the wrong schema. Rails
-- migrations (backend/db/migrate) and db/seeds.rb are now the only source of
-- truth for schema and seed data; this file just provisions the test
-- database, which the app's MySQL user isn't otherwise granted access to.
CREATE DATABASE IF NOT EXISTS expense_system_test CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON expense_system_test.* TO 'expense_user'@'%';
FLUSH PRIVILEGES;
