CREATE SEQUENCE migration_id_seq
  START WITH 1
  INCREMENT BY 1
  MINVALUE 0
  NO MAXVALUE;

CREATE TABLE migrations (
  id integer DEFAULT nextval('migration_id_seq'::regclass) NOT NULL PRIMARY KEY,
  filename character varying(255),
  status character varying(255),
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER SEQUENCE migration_id_seq OWNED BY migrations.id;

GRANT select, insert ON TABLE migrations TO nodeapp;

-- -- MODELS
--
-- -- CREATE SEQUENCE student_id_seq
-- --   START WITH 1
-- --   INCREMENT BY 1
-- --   NO MINVALUE
-- --   NO MAXVALUE;
-- --
-- -- CREATE TABLE students (
-- --   id integer DEFAULT nextval('student_id_seq'::regclass) NOT NULL PRIMARY KEY,
-- --   name text DEFAULT ''::text NOT NULL,
-- --   class_id integer NOT NULL references classes(id),
-- --   group_id integer references groups(uuid),
-- --   created_at timestamp with time zone DEFAULT now() NOT NULL,
-- --   updated_at timestamp with time zone DEFAULT now() NOT NULL
-- -- );
--
-- -- HASMANY RELATIONSHIPS
--
-- -- CREATE TABLE student_classes (
-- --   student_id integer NOT NULL references students(id),
-- --   class_id integer NOT NULL references class(id),
-- --   created_at timestamp with time zone DEFAULT now() NOT NULL,
-- --   updated_at timestamp with time zone DEFAULT now() NOT NULL
-- -- );
--
-- CREATE TABLE quiz_classes (
--   quiz_id integer NOT NULL references quizzes(id),
--   class_id integer NOT NULL references classes(id),
--   created_at timestamp with time zone DEFAULT now() NOT NULL,
--   updated_at timestamp with time zone DEFAULT now() NOT NULL
-- );
