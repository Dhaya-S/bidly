$env:PGPASSWORD = "postgres"
psql -h localhost -U postgres -d bidlydb_dev -c "ALTER TABLE reviews ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();"
psql -h localhost -U postgres -d bidlydb_dev -c "\d reviews"
