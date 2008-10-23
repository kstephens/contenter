--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: mal_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_applications (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mal_brands; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_brands (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mal_content_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_content_types (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mal_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_contents (
    id integer NOT NULL,
    key character varying(255),
    mal_content_type_id integer,
    mal_language_id integer,
    mal_country_id integer,
    mal_brand_id integer,
    mal_application_id integer,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mal_countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_countries (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mal_languages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mal_languages (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: mal_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_applications_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_applications_id_seq OWNED BY mal_applications.id;


--
-- Name: mal_brands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_brands_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_brands_id_seq OWNED BY mal_brands.id;


--
-- Name: mal_content_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_content_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_content_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_content_types_id_seq OWNED BY mal_content_types.id;


--
-- Name: mal_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_contents_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_contents_id_seq OWNED BY mal_contents.id;


--
-- Name: mal_countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_countries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_countries_id_seq OWNED BY mal_countries.id;


--
-- Name: mal_languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mal_languages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mal_languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mal_languages_id_seq OWNED BY mal_languages.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_applications ALTER COLUMN id SET DEFAULT nextval('mal_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_brands ALTER COLUMN id SET DEFAULT nextval('mal_brands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_content_types ALTER COLUMN id SET DEFAULT nextval('mal_content_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_contents ALTER COLUMN id SET DEFAULT nextval('mal_contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_countries ALTER COLUMN id SET DEFAULT nextval('mal_countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mal_languages ALTER COLUMN id SET DEFAULT nextval('mal_languages_id_seq'::regclass);


--
-- Name: mal_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_applications
    ADD CONSTRAINT mal_applications_pkey PRIMARY KEY (id);


--
-- Name: mal_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_brands
    ADD CONSTRAINT mal_brands_pkey PRIMARY KEY (id);


--
-- Name: mal_content_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_content_types
    ADD CONSTRAINT mal_content_types_pkey PRIMARY KEY (id);


--
-- Name: mal_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_contents
    ADD CONSTRAINT mal_contents_pkey PRIMARY KEY (id);


--
-- Name: mal_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_countries
    ADD CONSTRAINT mal_countries_pkey PRIMARY KEY (id);


--
-- Name: mal_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mal_languages
    ADD CONSTRAINT mal_languages_pkey PRIMARY KEY (id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20081017064213');

INSERT INTO schema_migrations (version) VALUES ('20081017064227');

INSERT INTO schema_migrations (version) VALUES ('20081017064710');

INSERT INTO schema_migrations (version) VALUES ('20081017064720');

INSERT INTO schema_migrations (version) VALUES ('20081017064734');

INSERT INTO schema_migrations (version) VALUES ('20081017064756');