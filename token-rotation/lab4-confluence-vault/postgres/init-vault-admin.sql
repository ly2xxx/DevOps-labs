-- Create Vault admin user (used by Vault to create dynamic users)
CREATE USER vault_admin WITH PASSWORD 'vault_password' CREATEROLE;
GRANT ALL PRIVILEGES ON DATABASE confluence TO vault_admin;

-- Verify
\du vault_admin
