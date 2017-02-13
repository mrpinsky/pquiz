CREATE SEQUENCE user_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE;

CREATE TABLE public.users (
  id integer DEFAULT nextval('user_id_seq'::regclass) NOT NULL,
  name text NOT NULL,
  email text DEFAULT ''::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER SEQUENCE user_id_seq OWNED BY users.id;
ALTER TABLE ONLY users ADD CONSTRAINT users_pkey PRIMARY KEY (id);
CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);

CREATE TRIGGER user_update_timestamp
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

INSERT INTO migrations (filename, status) VALUES ('001-users.sql', 'up');
