CREATE SEQUENCE class_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE;

CREATE TABLE public.classes (
  id integer DEFAULT nextVal('class_id_seq'::regclass) NOT NULL,
  name text DEFAULT ''::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER SEQUENCE class_id_seq OWNED BY classes.id;
ALTER TABLE ONLY classes ADD CONSTRAINT classes_pkey PRIMARY KEY (id);

CREATE TRIGGER class_update_timestamp
  BEFORE UPDATE ON classes
  FOR EACH ROW EXECUTE PROCEDURE update_timestamp();

CREATE TABLE public.teacher_classes (
  teacher_id integer NOT NULL references users(id),
  class_id integer NOT NULL references classes(id),
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

INSERT INTO migrations (filename, status) VALUES ('002-classes.sql', 'up');
