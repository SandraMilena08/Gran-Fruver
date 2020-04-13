PGDMP     	                    x            Gran_Fruver    11.5    12.0 ~    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    107942    Gran_Fruver    DATABASE     �   CREATE DATABASE "Gran_Fruver" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE "Gran_Fruver";
                postgres    false            
            2615    107943    producto    SCHEMA        CREATE SCHEMA producto;
    DROP SCHEMA producto;
                postgres    false            �           0    0    SCHEMA producto    COMMENT     6   COMMENT ON SCHEMA producto IS 'Esquema de productos';
                   postgres    false    10                        2615    107944 	   seguridad    SCHEMA        CREATE SCHEMA seguridad;
    DROP SCHEMA seguridad;
                postgres    false            �           0    0    SCHEMA seguridad    COMMENT     7   COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';
                   postgres    false    8                        2615    107945    usuario    SCHEMA        CREATE SCHEMA usuario;
    DROP SCHEMA usuario;
                postgres    false            �           0    0    SCHEMA usuario    COMMENT     3   COMMENT ON SCHEMA usuario IS 'Esquema de usuario';
                   postgres    false    6                        2615    116145    venta    SCHEMA        CREATE SCHEMA venta;
    DROP SCHEMA venta;
                postgres    false            �            1255    107946    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
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
    	   seguridad          postgres    false    8            �            1259    107971    producto    TABLE     �   CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    disponibilidad boolean
);
    DROP TABLE producto.producto;
       producto            postgres    false    10            �            1255    116133 i   field_audit(producto.producto, producto.producto, character varying, text, character varying, text, text)    FUNCTION     f  CREATE FUNCTION seguridad.field_audit(_data_new producto.producto, _data_old producto.producto, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('imagen_nuevo', _data_new.imagen)::jsonb;
				_datos := _datos || json_build_object('disponibilidad_nuevo', _data_new.disponibilidad)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('nombre_anterior', _data_old.nombre)::jsonb;
				_datos := _datos || json_build_object('imagen_anterior', _data_old.imagen)::jsonb;
				_datos := _datos || json_build_object('disponibilidad_anterior', _data_old.disponibilidad)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.nombre <> _data_new.nombre
				THEN _datos := _datos || json_build_object('nombre_anterior', _data_old.nombre, 'nombre_nuevo', _data_new.nombre)::jsonb;
			END IF;
			IF _data_old.imagen <> _data_new.imagen
				THEN _datos := _datos || json_build_object('imagen_anterior', _data_old.imagen, 'imagen_nuevo', _data_new.imagen)::jsonb;
			END IF;
			IF _data_old.disponibilidad <> _data_new.disponibilidad
				THEN _datos := _datos || json_build_object('disponibilidad_anterior', _data_old.disponibilidad, 'disponibilidad_nuevo', _data_new.disponibilidad)::jsonb;
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
			'producto',
			'producto',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new producto.producto, _data_old producto.producto, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    205    205    8            �            1259    107948    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);
 $   DROP TABLE seguridad.autenticacion;
    	   seguridad            postgres    false    8            �            1255    107954 u   field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text)    FUNCTION     m  CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    200    200    8            �            1259    108003    usuario    TABLE     �  CREATE TABLE usuario.usuario (
    id integer NOT NULL,
    nombre text NOT NULL,
    user_name text NOT NULL,
    correo text NOT NULL,
    password text NOT NULL,
    celular bigint NOT NULL,
    direccion text NOT NULL,
    rol_id integer,
    session text,
    last_modify timestamp without time zone,
    estado_id integer DEFAULT 1,
    token text,
    vencimiento_token timestamp without time zone
);
    DROP TABLE usuario.usuario;
       usuario            postgres    false    6            �            1255    108035 e   field_audit(usuario.usuario, usuario.usuario, character varying, text, character varying, text, text)    FUNCTION       CREATE FUNCTION seguridad.field_audit(_data_new usuario.usuario, _data_old usuario.usuario, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    213    213    8            �            1259    107955    detalle_lote    TABLE       CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL,
    fecha_ingreso timestamp without time zone NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    10            �            1259    107961    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    201    10            �           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    202            �            1259    107963    lote    TABLE     {   CREATE TABLE producto.lote (
    id integer NOT NULL,
    proveedor text NOT NULL,
    detalle_lote_id integer NOT NULL
);
    DROP TABLE producto.lote;
       producto            postgres    false    10            �            1259    107969    lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE producto.lote_id_seq;
       producto          postgres    false    203    10            �           0    0    lote_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE producto.lote_id_seq OWNED BY producto.lote.id;
          producto          postgres    false    204            �            1259    107977    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    10    205            �           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
          producto          postgres    false    206            �            1259    116166    recetas    TABLE     z   CREATE TABLE producto.recetas (
    id integer NOT NULL,
    descripcion text NOT NULL,
    producto_id jsonb NOT NULL
);
    DROP TABLE producto.recetas;
       producto            postgres    false    10            �            1259    116164    recetas_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.recetas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE producto.recetas_id_seq;
       producto          postgres    false    10    216            �           0    0    recetas_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE producto.recetas_id_seq OWNED BY producto.recetas.id;
          producto          postgres    false    215            �            1259    107979    auditoria_id_seq    SEQUENCE     |   CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE seguridad.auditoria_id_seq;
    	   seguridad          postgres    false    8            �            1259    107981 	   auditoria    TABLE     �  CREATE TABLE seguridad.auditoria (
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
    	   seguridad            postgres    false    207    8            �            1259    107988    autenticacion_id_seq    SEQUENCE     �   CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE seguridad.autenticacion_id_seq;
    	   seguridad          postgres    false    8    200            �           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
       	   seguridad          postgres    false    209            �            1259    107990    function_db_view    VIEW     �  CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));
 &   DROP VIEW seguridad.function_db_view;
    	   seguridad          postgres    false    8            �            1259    107995    rol    TABLE     �   CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);
    DROP TABLE usuario.rol;
       usuario            postgres    false    6            �            1259    108001 
   rol_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE usuario.rol_id_seq;
       usuario          postgres    false    211    6            �           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    212            �            1259    108010    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    213    6            �           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
          usuario          postgres    false    214            �            1259    116232    carro_compras    TABLE     �   CREATE TABLE venta.carro_compras (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
     DROP TABLE venta.carro_compras;
       venta            postgres    false    11            �            1259    116230    carro_compras_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.carro_compras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE venta.carro_compras_id_seq;
       venta          postgres    false    11    228            �           0    0    carro_compras_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE venta.carro_compras_id_seq OWNED BY venta.carro_compras.id;
          venta          postgres    false    227            �            1259    116216    detalle_factura    TABLE     f   CREATE TABLE venta.detalle_factura (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL
);
 "   DROP TABLE venta.detalle_factura;
       venta            postgres    false    11            �            1259    116214    detalle_factura_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.detalle_factura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE venta.detalle_factura_id_seq;
       venta          postgres    false    224    11            �           0    0    detalle_factura_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE venta.detalle_factura_id_seq OWNED BY venta.detalle_factura.id;
          venta          postgres    false    223            �            1259    116185    detalle_promocion    TABLE     �   CREATE TABLE venta.detalle_promocion (
    id integer NOT NULL,
    precio integer NOT NULL,
    cantidad integer NOT NULL,
    promocion_id integer NOT NULL,
    detalle_lote_id integer NOT NULL
);
 $   DROP TABLE venta.detalle_promocion;
       venta            postgres    false    11            �            1259    116183    detalle_promocion_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.detalle_promocion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE venta.detalle_promocion_id_seq;
       venta          postgres    false    220    11            �           0    0    detalle_promocion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE venta.detalle_promocion_id_seq OWNED BY venta.detalle_promocion.id;
          venta          postgres    false    219            �            1259    116224    factura    TABLE     �   CREATE TABLE venta.factura (
    id integer NOT NULL,
    precio_total integer NOT NULL,
    fecha_compra timestamp without time zone NOT NULL,
    producto_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
    DROP TABLE venta.factura;
       venta            postgres    false    11            �            1259    116222    factura_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.factura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE venta.factura_id_seq;
       venta          postgres    false    226    11            �           0    0    factura_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE venta.factura_id_seq OWNED BY venta.factura.id;
          venta          postgres    false    225            �            1259    116177    promociones    TABLE     �   CREATE TABLE venta.promociones (
    id integer NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL,
    producto_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
    DROP TABLE venta.promociones;
       venta            postgres    false    11            �            1259    116175    promociones_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.promociones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE venta.promociones_id_seq;
       venta          postgres    false    218    11            �           0    0    promociones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE venta.promociones_id_seq OWNED BY venta.promociones.id;
          venta          postgres    false    217            �            1259    116205 
   tipo_venta    TABLE     U   CREATE TABLE venta.tipo_venta (
    id integer NOT NULL,
    nombre text NOT NULL
);
    DROP TABLE venta.tipo_venta;
       venta            postgres    false    11            �            1259    116203    tipo_venta_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.tipo_venta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE venta.tipo_venta_id_seq;
       venta          postgres    false    222    11            �           0    0    tipo_venta_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE venta.tipo_venta_id_seq OWNED BY venta.tipo_venta.id;
          venta          postgres    false    221            �
           2604    108012    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    202    201            �
           2604    108013    lote id    DEFAULT     f   ALTER TABLE ONLY producto.lote ALTER COLUMN id SET DEFAULT nextval('producto.lote_id_seq'::regclass);
 8   ALTER TABLE producto.lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    204    203            �
           2604    108014    producto id    DEFAULT     n   ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);
 <   ALTER TABLE producto.producto ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    206    205            �
           2604    116169 
   recetas id    DEFAULT     l   ALTER TABLE ONLY producto.recetas ALTER COLUMN id SET DEFAULT nextval('producto.recetas_id_seq'::regclass);
 ;   ALTER TABLE producto.recetas ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    216    215    216            �
           2604    108015    autenticacion id    DEFAULT     z   ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);
 B   ALTER TABLE seguridad.autenticacion ALTER COLUMN id DROP DEFAULT;
    	   seguridad          postgres    false    209    200            �
           2604    108016    rol id    DEFAULT     b   ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);
 6   ALTER TABLE usuario.rol ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    212    211            �
           2604    108017 
   usuario id    DEFAULT     j   ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);
 :   ALTER TABLE usuario.usuario ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    214    213            �
           2604    116235    carro_compras id    DEFAULT     r   ALTER TABLE ONLY venta.carro_compras ALTER COLUMN id SET DEFAULT nextval('venta.carro_compras_id_seq'::regclass);
 >   ALTER TABLE venta.carro_compras ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    228    227    228            �
           2604    116219    detalle_factura id    DEFAULT     v   ALTER TABLE ONLY venta.detalle_factura ALTER COLUMN id SET DEFAULT nextval('venta.detalle_factura_id_seq'::regclass);
 @   ALTER TABLE venta.detalle_factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    223    224    224            �
           2604    116188    detalle_promocion id    DEFAULT     z   ALTER TABLE ONLY venta.detalle_promocion ALTER COLUMN id SET DEFAULT nextval('venta.detalle_promocion_id_seq'::regclass);
 B   ALTER TABLE venta.detalle_promocion ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    220    219    220            �
           2604    116227 
   factura id    DEFAULT     f   ALTER TABLE ONLY venta.factura ALTER COLUMN id SET DEFAULT nextval('venta.factura_id_seq'::regclass);
 8   ALTER TABLE venta.factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    225    226    226            �
           2604    116180    promociones id    DEFAULT     n   ALTER TABLE ONLY venta.promociones ALTER COLUMN id SET DEFAULT nextval('venta.promociones_id_seq'::regclass);
 <   ALTER TABLE venta.promociones ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    217    218    218            �
           2604    116208    tipo_venta id    DEFAULT     l   ALTER TABLE ONLY venta.tipo_venta ALTER COLUMN id SET DEFAULT nextval('venta.tipo_venta_id_seq'::regclass);
 ;   ALTER TABLE venta.tipo_venta ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    221    222    222            �          0    107955    detalle_lote 
   TABLE DATA           m   COPY producto.detalle_lote (id, cantidad, precio, producto_id, fecha_ingreso, fecha_vencimiento) FROM stdin;
    producto          postgres    false    201   ��       �          0    107963    lote 
   TABLE DATA           @   COPY producto.lote (id, proveedor, detalle_lote_id) FROM stdin;
    producto          postgres    false    203   ��       �          0    107971    producto 
   TABLE DATA           H   COPY producto.producto (id, nombre, imagen, disponibilidad) FROM stdin;
    producto          postgres    false    205   ��       �          0    116166    recetas 
   TABLE DATA           A   COPY producto.recetas (id, descripcion, producto_id) FROM stdin;
    producto          postgres    false    216   �       �          0    107981 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    208   8�       �          0    107948    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    200   �       �          0    107995    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    211   o�       �          0    108003    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    213   ��       �          0    116232    carro_compras 
   TABLE DATA           V   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    228   ��       �          0    116216    detalle_factura 
   TABLE DATA           =   COPY venta.detalle_factura (id, detalle_lote_id) FROM stdin;
    venta          postgres    false    224   ��       �          0    116185    detalle_promocion 
   TABLE DATA           _   COPY venta.detalle_promocion (id, precio, cantidad, promocion_id, detalle_lote_id) FROM stdin;
    venta          postgres    false    220   ��       �          0    116224    factura 
   TABLE DATA           h   COPY venta.factura (id, precio_total, fecha_compra, producto_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    226   �       �          0    116177    promociones 
   TABLE DATA           W   COPY venta.promociones (id, fecha_vencimiento, producto_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    218   #�       �          0    116205 
   tipo_venta 
   TABLE DATA           /   COPY venta.tipo_venta (id, nombre) FROM stdin;
    venta          postgres    false    222   @�       �           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 1, false);
          producto          postgres    false    202            �           0    0    lote_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('producto.lote_id_seq', 1, false);
          producto          postgres    false    204            �           0    0    producto_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('producto.producto_id_seq', 7, true);
          producto          postgres    false    206            �           0    0    recetas_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('producto.recetas_id_seq', 1, false);
          producto          postgres    false    215            �           0    0    auditoria_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 116, true);
       	   seguridad          postgres    false    207            �           0    0    autenticacion_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 65, true);
       	   seguridad          postgres    false    209            �           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    212            �           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 12, true);
          usuario          postgres    false    214            �           0    0    carro_compras_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('venta.carro_compras_id_seq', 1, false);
          venta          postgres    false    227            �           0    0    detalle_factura_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('venta.detalle_factura_id_seq', 1, false);
          venta          postgres    false    223            �           0    0    detalle_promocion_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('venta.detalle_promocion_id_seq', 1, false);
          venta          postgres    false    219            �           0    0    factura_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('venta.factura_id_seq', 1, false);
          venta          postgres    false    225            �           0    0    promociones_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('venta.promociones_id_seq', 1, false);
          venta          postgres    false    217            �           0    0    tipo_venta_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('venta.tipo_venta_id_seq', 2, true);
          venta          postgres    false    221            �
           2606    108019    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    201            �
           2606    108021    lote lote_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY producto.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY producto.lote DROP CONSTRAINT lote_pkey;
       producto            postgres    false    203            �
           2606    108023    producto producto_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY producto.producto DROP CONSTRAINT producto_pkey;
       producto            postgres    false    205            �
           2606    116174    recetas recetas_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY producto.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY producto.recetas DROP CONSTRAINT recetas_pkey;
       producto            postgres    false    216            �
           2606    108025    auditoria auditoria_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY seguridad.auditoria DROP CONSTRAINT auditoria_pkey;
    	   seguridad            postgres    false    208            �
           2606    108027     autenticacion autenticacion_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY seguridad.autenticacion DROP CONSTRAINT autenticacion_pkey;
    	   seguridad            postgres    false    200            �
           2606    108029    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    211            �
           2606    108031    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    213            
           2606    116237     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    228                       2606    116221 $   detalle_factura detalle_factura_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY venta.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY venta.detalle_factura DROP CONSTRAINT detalle_factura_pkey;
       venta            postgres    false    224                       2606    116190 (   detalle_promocion detalle_promocion_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY venta.detalle_promocion
    ADD CONSTRAINT detalle_promocion_pkey PRIMARY KEY (id);
 Q   ALTER TABLE ONLY venta.detalle_promocion DROP CONSTRAINT detalle_promocion_pkey;
       venta            postgres    false    220                       2606    116229    factura factura_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY venta.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY venta.factura DROP CONSTRAINT factura_pkey;
       venta            postgres    false    226                        2606    116182    promociones promociones_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY venta.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY venta.promociones DROP CONSTRAINT promociones_pkey;
       venta            postgres    false    218                       2606    116213    tipo_venta tipo_venta_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY venta.tipo_venta
    ADD CONSTRAINT tipo_venta_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY venta.tipo_venta DROP CONSTRAINT tipo_venta_pkey;
       venta            postgres    false    222                       2620    116135 %   detalle_lote tg_producto_detalle_lote    TRIGGER     �   CREATE TRIGGER tg_producto_detalle_lote AFTER INSERT OR DELETE OR UPDATE ON producto.detalle_lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_producto_detalle_lote ON producto.detalle_lote;
       producto          postgres    false    201    229                       2620    116134    lote tg_producto_lote    TRIGGER     �   CREATE TRIGGER tg_producto_lote AFTER INSERT OR DELETE OR UPDATE ON producto.lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_producto_lote ON producto.lote;
       producto          postgres    false    229    203                       2620    116132    producto tg_producto_producto    TRIGGER     �   CREATE TRIGGER tg_producto_producto AFTER INSERT OR DELETE OR UPDATE ON producto.producto FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_producto_producto ON producto.producto;
       producto          postgres    false    205    229                       2620    116238    recetas tg_producto_recetas    TRIGGER     �   CREATE TRIGGER tg_producto_recetas AFTER INSERT OR DELETE OR UPDATE ON producto.recetas FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_producto_recetas ON producto.recetas;
       producto          postgres    false    216    229                       2620    108032 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    200    229                       2620    108033    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    229    211                       2620    108034    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    213    229                       2620    116239 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    229    228                       2620    116240 (   detalle_factura tg_venta_detalle_factura    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_venta_detalle_factura ON venta.detalle_factura;
       venta          postgres    false    224    229                       2620    116241 ,   detalle_promocion tg_venta_detalle_promocion    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_promocion AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_promocion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_venta_detalle_promocion ON venta.detalle_promocion;
       venta          postgres    false    229    220                       2620    116242     detalle_factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_factura ON venta.detalle_factura;
       venta          postgres    false    224    229                       2620    116244    factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_venta_factura ON venta.factura;
       venta          postgres    false    226    229                       2620    116243     promociones tg_venta_promociones    TRIGGER     �   CREATE TRIGGER tg_venta_promociones AFTER INSERT OR DELETE OR UPDATE ON venta.promociones FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_promociones ON venta.promociones;
       venta          postgres    false    218    229                       2620    116245    tipo_venta tg_venta_tipo_venta    TRIGGER     �   CREATE TRIGGER tg_venta_tipo_venta AFTER INSERT OR DELETE OR UPDATE ON venta.tipo_venta FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_venta_tipo_venta ON venta.tipo_venta;
       venta          postgres    false    222    229            �      x������ � �      �      x������ � �      �   ,   x�3�H-���笋���MLO�K-������s�q��qqq ��      �      x������ � �      �      x�ݝYs�8����_��s7���if�����1��}�O��:�:,K�߾	R%AP�5���Qd�/G&@��!���Q�1z&D*�AW���_�����~��6�������_owכj{�����2�T�V���������lQ�f�r�~�ӻ��l��Hx�nx���'«��30)��7�Q��|��D���_>�ׇѧ���ǵD�{��l�u����O��l�H��r@��.wm�^|
<�Z����g��.l��v�^u�E�tO�϶ۇ����	鮖�MU��Y�����KS����|Ze�@U��M�j̵ȶ�O�u9��o[��Y��Ys�aίN4
��o}�|�8�"_���������ɛ'��f�S�A	������>�y{�S��~i�[W�,-IrW1�T��w���8b|��ñK�<:h_�s}�v��jUf�Ż���T�٢ثa؟7�pEbN��pe �p_ѽ%�C<1�����n�b �Ğ ��v�T�#��}�N��\�&���O�n���0J� ;f�0c8C�Z`Z����e���j��ʵ�^o�n�2G��� ��r�24��Tr�����I)�H!�BY�dV�EY2��U�rQʼ��̭aB�� �T5TW`�ն}dgX+�J�Ң�2��Z�9�����:W5]�KBU���05B^�(���7�bGU���q�JTB�!]�ow�2{Cc�k���hKk�JZ�U��Jdy��5��ڜ ��j�j�ʁK�j36����0�s0��-&���f��q-OǤ�XU�Ѕ���Yk�gQ��+�.!�:��lVV��2���2���C���+����h�9�NO��Tqм���jU̗4��֟<:/��PK������B������j�)<{"�I���h��q{�9/r5*nd�VX]�  C�U�g�M.꺮,�2�*�o�g��Lu؞��{:*U���x�9;NmNW�S�����|��ƚG��~0���Z��;����uFQ_��LYת.
i�����5�B�\��<��X%3ŪR��@Guyۚ��H=y�9=���iJ33D��h�j�cOh��<k
}-��%���6ˍV@��f5�U]��� �Z	U2^0S�Br�1�VE�4�C�)u��[�>a��ge͠D���kb^)��`ξ+4��{��3���l�c����D���
�k��F����fn������E�s@`-�ը���y/�g���J2T6ޞ�Dړ�S3)�&�����ƞfȞ��	���Ĭ�%���w"&f�dL��`���9��1�'�C��1u�NĤi��;���Ä���c����o�{`�-xiUFS~�W�4L�J�:W��J!��&��4��A͋݆�����9��8{:LM��^oO=C���l�g_h�	�=�&l��w2���G�0�cS.��E�j���/�y���4��Tj�����|O/�s�^="v���Ol^�%OP��3�ҚM��WOɮ���<�Pڅ���~�:�Lr;8Qx�����U_�״o��B�q�h�N���ҨAJ��0�xv
����kw>�fhΝ
n`J�F�0�JӖ�W6���I���;R&hNxH�/����{
��G�)M����q8�!��q<�i����u�R�yu�L�C�{[]�7�2+����F�y�����ٛ��x���W���zW=�����@Zܹ���ȵ,��L*0�M@�̊���|��׿��W��L�P�/�k�u�Uq�}��Cd�:M)9�~�"0_�I�1���p�J�'�
��o�̜(�h��A(��z2n�K(0���4ۢA��@ŅmUG��h�#�4y���C�pf��ҁ6�3��(��2M�}���p��@եnBn9��z,ӌo�jg�R�L<3P}�@�5��m��X�ەN���r6C���@ͅ%�A҈mQ�X��oW&��9�����t�n�&5�+=(ud�]�D@(ER\s�iS�c�����vE�]K�@��C�a��(\:�Fw���=�H��B"��̄J)З�M�����]y���^��×'��p]UC@�*:�FwN�����PL�)�6$�P���^�_6��n7��M�ދۧ[)���9T*�t���\wM�X���D���3FS+�B��J��b�T=݉/_$�_�拥�_���3KCş���]��#CHE"ђ���&�&�+�l8���'���R�	�'m�Ƒ������
�콕R�/4t2�.��!g�S�B*;u�~Yy9��6���6	���/���V���SfN}��N"�N�u�m��V���g���s�ݕ:�od)�\(3�w}x���)�}�ᅋ!�tr�M"���Ն�qB���;�=�C�4���-C�鼹��b.뛋��)��7�٘�l�i����$��� d���fc.��t-�i6d.86��p1Nj_淲�>1�����߯e�/�f2�,%c��)r�
5}&3T|h&�ߚ�4#x�;����$�/�sIt�	�l�?��4��ow��7�r_�֯x+k�̮�����鯿6?V[��e���Yz��uAϗ[W�ޯW�|�p�|�e��W���qhvA�Ti�a�������~�|ȁ}}����M�8��2���Cş��-��H!(C���=��f@Z���]΅��c�0�Nw��{�*!J>*|��f�)iat!u*�^J�Ҁr�'Ui�z4i��(����D� QР���{I�?PS�Ժ7������(�r��F���UA�o3��C�MP,�9{/��$�mU�fh�I���D�(�q���KUS��Ҭ����9�V�!��H�G*�{��Y35�?*�7�@m��ot�1���"�����H�)��8�ǽ����q��޻^�����`�x7���" K�4M�OpaG����m�z|���?��&{����M�C-{k%�+jL]�xB^��S:E��U���Z1>����H��N�'�w�#	t�l�G���-�\�VuH�0qP_���D	�(�[x ���ʦel.�Ӝ�8_�HL�(��4.��4Ub��4C)�K�٨�05�I/(CDU��G�k��`B)yv����u�Sw($ߘ�!�:Q�#*�k��2�;>�h(B� ���݁IM�(ӡiݺ����J��>ćHC���ژ�/CDi�d}�j&�����j��E�=�=�l��V�~#����]�+םS��# ��蔟�8�E���b^�y PD(,��3�fW3��ӣ�#�D�%o��Ɛ�bN�<����$l��0e�x'-�9±	ݢ�r�1&�����P6�R��g����@L�/�튳@�kt͑6�a��*F�輽��t��R�9pp����z�F�5�;̅C�������%�F���R۸ɫ/C���>Q;�&eܥ&�e�rxg�F�&^�G)ƌ\d	ѷEn�[-N�~ud�?�Fv�P���N��`�3����� ���3
-(\PgԪN�2qq�/C�&Z�D�����p�H�_r2�Eu�U\$��Q��N$�V)8��1�n�T����|Vݤ�WGԓ!�"��#��i�K֊Q�����j�n�O�k��î���T톈�79T��D[ՙ�*.��D��L��xr�x*9=k*��#ώ�i��₫����-P��u� L�eV��{�=o:��D[�� ���D;2DT'|�ڽd(�m/�<G��9��%N:l|�r!��6U�)�2�C&̘�n0�]gԷ�|�������#�D�?��q��[��{8c6O���$�5x>8�-I
G��Ӧ��y^�U��m�[~�\}�J�M
�ѾӠU �͗�����!5R��2�&F�P������B},Jx�rq{��z�_�,+��|}:c$���.�C8�S�5�+�3�d�]	�ف�3�'�Z��c1�Be�.	�A{�4Ƭ�d*$FyP9s�"�ܪ۹����˂�j/�;�&jG����}��푒�3:DM�
h/j�=7
lD�  CPyb�U`�n-gv|#�T��������m "�R��#U3�S�[���T����6�3e�GS�A��e��	d��D%��0j(��$���� �  ή�1�]ѬV�X�r/�Y���i(��,��������!�:��Au߸���l|{.���?�,�7�����Rn�PCLC�m���PNf�*/S���'CLMb���pg%0�r��x۟
���ԙ����D��@@����v�)=��]Ŗ0u��_W�`׫����)�~�vr��:_�L��}"�Fo�����H�d�]I��ne����~4�;�ͦ.n�v�Q,7"+�_���N�9T�8z�O�GP���*�;��&�܎f����P���9C�x�( C81����6ЩT��8C���r
� �C�T�z��/B<yb��Ӻ�-��{*�P�tI<�[y��9y2DT$�zD��	���|�$��!�Tw�i?˓P�7'IH��JP��m����i�ԩ��b����#CH�3��T�TU���r;�}��Jy�u]-��?���CD��1�Lt���!��g���U���D�-�� �Vo�K�xT?�I��\��>�.SR����HF8Bj)��6��f�%��4x�ſ���Ӌ꒹E�h��2��R�!�&X�1ϑNC��'2\R�:P�2��{"߮#���.��J���{�S�d��f�Tw߈a��M�}B
��ߔ�ՌS��$D�)��|���v?���nn�G��~8;���T����L��?�)~|�ݸ�\��H_��"1�>��M0���Y�T�����ԺVL:�1)�1���xLE�JC龜5���f"?v��ߪ��j=t�Y{�ݘ<ެ����
��u��7�~ʋ���o������ż��n�!# ;�""R�?_�"�Uohr�%F�yx�U!����`4�>����^PM{\��K�2�FS�����}��.`F�Q��mt���(F��ݭ|�r��'���t�����z�C���9�T�Ӯ��������Vw�y̖������$I�]_mp      �   S  x����r*7����\�Τ��In�"��fpO�#Wn
���M�x�W����뜆x��\0�F����ǟ��O���-��~�E�2��&�s1��f��+l�����L�2�_&����W�V�k#K� b�/Vh~x8�p���y�]��r�7���ZK-{�(@	em\cے3��J(k�*���/���Uٸ�`���J(k�U�؂3>v����Pc#ۂ�Ƌ�\BY[��a29��%_P��R'l�{���A����=<���*�D�-;C�ZW S�ޏ�հ��7<|\�0������!����/�$o{w��^ְ�'^^�"TE�&�ƃ�����&���v�|L>V�~-��l�}>kM�I��t�ÆϠ���b����a����j�
}�/��n{��[߀{���-���C	�߷��fwZ��7��a������5:M^����ߑ�,V��^A��%�?�?�[��`��m�-�(�2=�nQ^5:�j�"dr%��a��tX�:�����Gՙ����!�+h����D���"gI�a������6ݏz�ѼCh����t�L���<��M*lZ�i������7�S��	�Q��+lz���a�J(o6v-�F!ܯ�ț�Ӧ�Zi%jV�C	emd����ĥ��U�+��jl:_ֈ��E��a�M ��	\��۞ΐ4���ޣ��۞ΐ�킉��J	�mOgHJx׊76F
diǸ�z�<]g[<�p�������)��=�Z�9Ҫ�^��=���SD�L�Wk� 6������|�9�?ȫ(��v^�-�ʫ>�}����.�B���s�&���%t��n:,�Ƨ�{[���֛��mz�
�K)��{ޢ�xN��?�|��b~�45Bl�0�z���Ay!�	��Ԕ� �(/�J�vQ['�J(/�:!cjg���I���mm�@���BW#�|�z��9"��~�N��H�������P'd� ���n��z���h���y�,gk9��7k���CZ�*��P�'hOk�z_&�Jh1��ݔ�l����h6tGپO��T!��#2��#(��~?��ɡc��<�B�s#���cz��d���_��x����b�0�ת�k|$y׸b��"&*��M*l���~�E��=��r.�0RCo�>������ٴ��(���8�G��d�:o�~���w����-��I���~d�A�P��~�)O�>w�V�"PBY��6H��	6�H�����Nl\Byۯ��k�l�	1��W���:	�:�R)<��yr9�pZ�iģ�|5���@��*]L��V	�u\���1�<8.��NjtB)x��M��H���L�4/ry8      �   9   x�3��/H-J,���L���2�tL����,.)JL�/�L	r����$��1z\\\ �"L      �   �   x����n�0���)x��$@9�	v��J�-�J{�������2)Jl������'��1��)O��*����x��.8�ocR.�oI��~$$,PT�J�f�ZS��ڦK8��c%3��q!����/���!E�X��ω�A|ϹL���Q�<%��0/����,Hμ�w[��O+/����pM�	�bM�M��MklY�Ľ)�����;?%��L]�WFZ1̲֡�T��)      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   "   x�3���/�M��2�,(���O�������� n~�     