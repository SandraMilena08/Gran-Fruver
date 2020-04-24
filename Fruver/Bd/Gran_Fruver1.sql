PGDMP                         x            Gran_Fruver    11.5    12.0 B    W           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            X           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            Y           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            Z           1262    27696    Gran_Fruver    DATABASE     �   CREATE DATABASE "Gran_Fruver" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE "Gran_Fruver";
                postgres    false                        2615    27793    operario    SCHEMA        CREATE SCHEMA operario;
    DROP SCHEMA operario;
                postgres    false                        2615    27697    producto    SCHEMA        CREATE SCHEMA producto;
    DROP SCHEMA producto;
                postgres    false            [           0    0    SCHEMA producto    COMMENT     6   COMMENT ON SCHEMA producto IS 'Esquema de productos';
                   postgres    false    11                        2615    27698 	   seguridad    SCHEMA        CREATE SCHEMA seguridad;
    DROP SCHEMA seguridad;
                postgres    false            \           0    0    SCHEMA seguridad    COMMENT     7   COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';
                   postgres    false    5            	            2615    27699    usuario    SCHEMA        CREATE SCHEMA usuario;
    DROP SCHEMA usuario;
                postgres    false            ]           0    0    SCHEMA usuario    COMMENT     3   COMMENT ON SCHEMA usuario IS 'Esquema de usuario';
                   postgres    false    9            �            1255    27700    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
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
    	   seguridad          postgres    false    5            �            1259    27702    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);
 $   DROP TABLE seguridad.autenticacion;
    	   seguridad            postgres    false    5            �            1255    27708 u   field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text)    FUNCTION     m  CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    200    5    200            �            1259    27749    rol    TABLE     �   CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);
    DROP TABLE usuario.rol;
       usuario            postgres    false    9            �            1255    27790 ]   field_audit(usuario.rol, usuario.rol, character varying, text, character varying, text, text)    FUNCTION     @  CREATE FUNCTION seguridad.field_audit(_data_new usuario.rol, _data_old usuario.rol, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('nombre_nuevo', _data_new.nombre)::jsonb;
				_datos := _datos || json_build_object('session_nuevo', _data_new.session)::jsonb;
				_datos := _datos || json_build_object('last_modify_nuevo', _data_new.last_modify)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('nombre_anterior', _data_old.nombre)::jsonb;
				_datos := _datos || json_build_object('session_anterior', _data_old.session)::jsonb;
				_datos := _datos || json_build_object('last_modify_anterior', _data_old.last_modify)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.nombre <> _data_new.nombre
				THEN _datos := _datos || json_build_object('nombre_anterior', _data_old.nombre, 'nombre_nuevo', _data_new.nombre)::jsonb;
			END IF;
			IF _data_old.session <> _data_new.session
				THEN _datos := _datos || json_build_object('session_anterior', _data_old.session, 'session_nuevo', _data_new.session)::jsonb;
			END IF;
			IF _data_old.last_modify <> _data_new.last_modify
				THEN _datos := _datos || json_build_object('last_modify_anterior', _data_old.last_modify, 'last_modify_nuevo', _data_new.last_modify)::jsonb;
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
			'usuario',
			'rol',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new usuario.rol, _data_old usuario.rol, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    5    211    211            �            1259    27757    usuario    TABLE     �  CREATE TABLE usuario.usuario (
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
       usuario            postgres    false    9            �            1255    27789 e   field_audit(usuario.usuario, usuario.usuario, character varying, text, character varying, text, text)    FUNCTION       CREATE FUNCTION seguridad.field_audit(_data_new usuario.usuario, _data_old usuario.usuario, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('nombre_nuevo', _data_new.nombre)::jsonb;
				_datos := _datos || json_build_object('user_name_nuevo', _data_new.user_name)::jsonb;
				_datos := _datos || json_build_object('correo_nuevo', _data_new.correo)::jsonb;
				_datos := _datos || json_build_object('password_nuevo', _data_new.password)::jsonb;
				_datos := _datos || json_build_object('celular_nuevo', _data_new.celular)::jsonb;
				_datos := _datos || json_build_object('direccion_nuevo', _data_new.direccion)::jsonb;
				_datos := _datos || json_build_object('rol_id_nuevo', _data_new.rol_id)::jsonb;
				_datos := _datos || json_build_object('session_nuevo', _data_new.session)::jsonb;
				_datos := _datos || json_build_object('last_modify_nuevo', _data_new.last_modify)::jsonb;
				_datos := _datos || json_build_object('estado_id_nuevo', _data_new.estado_id)::jsonb;
				_datos := _datos || json_build_object('token_nuevo', _data_new.token)::jsonb;
				_datos := _datos || json_build_object('vencimiento_token_nuevo', _data_new.vencimiento_token)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('nombre_anterior', _data_old.nombre)::jsonb;
				_datos := _datos || json_build_object('user_name_anterior', _data_old.user_name)::jsonb;
				_datos := _datos || json_build_object('correo_anterior', _data_old.correo)::jsonb;
				_datos := _datos || json_build_object('password_anterior', _data_old.password)::jsonb;
				_datos := _datos || json_build_object('celular_anterior', _data_old.celular)::jsonb;
				_datos := _datos || json_build_object('direccion_anterior', _data_old.direccion)::jsonb;
				_datos := _datos || json_build_object('rol_id_anterior', _data_old.rol_id)::jsonb;
				_datos := _datos || json_build_object('session_anterior', _data_old.session)::jsonb;
				_datos := _datos || json_build_object('last_modify_anterior', _data_old.last_modify)::jsonb;
				_datos := _datos || json_build_object('estado_id_anterior', _data_old.estado_id)::jsonb;
				_datos := _datos || json_build_object('token_anterior', _data_old.token)::jsonb;
				_datos := _datos || json_build_object('vencimiento_token_anterior', _data_old.vencimiento_token)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.nombre <> _data_new.nombre
				THEN _datos := _datos || json_build_object('nombre_anterior', _data_old.nombre, 'nombre_nuevo', _data_new.nombre)::jsonb;
			END IF;
			IF _data_old.user_name <> _data_new.user_name
				THEN _datos := _datos || json_build_object('user_name_anterior', _data_old.user_name, 'user_name_nuevo', _data_new.user_name)::jsonb;
			END IF;
			IF _data_old.correo <> _data_new.correo
				THEN _datos := _datos || json_build_object('correo_anterior', _data_old.correo, 'correo_nuevo', _data_new.correo)::jsonb;
			END IF;
			IF _data_old.password <> _data_new.password
				THEN _datos := _datos || json_build_object('password_anterior', _data_old.password, 'password_nuevo', _data_new.password)::jsonb;
			END IF;
			IF _data_old.celular <> _data_new.celular
				THEN _datos := _datos || json_build_object('celular_anterior', _data_old.celular, 'celular_nuevo', _data_new.celular)::jsonb;
			END IF;
			IF _data_old.direccion <> _data_new.direccion
				THEN _datos := _datos || json_build_object('direccion_anterior', _data_old.direccion, 'direccion_nuevo', _data_new.direccion)::jsonb;
			END IF;
			IF _data_old.rol_id <> _data_new.rol_id
				THEN _datos := _datos || json_build_object('rol_id_anterior', _data_old.rol_id, 'rol_id_nuevo', _data_new.rol_id)::jsonb;
			END IF;
			IF _data_old.session <> _data_new.session
				THEN _datos := _datos || json_build_object('session_anterior', _data_old.session, 'session_nuevo', _data_new.session)::jsonb;
			END IF;
			IF _data_old.last_modify <> _data_new.last_modify
				THEN _datos := _datos || json_build_object('last_modify_anterior', _data_old.last_modify, 'last_modify_nuevo', _data_new.last_modify)::jsonb;
			END IF;
			IF _data_old.estado_id <> _data_new.estado_id
				THEN _datos := _datos || json_build_object('estado_id_anterior', _data_old.estado_id, 'estado_id_nuevo', _data_new.estado_id)::jsonb;
			END IF;
			IF _data_old.token <> _data_new.token
				THEN _datos := _datos || json_build_object('token_anterior', _data_old.token, 'token_nuevo', _data_new.token)::jsonb;
			END IF;
			IF _data_old.vencimiento_token <> _data_new.vencimiento_token
				THEN _datos := _datos || json_build_object('vencimiento_token_anterior', _data_old.vencimiento_token, 'vencimiento_token_nuevo', _data_new.vencimiento_token)::jsonb;
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
			'usuario',
			'usuario',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new usuario.usuario, _data_old usuario.usuario, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    213    5    213            �            1259    27709    detalle_lote    TABLE     �   CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    11            �            1259    27715    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    201    11            ^           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    202            �            1259    27717    lote    TABLE     �   CREATE TABLE producto.lote (
    id integer NOT NULL,
    nombre text NOT NULL,
    fecha timestamp without time zone NOT NULL,
    proveedor text NOT NULL,
    detalle_lote_id integer NOT NULL
);
    DROP TABLE producto.lote;
       producto            postgres    false    11            �            1259    27723    lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE producto.lote_id_seq;
       producto          postgres    false    203    11            _           0    0    lote_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE producto.lote_id_seq OWNED BY producto.lote.id;
          producto          postgres    false    204            �            1259    27725    producto    TABLE       CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL,
    precio integer NOT NULL,
    fecha_ingreso timestamp without time zone NOT NULL
);
    DROP TABLE producto.producto;
       producto            postgres    false    11            �            1259    27731    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    205    11            `           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
          producto          postgres    false    206            �            1259    27733    auditoria_id_seq    SEQUENCE     |   CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE seguridad.auditoria_id_seq;
    	   seguridad          postgres    false    5            �            1259    27735 	   auditoria    TABLE     �  CREATE TABLE seguridad.auditoria (
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
    	   seguridad            postgres    false    207    5            �            1259    27742    autenticacion_id_seq    SEQUENCE     �   CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE seguridad.autenticacion_id_seq;
    	   seguridad          postgres    false    5    200            a           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
       	   seguridad          postgres    false    209            �            1259    27744    function_db_view    VIEW     �  CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));
 &   DROP VIEW seguridad.function_db_view;
    	   seguridad          postgres    false    5            �            1259    27755 
   rol_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE usuario.rol_id_seq;
       usuario          postgres    false    9    211            b           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    212            �            1259    27764    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    9    213            c           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
          usuario          postgres    false    214            �
           2604    27766    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    202    201            �
           2604    27767    lote id    DEFAULT     f   ALTER TABLE ONLY producto.lote ALTER COLUMN id SET DEFAULT nextval('producto.lote_id_seq'::regclass);
 8   ALTER TABLE producto.lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    204    203            �
           2604    27768    producto id    DEFAULT     n   ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);
 <   ALTER TABLE producto.producto ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    206    205            �
           2604    27769    autenticacion id    DEFAULT     z   ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);
 B   ALTER TABLE seguridad.autenticacion ALTER COLUMN id DROP DEFAULT;
    	   seguridad          postgres    false    209    200            �
           2604    27770    rol id    DEFAULT     b   ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);
 6   ALTER TABLE usuario.rol ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    212    211            �
           2604    27771 
   usuario id    DEFAULT     j   ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);
 :   ALTER TABLE usuario.usuario ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    214    213            H          0    27709    detalle_lote 
   TABLE DATA           S   COPY producto.detalle_lote (id, nombre, cantidad, precio, producto_id) FROM stdin;
    producto          postgres    false    201   ��       J          0    27717    lote 
   TABLE DATA           O   COPY producto.lote (id, nombre, fecha, proveedor, detalle_lote_id) FROM stdin;
    producto          postgres    false    203   �       L          0    27725    producto 
   TABLE DATA           b   COPY producto.producto (id, nombre, imagen, fecha_vencimiento, precio, fecha_ingreso) FROM stdin;
    producto          postgres    false    205   .�       O          0    27735 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    208   K�       G          0    27702    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    200   _�       Q          0    27749    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    211   ��       S          0    27757    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    213   ��       d           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 1, false);
          producto          postgres    false    202            e           0    0    lote_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('producto.lote_id_seq', 1, false);
          producto          postgres    false    204            f           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 1, false);
          producto          postgres    false    206            g           0    0    auditoria_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 180, true);
       	   seguridad          postgres    false    207            h           0    0    autenticacion_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 100, true);
       	   seguridad          postgres    false    209            i           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    212            j           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 31, true);
          usuario          postgres    false    214            �
           2606    27773    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    201            �
           2606    27775    lote lote_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY producto.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY producto.lote DROP CONSTRAINT lote_pkey;
       producto            postgres    false    203            �
           2606    27777    producto producto_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY producto.producto DROP CONSTRAINT producto_pkey;
       producto            postgres    false    205            �
           2606    27779    auditoria auditoria_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY seguridad.auditoria DROP CONSTRAINT auditoria_pkey;
    	   seguridad            postgres    false    208            �
           2606    27781     autenticacion autenticacion_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY seguridad.autenticacion DROP CONSTRAINT autenticacion_pkey;
    	   seguridad            postgres    false    200            �
           2606    27783    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    211            �
           2606    27785    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    213            �
           2620    27786 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    200    215            �
           2620    27787    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    211    215            �
           2620    27788    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    213    215            H      x������ � �      J      x������ � �      L      x������ � �      O      x��}[��8���������;���3=@� rv�4t�U�I�-��=Ey��lJ\��5'��3��Ʋ˥��H�W$K�J�N�ߩ�|�Ռ�)��*x�������������r���@���j~�ʷ���vW���m��v�;���6�*ڦ��o���i��2>�/|~��M����@O����/��	~�щ��W������W~[��OI�ٓ��힞�e��y-7�dWx,l�e?;�6t�n��7���ό����r��>�>���}T���1u?��~�.�Y����������y��̎l���Q��1�6��De�G�K����k�z��0�a0s?ά�� ��9�ڈ3��G���ؕ�:;~���~�7�(o96U
$����?������������H���>H4MQ�ʈ&�m��0�����cH�<A���6��-�d�m��[�����c6�6� ;O���_���'z ���� �?W<�Oڅ'�ē��g��+D11@t���ߔ �L��>��@�vG'{��!�Y�P�	�G,)��Q55@��ޥ����[�YYE����g�O����� �)Ō�) ��4�!��:{�OZp%�p"�<NҔh)��R�T�y�El4�E:�ǩ�!�g�����iYK%aR��Pa4DF&�HcHE
��U,U�y��2�D��)��)Q�o����T:1cr*���l��eYeE��<V��TP����T����xg�!�2�|X#<§&��X��>j�6����n4���s�����0�,R��p�$�f�NT� f1����3I�L�S	Cs�	&J3�n���D���w��>!��	Պ�D�%��T2P�y�S�M��}���A���L5?յ;���22%e�ݟ��'%3a�T���P�?�%1��Jf(��nT� �gQ��1��<3$��пIQG<ɻ�9F���B ��=v�S��jCw*r���7?#���5R� f���25FR�ޤ���8�Ĺ���4�e�$�d9ӱ�sF�2�C��2"��$�R�瞉j��ڛ��(����tb ě�Ѧg��tZ�W��	�7��M���AS�`�0�F�Vp�(g*�3�q�i
:�\��%D�*g�<�eS\R����N�v{s�	��;�:ț�1�NT�p^��|���Ph�����fD� �L�d�)�J���'q�(1,GO)
��4W�.��P������se��gt�%���C@�R*M�?�(�'��3!�'����|��Ɵ��O�����KTA(Lmp_���2L�L�&�Lb����e����0=��"L
W+�}0����DI&F����M�� $2	K��0��q��@'T*��R$4�WXA��L� �b�_�9O&6Ɯ�O�/��(���Q�� ��g,4�ǟ�	��]�Jط=�8;m�Ҷ^���H���6�Ĝ_�����P8�{��O��V�g��^)���>�xB�¶xB��`f�a*�"��E_��W�+]l9���+��}±�\�f���'Z_��\�j��Y���.cp��>�F-�(y����Ϡ
v��>��rF s�)g^�`��v�Ҍ%��|�23�;,�Ӏ��Hg\4p���=S0����1>ńPpj�?ⵎ����a��p:��y8�.���e6���4Jߢ��c�D�t��cvQ�������/��J��z�)���^�B��)H=�t*BYD�Cu����?�+������J�O�G���y�,�?�g����)%ǀW�},�K4�O�ra�F:a�	P\<qVP8� zd@ٟ�wӁK��� ud��!�@l�a�������?9�w�)�(���$�y�
��G5P
#*��6����� @e��]��rK�f�Ȁ�?;��&�Zb��`@e��M���ȩ�Dj:2���hc�Bz{�mA�>��xSf@�Q@�N���?9�h:\��<�'�oz(��3�Ȁ�?;�v�f��"xQz���f&ڀ"�bR��Ӧ��ğQ���y�ȏ7 N]@�����66��g���o�� ��3P=�r�D_���^�C���ż�����n�Y�td��S?��v��$�}A@鄻L��+A�sٻ(�">E���GQ�1��|u[	�td��S?��vv�F�Q!e�r%�gS+A���J�~��e�5?����rS��Nl}��L�|�Cz�]a��I!�����=&�m��b��4���V�J��5[�Y:-�>H}tI�)�������w��)Y'�>�C5�?L�D#�	@�-���	W.���c�*1��X幸��Zͷ�x�[/����C�Ǘ�!��>��t!!��"*'\��
� S��d�l������2����{_¶�n��`˖pI��3�nbE�$J�""M��Y.���4
��挤(O���I�t��v[п%��k���-�z�����f����!�(���vD�n!#?���`*_;��*�~��;�]0�Zy�
����㞓o;��h��`���џ�i��(��=�v�4�BW.���z'�x��1Z��+��%/�g̹Ӄo"��I�M�>�'һ�i�!i['R5�9>#���F��2�=�w����WD�,��&�s!d���:판)��p�ꭘ��=�i{�o�=W9~���#�����97 ��ž�1���s��{���u^I��ПO���W��	�� ���gD�}@G��:��TP�(�qA��䀏��'Љ0��=-ʈ`���a��	��8`\�2��/�_w�U/��$��{�'����^XG�{���^p�RZ{\ /�`]�*�|"����E�+O���NS�f��U6�W�/����k�n�)�������*D��P͸Fƪzk e�����h��/�EUT*��o���O�%Z>�/'Z����)	�-Nw� �z"��(.�v�J+�{ЧKt���zU�|^�-�%K}��6P�!��>ѻ�I��-�u� �f"��(��U�^O&E��D���	�~c��fyZV�O�BH��j��{�T�l6�{�w����uF�� ���@�C��zD�zd����=��XV]���n���������~�i\?P{�[H$�{�������v��E|+���{�ͷ�8l��i<��M�Ԉ{�"d�y���XN�D�}�&ao.|j͔���y�C��4��4v�O�p�Ǝ�m��xJ����:��%םX���W��K����r�GF���%�1�I�/�k^��/Ӯ58e�'=�¼�.:<]�l����vT���Lu�$g�n���I��'��~�kX�b��R��<�I�ۺ��a��\�iK���D���x�/��]�{�� q{�t�E�����CK�B�&���0�t����6/"v]3��[D��p�\�b����y����Y����9N�&���ep�ǩ����6��Rs�-;[�_ğv���R{v^���/�1���9X��@�=#�=''+�jߤ���^�L	�`Нc7���ۮH��Q�y��{̲�F,>%1к���������l�dHJ��a�UB+�\xD�f���^�}����Tհ!���5dYϐ��3��+�v�S�"� j���a��=��&Q��Кf�C������7��cU��i���tƤ���AD�DQ��j�	7r��ܡ)�nmUeeΆE`V�ڶx��< !�޿�����u��J�B�N(��&)�ے�˲��e�=��,_���wnX�����t����'�:e0��DSQm/�
#���|yU��sE_lG�6����R����=^�W��7��P���{�lڻ1����c
O�k�N��Unli��e�YHqX-�^��K}�U��S������,�G���X�l�����I�h
ib��(c��b����&�������G9�ɥH�~�U��q�B��a,:�t�jzO�v� �8>���������7F��]����8V�c-�ؓ��.����i�B�!*l�MEm3�`DeQ5Ѫ��0S��(�K\���	|R��boar�Н�x�T?3��w_T�Z��)G����H�~�D�t����b�    ���?����gHV�ŜF�nG_�S��><���$����D0�O�L�nkzj�!���J�)��,]T;�(v�o�+޸��>���lLg��}�AD�ĸd�{|�Q���f�a���p��V��6�E���⻢��݌�i���j"�d<x�{�����ĸ����\I���"�:������k~<n��t"Wߘg�V=}�Ǩ5�އJ����ADab\��yӽ�����u��I���u}����D���j���|��wөP��O2�(���p5j*������N��;��vy�EY2�ξ[Tlܢ�O��Q�l�U���}�AD�ĸT�k{�_mho�c�=�uDo�#��^&)d�Rl|��[��i>��9C����'�eb���+���U<�嶯�6��S�%@?eQ11OL��L��q�Jӿ�W�=�<I�}Q@E��Ղ���W�c�r[��a�~�Ε��
B�A������D�9h�+!iQl�ĬWk.��p�,��h�t\j��>л�"��L��&F;�RnS'f�P�.K�M��3��<\���n.�j��}b��%�����M�����+���1���cZ��e�P�њ�k$!sB�s�b&�Ct\���>ѻ�LS��R'W5 ąT�8EN�ho2���~���$�-��-=^�|1��%L>���˵���Y�̏7NQpm��qdL�m��H�}y�O�x:��ⶪNg�k���eL>�ò�әT���@�AH!�mH�R)����!�ח����H�$"k���;k�ǥL>���}c:�:!gl�2)EH�� ��?N�B�V�op8�}U&i����E���xߩ6.g�i��tJ8:�ԖAHB�D��[F���۬�w����b!N�bq:��m���ۚ�>��%M>�!}7��3|?��B���$�2����RHY]ӳp�FW�E�.k�q>.o�i��~7���6�Ӑ,�-��
�T��*�f2�	N�Y��r��,��2Y��n	�h}�A:.q�iiӶ�h�"�`HeR�F:�@
�+���vCc���9��StM����e�]�ǥN>�!��.A1���P�j�W�mAݟ��s\,�ju.��<�y��Ų��q��O�p@�ACЍȖ�P� J��4)��%�H1�D��R8�^�q$��m�G�i�h��t����!�$��"q�B�䭊�zs�-̏��%˲+�N+���"�5:�9����1]�!)iK�Ǜ@���g�v{k^��w�t��-v[R@T3��";�B�t\���>��t�B���'�yPRN��]�R��?Jo,�ź��F��e�/{~.|��˛|�Cz7қ���B��	�)mnBk`���>��������$�.�
n��滭/��M>��!mL���PH��-��"o�Bj�|M�`zW��muޥE��%���qy	�o��˛|ڇC��%n#�7��AH�ۇ]�$��SIC��]�J�%��K����]�ŉg'�� ��M>�!���9�:�7=� �ț��MB4�(���S鶮b�6�|U��\�."�ѝ�6�qi�O�pD� 4�ܷeQ�M��&�-���^HWuze�t{����"[gP_5_�K�|ڇCژ�1c:�ԖAH�8�3qҳ�mNSC5#��.�Ev)�ɕG���O�t���'������N1*RG!E�Ɓ��gqL�HoZ��_��|秢�Hϗ뱚� �:y���n:n���w� �H�(q e��2�\ʀ�G�yT�|U�Szؗ�L��)��R'�����M�!�B3}G�ǛD�D�ȓci��iƌ�=sʎ{R]|�9_����?�A�r(9.y�i��Rs�a��+��"y�ԁ��Sn��SyN`eE�mD�ۯ�xGҝ�qɓO�`H�N4@X�ĕAH�<Q�B�\H����)�$]��9��4Y�K���t[�|=e���ɣ}8�������$ʕAH�<�'��F2(�л8��ے���m�"��J�8=� �>�G�@@��F+V�reP�N�:�=�g/��m���D?���*gˋhqY��E�:��D_�K�|�B�n��<�-��"u�҅��s(81��D���u6�|�Gp��+��G��ɧ}8���Sa�+��"w�ʁ�D�S���������59��kz�������A:.w�i��t{u<p�ɕAH�;�'�d��{e���E�X&主d&eyX.�-9�6���ɧ} ������2)r'j\H1�¹Ԑ�#�'Ɨ�V)�Q������z���}8=ڇ#�X����?� �H��xZ��[�xY�$�n����|q�X$Ū�|{Nj\���>��t$A�O["?��&�@m�Jڕ	���:�5�S�:�Ś���x�yUg_B�F>���>л�Dr� qeR�M���b�E��S�_nK��;0�kYW�#�pO�2���l�K���6+����J����nj��_=�܀��I��y�SԼܦ��|�����v�u}�J�ڀ��k>�g\&��$�L�=`_Y���_�@�_<��@F���=`�$��c �y�_�{ 	8{��)�:l��6���'��ͫtK�,�E~ݬ�^�U�2}ڇ�9��XЕ���98�s�B��PN�үO+���WC_���aM���Je�y��'�?t�jhK����`*'�6�^7�����nP�꺁�������>d�����F>�	hXÎ4t�f��|tP��r6��^�9ٽ4?}�Y���4�B���t��X��s��(L^9�Q/�
�/G�8
s\.Fvԋ]��rT��0�rdG��՝9��bDW����n.�*oF1�]6�S#�K����l�]w�暇!D�7h�o�kz�nV��\\��bË�w�P�{�ç}8�lL�F���� Ѵ)@��k���2썄�-y���.�e��)AE�զ�1�dy��e~\n�,�O뵯��T�O�`/�MC8�\�$�^��@�4�ك�WKX��GAit�ӱ��*6��v>�k�<5����6�4��2��R�r6�ũ�<��-)��v�/���>����u�t�S%>�]���.��Ә.�"<l�ΕAHq�./����Lfz!e��m��W[rMה�M���m�6�F����>һ���a��]�WD�28{>JN	��͙��8�b~�G���8�����U�{�ħ}������281G�B�R�kѦ����7��q���iX�6�c*��ŷeR�����J�Bs�To���(MEI
�r��,.�.��7�q2=�����Qژ.%���M�̏7MR��Pe7�5a�F�\�~������C��R]�1�Kg)}�.m�1�ҟ��+�i;Y�������5	\�F��X'R���� =��n��^�����i�w��^�,�d0�!}f$0�]Q�c?��Ɂ�l?_��_����r������G�@H�өњC���� �t�������|� p
�ʣ,�h�;�@��a�T�^��4=.o�i��� ��s��B��Y>0.������0�C/���|���8*w��X�N+�A��I�qI�O�H��O�	�A�en� �Hb%u �mQ����㧛����\�z�=�(�on�����=.��i��fj8rQ�-��"��̅���¨ ��V���Edq�c����*��:��X���6��O<$�j� �Hb%w �g��������m��d�:�oϛ4�����F�}���a}�#z�\PB�nB�eQ�R��*���&�z��S�ɮp)ł�Wdy�qN[����z\��>��ti����'��R)]H�릦Z�q�r�&U����튋��v��2Y�
�z\��>��t����G�B�V*R�Z���~o"ږg���xI��$�9���R3.��i��tMߦӖ��f��J�@*H�d�s[1�[��zS��v#P�+)���z���'�����MJHr�-��"y�ƅl�SEt�٩\�$�d��H���o��PT����;��G���P̓6��2�(r'Eڈ
m���^f1�e��{UT�-~�������%��g��N���Y�ڊ�=�7Q���E�˕O���4.#X%��hf\���><� �  �)(T�n�`D#uU.�̾�^*?�M��t󚲠�.���"�݄�h��;�X�}��*��Kq����?�3��� I�۞/�̯�"�^�E΢��cy�ԘqK>��C�1W~��ߣ�6GH��(ۡ`
hm�����ޗQ��1�n[��k5?�7�����>ҟ�������B*R�Bzo���^H��<[��N�n+d���_�
3n	��}8���MB��eR��JR�"�)��^f��{�q
�\�zI��%ڜ��יΌ[C�iic:F	jЖAHB�H�4mԀp�����<Y��������X��qk>�!��N,8J�dR��jRh6m	��_|�z�m�yv�s�R�FcӖ54U0ڗ*�z���)%U@Z���&�.�{W���s^��#	�Hm����U�\�n����N�ʶh3Ҿ����&���/�e���o�7�/�2n=ǧ~���n�P���7m�oh���L'�����7�      G   .  x���Ir�8�E��xHpgê�\EM@�=����C�W)��!�H'�]h��:�~A$<�C�G���������������"�-��A��G�jM��m�lu�l�Ş�����-��A� ��(���D
~q�Ųᶈ��6�u��|_
&�g�.x���
�����!}O �@^���[����ǃ(�F?f��ʆz�����
��-x+[� ����
��-|'�� ��"�x�~���M�!C)}��K^Џـ���Ѓ ������J<C��}�'�s�7�ą�{2�ܿ �اa��fr�����)���DFN�<	aȿ���P�����8��1������[R┗�^ \~�����9ң�u%�k]6���Z���|~����˿�O!���|��<et���`�V�L��e�:�����N6���q�+T�*��R<Wy��eW��:� x#�;k*�_���4�B��X�̴�ۤz`�Ȇp�-�C=��\Wh�e�q�Uo��v�l�FP�1�����i!��Wh�jUs^W��Y>����t��	�F6r�$�֍(�+4g*1�`Ƹͱ6�1-{^0�������t>��+�%�ZB��,�i���%����%�d����2v5D2�B��1�Ģ�t8e㘖51!��欕䞓��{�o�N���XD�.�Γ��H�	|'=<�~�Q�6���R�Ӵˤ�-�iV1A�d�έ �����������R��]V��lr�L�ђ�)��/�At��j5m����Ě��6�;��~6rU���5��nVk���z\����l���~8NxA�a�K����j+r�@#�;���P�Q�_w�����ܤ��;�Nq�L�T�gH|nr��%~]���C�R2����6=T��e����^D�+4+��ui�U.��������w��외'(��-{�e\�˶,G���r5��¤|g&���|����q+_D'�VLmi�&��mL�;3>x(	���gR��(q���~Z�DC:L�0�����N������l��l�
�n��;."�D.֯9�a�D'�10�~�
�}[1����3}n����i���U����f�6W=s�~6�gW!��_5�+*�j�	��4�{1�ƪ�"���l�":�x����wfW$9�9�6�]10�ww���K���%*!�W��ķ�q�q'���MO�����~�#�BIMz�'�4�������M�o+�GHy~R�'�W4$�b���%Y�xM��~o{����z��K|�[���:f�<%zjw��T�u���mO��i��͉��K��EAki�u��Jt᚝icxSK�ߜ;�<�F
q�@��u�Dp�j��JG����|�\]y��+��
�=�V���2):c�ZU�oj�3$����C�YJ�Yd�����U��ik���nG�T����\�\�Rl�)ҹڦq̒'���f�<#���,����e�]���Z7�uY���F��l���A�tAZ�G�v�$�t��Z��s3׭��+<oU!���4� �*�ɢk��H�KJW�[�T�gH<ǃ��iy��>d���]M���m��atSE>B��t�!�������!�j+��pd͑1��"!��R�������֣�:mR� Z-v,J�h���Q��Q`�UE^P"�>ផN�4u�hVLW���"DN���\�v��d3�ղaN����������������E���.�	�H��!Y�ב�49":��(��b�"�S��hH2�{=��bt_I��+*�%rӆ�.�<�V3	'a���9g�}%	�[U�M��R�_���j�G�f3�z�'�x�����ZrΕ^N�!B�W�{>��f�y��~��ok��m8��<�д%P�ԤiC�3��6��\��Zr�|6�g	K�Bu�K��X�6ͦQ�s70���8����Ga���D��j�IZ3s��ze�m-��Y:_�^n6SI_e2��Q�-�Ҙj�v��֒3�<���� �B�$=����ȺL�`��T���Z�B��=����Z3��5�d��>��V �[���Zr6�tn��\!�9����0���4eaZ�̿�%gHWT��H~K���˹%�9*������M��ඒ��gI	yI�$I��<���,���!f�}��G��q��%|Eɞ�Wklj̗t��ej����l�x�􈤌�
"�Ϻ��Ua���%�6�֑3dx:8�|WhX�n���T���-�i�,n����)�~Ŀ��MR�RfS��2�v�:[�g�m9C�5�q	�+DB��q�n�+Ӹ6j���Yֿ�m�t�!�� ��W�ּ̙��<+Ӿ]֭���c����gH�{~$p���,����廮�FWK�ƚ�uD<�
WSA�V���^P��kI�TP���3��R!n޷~�|^�p���=��~��V��ay�k��=���UZ��M�zz�Ȧ����d�m-9�5r�*D(���YS'_��b����ؕ��8��Z�����v>�� L��y1l[�u:M�`G�	�ג��<�0w�\���T���5a��Nf��n�njI�]�y�I\��_ܾ����l�b5uGb�n�x
&�YxSK�!���9D�j�~k�,};����Xl�e�MO��i��\�W蘗�L���ڻ!f�0O�^��$ϐ��p����ߑ>�֦I��vk��l�t4T��|���p?Q�u�^ж�&��NTȭ����+���7=�G����SD�ml���dN��_�
���)�*�Ԓg��Y�|V{})��$�j'�r���&&�I�K+XtSK�!�����]�fZ�e���0�n�S?���s�Ԓ��p^=r�g���S!��1y��6kd;�XtSK>B�S2��n/�\�T��Ÿ�m)O
�$c�;ZBx�� ��Y��}4��7E&��ݎ�r}it[K��9�;���x�BX.���VĜ��]*���n�nk��yE!��B���RW�]�芻Uk;�nk��|7t����W�5c�$;�n��jVQ.,��%.$���$����Ia�T�hS�}��Ok9����%!�w�	�B?f~[L�A���Vyx��&�5b)l�c�q+ak����c��7��      Q   9   x�3�-.M,���4���2��/H-�@|cNǔ�̼�⒢Ĕ�"Nc�`� ��      S   K  x��SAr�0<�W�a�l̩/�rр�8H���u M)Lr�xF�����l$��U���q����hk Bd�@/���S8�#L�*W7�w�1�*���]�ePx�J���Aŝ4P�m��E��b8�)\n��p~�<��s�8Z6����&�
�J����n�*�67:&kLE�*t��J���T<���T��̅�����U�NN�G{O1�!̍��:KRk��	ߌ.ˬ� Ap䂁�N��7���=__Q22<�������]�G(�ә�RaRҲk�0p���0�Ҫ
���&�q����D$�@�rU�p���[��f:|e��>�Q}�>�     