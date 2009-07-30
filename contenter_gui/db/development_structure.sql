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
-- Name: applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE applications (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255),
    name character varying(255),
    description character varying(255),
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE applications_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE applications_id_seq OWNED BY applications.id;


--
-- Name: auth_changes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auth_changes (
    id integer NOT NULL,
    user_id character varying(255),
    changed_at time without time zone NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: auth_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auth_changes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: auth_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auth_changes_id_seq OWNED BY auth_changes.id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brands (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: brands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brands_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brands_id_seq OWNED BY brands.id;


--
-- Name: capabilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE capabilities (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: capabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE capabilities_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: capabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE capabilities_id_seq OWNED BY capabilities.id;


--
-- Name: content_key_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_key_versions (
    id integer NOT NULL,
    content_key_id integer,
    version integer,
    uuid character varying(255) DEFAULT NULL::character varying,
    code character varying(255) DEFAULT NULL::character varying,
    name character varying(255) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    data text,
    content_type_id integer,
    creator_user_id integer,
    updater_user_id integer,
    updated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: content_key_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_key_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_key_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_key_versions_id_seq OWNED BY content_key_versions.id;


--
-- Name: content_keys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_keys (
    id integer NOT NULL,
    version integer NOT NULL,
    uuid character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    data text NOT NULL,
    content_type_id integer NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: content_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_keys_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_keys_id_seq OWNED BY content_keys.id;


--
-- Name: content_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_types (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    key_regexp character varying(255) NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: content_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_types_id_seq OWNED BY content_types.id;


--
-- Name: content_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_versions (
    id integer NOT NULL,
    content_id integer,
    version integer,
    uuid character varying(255) DEFAULT NULL::character varying,
    content_key_id integer,
    language_id integer,
    country_id integer,
    brand_id integer,
    application_id integer,
    mime_type_id integer,
    md5sum character varying(255) DEFAULT NULL::character varying,
    data bytea,
    creator_user_id integer,
    updater_user_id integer,
    updated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: content_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_versions_id_seq OWNED BY content_versions.id;


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents (
    id integer NOT NULL,
    uuid character varying(255) NOT NULL,
    content_key_id integer NOT NULL,
    language_id integer NOT NULL,
    country_id integer NOT NULL,
    brand_id integer NOT NULL,
    application_id integer NOT NULL,
    mime_type_id integer NOT NULL,
    md5sum character varying(255) NOT NULL,
    data bytea NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    version integer
);


--
-- Name: contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_id_seq OWNED BY contents.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE languages (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE languages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE languages_id_seq OWNED BY languages.id;


--
-- Name: mime_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mime_types (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mime_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mime_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: mime_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mime_types_id_seq OWNED BY mime_types.id;


--
-- Name: role_capabilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE role_capabilities (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    role_id integer NOT NULL,
    capability_id integer NOT NULL,
    allow boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: role_capabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE role_capabilities_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: role_capabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE role_capabilities_id_seq OWNED BY role_capabilities.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles_users (
    role_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(40) NOT NULL,
    name character varying(100) DEFAULT ''::character varying,
    email character varying(100) NOT NULL,
    crypted_password character varying(40) NOT NULL,
    salt character varying(40) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remember_token character varying(40),
    remember_token_expires_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: version_list_content_keys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE version_list_content_keys (
    id integer NOT NULL,
    version_list_id integer NOT NULL,
    content_key_version_id integer NOT NULL
);


--
-- Name: version_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE version_lists (
    id integer NOT NULL,
    lock_version integer NOT NULL,
    comment character varying(255) NOT NULL,
    point_in_time timestamp without time zone,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: version_list_content_key_version_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW version_list_content_key_version_view AS
    SELECT vl.id AS version_list_id, ckv.id AS content_key_version_id FROM ((version_lists vl LEFT JOIN version_list_content_keys vlck ON ((vlck.version_list_id = vl.id))) JOIN content_key_versions ckv ON (((ckv.id = vlck.content_key_version_id) OR (ckv.id IN (SELECT max(content_key_versions.id) AS max FROM content_key_versions WHERE (ckv.created_at <= vl.point_in_time) GROUP BY content_key_versions.content_key_id)))));


--
-- Name: VIEW version_list_content_key_version_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW version_list_content_key_version_view IS '
   A list of version_list_ids and the content_key_version_ids within them, 
   whether the content_key_versions are explicitly listed in the version_list_contents
   join table, or if they''re implicitly included in the version_list by virtue of
   being the most recent content_key_version at the time of the version_list.point_in_time

   Example: SELECT ckv.* FROM content_key_versions ckv
	    JOIN version_list_content_key_version_view vlcvv ON vlcvv.content_key_version_id = ckv.id
            WHERE version_list_id = 1

';


--
-- Name: version_list_content_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_list_content_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: version_list_content_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_list_content_keys_id_seq OWNED BY version_list_content_keys.id;


--
-- Name: version_list_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE version_list_contents (
    id integer NOT NULL,
    version_list_id integer NOT NULL,
    content_version_id integer NOT NULL
);


--
-- Name: version_list_content_version_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW version_list_content_version_view AS
    SELECT vl.id AS version_list_id, cv.id AS content_version_id FROM ((version_lists vl LEFT JOIN version_list_contents vlc ON ((vlc.version_list_id = vl.id))) JOIN content_versions cv ON (((cv.id = vlc.content_version_id) OR (cv.id IN (SELECT max(content_versions.id) AS max FROM content_versions WHERE (cv.created_at <= vl.point_in_time) GROUP BY content_versions.content_id)))));


--
-- Name: VIEW version_list_content_version_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW version_list_content_version_view IS '
   A list of version_list_ids and the content_version_ids within them, 
   whether the content_versions are explicitly listed in the version_list_contents
   join table, or if they''re implicitly included in the version_list by virtue of
   being the most recent content_version at the time of the version_list.point_in_time

   Example: SELECT cv.* FROM content_versions cv
	    JOIN version_list_content_version_view vlcvv ON vlcvv.content_version_id = cv.id
            WHERE  version_list_id = 1

';


--
-- Name: version_list_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_list_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: version_list_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_list_contents_id_seq OWNED BY version_list_contents.id;


--
-- Name: version_list_name_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE version_list_name_versions (
    id integer NOT NULL,
    version_list_name_id integer,
    version integer,
    name character varying(255) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    version_list_id integer,
    creator_user_id integer,
    updater_user_id integer,
    updated_at timestamp without time zone
);


--
-- Name: version_list_name_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_list_name_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: version_list_name_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_list_name_versions_id_seq OWNED BY version_list_name_versions.id;


--
-- Name: version_list_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE version_list_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    version_list_id integer,
    creator_user_id integer NOT NULL,
    updater_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    version integer
);


--
-- Name: version_list_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_list_names_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: version_list_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_list_names_id_seq OWNED BY version_list_names.id;


--
-- Name: version_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_lists_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: version_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_lists_id_seq OWNED BY version_lists.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE applications ALTER COLUMN id SET DEFAULT nextval('applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE auth_changes ALTER COLUMN id SET DEFAULT nextval('auth_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE brands ALTER COLUMN id SET DEFAULT nextval('brands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE capabilities ALTER COLUMN id SET DEFAULT nextval('capabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_key_versions ALTER COLUMN id SET DEFAULT nextval('content_key_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_keys ALTER COLUMN id SET DEFAULT nextval('content_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_types ALTER COLUMN id SET DEFAULT nextval('content_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_versions ALTER COLUMN id SET DEFAULT nextval('content_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents ALTER COLUMN id SET DEFAULT nextval('contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE languages ALTER COLUMN id SET DEFAULT nextval('languages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mime_types ALTER COLUMN id SET DEFAULT nextval('mime_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE role_capabilities ALTER COLUMN id SET DEFAULT nextval('role_capabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE version_list_content_keys ALTER COLUMN id SET DEFAULT nextval('version_list_content_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE version_list_contents ALTER COLUMN id SET DEFAULT nextval('version_list_contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE version_list_name_versions ALTER COLUMN id SET DEFAULT nextval('version_list_name_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE version_list_names ALTER COLUMN id SET DEFAULT nextval('version_list_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE version_lists ALTER COLUMN id SET DEFAULT nextval('version_lists_id_seq'::regclass);


--
-- Name: applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: auth_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auth_changes
    ADD CONSTRAINT auth_changes_pkey PRIMARY KEY (id);


--
-- Name: brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: capabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY capabilities
    ADD CONSTRAINT capabilities_pkey PRIMARY KEY (id);


--
-- Name: content_key_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_key_versions
    ADD CONSTRAINT content_key_versions_pkey PRIMARY KEY (id);


--
-- Name: content_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_keys
    ADD CONSTRAINT content_keys_pkey PRIMARY KEY (id);


--
-- Name: content_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_pkey PRIMARY KEY (id);


--
-- Name: content_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_versions
    ADD CONSTRAINT content_versions_pkey PRIMARY KEY (id);


--
-- Name: contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: mime_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mime_types
    ADD CONSTRAINT mime_types_pkey PRIMARY KEY (id);


--
-- Name: role_capabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY role_capabilities
    ADD CONSTRAINT role_capabilities_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: version_list_content_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_list_content_keys
    ADD CONSTRAINT version_list_content_keys_pkey PRIMARY KEY (id);


--
-- Name: version_list_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_list_contents
    ADD CONSTRAINT version_list_contents_pkey PRIMARY KEY (id);


--
-- Name: version_list_name_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_list_name_versions
    ADD CONSTRAINT version_list_name_versions_pkey PRIMARY KEY (id);


--
-- Name: version_list_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_list_names
    ADD CONSTRAINT version_list_names_pkey PRIMARY KEY (id);


--
-- Name: version_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY version_lists
    ADD CONSTRAINT version_lists_pkey PRIMARY KEY (id);


--
-- Name: contents_u; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_u ON contents USING btree (content_key_id, language_id, country_id, brand_id, application_id, mime_type_id);


--
-- Name: index_applications_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_applications_on_code ON applications USING btree (code);


--
-- Name: index_brands_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_brands_on_code ON brands USING btree (code);


--
-- Name: index_capabilities_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_capabilities_on_name ON capabilities USING btree (name);


--
-- Name: index_content_key_versions_on_content_key_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_key_versions_on_content_key_id ON content_key_versions USING btree (content_key_id);


--
-- Name: index_content_key_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_key_versions_on_created_at ON content_key_versions USING btree (created_at);


--
-- Name: index_content_keys_on_code_and_content_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_content_keys_on_code_and_content_type_id ON content_keys USING btree (code, content_type_id);


--
-- Name: index_content_keys_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_content_keys_on_uuid ON content_keys USING btree (uuid);


--
-- Name: index_content_types_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_content_types_on_code ON content_types USING btree (code);


--
-- Name: index_content_versions_on_application_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_application_id ON content_versions USING btree (application_id);


--
-- Name: index_content_versions_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_brand_id ON content_versions USING btree (brand_id);


--
-- Name: index_content_versions_on_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_content_id ON content_versions USING btree (content_id);


--
-- Name: index_content_versions_on_content_key_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_content_key_id ON content_versions USING btree (content_key_id);


--
-- Name: index_content_versions_on_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_country_id ON content_versions USING btree (country_id);


--
-- Name: index_content_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_created_at ON content_versions USING btree (created_at);


--
-- Name: index_content_versions_on_language_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_language_id ON content_versions USING btree (language_id);


--
-- Name: index_content_versions_on_md5sum; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_md5sum ON content_versions USING btree (md5sum);


--
-- Name: index_content_versions_on_mime_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_mime_type_id ON content_versions USING btree (mime_type_id);


--
-- Name: index_content_versions_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_content_versions_on_uuid ON content_versions USING btree (uuid);


--
-- Name: index_contents_on_application_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_application_id ON contents USING btree (application_id);


--
-- Name: index_contents_on_brand_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_brand_id ON contents USING btree (brand_id);


--
-- Name: index_contents_on_content_key_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_content_key_id ON contents USING btree (content_key_id);


--
-- Name: index_contents_on_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_country_id ON contents USING btree (country_id);


--
-- Name: index_contents_on_language_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_language_id ON contents USING btree (language_id);


--
-- Name: index_contents_on_md5sum; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_md5sum ON contents USING btree (md5sum);


--
-- Name: index_contents_on_mime_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contents_on_mime_type_id ON contents USING btree (mime_type_id);


--
-- Name: index_contents_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_contents_on_uuid ON contents USING btree (uuid);


--
-- Name: index_countries_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_countries_on_code ON countries USING btree (code);


--
-- Name: index_languages_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_languages_on_code ON languages USING btree (code);


--
-- Name: index_mime_types_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mime_types_on_code ON mime_types USING btree (code);


--
-- Name: index_role_capabilities_on_capability_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_role_capabilities_on_capability_id ON role_capabilities USING btree (capability_id);


--
-- Name: index_role_capabilities_on_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_role_capabilities_on_role_id ON role_capabilities USING btree (role_id);


--
-- Name: index_role_capabilities_on_role_id_and_capability_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_role_capabilities_on_role_id_and_capability_id ON role_capabilities USING btree (role_id, capability_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_roles_on_name ON roles USING btree (name);


--
-- Name: index_roles_users_on_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_users_on_role_id ON roles_users USING btree (role_id);


--
-- Name: index_roles_users_on_role_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_roles_users_on_role_id_and_user_id ON roles_users USING btree (role_id, user_id);


--
-- Name: index_roles_users_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_users_on_user_id ON roles_users USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_user_id ON sessions USING btree (user_id);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: index_version_list_content_keys_on_content_key_version_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_content_keys_on_content_key_version_id ON version_list_content_keys USING btree (content_key_version_id);


--
-- Name: index_version_list_content_keys_on_version_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_content_keys_on_version_list_id ON version_list_content_keys USING btree (version_list_id);


--
-- Name: index_version_list_contents_on_content_version_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_contents_on_content_version_id ON version_list_contents USING btree (content_version_id);


--
-- Name: index_version_list_contents_on_version_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_contents_on_version_list_id ON version_list_contents USING btree (version_list_id);


--
-- Name: index_version_list_name_versions_on_version_list_name_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_name_versions_on_version_list_name_id ON version_list_name_versions USING btree (version_list_name_id);


--
-- Name: index_version_list_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_version_list_names_on_name ON version_list_names USING btree (name);


--
-- Name: index_version_list_names_on_version_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_list_names_on_version_list_id ON version_list_names USING btree (version_list_id);


--
-- Name: index_version_lists_on_point_in_time; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_version_lists_on_point_in_time ON version_lists USING btree (point_in_time);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: version_list_key_u; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX version_list_key_u ON version_list_content_keys USING btree (version_list_id, content_key_version_id);


--
-- Name: version_list_u; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX version_list_u ON version_list_contents USING btree (version_list_id, content_version_id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20080901000000');

INSERT INTO schema_migrations (version) VALUES ('20080901000001');

INSERT INTO schema_migrations (version) VALUES ('20081017060000');

INSERT INTO schema_migrations (version) VALUES ('20081017060001');

INSERT INTO schema_migrations (version) VALUES ('20081017060010');

INSERT INTO schema_migrations (version) VALUES ('20081017060011');

INSERT INTO schema_migrations (version) VALUES ('20081017060021');

INSERT INTO schema_migrations (version) VALUES ('20081017064227');

INSERT INTO schema_migrations (version) VALUES ('20081017064228');

INSERT INTO schema_migrations (version) VALUES ('20081017064229');

INSERT INTO schema_migrations (version) VALUES ('20081017064710');

INSERT INTO schema_migrations (version) VALUES ('20081017064720');

INSERT INTO schema_migrations (version) VALUES ('20081017064734');

INSERT INTO schema_migrations (version) VALUES ('20081017064756');

INSERT INTO schema_migrations (version) VALUES ('20081017080000');

INSERT INTO schema_migrations (version) VALUES ('20090109023201');

INSERT INTO schema_migrations (version) VALUES ('20090109023202');

INSERT INTO schema_migrations (version) VALUES ('20090109023203');

INSERT INTO schema_migrations (version) VALUES ('20090214190000');

INSERT INTO schema_migrations (version) VALUES ('20090729160039');

INSERT INTO schema_migrations (version) VALUES ('20090729180403');

INSERT INTO schema_migrations (version) VALUES ('20091231000000');