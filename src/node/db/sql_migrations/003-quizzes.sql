CREATE SEQUENCE quiz_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE;

CREATE TABLE public.quizzes (
  id integer DEFAULT nextval('quiz_id_seq'::regclass) NOT NULL,
  class integer references classes(id),
  label text DEFAULT ''::text NOT NULL,
  model json,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER SEQUENCE quiz_id_seq OWNED BY quizzes.id;
ALTER TABLE ONLY quizzes ADD CONSTRAINT quizzes_pkey PRIMARY KEY (id);
CREATE UNIQUE INDEX index_quizzes_on_class_label on quizzes using btree (class, label);

CREATE TRIGGER quiz_update_timestamp
  BEFORE UPDATE ON quizzes
  FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

INSERT INTO migrations (filename, status) VALUES ('003-quizzes.sql', 'up');
