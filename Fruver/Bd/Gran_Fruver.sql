toc.dat                                                                                             0000600 0004000 0002000 00000070525 13637716272 0014466 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP           3                x            Gran_Fruver    11.5    12.0 @    T           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         U           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         V           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         W           1262    83414    Gran_Fruver    DATABASE     �   CREATE DATABASE "Gran_Fruver" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE "Gran_Fruver";
                postgres    false         X           0    0    DATABASE "Gran_Fruver"    COMMENT     7   COMMENT ON DATABASE "Gran_Fruver" IS 'Bd Gran Fruver';
                   postgres    false    2903                     2615    83417    producto    SCHEMA        CREATE SCHEMA producto;
    DROP SCHEMA producto;
                postgres    false         Y           0    0    SCHEMA producto    COMMENT     6   COMMENT ON SCHEMA producto IS 'Esquema de productos';
                   postgres    false    6         
            2615    83416 	   seguridad    SCHEMA        CREATE SCHEMA seguridad;
    DROP SCHEMA seguridad;
                postgres    false         Z           0    0    SCHEMA seguridad    COMMENT     7   COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';
                   postgres    false    10                     2615    83415    usuario    SCHEMA        CREATE SCHEMA usuario;
    DROP SCHEMA usuario;
                postgres    false         [           0    0    SCHEMA usuario    COMMENT     3   COMMENT ON SCHEMA usuario IS 'Esquema de usuario';
                   postgres    false    7         �            1255    91627    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	 DECLARE
		_pk TEXT :='';		-- Representa la llave primaria de la tabla que esta siedno modificada.
		_sql TEXT;		-- Variable para la creacion del procedured.
		_column_guia RECORD; 	-- Variable para el FOR guarda los nombre de las columnas.
		_column_key RECORD; 	-- Variable para el FOR guarda los PK de las columnas.
		_session TEXT;	-- Almacena el usuario que genera el cambio.
		_user_db TEXT;		-- Almacena el usuario de bd que genera la transaccion.
		_control INT;		-- Variabel de control par alas llaves primarias.
		_count_key INT = 0;	-- Cantidad de columnas pertenecientes al PK.
		_sql_insert TEXT;	-- Variable para la construcción del insert del json de forma dinamica.
		_sql_delete TEXT;	-- Variable para la construcción del delete del json de forma dinamica.
		_sql_update TEXT;	-- Variable para la construcción del update del json de forma dinamica.
		_new_data RECORD; 	-- Fila que representa los campos nuevos del registro.
		_old_data RECORD;	-- Fila que representa los campos viejos del registro.

	BEGIN

			-- Se genera la evaluacion para determianr el tipo de accion sobre la tabla
		 IF (TG_OP = 'INSERT') THEN
			_new_data := NEW;
			_old_data := NEW;
		ELSEIF (TG_OP = 'UPDATE') THEN
			_new_data := NEW;
			_old_data := OLD;
		ELSE
			_new_data := OLD;
			_old_data := OLD;
		END IF;

		-- Se genera la evaluacion para determianr el tipo de accion sobre la tabla
		IF ((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME AND column_name = 'id' ) > 0) THEN
			_pk := _new_data.id;
		ELSE
			_pk := '-1';
		END IF;

		-- Se valida que exista el campo modified_by
		IF ((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME AND column_name = 'session') > 0) THEN
			_session := _new_data.session;
		ELSE
			_session := '';
		END IF;

		-- Se guarda el susuario de bd que genera la transaccion
		_user_db := (SELECT CURRENT_USER);

		-- Se evalua que exista el procedimeinto adecuado
		IF (SELECT COUNT(*) FROM seguridad.function_db_view acfdv WHERE acfdv.b_function = 'field_audit' AND acfdv.b_type_parameters = TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', character varying, character varying, character varying, text, character varying, text, text') > 0
			THEN
				-- Se realiza la invocación del procedured generado dinamivamente
				PERFORM seguridad.field_audit(_new_data, _old_data, TG_OP, _session, _user_db , _pk, ''::text);
		ELSE
			-- Se empieza la construcción del Procedured generico
			_sql := 'CREATE OR REPLACE FUNCTION seguridad.field_audit( _data_new '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', _data_old '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', _accion character varying, _session text, _user_db character varying, _table_pk text, _init text)'
			|| ' RETURNS TEXT AS ''
'
			|| '
'
	|| '	DECLARE
'
	|| '		_column_data TEXT;
	 	_datos jsonb;
	 	
'
	|| '	BEGIN
			_datos = ''''{}'''';
';
			-- Se evalua si hay que actualizar la pk del registro de auditoria.
			IF _pk = '-1'
				THEN
					_sql := _sql
					|| '
		_column_data := ';

					-- Se genera el update con la clave pk de la tabla
					SELECT
						COUNT(isk.column_name)
					INTO
						_control
					FROM
						information_schema.table_constraints istc JOIN information_schema.key_column_usage isk ON isk.constraint_name = istc.constraint_name
					WHERE
						istc.table_schema = TG_TABLE_SCHEMA
					 AND	istc.table_name = TG_TABLE_NAME
					 AND	istc.constraint_type ilike '%primary%';

					-- Se agregan las columnas que componen la pk de la tabla.
					FOR _column_key IN SELECT
							isk.column_name
						FROM
							information_schema.table_constraints istc JOIN information_schema.key_column_usage isk ON isk.constraint_name = istc.constraint_name
						WHERE
							istc.table_schema = TG_TABLE_SCHEMA
						 AND	istc.table_name = TG_TABLE_NAME
						 AND	istc.constraint_type ilike '%primary%'
						ORDER BY 
							isk.ordinal_position  LOOP

						_sql := _sql || ' _data_new.' || _column_key.column_name;
						
						_count_key := _count_key + 1 ;
						
						IF _count_key < _control THEN
							_sql :=	_sql || ' || ' || ''''',''''' || ' ||';
						END IF;
					END LOOP;
				_sql := _sql || ';';
			END IF;

			_sql_insert:='
		IF _accion = ''''INSERT''''
			THEN
				';
			_sql_delete:='
		ELSEIF _accion = ''''DELETE''''
			THEN
				';
			_sql_update:='
		ELSE
			';

			-- Se genera el ciclo de agregado de columnas para el nuevo procedured
			FOR _column_guia IN SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME
				LOOP
						
					_sql_insert:= _sql_insert || '_datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_nuevo'
					|| ''''', '
					|| '_data_new.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_insert:= _sql_insert
						||'::text';
					END IF;

					_sql_insert:= _sql_insert || ')::jsonb;
				';

					_sql_delete := _sql_delete || '_datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_anterior'
					|| ''''', '
					|| '_data_old.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_delete:= _sql_delete
						||'::text';
					END IF;

					_sql_delete:= _sql_delete || ')::jsonb;
				';

					_sql_update := _sql_update || 'IF _data_old.' || _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update || ' <> _data_new.' || _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update || '
				THEN _datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_anterior'
					|| ''''', '
					|| '_data_old.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update
					|| ', '''''
					|| _column_guia.column_name
					|| '_nuevo'
					|| ''''', _data_new.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update
					|| ')::jsonb;
			END IF;
			';
			END LOOP;

			-- Se le agrega la parte final del procedured generico
			
			_sql:= _sql || _sql_insert || _sql_delete || _sql_update
			|| ' 
		END IF;

		INSERT INTO seguridad.auditoria
		(
			fecha,
			accion,
			schema,
			tabla,
			pk,
			session,
			user_bd,
			data
		)
		VALUES
		(
			CURRENT_TIMESTAMP,
			_accion,
			''''' || TG_TABLE_SCHEMA || ''''',
			''''' || TG_TABLE_NAME || ''''',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;'''
|| '
LANGUAGE plpgsql;';

			-- Se genera la ejecución de _sql, es decir se crea el nuevo procedured de forma generica.
			EXECUTE _sql;

		-- Se realiza la invocación del procedured generado dinamivamente
			PERFORM seguridad.field_audit(_new_data, _old_data, TG_OP::character varying, _session, _user_db, _pk, ''::text);

		END IF;

		RETURN NULL;

END;
$$;
 +   DROP FUNCTION seguridad.f_log_auditoria();
    	   seguridad          postgres    false    10         �            1259    99751    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);
 $   DROP TABLE seguridad.autenticacion;
    	   seguridad            postgres    false    10         �            1255    99761 u   field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text)    FUNCTION     m  CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
    LANGUAGE plpgsql
    AS $$

	DECLARE
		_column_data TEXT;
	 	_datos jsonb;
	 	
	BEGIN
			_datos = '{}';

		IF _accion = 'INSERT'
			THEN
				_datos := _datos || json_build_object('id_nuevo', _data_new.id)::jsonb;
				_datos := _datos || json_build_object('user_id_nuevo', _data_new.user_id)::jsonb;
				_datos := _datos || json_build_object('ip_nuevo', _data_new.ip)::jsonb;
				_datos := _datos || json_build_object('mac_nuevo', _data_new.mac)::jsonb;
				_datos := _datos || json_build_object('fecha_inicio_nuevo', _data_new.fecha_inicio)::jsonb;
				_datos := _datos || json_build_object('fecha_fin_nuevo', _data_new.fecha_fin)::jsonb;
				_datos := _datos || json_build_object('session_nuevo', _data_new.session)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('user_id_anterior', _data_old.user_id)::jsonb;
				_datos := _datos || json_build_object('ip_anterior', _data_old.ip)::jsonb;
				_datos := _datos || json_build_object('mac_anterior', _data_old.mac)::jsonb;
				_datos := _datos || json_build_object('fecha_inicio_anterior', _data_old.fecha_inicio)::jsonb;
				_datos := _datos || json_build_object('fecha_fin_anterior', _data_old.fecha_fin)::jsonb;
				_datos := _datos || json_build_object('session_anterior', _data_old.session)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.user_id <> _data_new.user_id
				THEN _datos := _datos || json_build_object('user_id_anterior', _data_old.user_id, 'user_id_nuevo', _data_new.user_id)::jsonb;
			END IF;
			IF _data_old.ip <> _data_new.ip
				THEN _datos := _datos || json_build_object('ip_anterior', _data_old.ip, 'ip_nuevo', _data_new.ip)::jsonb;
			END IF;
			IF _data_old.mac <> _data_new.mac
				THEN _datos := _datos || json_build_object('mac_anterior', _data_old.mac, 'mac_nuevo', _data_new.mac)::jsonb;
			END IF;
			IF _data_old.fecha_inicio <> _data_new.fecha_inicio
				THEN _datos := _datos || json_build_object('fecha_inicio_anterior', _data_old.fecha_inicio, 'fecha_inicio_nuevo', _data_new.fecha_inicio)::jsonb;
			END IF;
			IF _data_old.fecha_fin <> _data_new.fecha_fin
				THEN _datos := _datos || json_build_object('fecha_fin_anterior', _data_old.fecha_fin, 'fecha_fin_nuevo', _data_new.fecha_fin)::jsonb;
			END IF;
			IF _data_old.session <> _data_new.session
				THEN _datos := _datos || json_build_object('session_anterior', _data_old.session, 'session_nuevo', _data_new.session)::jsonb;
			END IF;
			 
		END IF;

		INSERT INTO seguridad.auditoria
		(
			fecha,
			accion,
			schema,
			tabla,
			pk,
			session,
			user_bd,
			data
		)
		VALUES
		(
			CURRENT_TIMESTAMP,
			_accion,
			'seguridad',
			'autenticacion',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    213    213    10         �            1259    83475    detalle_lote    TABLE     �   CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    6         �            1259    83473    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    6    208         \           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    207         �            1259    83464    lote    TABLE     �   CREATE TABLE producto.lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    fecha timestamp without time zone NOT NULL,
    proveedor text NOT NULL,
    detalle_lote_id integer NOT NULL
);
    DROP TABLE producto.lote;
       producto            postgres    false    6         �            1259    83462    lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE producto.lote_id_seq;
       producto          postgres    false    206    6         ]           0    0    lote_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE producto.lote_id_seq OWNED BY producto.lote.id;
          producto          postgres    false    205         �            1259    83453    producto    TABLE       CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL,
    precio integer NOT NULL,
    fecha_ingreso timestamp without time zone NOT NULL
);
    DROP TABLE producto.producto;
       producto            postgres    false    6         �            1259    83451    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    204    6         ^           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
          producto          postgres    false    203         �            1259    91607    auditoria_id_seq    SEQUENCE     |   CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE seguridad.auditoria_id_seq;
    	   seguridad          postgres    false    10         �            1259    91618 	   auditoria    TABLE     �  CREATE TABLE seguridad.auditoria (
    id bigint DEFAULT nextval('seguridad.auditoria_id_seq'::regclass) NOT NULL,
    fecha timestamp without time zone,
    accion character varying(100),
    schema character varying(200) NOT NULL,
    tabla character varying(200),
    session text NOT NULL,
    user_bd character varying(100) NOT NULL,
    data jsonb NOT NULL,
    pk text NOT NULL
);
     DROP TABLE seguridad.auditoria;
    	   seguridad            postgres    false    209    10         �            1259    99749    autenticacion_id_seq    SEQUENCE     �   CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE seguridad.autenticacion_id_seq;
    	   seguridad          postgres    false    213    10         _           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
       	   seguridad          postgres    false    212         �            1259    91630    function_db_view    VIEW     �  CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));
 &   DROP VIEW seguridad.function_db_view;
    	   seguridad          postgres    false    10         �            1259    83420    rol    TABLE     �   CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);
    DROP TABLE usuario.rol;
       usuario            postgres    false    7         �            1259    83418 
   rol_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE usuario.rol_id_seq;
       usuario          postgres    false    200    7         `           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    199         �            1259    83431    usuario    TABLE     �  CREATE TABLE usuario.usuario (
    id integer NOT NULL,
    nombre text NOT NULL,
    user_name text NOT NULL,
    correo text NOT NULL,
    password text NOT NULL,
    celular integer NOT NULL,
    direccion text NOT NULL,
    rol_id integer,
    session text,
    last_modify timestamp without time zone,
    estado_id integer DEFAULT 1,
    token text,
    vencimiento_token timestamp without time zone
);
    DROP TABLE usuario.usuario;
       usuario            postgres    false    7         �            1259    83429    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    202    7         a           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
          usuario          postgres    false    201         �
           2604    83478    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    207    208    208         �
           2604    83467    lote id    DEFAULT     f   ALTER TABLE ONLY producto.lote ALTER COLUMN id SET DEFAULT nextval('producto.lote_id_seq'::regclass);
 8   ALTER TABLE producto.lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    205    206    206         �
           2604    83456    producto id    DEFAULT     n   ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);
 <   ALTER TABLE producto.producto ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    203    204    204         �
           2604    99754    autenticacion id    DEFAULT     z   ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);
 B   ALTER TABLE seguridad.autenticacion ALTER COLUMN id DROP DEFAULT;
    	   seguridad          postgres    false    212    213    213         �
           2604    83423    rol id    DEFAULT     b   ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);
 6   ALTER TABLE usuario.rol ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    199    200    200         �
           2604    83434 
   usuario id    DEFAULT     j   ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);
 :   ALTER TABLE usuario.usuario ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    201    202    202         M          0    83475    detalle_lote 
   TABLE DATA           S   COPY producto.detalle_lote (id, nombre, cantidad, precio, producto_id) FROM stdin;
    producto          postgres    false    208       2893.dat K          0    83464    lote 
   TABLE DATA           O   COPY producto.lote (id, nombre, fecha, proveedor, detalle_lote_id) FROM stdin;
    producto          postgres    false    206       2891.dat I          0    83453    producto 
   TABLE DATA           b   COPY producto.producto (id, nombre, imagen, fecha_vencimiento, precio, fecha_ingreso) FROM stdin;
    producto          postgres    false    204       2889.dat O          0    91618 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    210       2895.dat Q          0    99751    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    213       2897.dat E          0    83420    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    200       2885.dat G          0    83431    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    202       2887.dat b           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 1, false);
          producto          postgres    false    207         c           0    0    lote_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('producto.lote_id_seq', 1, false);
          producto          postgres    false    205         d           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 1, false);
          producto          postgres    false    203         e           0    0    auditoria_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 45, true);
       	   seguridad          postgres    false    209         f           0    0    autenticacion_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 14, true);
       	   seguridad          postgres    false    212         g           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    199         h           0    0    usuario_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('usuario.usuario_id_seq', 6, true);
          usuario          postgres    false    201         �
           2606    83483    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    208         �
           2606    83472    lote lote_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY producto.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY producto.lote DROP CONSTRAINT lote_pkey;
       producto            postgres    false    206         �
           2606    83461    producto producto_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY producto.producto DROP CONSTRAINT producto_pkey;
       producto            postgres    false    204         �
           2606    91626    auditoria auditoria_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY seguridad.auditoria DROP CONSTRAINT auditoria_pkey;
    	   seguridad            postgres    false    210         �
           2606    99759     autenticacion autenticacion_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY seguridad.autenticacion DROP CONSTRAINT autenticacion_pkey;
    	   seguridad            postgres    false    213         �
           2606    83428    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    200         �
           2606    83439    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    202         �
           2620    99760 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    213    214         �
           2620    91637    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    200    214         �
           2620    91629    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    214    202                                                                                                                                                                                   2893.dat                                                                                            0000600 0004000 0002000 00000000005 13637716272 0014270 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           2891.dat                                                                                            0000600 0004000 0002000 00000000005 13637716272 0014266 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           2889.dat                                                                                            0000600 0004000 0002000 00000000005 13637716273 0014276 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           2895.dat                                                                                            0000600 0004000 0002000 00000027137 13637716273 0014312 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        2	2020-03-26 14:47:44.468271	UPDATE	usuario	usuario	1234	postgres	{"nombre_nuevo": "jalejandro", "nombre_anterior": "alejandro"}	3
4	2020-03-26 14:53:18.393932	UPDATE	usuario	usuario	123	postgres	{}	2
5	2020-03-26 14:53:18.393932	DELETE	usuario	usuario	123	postgres	{"id_anterior": 2, "correo_anterior": "erika@gmail.com", "nombre_anterior": "erika", "rol_id_anterior": 2, "celular_anterior": 320, "session_anterior": "123", "password_anterior": "12345", "direccion_anterior": "Facatativa", "user_name_anterior": "erikamoreno", "last_modify_anterior": null}	2
6	2020-03-26 14:53:18.393932	DELETE	usuario	usuario	1234	postgres	{"id_anterior": 3, "correo_anterior": "jalejandro@gmail.com", "nombre_anterior": "jalejandro", "rol_id_anterior": 3, "celular_anterior": 321, "session_anterior": "1234", "password_anterior": "12345", "direccion_anterior": "mosquera", "user_name_anterior": "jalejandro", "last_modify_anterior": null}	3
7	2020-03-26 14:56:13.771641	INSERT	usuario	usuario	1	postgres	{"id_nuevo": 4, "correo_nuevo": "sandra.duarte0806@gmail.com", "nombre_nuevo": "sandra", "rol_id_nuevo": 1, "celular_nuevo": 310, "session_nuevo": "1", "password_nuevo": "12345", "direccion_nuevo": "hacienda el pedregal", "user_name_nuevo": "sandramoreno", "last_modify_nuevo": null}	4
8	2020-03-26 14:56:13.771641	INSERT	usuario	usuario	2	postgres	{"id_nuevo": 5, "correo_nuevo": "erika@gmail.com", "nombre_nuevo": "erika", "rol_id_nuevo": 2, "celular_nuevo": 320, "session_nuevo": "2", "password_nuevo": "12345", "direccion_nuevo": "facatativa", "user_name_nuevo": "erikamoreno", "last_modify_nuevo": null}	5
9	2020-03-26 14:56:13.771641	INSERT	usuario	usuario	3	postgres	{"id_nuevo": 6, "correo_nuevo": "jalejandro@gmail.com", "nombre_nuevo": "alejandro", "rol_id_nuevo": 3, "celular_nuevo": 210, "session_nuevo": "3", "password_nuevo": "12345", "direccion_nuevo": "mosquera", "user_name_nuevo": "jalejandro", "last_modify_nuevo": null}	6
10	2020-03-26 21:02:27.910776	UPDATE	usuario	usuario	1	postgres	{"password_nuevo": "", "estado_id_nuevo": 2, "password_anterior": "12345", "estado_id_anterior": 1}	4
11	2020-03-26 21:05:25.11423	UPDATE	usuario	usuario	1	postgres	{"token_nuevo": "55418544ac69405afbcdd086609ed0b4d5bff85b980463a8c14fbd6f1c234108", "token_anterior": "ed603676d925981a96cf5db1d5d1e9b7b6327676bd9146e914ac8f21be24d07a"}	4
12	2020-03-26 22:15:36.526474	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "4b7426d529d98b1d77beda7e4abe181eae4f05db9b6604adb10f91b6b1356e94", "session_nuevo": "Sistema", "token_anterior": "55418544ac69405afbcdd086609ed0b4d5bff85b980463a8c14fbd6f1c234108", "session_anterior": "1"}	4
13	2020-03-26 22:15:44.470375	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "64542ee8c7c71b3b2a9988345ccce6fe37c351b1fb44e5819ade63c4906b5af5", "token_anterior": "4b7426d529d98b1d77beda7e4abe181eae4f05db9b6604adb10f91b6b1356e94", "last_modify_nuevo": "2020-03-26T22:15:44.428734", "last_modify_anterior": "2020-03-26T22:15:35.631735", "vencimiento_token_nuevo": "2020-03-27T22:15:40.825734", "vencimiento_token_anterior": "2020-03-27T22:15:30.005736"}	4
14	2020-03-26 22:20:59.289286	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "fb3cb01f2639215f29497cb9c11542feaba178b4fffe90aa90e351cba20ba4cf", "token_anterior": "64542ee8c7c71b3b2a9988345ccce6fe37c351b1fb44e5819ade63c4906b5af5", "last_modify_nuevo": "2020-03-26T22:20:56.61723", "last_modify_anterior": "2020-03-26T22:15:44.428734", "vencimiento_token_nuevo": "2020-03-27T22:20:50.87023", "vencimiento_token_anterior": "2020-03-27T22:15:40.825734"}	4
15	2020-03-27 11:39:02.996246	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "2a3a24d5b86b63003e8dff6fcc59ef38b8bf32c6d368938c7f6a0e5a60ed5ffa", "token_anterior": "fb3cb01f2639215f29497cb9c11542feaba178b4fffe90aa90e351cba20ba4cf", "last_modify_nuevo": "2020-03-27T11:39:02.312264", "last_modify_anterior": "2020-03-26T22:20:56.61723", "vencimiento_token_nuevo": "2020-03-28T11:38:22.471872", "vencimiento_token_anterior": "2020-03-27T22:20:50.87023"}	4
16	2020-03-27 11:45:29.317535	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "ab8761ee89af37efe137ce8218f646d03c08d7c53b1dfbf6cb2541481d57e49d", "token_anterior": "2a3a24d5b86b63003e8dff6fcc59ef38b8bf32c6d368938c7f6a0e5a60ed5ffa", "last_modify_nuevo": "2020-03-27T11:45:29.312468", "last_modify_anterior": "2020-03-27T11:39:02.312264", "vencimiento_token_nuevo": "2020-03-28T11:45:18.395466", "vencimiento_token_anterior": "2020-03-28T11:38:22.471872"}	4
17	2020-03-27 13:07:11.388924	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "7c25204cbcb6ac93f81d721340df706d52731100c21f5d340f11abef479726ca", "token_anterior": "ab8761ee89af37efe137ce8218f646d03c08d7c53b1dfbf6cb2541481d57e49d", "last_modify_nuevo": "2020-03-27T13:07:10.650269", "last_modify_anterior": "2020-03-27T11:45:29.312468", "vencimiento_token_nuevo": "2020-03-28T13:06:55.478268", "vencimiento_token_anterior": "2020-03-28T11:45:18.395466"}	4
18	2020-03-27 13:07:11.388738	UPDATE	usuario	usuario	Sistema	postgres	{"last_modify_nuevo": "2020-03-27T13:07:09.471271", "last_modify_anterior": "2020-03-27T13:07:10.650269", "vencimiento_token_nuevo": "2020-03-28T13:06:55.095268", "vencimiento_token_anterior": "2020-03-28T13:06:55.478268"}	4
19	2020-03-27 13:07:12.336213	UPDATE	usuario	usuario	Sistema	postgres	{"last_modify_nuevo": "2020-03-27T13:07:12.305268", "last_modify_anterior": "2020-03-27T13:07:09.471271", "vencimiento_token_nuevo": "2020-03-28T13:06:55.754269", "vencimiento_token_anterior": "2020-03-28T13:06:55.095268"}	4
20	2020-03-27 13:07:32.012448	UPDATE	usuario	usuario	Sistema	postgres	{"token_nuevo": "710a9c3d96ab984bec58318c2679fb65c2e62ffe8a1cd8e7f171ae44c582f41f", "token_anterior": "7c25204cbcb6ac93f81d721340df706d52731100c21f5d340f11abef479726ca", "last_modify_nuevo": "2020-03-27T13:07:32.006269", "last_modify_anterior": "2020-03-27T13:07:12.305268", "vencimiento_token_nuevo": "2020-03-28T13:07:24.411269", "vencimiento_token_anterior": "2020-03-28T13:06:55.754269"}	4
21	2020-03-27 13:12:14.879523	UPDATE	usuario	usuario	Sistema	postgres	{"estado_id_nuevo": 1, "estado_id_anterior": 2}	4
22	2020-03-27 13:12:28.79607	UPDATE	usuario	usuario	Sistema	postgres	{}	4
23	2020-03-27 13:28:23.574142	UPDATE	usuario	usuario	3	postgres	{"correo_nuevo": "jhony2010j222@gmail.com", "correo_anterior": "jalejandro@gmail.com"}	6
24	2020-03-27 13:29:41.67705	UPDATE	usuario	usuario	Sistema	postgres	{"session_nuevo": "Sistema", "password_nuevo": "", "estado_id_nuevo": 2, "session_anterior": "3", "password_anterior": "12345", "estado_id_anterior": 1}	6
25	2020-03-27 13:49:55.505394	UPDATE	usuario	usuario	jalejandro	postgres	{"session_nuevo": "jalejandro", "password_nuevo": "sandra", "estado_id_nuevo": 1, "session_anterior": "Sistema", "last_modify_nuevo": "2020-03-27T13:49:54.295586", "password_anterior": "", "estado_id_anterior": 2, "last_modify_anterior": "2020-03-27T13:29:41.657134"}	6
26	2020-03-27 16:01:20.43818	UPDATE	usuario	usuario	Sistema	postgres	{"password_nuevo": "12345", "password_anterior": ""}	4
27	2020-03-27 16:24:33.995197	UPDATE	usuario	usuario	2	postgres	{}	5
28	2020-03-27 16:24:33.995197	UPDATE	usuario	usuario	jalejandro	postgres	{}	6
29	2020-03-27 16:24:33.995197	UPDATE	usuario	usuario	Sistema	postgres	{}	4
30	2020-03-27 16:29:34.541549	UPDATE	usuario	usuario	2	postgres	{}	5
31	2020-03-27 16:29:34.541549	UPDATE	usuario	usuario	jalejandro	postgres	{}	6
32	2020-03-27 16:29:34.541549	UPDATE	usuario	usuario	Sistema	postgres	{}	4
33	2020-03-28 12:55:11.960045	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 2, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T12:55:10.643457", "fecha_inicio_nuevo": "2020-03-28T12:55:10.642459"}	2
34	2020-03-28 13:03:47.671508	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 3, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:03:47.146381", "fecha_inicio_nuevo": "2020-03-28T13:03:47.146381"}	3
35	2020-03-28 13:10:36.379707	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 4, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:10:36.214273", "fecha_inicio_nuevo": "2020-03-28T13:10:36.214273"}	4
36	2020-03-28 13:11:44.281221	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 5, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:11:44.079732", "fecha_inicio_nuevo": "2020-03-28T13:11:44.079732"}	5
37	2020-03-28 13:14:29.683914	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 6, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:14:28.862738", "fecha_inicio_nuevo": "2020-03-28T13:14:28.862738"}	6
38	2020-03-28 13:19:16.920682	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 7, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:19:16.798469", "fecha_inicio_nuevo": "2020-03-28T13:19:16.798469"}	7
39	2020-03-28 13:30:21.092282	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 8, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:30:15.649244", "fecha_inicio_nuevo": "2020-03-28T13:30:15.649244"}	8
40	2020-03-28 13:32:16.315319	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 9, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:32:15.833653", "fecha_inicio_nuevo": "2020-03-28T13:32:15.833653"}	9
41	2020-03-28 13:32:54.368808	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 10, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:32:54.17747", "fecha_inicio_nuevo": "2020-03-28T13:32:54.17747"}	10
42	2020-03-28 13:37:54.628003	INSERT	seguridad	autenticacion	053huw4wu2wx0ngxkey0gyuh	postgres	{"id_nuevo": 11, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "053huw4wu2wx0ngxkey0gyuh", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:37:54.10203", "fecha_inicio_nuevo": "2020-03-28T13:37:54.10203"}	11
43	2020-03-28 13:38:46.586519	INSERT	seguridad	autenticacion	f2ysqtdkwmgmn4wvz3z21gee	postgres	{"id_nuevo": 12, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "f2ysqtdkwmgmn4wvz3z21gee", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:38:46.38006", "fecha_inicio_nuevo": "2020-03-28T13:38:46.38006"}	12
44	2020-03-28 13:39:55.554462	INSERT	seguridad	autenticacion	u5bvr5cejrr5m1reou4jzj55	postgres	{"id_nuevo": 13, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "u5bvr5cejrr5m1reou4jzj55", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:39:55.318808", "fecha_inicio_nuevo": "2020-03-28T13:39:55.318808"}	13
45	2020-03-28 13:44:08.852477	INSERT	seguridad	autenticacion	dpllzezk4vv51dvkilm5po5n	postgres	{"id_nuevo": 14, "ip_nuevo": "192.168.42.52", "mac_nuevo": "4CEDFB4E4F32", "session_nuevo": "dpllzezk4vv51dvkilm5po5n", "user_id_nuevo": 1, "fecha_fin_nuevo": "2020-03-28T13:44:08.710303", "fecha_inicio_nuevo": "2020-03-28T13:44:08.710303"}	14
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                 2897.dat                                                                                            0000600 0004000 0002000 00000003010 13637716273 0014274 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	192.168.42.52	4CEDFB4E4F32	2020-03-27 20:44:52.936698	2020-03-27 20:44:52.936698	nmka0z1nflwkglw1d2yfhydt
2	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 12:55:10.642459	2020-03-28 12:55:10.643457	053huw4wu2wx0ngxkey0gyuh
3	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:03:47.146381	2020-03-28 13:03:47.146381	053huw4wu2wx0ngxkey0gyuh
4	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:10:36.214273	2020-03-28 13:10:36.214273	053huw4wu2wx0ngxkey0gyuh
5	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:11:44.079732	2020-03-28 13:11:44.079732	053huw4wu2wx0ngxkey0gyuh
6	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:14:28.862738	2020-03-28 13:14:28.862738	053huw4wu2wx0ngxkey0gyuh
7	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:19:16.798469	2020-03-28 13:19:16.798469	053huw4wu2wx0ngxkey0gyuh
8	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:30:15.649244	2020-03-28 13:30:15.649244	053huw4wu2wx0ngxkey0gyuh
9	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:32:15.833653	2020-03-28 13:32:15.833653	053huw4wu2wx0ngxkey0gyuh
10	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:32:54.17747	2020-03-28 13:32:54.17747	053huw4wu2wx0ngxkey0gyuh
11	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:37:54.10203	2020-03-28 13:37:54.10203	053huw4wu2wx0ngxkey0gyuh
12	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:38:46.38006	2020-03-28 13:38:46.38006	f2ysqtdkwmgmn4wvz3z21gee
13	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:39:55.318808	2020-03-28 13:39:55.318808	u5bvr5cejrr5m1reou4jzj55
14	1	192.168.42.52	4CEDFB4E4F32	2020-03-28 13:44:08.710303	2020-03-28 13:44:08.710303	dpllzezk4vv51dvkilm5po5n
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        2885.dat                                                                                            0000600 0004000 0002000 00000000071 13637716273 0014275 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        2	Operario	a	\N
3	Administrador	b	\N
1	Usuario	c	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                       2887.dat                                                                                            0000600 0004000 0002000 00000000647 13637716273 0014310 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        5	erika	erikamoreno	erika@gmail.com	12345	320	facatativa	2	2	2020-03-27 13:49:54.295586	1	token	2020-03-27 13:49:54.295586
6	alejandro	jalejandro	jhony2010j222@gmail.com	sandra	210	mosquera	3	jalejandro	2020-03-27 13:49:54.295586	1	token	2020-03-27 13:49:54.295586
4	sandra	sandramoreno	sandra.duarte0806@gmail.com	12345	310	hacienda el pedregal	1	Sistema	2020-03-27 13:49:54.295586	1	token	2020-03-27 13:49:54.295586
\.


                                                                                         restore.sql                                                                                         0000600 0004000 0002000 00000062704 13637716273 0015414 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5
-- Dumped by pg_dump version 12.0

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

DROP DATABASE "Gran_Fruver";
--
-- Name: Gran_Fruver; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "Gran_Fruver" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';


ALTER DATABASE "Gran_Fruver" OWNER TO postgres;

\connect "Gran_Fruver"

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

--
-- Name: DATABASE "Gran_Fruver"; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE "Gran_Fruver" IS 'Bd Gran Fruver';


--
-- Name: producto; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA producto;


ALTER SCHEMA producto OWNER TO postgres;

--
-- Name: SCHEMA producto; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA producto IS 'Esquema de productos';


--
-- Name: seguridad; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA seguridad;


ALTER SCHEMA seguridad OWNER TO postgres;

--
-- Name: SCHEMA seguridad; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';


--
-- Name: usuario; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA usuario;


ALTER SCHEMA usuario OWNER TO postgres;

--
-- Name: SCHEMA usuario; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA usuario IS 'Esquema de usuario';


--
-- Name: f_log_auditoria(); Type: FUNCTION; Schema: seguridad; Owner: postgres
--

CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	 DECLARE
		_pk TEXT :='';		-- Representa la llave primaria de la tabla que esta siedno modificada.
		_sql TEXT;		-- Variable para la creacion del procedured.
		_column_guia RECORD; 	-- Variable para el FOR guarda los nombre de las columnas.
		_column_key RECORD; 	-- Variable para el FOR guarda los PK de las columnas.
		_session TEXT;	-- Almacena el usuario que genera el cambio.
		_user_db TEXT;		-- Almacena el usuario de bd que genera la transaccion.
		_control INT;		-- Variabel de control par alas llaves primarias.
		_count_key INT = 0;	-- Cantidad de columnas pertenecientes al PK.
		_sql_insert TEXT;	-- Variable para la construcción del insert del json de forma dinamica.
		_sql_delete TEXT;	-- Variable para la construcción del delete del json de forma dinamica.
		_sql_update TEXT;	-- Variable para la construcción del update del json de forma dinamica.
		_new_data RECORD; 	-- Fila que representa los campos nuevos del registro.
		_old_data RECORD;	-- Fila que representa los campos viejos del registro.

	BEGIN

			-- Se genera la evaluacion para determianr el tipo de accion sobre la tabla
		 IF (TG_OP = 'INSERT') THEN
			_new_data := NEW;
			_old_data := NEW;
		ELSEIF (TG_OP = 'UPDATE') THEN
			_new_data := NEW;
			_old_data := OLD;
		ELSE
			_new_data := OLD;
			_old_data := OLD;
		END IF;

		-- Se genera la evaluacion para determianr el tipo de accion sobre la tabla
		IF ((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME AND column_name = 'id' ) > 0) THEN
			_pk := _new_data.id;
		ELSE
			_pk := '-1';
		END IF;

		-- Se valida que exista el campo modified_by
		IF ((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME AND column_name = 'session') > 0) THEN
			_session := _new_data.session;
		ELSE
			_session := '';
		END IF;

		-- Se guarda el susuario de bd que genera la transaccion
		_user_db := (SELECT CURRENT_USER);

		-- Se evalua que exista el procedimeinto adecuado
		IF (SELECT COUNT(*) FROM seguridad.function_db_view acfdv WHERE acfdv.b_function = 'field_audit' AND acfdv.b_type_parameters = TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', character varying, character varying, character varying, text, character varying, text, text') > 0
			THEN
				-- Se realiza la invocación del procedured generado dinamivamente
				PERFORM seguridad.field_audit(_new_data, _old_data, TG_OP, _session, _user_db , _pk, ''::text);
		ELSE
			-- Se empieza la construcción del Procedured generico
			_sql := 'CREATE OR REPLACE FUNCTION seguridad.field_audit( _data_new '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', _data_old '|| TG_TABLE_SCHEMA || '.'|| TG_TABLE_NAME || ', _accion character varying, _session text, _user_db character varying, _table_pk text, _init text)'
			|| ' RETURNS TEXT AS ''
'
			|| '
'
	|| '	DECLARE
'
	|| '		_column_data TEXT;
	 	_datos jsonb;
	 	
'
	|| '	BEGIN
			_datos = ''''{}'''';
';
			-- Se evalua si hay que actualizar la pk del registro de auditoria.
			IF _pk = '-1'
				THEN
					_sql := _sql
					|| '
		_column_data := ';

					-- Se genera el update con la clave pk de la tabla
					SELECT
						COUNT(isk.column_name)
					INTO
						_control
					FROM
						information_schema.table_constraints istc JOIN information_schema.key_column_usage isk ON isk.constraint_name = istc.constraint_name
					WHERE
						istc.table_schema = TG_TABLE_SCHEMA
					 AND	istc.table_name = TG_TABLE_NAME
					 AND	istc.constraint_type ilike '%primary%';

					-- Se agregan las columnas que componen la pk de la tabla.
					FOR _column_key IN SELECT
							isk.column_name
						FROM
							information_schema.table_constraints istc JOIN information_schema.key_column_usage isk ON isk.constraint_name = istc.constraint_name
						WHERE
							istc.table_schema = TG_TABLE_SCHEMA
						 AND	istc.table_name = TG_TABLE_NAME
						 AND	istc.constraint_type ilike '%primary%'
						ORDER BY 
							isk.ordinal_position  LOOP

						_sql := _sql || ' _data_new.' || _column_key.column_name;
						
						_count_key := _count_key + 1 ;
						
						IF _count_key < _control THEN
							_sql :=	_sql || ' || ' || ''''',''''' || ' ||';
						END IF;
					END LOOP;
				_sql := _sql || ';';
			END IF;

			_sql_insert:='
		IF _accion = ''''INSERT''''
			THEN
				';
			_sql_delete:='
		ELSEIF _accion = ''''DELETE''''
			THEN
				';
			_sql_update:='
		ELSE
			';

			-- Se genera el ciclo de agregado de columnas para el nuevo procedured
			FOR _column_guia IN SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME
				LOOP
						
					_sql_insert:= _sql_insert || '_datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_nuevo'
					|| ''''', '
					|| '_data_new.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_insert:= _sql_insert
						||'::text';
					END IF;

					_sql_insert:= _sql_insert || ')::jsonb;
				';

					_sql_delete := _sql_delete || '_datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_anterior'
					|| ''''', '
					|| '_data_old.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_delete:= _sql_delete
						||'::text';
					END IF;

					_sql_delete:= _sql_delete || ')::jsonb;
				';

					_sql_update := _sql_update || 'IF _data_old.' || _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update || ' <> _data_new.' || _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update || '
				THEN _datos := _datos || json_build_object('''''
					|| _column_guia.column_name
					|| '_anterior'
					|| ''''', '
					|| '_data_old.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea','USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update
					|| ', '''''
					|| _column_guia.column_name
					|| '_nuevo'
					|| ''''', _data_new.'
					|| _column_guia.column_name;

					IF _column_guia.data_type IN ('bytea', 'USER-DEFINED') THEN 
						_sql_update:= _sql_update
						||'::text';
					END IF;

					_sql_update:= _sql_update
					|| ')::jsonb;
			END IF;
			';
			END LOOP;

			-- Se le agrega la parte final del procedured generico
			
			_sql:= _sql || _sql_insert || _sql_delete || _sql_update
			|| ' 
		END IF;

		INSERT INTO seguridad.auditoria
		(
			fecha,
			accion,
			schema,
			tabla,
			pk,
			session,
			user_bd,
			data
		)
		VALUES
		(
			CURRENT_TIMESTAMP,
			_accion,
			''''' || TG_TABLE_SCHEMA || ''''',
			''''' || TG_TABLE_NAME || ''''',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;'''
|| '
LANGUAGE plpgsql;';

			-- Se genera la ejecución de _sql, es decir se crea el nuevo procedured de forma generica.
			EXECUTE _sql;

		-- Se realiza la invocación del procedured generado dinamivamente
			PERFORM seguridad.field_audit(_new_data, _old_data, TG_OP::character varying, _session, _user_db, _pk, ''::text);

		END IF;

		RETURN NULL;

END;
$$;


ALTER FUNCTION seguridad.f_log_auditoria() OWNER TO postgres;

SET default_tablespace = '';

--
-- Name: autenticacion; Type: TABLE; Schema: seguridad; Owner: postgres
--

CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);


ALTER TABLE seguridad.autenticacion OWNER TO postgres;

--
-- Name: field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text); Type: FUNCTION; Schema: seguridad; Owner: postgres
--

CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
    LANGUAGE plpgsql
    AS $$

	DECLARE
		_column_data TEXT;
	 	_datos jsonb;
	 	
	BEGIN
			_datos = '{}';

		IF _accion = 'INSERT'
			THEN
				_datos := _datos || json_build_object('id_nuevo', _data_new.id)::jsonb;
				_datos := _datos || json_build_object('user_id_nuevo', _data_new.user_id)::jsonb;
				_datos := _datos || json_build_object('ip_nuevo', _data_new.ip)::jsonb;
				_datos := _datos || json_build_object('mac_nuevo', _data_new.mac)::jsonb;
				_datos := _datos || json_build_object('fecha_inicio_nuevo', _data_new.fecha_inicio)::jsonb;
				_datos := _datos || json_build_object('fecha_fin_nuevo', _data_new.fecha_fin)::jsonb;
				_datos := _datos || json_build_object('session_nuevo', _data_new.session)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('user_id_anterior', _data_old.user_id)::jsonb;
				_datos := _datos || json_build_object('ip_anterior', _data_old.ip)::jsonb;
				_datos := _datos || json_build_object('mac_anterior', _data_old.mac)::jsonb;
				_datos := _datos || json_build_object('fecha_inicio_anterior', _data_old.fecha_inicio)::jsonb;
				_datos := _datos || json_build_object('fecha_fin_anterior', _data_old.fecha_fin)::jsonb;
				_datos := _datos || json_build_object('session_anterior', _data_old.session)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.user_id <> _data_new.user_id
				THEN _datos := _datos || json_build_object('user_id_anterior', _data_old.user_id, 'user_id_nuevo', _data_new.user_id)::jsonb;
			END IF;
			IF _data_old.ip <> _data_new.ip
				THEN _datos := _datos || json_build_object('ip_anterior', _data_old.ip, 'ip_nuevo', _data_new.ip)::jsonb;
			END IF;
			IF _data_old.mac <> _data_new.mac
				THEN _datos := _datos || json_build_object('mac_anterior', _data_old.mac, 'mac_nuevo', _data_new.mac)::jsonb;
			END IF;
			IF _data_old.fecha_inicio <> _data_new.fecha_inicio
				THEN _datos := _datos || json_build_object('fecha_inicio_anterior', _data_old.fecha_inicio, 'fecha_inicio_nuevo', _data_new.fecha_inicio)::jsonb;
			END IF;
			IF _data_old.fecha_fin <> _data_new.fecha_fin
				THEN _datos := _datos || json_build_object('fecha_fin_anterior', _data_old.fecha_fin, 'fecha_fin_nuevo', _data_new.fecha_fin)::jsonb;
			END IF;
			IF _data_old.session <> _data_new.session
				THEN _datos := _datos || json_build_object('session_anterior', _data_old.session, 'session_nuevo', _data_new.session)::jsonb;
			END IF;
			 
		END IF;

		INSERT INTO seguridad.auditoria
		(
			fecha,
			accion,
			schema,
			tabla,
			pk,
			session,
			user_bd,
			data
		)
		VALUES
		(
			CURRENT_TIMESTAMP,
			_accion,
			'seguridad',
			'autenticacion',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;


ALTER FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) OWNER TO postgres;

--
-- Name: detalle_lote; Type: TABLE; Schema: producto; Owner: postgres
--

CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL
);


ALTER TABLE producto.detalle_lote OWNER TO postgres;

--
-- Name: detalle_lote_id_seq; Type: SEQUENCE; Schema: producto; Owner: postgres
--

CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE producto.detalle_lote_id_seq OWNER TO postgres;

--
-- Name: detalle_lote_id_seq; Type: SEQUENCE OWNED BY; Schema: producto; Owner: postgres
--

ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;


--
-- Name: lote; Type: TABLE; Schema: producto; Owner: postgres
--

CREATE TABLE producto.lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    fecha timestamp without time zone NOT NULL,
    proveedor text NOT NULL,
    detalle_lote_id integer NOT NULL
);


ALTER TABLE producto.lote OWNER TO postgres;

--
-- Name: lote_id_seq; Type: SEQUENCE; Schema: producto; Owner: postgres
--

CREATE SEQUENCE producto.lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE producto.lote_id_seq OWNER TO postgres;

--
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: producto; Owner: postgres
--

ALTER SEQUENCE producto.lote_id_seq OWNED BY producto.lote.id;


--
-- Name: producto; Type: TABLE; Schema: producto; Owner: postgres
--

CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL,
    precio integer NOT NULL,
    fecha_ingreso timestamp without time zone NOT NULL
);


ALTER TABLE producto.producto OWNER TO postgres;

--
-- Name: producto_id_seq; Type: SEQUENCE; Schema: producto; Owner: postgres
--

CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE producto.producto_id_seq OWNER TO postgres;

--
-- Name: producto_id_seq; Type: SEQUENCE OWNED BY; Schema: producto; Owner: postgres
--

ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: seguridad; Owner: postgres
--

CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seguridad.auditoria_id_seq OWNER TO postgres;

--
-- Name: auditoria; Type: TABLE; Schema: seguridad; Owner: postgres
--

CREATE TABLE seguridad.auditoria (
    id bigint DEFAULT nextval('seguridad.auditoria_id_seq'::regclass) NOT NULL,
    fecha timestamp without time zone,
    accion character varying(100),
    schema character varying(200) NOT NULL,
    tabla character varying(200),
    session text NOT NULL,
    user_bd character varying(100) NOT NULL,
    data jsonb NOT NULL,
    pk text NOT NULL
);


ALTER TABLE seguridad.auditoria OWNER TO postgres;

--
-- Name: autenticacion_id_seq; Type: SEQUENCE; Schema: seguridad; Owner: postgres
--

CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seguridad.autenticacion_id_seq OWNER TO postgres;

--
-- Name: autenticacion_id_seq; Type: SEQUENCE OWNED BY; Schema: seguridad; Owner: postgres
--

ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;


--
-- Name: function_db_view; Type: VIEW; Schema: seguridad; Owner: postgres
--

CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));


ALTER TABLE seguridad.function_db_view OWNER TO postgres;

--
-- Name: rol; Type: TABLE; Schema: usuario; Owner: postgres
--

CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);


ALTER TABLE usuario.rol OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE; Schema: usuario; Owner: postgres
--

CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usuario.rol_id_seq OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: usuario; Owner: postgres
--

ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;


--
-- Name: usuario; Type: TABLE; Schema: usuario; Owner: postgres
--

CREATE TABLE usuario.usuario (
    id integer NOT NULL,
    nombre text NOT NULL,
    user_name text NOT NULL,
    correo text NOT NULL,
    password text NOT NULL,
    celular integer NOT NULL,
    direccion text NOT NULL,
    rol_id integer,
    session text,
    last_modify timestamp without time zone,
    estado_id integer DEFAULT 1,
    token text,
    vencimiento_token timestamp without time zone
);


ALTER TABLE usuario.usuario OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: usuario; Owner: postgres
--

CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usuario.usuario_id_seq OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: usuario; Owner: postgres
--

ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;


--
-- Name: detalle_lote id; Type: DEFAULT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);


--
-- Name: lote id; Type: DEFAULT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.lote ALTER COLUMN id SET DEFAULT nextval('producto.lote_id_seq'::regclass);


--
-- Name: producto id; Type: DEFAULT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);


--
-- Name: autenticacion id; Type: DEFAULT; Schema: seguridad; Owner: postgres
--

ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);


--
-- Name: rol id; Type: DEFAULT; Schema: usuario; Owner: postgres
--

ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: usuario; Owner: postgres
--

ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);


--
-- Data for Name: detalle_lote; Type: TABLE DATA; Schema: producto; Owner: postgres
--

COPY producto.detalle_lote (id, nombre, cantidad, precio, producto_id) FROM stdin;
\.
COPY producto.detalle_lote (id, nombre, cantidad, precio, producto_id) FROM '$$PATH$$/2893.dat';

--
-- Data for Name: lote; Type: TABLE DATA; Schema: producto; Owner: postgres
--

COPY producto.lote (id, nombre, fecha, proveedor, detalle_lote_id) FROM stdin;
\.
COPY producto.lote (id, nombre, fecha, proveedor, detalle_lote_id) FROM '$$PATH$$/2891.dat';

--
-- Data for Name: producto; Type: TABLE DATA; Schema: producto; Owner: postgres
--

COPY producto.producto (id, nombre, imagen, fecha_vencimiento, precio, fecha_ingreso) FROM stdin;
\.
COPY producto.producto (id, nombre, imagen, fecha_vencimiento, precio, fecha_ingreso) FROM '$$PATH$$/2889.dat';

--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: seguridad; Owner: postgres
--

COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
\.
COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM '$$PATH$$/2895.dat';

--
-- Data for Name: autenticacion; Type: TABLE DATA; Schema: seguridad; Owner: postgres
--

COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
\.
COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM '$$PATH$$/2897.dat';

--
-- Data for Name: rol; Type: TABLE DATA; Schema: usuario; Owner: postgres
--

COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
\.
COPY usuario.rol (id, nombre, session, last_modify) FROM '$$PATH$$/2885.dat';

--
-- Data for Name: usuario; Type: TABLE DATA; Schema: usuario; Owner: postgres
--

COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
\.
COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM '$$PATH$$/2887.dat';

--
-- Name: detalle_lote_id_seq; Type: SEQUENCE SET; Schema: producto; Owner: postgres
--

SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 1, false);


--
-- Name: lote_id_seq; Type: SEQUENCE SET; Schema: producto; Owner: postgres
--

SELECT pg_catalog.setval('producto.lote_id_seq', 1, false);


--
-- Name: producto_id_seq; Type: SEQUENCE SET; Schema: producto; Owner: postgres
--

SELECT pg_catalog.setval('producto.producto_id_seq', 1, false);


--
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: seguridad; Owner: postgres
--

SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 45, true);


--
-- Name: autenticacion_id_seq; Type: SEQUENCE SET; Schema: seguridad; Owner: postgres
--

SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 14, true);


--
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: usuario; Owner: postgres
--

SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: usuario; Owner: postgres
--

SELECT pg_catalog.setval('usuario.usuario_id_seq', 6, true);


--
-- Name: detalle_lote detalle_lote_pkey; Type: CONSTRAINT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);


--
-- Name: lote lote_pkey; Type: CONSTRAINT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: producto; Owner: postgres
--

ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: postgres
--

ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: autenticacion autenticacion_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: postgres
--

ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: usuario; Owner: postgres
--

ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: usuario; Owner: postgres
--

ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: autenticacion tg_seguridad_autenticacion; Type: TRIGGER; Schema: seguridad; Owner: postgres
--

CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();


--
-- Name: rol tg_usuario_rol; Type: TRIGGER; Schema: usuario; Owner: postgres
--

CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();


--
-- Name: usuario tg_usuario_usuario; Type: TRIGGER; Schema: usuario; Owner: postgres
--

CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            