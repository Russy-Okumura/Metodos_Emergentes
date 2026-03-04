-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.alumno (
  no_control integer NOT NULL,
  pri_nombre character varying,
  seg_nombre character varying,
  pri_apellido character varying,
  seg_apellido character varying,
  estado_control boolean,
  CONSTRAINT alumno_pkey PRIMARY KEY (no_control)
);
CREATE TABLE public.maestros (
  matricula integer NOT NULL,
  pri_nombre character varying,
  seg_nombre character varying,
  pri_apellido character varying,
  seg_apellido character varying,
  estado_matricula boolean,
  CONSTRAINT maestros_pkey PRIMARY KEY (matricula)
);
CREATE TABLE public.proveedores (
  no_provedor integer NOT NULL,
  pri_nombre character varying,
  seg_nombre character varying,
  pri_apellido character varying,
  seg_apellido character varying,
  empresa_prov character varying,
  area_trab character varying,
  CONSTRAINT proveedores_pkey PRIMARY KEY (no_provedor)
);
CREATE TABLE public.trabajadores (
  no_trabajador integer NOT NULL,
  pri_nombre character varying,
  seg_nombre character varying,
  pri_apellido character varying,
  seg_apellido character varying,
  rol_inst character varying,
  CONSTRAINT trabajadores_pkey PRIMARY KEY (no_trabajador)
);
CREATE TABLE public.visita (
  no_visita integer NOT NULL,
  pri_nombre character varying,
  seg_nombre character varying,
  pri_apellido character varying,
  seg_apellido character varying,
  motivo_visita character varying,
  CONSTRAINT visita_pkey PRIMARY KEY (no_visita)
);
