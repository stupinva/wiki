SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
SET default_tablespace = '';
DROP TABLE IF EXISTS public.checksum,
                     public.class,
                     public.device,
                     public.domain,
                     public.file,
                     public.file_on,
                     public.file_on_corrupt,
                     public.file_to_delete,
                     public.file_to_delete2,
                     public.file_to_delete_later,
                     public.file_to_queue,
                     public.file_to_replicate,
                     public.fsck_log,
                     public.host,
                     public.lock,
                     public.server_settings,
                     public.tempfile,
                     public.unreachable_fids;
CREATE TABLE public.checksum (
    fid bigint NOT NULL,
    hashtype smallint NOT NULL,
    checksum bytea NOT NULL
);
ALTER TABLE public.checksum OWNER TO mogilefs;
CREATE TABLE public.class (
    dmid smallint NOT NULL,
    classid smallint NOT NULL,
    classname character varying(50),
    mindevcount smallint NOT NULL,
    hashtype smallint,
    replpolicy character varying(255)
);
ALTER TABLE public.class OWNER TO mogilefs;
CREATE TABLE public.device (
    devid smallint NOT NULL,
    hostid smallint NOT NULL,
    status character varying(8),
    weight integer DEFAULT 100,
    mb_total integer,
    mb_used integer,
    mb_asof integer,
    CONSTRAINT device_devid_check CHECK ((devid >= 0)),
    CONSTRAINT device_mb_asof_check CHECK ((mb_asof >= 0)),
    CONSTRAINT device_mb_total_check CHECK ((mb_total >= 0)),
    CONSTRAINT device_mb_used_check CHECK ((mb_used >= 0)),
    CONSTRAINT device_status_check CHECK (((status)::text = ANY ((ARRAY['alive'::character varying, 'dead'::character varying, 'down'::character varying, 'readonly'::character varying, 'drain'::character varying])::text[])))
);
ALTER TABLE public.device OWNER TO mogilefs;
CREATE TABLE public.domain (
    dmid smallint NOT NULL,
    namespace character varying(255)
);
ALTER TABLE public.domain OWNER TO mogilefs;
CREATE TABLE public.file (
    fid bigint NOT NULL,
    dmid smallint NOT NULL,
    dkey character varying(255),
    length bigint,
    classid smallint NOT NULL,
    devcount smallint NOT NULL,
    CONSTRAINT file_length_check CHECK ((length >= 0))
);
ALTER TABLE public.file OWNER TO mogilefs;
CREATE TABLE public.file_on (
    fid bigint NOT NULL,
    devid smallint NOT NULL
);
ALTER TABLE public.file_on OWNER TO mogilefs;
CREATE TABLE public.file_on_corrupt (
    fid bigint NOT NULL,
    devid smallint NOT NULL
);
ALTER TABLE public.file_on_corrupt OWNER TO mogilefs;
CREATE TABLE public.file_to_delete (
    fid bigint NOT NULL
);
ALTER TABLE public.file_to_delete OWNER TO mogilefs;
CREATE TABLE public.file_to_delete2 (
    fid bigint NOT NULL,
    nexttry integer NOT NULL,
    failcount smallint DEFAULT '0'::smallint NOT NULL
);
ALTER TABLE public.file_to_delete2 OWNER TO mogilefs;
CREATE TABLE public.file_to_delete_later (
    fid bigint NOT NULL,
    delafter integer NOT NULL
);
ALTER TABLE public.file_to_delete_later OWNER TO mogilefs;
CREATE TABLE public.file_to_queue (
    fid bigint NOT NULL,
    devid integer,
    type smallint NOT NULL,
    nexttry integer NOT NULL,
    failcount smallint DEFAULT '0'::smallint NOT NULL,
    flags smallint DEFAULT '0'::smallint NOT NULL,
    arg text
);
ALTER TABLE public.file_to_queue OWNER TO mogilefs;
CREATE TABLE public.file_to_replicate (
    fid bigint NOT NULL,
    nexttry integer NOT NULL,
    fromdevid integer,
    failcount smallint DEFAULT 0 NOT NULL,
    flags smallint DEFAULT 0 NOT NULL
);
ALTER TABLE public.file_to_replicate OWNER TO mogilefs;
CREATE TABLE public.fsck_log (
    logid integer NOT NULL,
    utime integer NOT NULL,
    fid bigint,
    evcode character(4),
    devid smallint
);
ALTER TABLE public.fsck_log OWNER TO mogilefs;
CREATE SEQUENCE public.fsck_log_logid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.fsck_log_logid_seq OWNER TO mogilefs;
ALTER SEQUENCE public.fsck_log_logid_seq OWNED BY public.fsck_log.logid;
CREATE TABLE public.host (
    hostid smallint NOT NULL,
    status character varying(8),
    http_port integer DEFAULT 7500,
    http_get_port integer,
    hostname character varying(40),
    hostip character varying(15),
    altip character varying(15),
    altmask character varying(18),
    CONSTRAINT host_hostid_check CHECK ((hostid >= 0)),
    CONSTRAINT host_http_get_port_check CHECK ((http_get_port >= 0)),
    CONSTRAINT host_http_get_port_check1 CHECK ((http_get_port < 65536)),
    CONSTRAINT host_http_port_check CHECK ((http_port >= 0)),
    CONSTRAINT host_http_port_check1 CHECK ((http_port < 65536)),
    CONSTRAINT host_status_check CHECK (((status)::text = ANY ((ARRAY['alive'::character varying, 'dead'::character varying, 'down'::character varying])::text[])))
);
ALTER TABLE public.host OWNER TO mogilefs;
CREATE TABLE public.lock (
    lockid integer NOT NULL,
    hostname character varying(255) NOT NULL,
    pid integer NOT NULL,
    acquiredat integer NOT NULL,
    CONSTRAINT lock_acquiredat_check CHECK ((acquiredat >= 0)),
    CONSTRAINT lock_lockid_check CHECK ((lockid >= 0)),
    CONSTRAINT lock_pid_check CHECK ((pid >= 0))
);
ALTER TABLE public.lock OWNER TO mogilefs;
CREATE TABLE public.server_settings (
    field character varying(50) NOT NULL,
    value text
);
ALTER TABLE public.server_settings OWNER TO mogilefs;
CREATE TABLE public.tempfile (
    fid integer NOT NULL,
    createtime integer NOT NULL,
    classid smallint NOT NULL,
    dmid smallint NOT NULL,
    dkey character varying(255),
    devids character varying(60)
);
ALTER TABLE public.tempfile OWNER TO mogilefs;
CREATE SEQUENCE public.tempfile_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.tempfile_fid_seq OWNER TO mogilefs;
ALTER SEQUENCE public.tempfile_fid_seq OWNED BY public.tempfile.fid;
CREATE TABLE public.unreachable_fids (
    fid bigint NOT NULL,
    lastupdate integer NOT NULL
);
ALTER TABLE public.unreachable_fids OWNER TO mogilefs;
ALTER TABLE ONLY public.fsck_log ALTER COLUMN logid SET DEFAULT nextval('public.fsck_log_logid_seq'::regclass);
ALTER TABLE ONLY public.tempfile ALTER COLUMN fid SET DEFAULT nextval('public.tempfile_fid_seq'::regclass);
ALTER TABLE ONLY public.checksum
    ADD CONSTRAINT checksum_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_dmid_classname_key UNIQUE (dmid, classname);
ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_pkey PRIMARY KEY (dmid, classid);
ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (devid);
ALTER TABLE ONLY public.domain
    ADD CONSTRAINT domain_namespace_key UNIQUE (namespace);
