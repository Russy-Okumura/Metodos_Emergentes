


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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."alumno" (
    "no_control" integer NOT NULL,
    "pri_nombre" character varying(15),
    "seg_nombre" character varying(15),
    "pri_apellido" character varying(15),
    "seg_apellido" character varying(15),
    "estado_control" boolean
);


ALTER TABLE "public"."alumno" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."maestros" (
    "matricula" integer NOT NULL,
    "pri_nombre" character varying(15),
    "seg_nombre" character varying(15),
    "pri_apellido" character varying(15),
    "seg_apellido" character varying(15),
    "estado_matricula" boolean
);


ALTER TABLE "public"."maestros" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."proveedores" (
    "no_provedor" integer NOT NULL,
    "pri_nombre" character varying(15),
    "seg_nombre" character varying(15),
    "pri_apellido" character varying(15),
    "seg_apellido" character varying(15),
    "empresa_prov" character varying(20),
    "area_trab" character varying(20)
);


ALTER TABLE "public"."proveedores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trabajadores" (
    "no_trabajador" integer NOT NULL,
    "pri_nombre" character varying(15),
    "seg_nombre" character varying(15),
    "pri_apellido" character varying(15),
    "seg_apellido" character varying(15),
    "rol_inst" character varying(30)
);


ALTER TABLE "public"."trabajadores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."visita" (
    "no_visita" integer NOT NULL,
    "pri_nombre" character varying(15),
    "seg_nombre" character varying(15),
    "pri_apellido" character varying(15),
    "seg_apellido" character varying(15),
    "motivo_visita" character varying(40)
);


ALTER TABLE "public"."visita" OWNER TO "postgres";


ALTER TABLE ONLY "public"."alumno"
    ADD CONSTRAINT "alumno_pkey" PRIMARY KEY ("no_control");



ALTER TABLE ONLY "public"."maestros"
    ADD CONSTRAINT "maestros_pkey" PRIMARY KEY ("matricula");



ALTER TABLE ONLY "public"."proveedores"
    ADD CONSTRAINT "proveedores_pkey" PRIMARY KEY ("no_provedor");



ALTER TABLE ONLY "public"."trabajadores"
    ADD CONSTRAINT "trabajadores_pkey" PRIMARY KEY ("no_trabajador");



ALTER TABLE ONLY "public"."visita"
    ADD CONSTRAINT "visita_pkey" PRIMARY KEY ("no_visita");





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";








































































































































































GRANT ALL ON TABLE "public"."alumno" TO "anon";
GRANT ALL ON TABLE "public"."alumno" TO "authenticated";
GRANT ALL ON TABLE "public"."alumno" TO "service_role";



GRANT ALL ON TABLE "public"."maestros" TO "anon";
GRANT ALL ON TABLE "public"."maestros" TO "authenticated";
GRANT ALL ON TABLE "public"."maestros" TO "service_role";



GRANT ALL ON TABLE "public"."proveedores" TO "anon";
GRANT ALL ON TABLE "public"."proveedores" TO "authenticated";
GRANT ALL ON TABLE "public"."proveedores" TO "service_role";



GRANT ALL ON TABLE "public"."trabajadores" TO "anon";
GRANT ALL ON TABLE "public"."trabajadores" TO "authenticated";
GRANT ALL ON TABLE "public"."trabajadores" TO "service_role";



GRANT ALL ON TABLE "public"."visita" TO "anon";
GRANT ALL ON TABLE "public"."visita" TO "authenticated";
GRANT ALL ON TABLE "public"."visita" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";


