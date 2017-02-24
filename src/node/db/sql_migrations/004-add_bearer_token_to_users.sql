ALTER TABLE users ADD COLUMN bearer_token varchar(24);
ALTER TABLE users ADD COLUMN token_valid_until timestamptz DEFAULT (now() + interval '1 year');

INSERT INTO migrations (filename, status) VALUES ('004-add_bearer_token_to_user.sql', 'up');