ALTER TABLE ONLY public.domain
    ADD CONSTRAINT domain_pkey PRIMARY KEY (dmid);
ALTER TABLE ONLY public.file
    ADD CONSTRAINT file_dmid_dkey_key UNIQUE (dmid, dkey);
ALTER TABLE ONLY public.file_on_corrupt
    ADD CONSTRAINT file_on_corrupt_pkey PRIMARY KEY (fid, devid);
ALTER TABLE ONLY public.file_on
    ADD CONSTRAINT file_on_pkey PRIMARY KEY (fid, devid);
ALTER TABLE ONLY public.file
    ADD CONSTRAINT file_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.file_to_delete2
    ADD CONSTRAINT file_to_delete2_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.file_to_delete_later
    ADD CONSTRAINT file_to_delete_later_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.file_to_delete
    ADD CONSTRAINT file_to_delete_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.file_to_queue
    ADD CONSTRAINT file_to_queue_pkey PRIMARY KEY (fid, type);
ALTER TABLE ONLY public.file_to_replicate
    ADD CONSTRAINT file_to_replicate_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.fsck_log
    ADD CONSTRAINT fsck_log_pkey PRIMARY KEY (logid);
ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_altip_key UNIQUE (altip);
ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_hostip_key UNIQUE (hostip);
ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_hostname_key UNIQUE (hostname);
ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_pkey PRIMARY KEY (hostid);
ALTER TABLE ONLY public.lock
    ADD CONSTRAINT lock_pkey PRIMARY KEY (lockid);
ALTER TABLE ONLY public.server_settings
    ADD CONSTRAINT server_settings_pkey PRIMARY KEY (field);
ALTER TABLE ONLY public.tempfile
    ADD CONSTRAINT tempfile_pkey PRIMARY KEY (fid);
ALTER TABLE ONLY public.unreachable_fids
    ADD CONSTRAINT unreachable_fids_pkey PRIMARY KEY (fid);
CREATE INDEX device_status ON public.device USING btree (status);
CREATE INDEX file_devcount ON public.file USING btree (dmid, classid, devcount);
CREATE INDEX file_on_devid ON public.file_on USING btree (devid);
CREATE INDEX file_to_delete2_nexttry ON public.file_to_delete2 USING btree (nexttry);
CREATE INDEX file_to_delete_later_delafter ON public.file_to_delete_later USING btree (delafter);
CREATE INDEX file_to_replicate_nexttry ON public.file_to_replicate USING btree (nexttry);
CREATE INDEX fsck_log_utime ON public.fsck_log USING btree (utime);
CREATE INDEX type_nexttry ON public.file_to_queue USING btree (type, nexttry);
CREATE INDEX unreachable_fids_lastupdate ON public.unreachable_fids USING btree (lastupdate);
