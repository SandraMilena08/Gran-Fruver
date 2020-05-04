PGDMP          $                x            Gran_Fruver_Def    11.5    12.0 s    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    27911    Gran_Fruver_Def    DATABASE     �   CREATE DATABASE "Gran_Fruver_Def" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
 !   DROP DATABASE "Gran_Fruver_Def";
                postgres    false            	            2615    27912    producto    SCHEMA        CREATE SCHEMA producto;
    DROP SCHEMA producto;
                postgres    false            �           0    0    SCHEMA producto    COMMENT     6   COMMENT ON SCHEMA producto IS 'Esquema de productos';
                   postgres    false    9                        2615    27913 	   seguridad    SCHEMA        CREATE SCHEMA seguridad;
    DROP SCHEMA seguridad;
                postgres    false            �           0    0    SCHEMA seguridad    COMMENT     7   COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';
                   postgres    false    7                        2615    27914    usuario    SCHEMA        CREATE SCHEMA usuario;
    DROP SCHEMA usuario;
                postgres    false            �           0    0    SCHEMA usuario    COMMENT     3   COMMENT ON SCHEMA usuario IS 'Esquema de usuario';
                   postgres    false    11                        2615    27915    venta    SCHEMA        CREATE SCHEMA venta;
    DROP SCHEMA venta;
                postgres    false            �            1259    27940    detalle_lote    TABLE     �   CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL,
    fecha_ingreso date NOT NULL,
    fecha_vencimiento date NOT NULL,
    nombre_lote text
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    9            �            1255    36284    notificar_producto()    FUNCTION       CREATE FUNCTION producto.notificar_producto() RETURNS SETOF producto.detalle_lote
    LANGUAGE plpgsql
    AS $$

			BEGIN
				RETURN QUERY
				SELECT
					*
				FROM
					producto.detalle_lote
				WHERE
					detalle_lote.cantidad <= 0;
					
				
		END;
		
	
$$;
 -   DROP FUNCTION producto.notificar_producto();
       producto          postgres    false    203    9            �            1255    27916    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
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
    	   seguridad          postgres    false    7            �            1255    28082 q   field_audit(producto.detalle_lote, producto.detalle_lote, character varying, text, character varying, text, text)    FUNCTION     k  CREATE FUNCTION seguridad.field_audit(_data_new producto.detalle_lote, _data_old producto.detalle_lote, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('cantidad_nuevo', _data_new.cantidad)::jsonb;
				_datos := _datos || json_build_object('precio_nuevo', _data_new.precio)::jsonb;
				_datos := _datos || json_build_object('producto_id_nuevo', _data_new.producto_id)::jsonb;
				_datos := _datos || json_build_object('fecha_ingreso_nuevo', _data_new.fecha_ingreso)::jsonb;
				_datos := _datos || json_build_object('fecha_vencimiento_nuevo', _data_new.fecha_vencimiento)::jsonb;
				_datos := _datos || json_build_object('nombre_lote_nuevo', _data_new.nombre_lote)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('cantidad_anterior', _data_old.cantidad)::jsonb;
				_datos := _datos || json_build_object('precio_anterior', _data_old.precio)::jsonb;
				_datos := _datos || json_build_object('producto_id_anterior', _data_old.producto_id)::jsonb;
				_datos := _datos || json_build_object('fecha_ingreso_anterior', _data_old.fecha_ingreso)::jsonb;
				_datos := _datos || json_build_object('fecha_vencimiento_anterior', _data_old.fecha_vencimiento)::jsonb;
				_datos := _datos || json_build_object('nombre_lote_anterior', _data_old.nombre_lote)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.cantidad <> _data_new.cantidad
				THEN _datos := _datos || json_build_object('cantidad_anterior', _data_old.cantidad, 'cantidad_nuevo', _data_new.cantidad)::jsonb;
			END IF;
			IF _data_old.precio <> _data_new.precio
				THEN _datos := _datos || json_build_object('precio_anterior', _data_old.precio, 'precio_nuevo', _data_new.precio)::jsonb;
			END IF;
			IF _data_old.producto_id <> _data_new.producto_id
				THEN _datos := _datos || json_build_object('producto_id_anterior', _data_old.producto_id, 'producto_id_nuevo', _data_new.producto_id)::jsonb;
			END IF;
			IF _data_old.fecha_ingreso <> _data_new.fecha_ingreso
				THEN _datos := _datos || json_build_object('fecha_ingreso_anterior', _data_old.fecha_ingreso, 'fecha_ingreso_nuevo', _data_new.fecha_ingreso)::jsonb;
			END IF;
			IF _data_old.fecha_vencimiento <> _data_new.fecha_vencimiento
				THEN _datos := _datos || json_build_object('fecha_vencimiento_anterior', _data_old.fecha_vencimiento, 'fecha_vencimiento_nuevo', _data_new.fecha_vencimiento)::jsonb;
			END IF;
			IF _data_old.nombre_lote <> _data_new.nombre_lote
				THEN _datos := _datos || json_build_object('nombre_lote_anterior', _data_old.nombre_lote, 'nombre_lote_nuevo', _data_new.nombre_lote)::jsonb;
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
			'detalle_lote',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new producto.detalle_lote, _data_old producto.detalle_lote, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    7    203    203            �            1259    27918    producto    TABLE     �   CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    disponibilidad boolean
);
    DROP TABLE producto.producto;
       producto            postgres    false    9            �            1255    27924 i   field_audit(producto.producto, producto.producto, character varying, text, character varying, text, text)    FUNCTION     f  CREATE FUNCTION seguridad.field_audit(_data_new producto.producto, _data_old producto.producto, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    200    200    7            �            1259    27925    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);
 $   DROP TABLE seguridad.autenticacion;
    	   seguridad            postgres    false    7            �            1255    27931 u   field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text)    FUNCTION     m  CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    201    201    7            �            1259    27979    rol    TABLE     �   CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);
    DROP TABLE usuario.rol;
       usuario            postgres    false    11            �            1255    28083 ]   field_audit(usuario.rol, usuario.rol, character varying, text, character varying, text, text)    FUNCTION     @  CREATE FUNCTION seguridad.field_audit(_data_new usuario.rol, _data_old usuario.rol, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    212    212    7            �            1259    27932    usuario    TABLE     �  CREATE TABLE usuario.usuario (
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
       usuario            postgres    false    11            �            1255    27939 e   field_audit(usuario.usuario, usuario.usuario, character varying, text, character varying, text, text)    FUNCTION       CREATE FUNCTION seguridad.field_audit(_data_new usuario.usuario, _data_old usuario.usuario, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    202    202    7            �            1259    28009    promociones    TABLE     �   CREATE TABLE venta.promociones (
    id integer NOT NULL,
    fecha_vencimiento date NOT NULL,
    lote_id integer NOT NULL,
    tipo_venta_id integer NOT NULL,
    estado boolean NOT NULL,
    precio double precision,
    cantidad integer
);
    DROP TABLE venta.promociones;
       venta            postgres    false    6            �            1255    28382 i   field_audit(venta.promociones, venta.promociones, character varying, text, character varying, text, text)    FUNCTION       CREATE FUNCTION seguridad.field_audit(_data_new venta.promociones, _data_old venta.promociones, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('fecha_vencimiento_nuevo', _data_new.fecha_vencimiento)::jsonb;
				_datos := _datos || json_build_object('lote_id_nuevo', _data_new.lote_id)::jsonb;
				_datos := _datos || json_build_object('tipo_venta_id_nuevo', _data_new.tipo_venta_id)::jsonb;
				_datos := _datos || json_build_object('estado_nuevo', _data_new.estado)::jsonb;
				_datos := _datos || json_build_object('precio_nuevo', _data_new.precio)::jsonb;
				_datos := _datos || json_build_object('cantidad_nuevo', _data_new.cantidad)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('fecha_vencimiento_anterior', _data_old.fecha_vencimiento)::jsonb;
				_datos := _datos || json_build_object('lote_id_anterior', _data_old.lote_id)::jsonb;
				_datos := _datos || json_build_object('tipo_venta_id_anterior', _data_old.tipo_venta_id)::jsonb;
				_datos := _datos || json_build_object('estado_anterior', _data_old.estado)::jsonb;
				_datos := _datos || json_build_object('precio_anterior', _data_old.precio)::jsonb;
				_datos := _datos || json_build_object('cantidad_anterior', _data_old.cantidad)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.fecha_vencimiento <> _data_new.fecha_vencimiento
				THEN _datos := _datos || json_build_object('fecha_vencimiento_anterior', _data_old.fecha_vencimiento, 'fecha_vencimiento_nuevo', _data_new.fecha_vencimiento)::jsonb;
			END IF;
			IF _data_old.lote_id <> _data_new.lote_id
				THEN _datos := _datos || json_build_object('lote_id_anterior', _data_old.lote_id, 'lote_id_nuevo', _data_new.lote_id)::jsonb;
			END IF;
			IF _data_old.tipo_venta_id <> _data_new.tipo_venta_id
				THEN _datos := _datos || json_build_object('tipo_venta_id_anterior', _data_old.tipo_venta_id, 'tipo_venta_id_nuevo', _data_new.tipo_venta_id)::jsonb;
			END IF;
			IF _data_old.estado <> _data_new.estado
				THEN _datos := _datos || json_build_object('estado_anterior', _data_old.estado, 'estado_nuevo', _data_new.estado)::jsonb;
			END IF;
			IF _data_old.precio <> _data_new.precio
				THEN _datos := _datos || json_build_object('precio_anterior', _data_old.precio, 'precio_nuevo', _data_new.precio)::jsonb;
			END IF;
			IF _data_old.cantidad <> _data_new.cantidad
				THEN _datos := _datos || json_build_object('cantidad_anterior', _data_old.cantidad, 'cantidad_nuevo', _data_new.cantidad)::jsonb;
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
			'venta',
			'promociones',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new venta.promociones, _data_old venta.promociones, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    7    221    221            �            1255    28386    f_fecha_vencimiento()    FUNCTION       CREATE FUNCTION venta.f_fecha_vencimiento() RETURNS SETOF void
    LANGUAGE plpgsql
    AS $$

DECLARE _promocion REFCURSOR;
		_row_promocion RECORD;
		_usuarios REFCURSOR;
		_row_usuarios RECORD;
		BEGIN
		
		OPEN _promocion for select * from producto.detalle_lote where  fecha_vencimiento BETWEEN current_date AND current_date + interval '1' day;
		lOOP
			FETCH _promocion into _row_promocion;
			exit when not found;
			OPEN _usuarios for select * from usuario.usuario where rol_id = 2 or rol_id = 3;
				LOOP
						FETCH _usuarios into _row_usuarios;
						exit when not found;
						IF  ((SELECT COUNT(*) FROM venta.promociones WHERE lote_id = _row_promocion.id) = 0)
							THEN
								INSERT INTO venta.promociones (fecha_vencimiento,lote_id,tipo_venta_id, estado,precio,cantidad) VALUES (_row_promocion.fecha_vencimiento,_row_promocion.id,2,true,_row_promocion.precio,_row_promocion.cantidad);							
					END IF;							
				end loop;
				close _usuarios;
			RAISE NOTICE 'HOLA';
			END LOOP;
			close _promocion;
			
		END;					
		
$$;
 +   DROP FUNCTION venta.f_fecha_vencimiento();
       venta          postgres    false    6            �            1259    27943    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    9    203            �           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    204            �            1259    27953    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    200    9            �           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
          producto          postgres    false    205            �            1259    27955    recetas    TABLE     z   CREATE TABLE producto.recetas (
    id integer NOT NULL,
    descripcion text NOT NULL,
    producto_id jsonb NOT NULL
);
    DROP TABLE producto.recetas;
       producto            postgres    false    9            �            1259    27961    recetas_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.recetas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE producto.recetas_id_seq;
       producto          postgres    false    9    206            �           0    0    recetas_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE producto.recetas_id_seq OWNED BY producto.recetas.id;
          producto          postgres    false    207            �            1259    27963    auditoria_id_seq    SEQUENCE     |   CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE seguridad.auditoria_id_seq;
    	   seguridad          postgres    false    7            �            1259    27965 	   auditoria    TABLE     �  CREATE TABLE seguridad.auditoria (
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
    	   seguridad            postgres    false    208    7            �            1259    27972    autenticacion_id_seq    SEQUENCE     �   CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE seguridad.autenticacion_id_seq;
    	   seguridad          postgres    false    7    201            �           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
       	   seguridad          postgres    false    210            �            1259    27974    function_db_view    VIEW     �  CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));
 &   DROP VIEW seguridad.function_db_view;
    	   seguridad          postgres    false    7            �            1259    27985 
   rol_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE usuario.rol_id_seq;
       usuario          postgres    false    212    11            �           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    213            �            1259    27987    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    11    202            �           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
          usuario          postgres    false    214            �            1259    27989    carro_compras    TABLE     �   CREATE TABLE venta.carro_compras (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
     DROP TABLE venta.carro_compras;
       venta            postgres    false    6            �            1259    27992    carro_compras_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.carro_compras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE venta.carro_compras_id_seq;
       venta          postgres    false    215    6            �           0    0    carro_compras_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE venta.carro_compras_id_seq OWNED BY venta.carro_compras.id;
          venta          postgres    false    216            �            1259    27994    detalle_factura    TABLE     f   CREATE TABLE venta.detalle_factura (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL
);
 "   DROP TABLE venta.detalle_factura;
       venta            postgres    false    6            �            1259    27997    detalle_factura_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.detalle_factura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE venta.detalle_factura_id_seq;
       venta          postgres    false    217    6            �           0    0    detalle_factura_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE venta.detalle_factura_id_seq OWNED BY venta.detalle_factura.id;
          venta          postgres    false    218            �            1259    28004    factura    TABLE     �   CREATE TABLE venta.factura (
    id integer NOT NULL,
    precio_total integer NOT NULL,
    fecha_compra timestamp without time zone NOT NULL,
    producto_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
    DROP TABLE venta.factura;
       venta            postgres    false    6            �            1259    28007    factura_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.factura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE venta.factura_id_seq;
       venta          postgres    false    6    219            �           0    0    factura_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE venta.factura_id_seq OWNED BY venta.factura.id;
          venta          postgres    false    220            �            1259    28012    promociones_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.promociones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE venta.promociones_id_seq;
       venta          postgres    false    221    6            �           0    0    promociones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE venta.promociones_id_seq OWNED BY venta.promociones.id;
          venta          postgres    false    222            �            1259    28014 
   tipo_venta    TABLE     U   CREATE TABLE venta.tipo_venta (
    id integer NOT NULL,
    nombre text NOT NULL
);
    DROP TABLE venta.tipo_venta;
       venta            postgres    false    6            �            1259    28020    tipo_venta_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.tipo_venta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE venta.tipo_venta_id_seq;
       venta          postgres    false    6    223            �           0    0    tipo_venta_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE venta.tipo_venta_id_seq OWNED BY venta.tipo_venta.id;
          venta          postgres    false    224            �
           2604    28022    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    204    203            �
           2604    28024    producto id    DEFAULT     n   ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);
 <   ALTER TABLE producto.producto ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    205    200            �
           2604    28025 
   recetas id    DEFAULT     l   ALTER TABLE ONLY producto.recetas ALTER COLUMN id SET DEFAULT nextval('producto.recetas_id_seq'::regclass);
 ;   ALTER TABLE producto.recetas ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    207    206            �
           2604    28026    autenticacion id    DEFAULT     z   ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);
 B   ALTER TABLE seguridad.autenticacion ALTER COLUMN id DROP DEFAULT;
    	   seguridad          postgres    false    210    201            �
           2604    28027    rol id    DEFAULT     b   ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);
 6   ALTER TABLE usuario.rol ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    213    212            �
           2604    28028 
   usuario id    DEFAULT     j   ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);
 :   ALTER TABLE usuario.usuario ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    214    202            �
           2604    28029    carro_compras id    DEFAULT     r   ALTER TABLE ONLY venta.carro_compras ALTER COLUMN id SET DEFAULT nextval('venta.carro_compras_id_seq'::regclass);
 >   ALTER TABLE venta.carro_compras ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    216    215            �
           2604    28030    detalle_factura id    DEFAULT     v   ALTER TABLE ONLY venta.detalle_factura ALTER COLUMN id SET DEFAULT nextval('venta.detalle_factura_id_seq'::regclass);
 @   ALTER TABLE venta.detalle_factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    218    217            �
           2604    28032 
   factura id    DEFAULT     f   ALTER TABLE ONLY venta.factura ALTER COLUMN id SET DEFAULT nextval('venta.factura_id_seq'::regclass);
 8   ALTER TABLE venta.factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    220    219            �
           2604    28033    promociones id    DEFAULT     n   ALTER TABLE ONLY venta.promociones ALTER COLUMN id SET DEFAULT nextval('venta.promociones_id_seq'::regclass);
 <   ALTER TABLE venta.promociones ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    222    221            �
           2604    28034    tipo_venta id    DEFAULT     l   ALTER TABLE ONLY venta.tipo_venta ALTER COLUMN id SET DEFAULT nextval('venta.tipo_venta_id_seq'::regclass);
 ;   ALTER TABLE venta.tipo_venta ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    224    223            �          0    27940    detalle_lote 
   TABLE DATA           z   COPY producto.detalle_lote (id, cantidad, precio, producto_id, fecha_ingreso, fecha_vencimiento, nombre_lote) FROM stdin;
    producto          postgres    false    203   y�       �          0    27918    producto 
   TABLE DATA           H   COPY producto.producto (id, nombre, imagen, disponibilidad) FROM stdin;
    producto          postgres    false    200   ��       �          0    27955    recetas 
   TABLE DATA           A   COPY producto.recetas (id, descripcion, producto_id) FROM stdin;
    producto          postgres    false    206   S�       �          0    27965 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    209   p�       �          0    27925    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    201   +p      �          0    27979    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    212   �      �          0    27932    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    202   /�      �          0    27989    carro_compras 
   TABLE DATA           V   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    215   ��      �          0    27994    detalle_factura 
   TABLE DATA           =   COPY venta.detalle_factura (id, detalle_lote_id) FROM stdin;
    venta          postgres    false    217   ��      �          0    28004    factura 
   TABLE DATA           h   COPY venta.factura (id, precio_total, fecha_compra, producto_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    219   М      �          0    28009    promociones 
   TABLE DATA           m   COPY venta.promociones (id, fecha_vencimiento, lote_id, tipo_venta_id, estado, precio, cantidad) FROM stdin;
    venta          postgres    false    221   �      �          0    28014 
   tipo_venta 
   TABLE DATA           /   COPY venta.tipo_venta (id, nombre) FROM stdin;
    venta          postgres    false    223   
�      �           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 32, true);
          producto          postgres    false    204            �           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 24, true);
          producto          postgres    false    205            �           0    0    recetas_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('producto.recetas_id_seq', 1, false);
          producto          postgres    false    207            �           0    0    auditoria_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 791, true);
       	   seguridad          postgres    false    208            �           0    0    autenticacion_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 373, true);
       	   seguridad          postgres    false    210            �           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    213            �           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 19, true);
          usuario          postgres    false    214            �           0    0    carro_compras_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('venta.carro_compras_id_seq', 1, false);
          venta          postgres    false    216            �           0    0    detalle_factura_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('venta.detalle_factura_id_seq', 1, false);
          venta          postgres    false    218            �           0    0    factura_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('venta.factura_id_seq', 1, false);
          venta          postgres    false    220            �           0    0    promociones_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('venta.promociones_id_seq', 48, true);
          venta          postgres    false    222            �           0    0    tipo_venta_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('venta.tipo_venta_id_seq', 2, true);
          venta          postgres    false    224            �
           2606    28036    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    203            �
           2606    28040    producto producto_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY producto.producto DROP CONSTRAINT producto_pkey;
       producto            postgres    false    200            �
           2606    28042    recetas recetas_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY producto.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY producto.recetas DROP CONSTRAINT recetas_pkey;
       producto            postgres    false    206            �
           2606    28044    auditoria auditoria_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY seguridad.auditoria DROP CONSTRAINT auditoria_pkey;
    	   seguridad            postgres    false    209            �
           2606    28046     autenticacion autenticacion_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY seguridad.autenticacion DROP CONSTRAINT autenticacion_pkey;
    	   seguridad            postgres    false    201            �
           2606    28048    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    212            �
           2606    28050    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    202            �
           2606    28052     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    215            �
           2606    28054 $   detalle_factura detalle_factura_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY venta.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY venta.detalle_factura DROP CONSTRAINT detalle_factura_pkey;
       venta            postgres    false    217            �
           2606    28058    factura factura_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY venta.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY venta.factura DROP CONSTRAINT factura_pkey;
       venta            postgres    false    219            �
           2606    28060    promociones promociones_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY venta.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY venta.promociones DROP CONSTRAINT promociones_pkey;
       venta            postgres    false    221            �
           2606    28062    tipo_venta tipo_venta_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY venta.tipo_venta
    ADD CONSTRAINT tipo_venta_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY venta.tipo_venta DROP CONSTRAINT tipo_venta_pkey;
       venta            postgres    false    223                        2620    28063 %   detalle_lote tg_producto_detalle_lote    TRIGGER     �   CREATE TRIGGER tg_producto_detalle_lote AFTER INSERT OR DELETE OR UPDATE ON producto.detalle_lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_producto_detalle_lote ON producto.detalle_lote;
       producto          postgres    false    225    203            �
           2620    28065    producto tg_producto_producto    TRIGGER     �   CREATE TRIGGER tg_producto_producto AFTER INSERT OR DELETE OR UPDATE ON producto.producto FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_producto_producto ON producto.producto;
       producto          postgres    false    225    200                       2620    28066    recetas tg_producto_recetas    TRIGGER     �   CREATE TRIGGER tg_producto_recetas AFTER INSERT OR DELETE OR UPDATE ON producto.recetas FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_producto_recetas ON producto.recetas;
       producto          postgres    false    206    225            �
           2620    28067 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    225    201                       2620    28068    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    212    225            �
           2620    28069    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    225    202                       2620    28070 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    225    215                       2620    28071 (   detalle_factura tg_venta_detalle_factura    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_venta_detalle_factura ON venta.detalle_factura;
       venta          postgres    false    225    217                       2620    28073     detalle_factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_factura ON venta.detalle_factura;
       venta          postgres    false    225    217                       2620    28074    factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_venta_factura ON venta.factura;
       venta          postgres    false    225    219                       2620    28075     promociones tg_venta_promociones    TRIGGER     �   CREATE TRIGGER tg_venta_promociones AFTER INSERT OR DELETE OR UPDATE ON venta.promociones FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_promociones ON venta.promociones;
       venta          postgres    false    225    221                       2620    28076    tipo_venta tg_venta_tipo_venta    TRIGGER     �   CREATE TRIGGER tg_venta_tipo_venta AFTER INSERT OR DELETE OR UPDATE ON venta.tipo_venta FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_venta_tipo_venta ON venta.tipo_venta;
       venta          postgres    false    225    223            �   M   x�36�450�44�42�4202�50�50�39��R����9A
QU�"��P��\�@u�@	T�&Ⱥ J�b���� v��      �   m   x�32���M,I嬋���MLO�K-������s�q�r:���e��%�*��TZrd����*��B�p�&V�%����2�t,*K�BS�)����� C�B�      �      x������ � �      �      x�ܽے�ȍ-�\�e�,����Oݭ���XkL6��el��x�#��X�?�o8?6 ��;�IOzp�J�]�%me���� ��F�L������W�_��	e��?�������ןꪎ���)��]Y燬����-7�!�u[g��ןYEE������O?��6�3 >����O�E8� �+53n�_��'�}�o?���[����������Lￒ��'�ᐕ�YG�2�D�b�����S��CY���ެ���p�c���ʪjYn�_�o�EUu.��;!���%�K��(���qyj����ï�h���m��*����L�����m]������q��D�`?�[q�C��c!ߔվ�� ������_���z�|�5U���?�������������ߑ���~H4K��CT/���w0����a��3N�U�����?����E�,�m��?���ͣ�`������\�bF��<��p�k��#=x�><Y/��y<sϺ��Y! �;Dw�}��q`!�x�o�@�M֯��y4���g;�C�^(�ǒ�W�^��YJ�Vޭ���#Ϭ:Fi����w��_S�5��_)_��Q*`;��c�����RP#��e�Q'iJ�R�f)�E*�<72���#�P�ǩ�i�J���m_�����p�Uj���FV%�Lc�ʔf6ֱ�L����R�2��(19�q�DJt�K#*{��R���L2%�������m�O$�L�����$��,�t&�8��fQ&rkc AD��$�4V1�>�ٛ:��ƶ�)0��)[�x&�"5�Z��I	)X��D'��<f��ƀ~&I��<�:��4��Ȥ�6J3�a��AD����M�_�C��;�h�!����3ũ��矲m����w,u�� �����0�ƮK������!@����x2�*�ˌw�<�ILh���ʜYauۄR�<��j�<�3K�Ȓ�7�#F�H$y�xN�%������ƃ��A	����pj�r{r4�kB3�w�����Wnac�Y�����d�.F�ZJ�L��*Oi�����9g�J�2����*"���R�瞅j
�|4��8e�����!�in�1X�����ׄf4�3�v_�h�`��b��id���,�(̛�0jr%TJxBL��a���\%1�-E�Oa�i�hN�#���	�^N`���R(��pvU�O�0����WJg��b�&�N�dD$q�(�<��ҌrA�\��4����Q0���9���B[�T♝Sh��x�����)>���'�S�R�#��.4�i|㩹yb<�`"u�i
S�'a"V>�q��	f#W���Äo&����O¤a���;��#]�8�Pr�6��%�MxjU&���DNM�y�d�2�`�5MR��j
v���X.���b�	O���'V�����~e`�Q:z<�t�O�'�M��C���w=z���Y×u�23�Vζyw��`G�3�a�����=� Ϣ�^�d�{��ƅ1x�a�UЙҚ<c}�W?]�������'��E�Dr�5������!����þ���'�n��3f�4ʋ� ��)�Դ� �G{Z�
6�LpC�Y`?�����%��f�s��$��i�&�|af�Kz���Îx[�J���*���B)l�t��x�W:�F��#��:h~��TJ��`A%B�ǽ�l^�i���G�1�I���`�.�8��|!��e�]��Z/<aqT���N�,�Qef��d�Pn��.��������M�U����H���G�ڙ�y�,�_�g�lE�R���_>��%;DÄĭ��p� (l��*hX��$fb@���]t*�Ba�:4xtȥ(%��`m��?-��ڊ��D�<��f�+P��=f(ctb@�W���.�� ��iw�*ЅW�[*&T}u@�F���`@�i��͸��W�f�e�Ā�h#����ۂ ����'�­('������䀚/(�N%�ؖ	
��o?�A\@BΩ��N����a��p�d��@��O�E�.��Iqe��fS�1��٩�"�}$��'J^s���b�>5�����N�g�zG���]@ͫP3p����ٵ���y3�l��t�7F�Y�tbW��~<���tIzG���zJ��I!��T��t�I�:�����JJ��J>��md���`D�i R�"\_I�W��dB�J�(n�m-N'I��zYl䮔[�;K>��!meה��Y�@����-�?��걢��#Iyb���>����j6��������R�����H&z9B�@�W�gL
��9������'�<��n�$e��|��������R?���O_&�?�ܓ:�~�ߗE��������ٕ�E��802�e�������C��m�\��!f�I���;mx�����vg���!���i�l���|z��1\�.��g��޳���s������1/�tǁ�80�81m̗�6�#��f��p���b�U��33�	>辜�+�V7"o�(�UV�ʫ���g�t���̌�1.gB=o����Y2�3K���[ٙ�Y9Dw	!D��~�O�?S"�����ؾw�2��c��/�E�6��>��������0����V�h�������_��X���2^8��u�k�d�@�,>S�s:��}�9lw�js�)���u^,����DXL|�G*û�Y�=�^��"�)%�����]���c�b����{ç*}$ (�p�`yϘ���>h'$�� 嘓�4az0h��(��/R�"J5ՓO�N������*P�7���j�e�ub�_�Fv&�>����|�ځ�5N��f�U�u��_�Vt��B
�� ��EQN1q��������f�b���3j�<��Hً�]H�»5Ěg]P��rA��{��Ew�g�X"�"G��g�\Õ�p�3�	���y�����s�މ��������uj��܍��0�w���U�&�'���)&�J���a����!:���/2��sV��f3�G��}��,��[+:��Z>|���H��E��(���AI0g[>x��,������h+:�Ya��. *^�p�(��ie����B���0����}�)_�t�4��s0���;��WB��JC�`�^/ �^�r�#D(%'G�/��E�a9�'��� ��EiQ�p�K�p�����y�_�Vt�h�zGh�eдx�'-��R�ɷ�� җA�]t���!�y��ɺ��W�@N�|ѩ&g,���{`��m�e�����?zr�P�����U�	��>d���2�� P�+Dɋ&��P�dU#��x�+�� ���A��o�B��yk���O��-�M�Qt8��~��Iat�H+����&~���Mtk974$�ե��'N^(U�]S�FRn�|��gtNn��1ݽF��=����=�~^������b��̾gU�/,��T�]J�m���Ҁj��]D�+73�1���^F�Y1���H�S�Wh)Ő�FBtG<7ͭcү��W"	�U}6T��)0���x�Ѐ�B&_����bԊ�2a~�K�{��E��f��S{��+#?DgZ3�I�4�(��4�4�shg�Ѐ��"����o�����S��C��mD�~�d�DtE��
��o�����Ϸ��Ct�h���hD[щ�*̙vH O����'�m��$'�׳��s�p��p��l���*,�{G�y�z1��Al�-�b0��,�ӆ#'G��
�(�4��~1�ET�%C�0��i����F��P %R��Le��|_e��b0���r\�)�-�I>x'�YE�D�p����lX�[���a��CZn^�wO�ҷx0$��؎�C���e��Eo�������䃳/L��a��h[��9P}�꧗�P��tf��$`1�P�.��� ��$��^���YZ���e����&c����1���!P}0BS� j�W�����淟y1�T���+ܵ"�e1��/
��@}�^�B��zh T�b�*'+R
Oݦ�ϛ�Z�����kBA}�Pa��.�s��4�nQς���~1P�Q�D	zh T�b��    `��ZN�p"糠���_�Vz�pº$ �x1օT�r=c�<ry�>���A�HO��<p�rh T�b��M2���$�Yς���~%P�)֮�!��$�9���RR����L�����_�Vz��
��P����J-��ƿ5�`����m������=�x�����v}vf5�d�h{���YqZ�7���,�G_�����F�G+�D�n��y��~���D�8�|x{���Am��3F�9��P�}����큼�à.�u��̷�yUݢ�9;�r��J%v����p6r3;\���o?I�b=B��9�qf��<YiU�B$����B���g�#���H8��)�:4 '}�ʁk��6+��A�g����_�Vn�	cפzh N�b�@��N�3�,e����0�g�������NY���.	��_�q�xJ�Ha�>�+�i��r#x�v�� �`7YѶ�� �L?�{�b|DQt�81\�ˡP�7E1�|�@��n�� ��oH��%��(:�)±fH �4 )���]H%��J�	���x��7��Rf�n=�S�+��u%F#���#�b�A+8��D5 ��-��Ta��R5�xRI{!|%}]�,�R�mLw4i R�r�f�҄�|����X���	ڇ��yX0��4 �H�)%h`��`�p��9HUoq��)�Na�Z6���~R ��#�3)���,���%�δGѱ��&��wi R
����\�rpQ���Q/�>��^.x$��b�\��� �M�3�����c�c?S��Mv�ưS�.`� S�b��F5h�?�io2�W���,���y�0倩q0��(�$6{�V������N���n�-}�����Dwߟȣ�ʰJ,%��v��V̌�R�?6H��-� P2� �����Q�O$y$D�tO]Q@�x��ܟ�����_h��f�	��
�K�40GS�`*�V��P��,6x������[} �r���o.&��Pm�ڽ<}���+؜Ra�ک��7���u+;�<$��K��~Ws��
�X����}(D����~-�c��	�փ������*�����wv�������Rm��4�����N%|�i����>*����uQ��������/��M����p�ʁ|hʿ}�N�A^n���y��6EFԌ����	���A	�E�,?ψ�x"�>�-	>�?�=ؖ��ɊN��I	ΈF���G2�Ѥ��`{��hj菭 VD?G��,�4z�~]m$n?���5�����'�{?^���k�����Vu�̎�6w�s%x{�wFݱ���_����i�ۗ!_�m~|�v��O��.��$�����~����������\��Τ�u��b*	�& A<N�D���n��L�#�6�־���=m�B��>f!��D�3X	�� :$��@�����!3��JaO����:��>D�F,�� � �.��Y"m�Cr�iEq]������"Nok_uw��6r��pc���4�+�H�QV� � ��B*�(eg���j_�����43#�U� ��淟4D��(� f�M���	�����F^x+��z8�SLu��A*�����O�]��?�D�+���ˁz�]94�.�B.T[Ю�bǮ���9���$b��1��c7N�}��+v#�Z�����W���d�@:��xb�;l���b���CZ�*_���u����hH[х�$�d�K�2��>@��23��e0q���q����r���C_�tw9� ������HH�E�F��.@
~
'.�M��Za�`@�YH}��
�o,Z�d���T�``��``v�S��=�m�:�),7�o����7
{2g��`�����-P�ƫæZd�89��<�X�:z�._��qJ��>Z)Pt�g�*\)h@)$@�He�JVH����wѺ�N�8I��U��9�1�M�Ͷ������EۂRAB��4 )��\����7��8��Z��T��:�ޮg���o��i]p��.x+��Y�m@e�.	 
.8�.�����`Ow0h��E2��f ��O<�Jk�c�����(����Hw�ؘ��,����'_s�7�޾@�|����l�5"��W/܇�T#��w���樉�u4%�[����5x���P����R�����?��Tͬ"�Fג�%�n�zu:V��~ŢJ�"����F�|��l?�ۇ�FtQ�K��yw��La�K�A�����9��5�>i�׵�����Tch�Yg`�ؤ3����m��#�6���|K�QV��w`������X���C�.�}ÅL����9�,������JȜ��,7��ū��������2�U@G���~2�����J�k&r0%PF�yr+�������1M��/nj�/������KJl8��4 )H��jz%Jrg|���fַr��Գ�>������/���R�b����'�{�A�/nx��V��V�m����A�ھF:��_��n��S,/y^�i����4����77�O��q�Ǽ�Xj)�A7Y�4�� U.����j4��?�6Z���7^��@��=�e�ty�K��hWDӈh�^�X}(������z-��r~�H~�j0ӆ-}��kM#�J��Ҁ�p�Եg1��f�:�%�Ƶ���=!Cn��IV��B7ts-��vk��L��q=2��Li�Bb]�4�k=I�^!�f�V�u!��>^��B3���J��a�������]i��� ���ҵ�������A�$��нt(�ԛ��uVP�G��b)��5�6�w���Kqޒ�	z�s&Q�?��c��#U�]tۜ�P��.�xϡ�6F5l�j���{��]uPA`��F�M��|�BFS��4�\� ���{pF��� `̨��~�~.��p�V^˦�m�׃)&U��l��H�|*�!_��E��-���*��{2�	�����`N�2�{v^�$"D���1���Ÿߏ���~��ؔ�{�������o�!ۮ��W��D��޺"�&ހ9<b2]��XD�W��_|?�����o1G_�����!�?�)�	h�jƈR|�����#ǃ����54Ҹ��t��aJ4��uq�?^�{�/v��X����x�8���}��Њ�9V$	5h�x@H��\C!xn-S�%2�8���\$������r���i|��@�����A���0�C��T��6����T��Ir�Y�/�j��x��[�� �6��>Ҷճ������� �`���EHMc�x@b��m��X^v�5=^��bY�����i��>�#!}](�����4`f�T9��iX���aR®%�%|y�W亨n�m�_�;m8��}4���pTs�K��yWܚ����}e9�n;� �w�M�PT>s�|?GvN���{A�8:.w��̇H�'��8�{K��iG50��b�a�����j��&�;d�pJF�*>8<o���N/�6o��>��ݰ!��qk��WB~	C���  c\dx��� ����\��������ܖ����b�v�|^�ѓEoz��3�.Lp8�A*1A���N���!��z��_׌OՊ�ʄ�>ec����{eCd��o*�h�u��CY<����=�%�$�nk�$;�);�c�I'�d�?e�}��_�ڵ xs�!����m�b�������.K��-͊�o�N{����7s���5�� ;������=40sRׂ�M���e�B:���3�-���t��K���ݝ�3�RN�!��ó�N{p��C�-<��.B�ti R	��[6o�{�������,��8����Z����]�T�օT!�Z+;l�s��]��<_є��~~拔2�ӆa|��O�Fti�(֥H���Q�B*��k��Tz=�_$�bw�it��S�j��;;m��}4���V���A]������b�ŁB*jN�z{�q�q|�rS���a��DgLY�q�H������E*)�Fjf1�k��Ir�D��X�K�߮��z.���    Ӵq�ј��KN����Y յ�%�|2!�����z]�xy��v�"�n���@%�Fb|�ǃ��Ό�/ߥAP��1�w��X$x�R�o⬾�w��>���7�:Y�.k_X��i=u��6�kji��~O����f<(�S�3
�)���sIQ<�	/��Ի�>�n|�9(�օ���`DrI�ZviT�r@�AbF5�j8���9�$t{���u~K7���,%�:Q>��Ame�6�]�(��E�&!�����0��$�%�h��	���[|)bq�D^P�u�|�G��.;�2�B�!/ʘ.�`h�,1�s�Ϣt�}��@�}b��'pc��������1h�{�j(n�Gԉ�¥q�7Rr19-׫�,���/��"�kz��S2���c?^�57�Nk�u�NKPv�QJ��}C�%����Y�rj*�0p��R�8��n=�U����K%���R2���c?z�DS��Zcu��K��.�e��D�~����?��*�Z�}�~�Y5�"�gC��:�~�]l�+s�+�65ރMS�������43��D�.Ș{d�@��A,S.��t������iQ]��ctZ������d�������݇�ZH��y�g�L�����H��f0~�ވ�v���:^Ϸ��]��%={A�64�c?�Vv�8ƥ@@- �hų7�Hj&�������T�}�b�v�T$��P:m\��~�~�.���5���`5y�V��*��K5��������zq�'��%?��uY�7o��N�j#;1`��\-�J�6��&-�m(ϺO`R�����X������Q|�b�N��.ց�w��2^�_�q_��f�+�s���WQ�U�����=�*�
����`�}@v���}�\I}^���x�D���|�GO"�]̬��A�'PyT�f���&�D�sGO�'<�֑eD��6A,�v��QQ?^�>uH��Ű�w/m��슊ר��L=1�5����e�H�t��`�گr7T���L+b��_�9��I���ܝI0��U�� {<T�dN�@Ec��G�I�n:���P��`tay�>Z�(ޱ�f�o����;�-J���؏^�[٥`Z�'\�a�Rw�����I�1�f*����?��sk�i��>�MmI�
o�SO�ϴG�O[��ά�5��phP}`ʺ�6M>8�?�>Oo�U凶��$�ʻ�����J PT�{�*�-����Rθ�U�G���}�PQ���I�+*�\������ �}UәHk��sc9�S��fW�z�'A���{�i��|��/0��B�����#T���o`\NiG���h汃>�����%��ؾa�o��d����L$�%����3>���M�Ǧ1�/�XW��\k������aGd̞AY���5z8Vޚ	-�p��]��Ŧ���i��*��v8x3$)�����腾�L�(���B� T׼����i��3aTE�|ᬩ !�Nb{z|�=��~|X�6Ϩ�w��P]C�s�ܨ���8-��Pzk����t;Ԯy��+3��pr�iy����S���b�O	��\Ӟs�؏�Fv�E������P��\K�[<UWR�9�sC�n���g�a���'Mh��늬�T�N�|�����'����=>��4xh������]����R���T�4ت��LŇ8:Pܵ*�~%z�,�?�t����m��kB��?w�
a�� L:n��H/o1!E��W	�E��].��W����/	x؏�*�삁/xn��`U.��V�h*)���>����k�R�]�D�Upn@���V����CO׸k�H���TҊ����I㓠��|�ֻlS_�q�&n��a?z���s�X���@�SAu�2�z5��	7�P��,�]}|�U��������R>�ut���Λ��D�u.ׄ��!�kϴg�>�㵧]Hl��=�4�=�Q�6#65��!C����Y�����iפ�����r�u��@�+t���:����Д�Y7`C�H�-��u�����_�m���:�l�W��3��< X�˥���s���4���Gњ�a�h}���m~�֧2�Ȋg��*����>�c@5�>dW�rLХAP��P1�$gL�C>�M��):��yC�HQn�����g/��AEٱ;YPj�K��J ��p�?S	�c��c�S?�u_�ל�9_l�:��&9m���~��ۛ�zքwCb�]U��UcLje_���
8���
��>Q�(Mp��8��A��J�^��O8U��X
�"ɠ�o�tU�/I).���p"5�6�jִ�Y�њ��N|hHF�5K���)?m��ݢ�!�%��Ei����-�S�$:�ʫ\!a�94�q�ҽ8��=��=�aV�}����XʜH����=�}��.b5y{�nd�oy:�{���O�ˣ�C�6.����X߷vh���9æ��M�zE�2���B��>��Ϭө�������0߉�A�<]\H���3т�6p��D��m��+��ݢ|��f^y���
��ф&B �t��εՁ��~t�K����d3!�6���_�N�������qyXS~(���� �F��g�@I�Kiݖt����u����e�'�:/�޹?���������.	����}��F����R��9j����g����<m��zg�
��aI�؊�X�����1�I1!B�F]����Z�g����c���|�wF�~�w癤��g߇��2R�ÒіÅ"�ˏ�#����\��<�w���4��=,�9��e'�ʠò"MsX���o�т*����q%�M��1���?��@��oZ; 
��4���Cf?��`�WP�Q/���ȹo��������������.0�E�0���\��{�VWv8.��5��o��O\���~��oe������]T6�4�肊ˉV#S600�m����h�l�)�����AS�a�|v063��������)!��JP��g�H�7e�O{<�c?Z�Qt��*A�Z�������=������v=u�/���+~;���$.q�n��N{��c?�VvɕU���C���e���طC�X������Po��5�z��!�P28�lE�~)����8�|{�I�-Yɧ=O�?���t�ߥ��/L�� F��V&���ӠN{�6=���Q��K��J յ,�!;Ӫ�z�',�]۰}�!F��E�6l'��lL8�1�n���yS`׮y�ͭՌ��h˙�b��L���-�v�ž�i�1�Kfw��M>�v�)����<�M{�T�	<��ӜP���O ���Ѯ�78�b��Z�no�G��m��hj@~T@�����&H�V�����O˘��c��K�ہ��ؖ�i�@�N���]9'�}�/��Rg"�[R�w��6U��~�^�Ȯa*$��K�{�P;��m:�`�q��F�#����#�Q��b?x�l��B��7 ~�Լ0�1m[M�1��]Ok��c���� ���+�J��K{$g:&\�_��j��!�]�t@��~V�,{J{j9����SG{\@t���$���i��7�Q%�X�f�����,�	;4���y%�1��Y��#���Ө������8aT�0���I�MȻ��b\�ˉљ�wݤIx�$YD����/lS��8���6�q���D������c.�������b��XK���6�Y�\m���t�*}߲�:�Tcc a,��I��vJ�y_������Åܼ�#���>�#BF�}�N1!�=4�����Ֆ��/!���e[25�q:�W�y���e�#��f{�؏���KkD��O�
v�]k�T|N4;�p����x(�rwۮ�r(�g!%��:m���hP[��B��{hT�2T�J��a������ty���尭1�)EƮ���������xP�)��Ģ�3a�������3c����$%���ِ�%��e��˼�iĴǾ>�?*�pa:�~��4*�zwM�@�6�%��ڨ���>���-k���+���'�N{��c?�Fvi�O    0��4*��w]T��6$�آyPS4��h�Uɬ^^��n��^P�=j��	j+;�E�
8��AP���ЂJeS��k=\���d����9��+�f�~�#r������؏���0ԛ��A �v@mKvi#��СxZ�`Z��LW��U۬W�;^b�C>�Ѡ��+�Br�$)8Fw}ZH���:L�tM�&�s]gut\�q8����F����Ƃ}�GC��N��$XOhT��u@xco\S9��ue�C]�یݎ�<�pn�7��N1�?�c?�Vv��΢�$�~ᄸ��X۪ ����"a�>]xq:n9c��/��:S>��mD�Z������ ���TJ\�ނ�К����ׇ}\�֗�B��f^�3%&�u�a?�Vv�9�硠>� �@e.�
k�I.�̆;̫���趸.�{�Uu�2�5%�u�|�ǃ��.�*��C��;��9S����3Υ%���wb^��#hIm��z�v���wIN�L�؏����(7!�p=4*P�j[�Rib7�Eu�ř���VW�j~<�j?�b:�/�c?ӷ�JӐ�=4�)L����\5
N���O�S}-�l{�iˢZ_8��G�rZ_��~<����LX8��4*�w]V Tp�n������X�"(9��I<��s�9��괾���8P?dT���A/��I���U�]M�i���Y���B(M���K��%��kQɉ&=�ǃ��N�e!�.{hT	�T�n�!=l�ǫc��kz=�k&b~�\�C�uP�ޔ��hP[ى2(�ҥAP�j]PV*����>(+Y��z��4�Vq��+�8o�ON�M�؏��]IaC��	B
��]�7HeS�II9X�)g��z��bQ]hR�NU^�
��":�7�c?�Ft���l��1o�[��
�h�}��'E.�":��yg.7�9��uZo��~<���K)C�]���v=�J1�0��[��bw�nK~�n���;R�jZo���G@ٙRA��{h0��)�]P5^L����Rd�5��l���b���g��kor5�7�c?�FvP4Eü)�Ao�
T��a��!��<n��:ެ��e��� �j�x�تi�)�Ѡ��%�
��� ��NQ��ޗD��z��Xn��OI�����<_o�2�k��xPٙ�<�{�)��N)�%+�Ρ l{�n�.Ϋ�z�ڬ��zM��:�;�c?�Vv:�DȐz�=4*�ST���W!g\¿��&���xq����n��N,>�s�%X5�;�c?�Fvƕ���C���;E���h
cZ��hʉ�S�جN�,:��GY6��{5�;�c?�FvJ$S�&�C���;E���V�V����6;�d*Ol�U�Z��5�=�:�;�c?�Fv�Ѧ���.�
#���TB�����Z�˼>-i-���T,b��x5�G�c?T��K[ƃ��;�am�w�.��:��>���%9�b#@���#��dE^P���|�ǃ�Ȯ869
��A��1T�6B4}�$Ki�N�t�|��}J��{�����|�G��ʮgAi�] U�GŸ�j��[%԰I�)��1:��$���d�/��k���Ƌ��xPٹ6"|�z�AP��b�*��熈q5b����{�����U^����pMZ�-s8�~���.Tq�k`��#���b�>���ZT+Z^���yr�A�Ӻ�>��5�]+���{�ppo��40��,؊}O|N�{�k{
zU�#WF��qC�6a
pp��70S-��0��e�jƱ^�p�MA��(��`Y�f�8^W��D[O-�������@�u��uV�Z�x�EgJ*X�G�o��r�|�í]Z��_��ז���H�q�$�x������E�	^���h>��yO1uֻQ6兞_EB�:?W��J µ�ހ�}����e����ͩ$#t�]�j������N�륤ۓ8�.+�^7m���~�:��+��<qthpA-u�.���� �˵(��Ƨ�B&��%�T	����1z� ���xP٩�;s4*j�k�a�~9��ez��[�7��o毋�|yXZ�f~p���DV/������*����1Xq�0����m�l�N���7ٕ�N	+�ݘ6\�c?^�٥�-:8��@�*�C�u��m�Qv0Iy_d��)���|��1������^P�W�؏��<`t�K���.\��� ��H���p��nǙ��q�x���FaD\���A1I����p-0!�ή����Mz
Q�'M�\�Z�=���L5 �t�Z`o@X��]H�k�IՖ����9_m��c:?�Z֛�*JRvL���GOM��=�[ى <<��F�-W��c�`Rc�^���(�)�,�u�-/���Q��ݷ[�*XG[�����A�L���S���`��9�0D�?̫���~�%�J:ګ�����^�g�'���i���F�z�hx�W���x�Z>�!�3|uYSΈK���m�YR���������|��0&o|��{=�ޏ���3"�{8ۙd����G��7�E�/�3k4�O�x�Z�Y�?S�*-^����Ӷ�qM�Uq.��$��Yl��c=q��1{���&����B��.F�5�AL��t{+�ܵ!�
T3�a�Ġ��.4S!_�-H����A�U+f
l�?fcD���[��Gh+��º�e�}#�d_�=����ǾG�5����B����9�DA7~����+��cG��ל�Յ�l�z�`��s�9��!�����wp`�b��`?��!b���+3|t3P�_������cu�M\s�0+��`Ӣ�Z�*���=�uL�2����C��Vvp}HP1�.n�tA�B23X�>�Y
πJ�@md�"�!}�{hT�Ǫ��03>h9�r�Xd|_ʺ:�*�����c�u��P����Vv!�Im� ����v#��c3b8%��n���p�v���P��('i��G/�Ӟ0�؏���)�%�����A �k9�C��8�6Ó�����y���`�y���,=2�I������~��6�3&���إAP��z��ūd���3|��iP�=Ӛ�w�	ׂ���wiT��4qA�M_�'�X�����Y�[�珏�V�>���[�������t-�ï�k��z�c���N;X_�k�7�KJo(������2N<=ݻ�H2�5끂��u���^hhk�~�n���.��[�鴝���y���ݪ:�e.���Z�L\���~�f�.�"�o�	i�u\����6�91��㸤������7�q�8��	���ջ<���6�!ۖ�2�D�b������]�e�.bIV�Et��e�4[4�\��$�|���\һ���{��Y�<�+�٬:Fi�Z�͠m�M֑	i��:��)�e~u���p]�Z�_?��=J!g�л~�>Mώ��r�oٍ��%9_Ҥ��-0Ӟ�؏܌Z��LYl694�鸜ߙ�
��%�L
j�`3+o��<��V���9��z�.�i�>�c@U��d�:,1�K��Z U��J��-���uDd.I^T[����Eɼ�l촁a��6�+��qD�4x ���qAm.�i�Ć��j��c����N,Y,��n~X&��5�iC&>��Amd����;]���Tk*�A#���Y�����(>���D�U�{�~���M����Un��etNj^,w���We��g�5�z�Y�i�?>��գ�]sb�*0tiP=��������\��«�m�_�Y*��eQ�n"���[퍨�i�?>��Amd'��BwHR�2R۔5����uv>�uq���U���H\�^{�N��i#;�5)� �C��
��?@ڔh �$�vϤ�.i�����w7�����1��<����JBz�ޥb>��X_>����Υ}����4���$�8��1���s��O0��=���'6�^\�7���B���#N�IlzO�4��i�D���kɍ�}��B�?����Q �f�8%��=��XjЬbR1�F�C������p˱ϭ{�o�{�Pn��#XE�!_�k�լ`)�\W�����+�8��;഑z��;��T#�K�{ ,z�v1�tf�!��ZK>s�oY�WXb���    ��Q�
�[����ݴ�m���u�F_��Q�`鸒��--c��?qY�g!��B}2x��u��F�TL"v3$�́]��LH#z��C�n�:��'2��C�I`_��Ճ��J��"		������Y�	���JAi�Lhi��qa��q�%ѵ�@	V���ϟ�ِ�>ψ||2}��5f�tHK@�����	���C�=�|�����_!H���MDe��7��� ��us�\�e�gi��lroO;�!���x{���YmXH�n�uB�{C�oj	%�	l���3�^�ے��u���qʼ�v�cG��6�C���A� j�|x�v~�ѐ�6Mb l�t���ʺLɱ���y���ݯ�'�_���.эyxB;�֟��m�<Ma�9�3f��q���A��#ߕ�1rf��;c�=���?cڪ�L3�Iץ�c Ԏ��jf��۞�'�S��L���ۥ���^���a I�~3M\�+jF���5(�������ݝ�����0a�wЄ4:�_��bذ�q,|�k�q�JhSWbܝY�S�N���_�}���%�;�?�`�p��I�4a?ZP�k��{�f'���W�z��q�ߙ�}���ϩ� 0�_�W���&d�4�����u~\Ļ}���"��q�MC��f_�؏�Z���&؊z�ACs�1���=fT���U�򜿸wN:��g�~%���kv�hJm�R�6oݝ��Ȍj���k����.�~L$	��X#�`���^,���q��v���:�T�����&�Nn�yͷ��uw[2�]F'_�F��=�����Ι	���!A�,wj\D٫ 3#���#�܂�Sgk���(�En�����e�q��e�1��/�V�g����ޯ�D������"��G]5� y�ş� ����kf��ᫎ��8���&_曣�zYU���8�L���c?~AjD��������DS�b*q4��+R_	/ϊ���G�8��`�i C�a���*��K�t��4�L�b��cT��viU�xy��Y����S�Ѥz�c?�"F����Ԓ�Ru]�s��.�X7T>|U�iP�M@|԰ţ��pV��K���+�,D���[��M���\׻�bA��mq:W��*.�t���*ݟT�q�~ȎU�s�]\yf\P�[}L
A�D��T7�yz�6�%[^���ȴY->��Amd'Br��K���/�l��
KS"���� x�;�}ap���.Ɖ#+5�0J25���Z��"��UqǺ��Ob+�������~���+����
�@�
�'�.���d��r7j�C��O�	�3�����܂�2�h,d�Yoȥ���r�ȫ"��<O�c>�)���8��CvJ��a��.�9�ʻ�
=�4b�1�^�tOs6�"۶���eIm��d��7������f��!�����g�_�8g!l�>��Nj�<o����:�.��|`��w���i}��(���!;,�6�/S�� ��UbaTp
����[R����5KOU�I�"���ח��i��>�cV��FvB��!��K����s_t�TIf\;�T��ڱ�����l��@��7�OSy��V�0��PR&���牙���ۯ�ޏ3�n�b�?��}U�� w+�Ky�u�atڐ����ţ��hfD��ԥAL	�j]P-���ޝ�{;V�ϛ��:_�2����@.G�XyA�6l�c?�Fv�2�Qf�AM��<߀J�JA�kI�9[�W[���>.��:���+�!�ј��s�M���@���q_ƾ�Vm��H���O��b���QYo�r53eK����!��6�k-9��� �@e���5A�p�q�X�ds*/�2:E���"�g_	zF����؏�E�3�$	�=ڥAL`�]L-�QxP1)Y����&�o��\��4��� ��i#$>��ͱVv�������A�A����Ƣ�R�����.���|��U^����Z�8J��<:m���~4���(�Kݓ �
 u�xF���<�$
!����K~>W�}]
��v�J�N��؏����|U��� ����G������ /��,Z�����M�ɪz��:?yãt��=�#��]vT,�K����!�jS�o&��àO�-_nIt����e^����N���؏���[�(�4*8�¸�6)�VK���p������}Qȴ.���xWT6�7�c?�FvM%����`:/xSº��T��z��R�8�M���2�W�xI�K����شޔ��xP����o94*xS���Z,,!����P�g��Z\�����6ޝw��Ϧu�|�GnT�s�L���� ��NI����a\h2XG(�W�[}H��)Z���q^l�j��Rٴ�hP[�)%a�x]�)�P9�ʹ6��S�]�Qy8ǫzQėM�"_A4Ʀ��|�GO�Kkg�h�;4*�S���2t�'T�F�-c)�|��|��N��:Zz6�?�c?�&QSB�g�=	B
ޔ.�ͱlev���ӐN�M=i��G�	�$P���AJJT�V�1���C�ˍ�w��2��ݾ^׻�ޯ���4c��S>��Amd�B)���4*�S�������9rc�l�剓sV�d�Y��ۄ�M�O����:����]k,
��
��t�)x�k�d�Ճ��ӠN|`��A+j+;3��;��4*�S���� %lT�k*�V�C|�����V<92�E��^��֟�=�[�S"4����e<��?e^I��cd���6�:ˣ�.Γ�y��N�czN��i�)������S&�tʡAP��R��cW)#������^�l5��6�b1_��l}�:a|Z��~���]ji���tiT�uAM�/��p��r�mΥ8��A��u�*�Mq<��������xMmd�D��h�#	B
ޔz�I(Ś��������I�l�w�r�+%,��y��6�/��*���bY�8)7˹7[�O���؏�o�˙$:�1s��8%\PuÕoS-:弢t��ħB������ʴ��e|�a��6%1��6�ǥAP��S���=e���9:�HI��V�u_D�ZЅ��.��o���hP�ϕv�v���A?N)�6�CRe�ȥ}�s-z:J���Jj���]�y�V��v�j��}r]���j����H�K�U�i=Q��jъ.��$l�wiP-S�b�0�X�卧uZOtzPY3%,3*��M�A��VT,�������q��ǂ��^�l�gǒ��N��؏�T��oT5��� ���j�b�б8jpS�mE�7QD#I��,�~Y��̼5I�uD}��Y���iP�.0GT��(<��LYK�p��,Nn�S�gQ�f+1���t��>��������쀉���4*8��5�EsPE���)}��V�d��ϤH�m���>&��*������m�tA�K���#�]C[6���a�%XVF�i{(�|u��k��yv�|�����*�F3�!A�L�4*���5���?3#���BɅ���N����V�m}��1q����xP���A���4*���5�1��Θ�j���w�E�߭�S��j_N9�o�b�����1UmU-�zCwiS���EH�#`
O7ܖņ���F�5&��,W�e޻@bZ���~<��씩��3�A�P?�S{@`K.���6%v%OƗ��$�c*.��0o���֝����Rqx�� ��Ni�b��W%6�AP��yu�+�����\�KTs�A5�M�~��A�x��)S%\�)C\P��Q
��&uZjzP�%�����
���.�k��#J���<�Ot�۞���s�I���M?���S>��Amd��=o�0T�������yR$ɒ���&���nu(�֔�֙���m��0T�K���3e��(m�-JI>���ӑ��b���x��]���r�����:S>��AE��LaE��>� ��L�*1=���{|�&�|�����x*Nb���/�rZW��~<���J�'6��\)#]Hư��F��O�:�+5=���a.���ޑ ��H�@�I�����Logz������&)v������i=)�ѐ    b�L!%"�zT�AO��.����u1����|Mvk���*��r]ys$崞���xP٩T2�@}�AP��2�'�v���{2��l�e����j�=�금�d�&/��Hz؏��]�s$]\)�R�a�c.8�Q�+)��7�L�~�WQ��:�ӺR>��Ame��枸4*�R�u��$����ü�o�l����6��o�N�J�؏��{���.�
��}t�,�`s�ç�k-/'~��e�zw-�!�ILJo�T5�+�c?�Vv��U�n���W�2TLj`3 |؞:/�Ǥ�Ur�nv�����J�OM�L�؏�E�3py4M;4�)8S���b�I��}
|�n������Noe�6��
��M�"�.ȐqR�ˈb�,Y%|[��	2��c?n0?d�<�7]]Lp��L��1�5Ä�!���N��p[�����t�W)c^�XM���؏�|���k�RϺ4*�q�}P%m�Ӵ��ň;�[vȶ�l�ѷ+���_ܶEm���N���2t;AO	�=�cR�'?������{��Ln0�}��{P)�1ѻ/|�s<���@��D_Ѭ��cb×�ө�2��y���f��lq[G|�f����6�c?na�����BBf]\�JP���2V��b�<:ͯ;!�~�,�~v^���25m,��~4����RcCb�]�T��M<N��E�)����`,��uu�ħ�׋#����VJ?���"|�G��ɷ��R�"i���� T�*��̚K5�Iw��<��z�Y$Q���s�ߞ��oԴ��yr-@��JpBA}�AP5�*\P�`i�᫅�%�o�E�������e���讚6�c?�Fv�)1yr=4*�S�Ubh�`���5u�������^��Et,�9;z�j�X���xPe�W;��zO���y׈Amn�P;�F��5j����E�"i}�"y"q�aI�M����"|�G��ﲃ�	��Р!G T�U��a�F�+.˓8֗�|{�wE<�/���{�GO�&�a?RS�eWv��5աAP鋼����mN"���p�ۨ�v��z�T��6�8]����=���|�ǃ��N9�!��=4*P�*��~��9�z��ᑨ-��S$�?�������hs_y=j/[Qu�uS������N𲥥�o�gW ;��}>�߈}��)�f5xTC����_����ı��`�ٙۢ΋*ɗ��t�����r��JVzڠ����展���ӯ.	�BJHE�UV�CE��m��&YZ�g�\Fd�!�ᗞ�:���hH[٥��m��>� ��nR��q�g������<�G��~�̛��M��@O�����!ѐc>%��h�ᾧIH���6rb��g����R��޶��f����}��+I#;甅���Р���LeT4��a<��s38�}�m�c�R�Aġ�=����o���\p6����Y�Ղ�r��q�tU����_[O��%���Z�M��D��v�żeNg�(��|���J�(%-7���%���8�i>�#A}��q-Y���� �@�.�M���.1~��,��q^����/�ͩH��{<�'.��a?Զ$W�z�j^$#.��I�5�����/ir]G�]����� �Yy�ww�":4P���#���T%��R8]�pt��
�>$�#�ɗ4ZOp�C���i�jn$����8�Ǔ�|�����<�ț���ﾺ%v����}C��~)!|R�[�\����y�8��C��C������lz�L�b7ܣ6W��(n=�6����☛{gT��xB	#��J��[Ѱ�uD��Q��)�V�44� j:��C�O���z=8��!6q�������ݠ��m�����_Jh���mg�����\��>L�|?��j���Va6m�$4}wJK�V�?$���$��'Ց�+���4$͟;0|�ÿ���VD�$z��z��9uE@ �m'XY� ,�dq���a���/��y�?���l�pFh���Aة1):Бn�7���H�m;a��qW6�z���i `u�o�����d>��Hڴ����I-����RB��_
|�����y���r�ž��8�E~d���4�lZ�?4}gJo؅�&a����!R���JC]f�S펋��"�e�΋	�����:̏�`�ܦ��C�w'�|��
u{�f���2�V*��j�b�����_��_�U�U9O��m���T�D��x��o3���С
�JD��+K�
�8�f+�z�J2������o��_z��G�p�e�}��[yX.G0������j0��\�'���6F���V�a��n���/ch+$�7����iA���fg)D �E��o6�|=�uX餍ф��Nj��q6�||C�Z$�7�e�k���FI]���a�fr�����#?�2c�l�M	Mߝ�;�Z�h�e��Tߌ��RB�o��J!�3�Fy9��'>=f�a�g�K�MߝTM��2�C�$�1$�7㥡��q%�#�����S��@"��ҷ{P�Y �X�3f��`�V�d��dt�LV��2qi"��;/�;=�e�H�o�����UZ����=�~3��`�#���h���Z�����:��2���%���4%v@'8��h�Z�Ȥog*C��Df$�-��׫~��l�ۿ�#�u���w���Nj�=��a�O�tŠ�e�yĝ�;�[������=�����{E;�LG��F��� �!��.����6�v\rS�^3�6:`RWI�cx\��_�/���͖0><��+s��1'3_�r����j�A����w�L�]f���2m-3�cHf�T[%U��Cӱ9q?�\��UN����zZ-��i�Vͥ����V ���g"���1D�BR�G��T�ę��%&���8�.w��e�������,Xb���B�w&��sz�S���?�Hտ�b>��dL3�x�dj:�M'őm���)_�y��vi���sZBW����?�85�)�r�lOHJ	v)�]͖Y����ʷ��w�B��uL)�ׇr�QF¥�u��u��5���R^%<��UJ�S�n�]��1�
1,�˼�\���q��wr�7��w��v%,D���cH�,�
UR�M0�L���[���~>��[��cZ.�r��\��ͻI1����Ί�(�M��h���ߓu~΋�f�=S�.m@+4}w1�X�È�5cH����Pv�������S�>#��H���ыt���7�A��0C72���|����#\�6m7ӫ��S(� ,m/4}w1*�fdL���1���#��t3u �#�1m�_M���l�V|�]N���[�O����҆�B�w'�:VP�w�G��"�#��[�|5�]Ⱦ�����T ��/֋W�2?,����z��֕;<�9Y�g��p�
�#���n����{���-�������-)�L�c9��f����~Z�F��"@*}K������������lT~R�/����U<�����Dߏ ߵ�������5-�C���Z�Ǐ^��;�R�����G�O��J?V�k�Jc]�T@�����}���u�����_ _��a��[~o���̝��<��zE��+��:q������/����t*�:��T~)������wF	�b���#3��0�E��[g��2(*���-������2��G���|���g<���1����T7�	,RI{cH�$|Ry�ɝj��5:���:��iq<Ǔ�����sXG���﨣е2汫�1�)�Z��*j ��pl�m/��*N�y�����a�Y���؆�����SC�w'��nD����D�DBU�P*q��]�~��+��*����&��H���N�5?NO�Á������P^X�pnh��kZbG��E4��C몐T��(����m��C��6��8��>;�W�l1^��ARӆsC�w'���-��4��C���Z�T�w��"^��&u9����g��qv�CXM��熦�&oؙf2�?�H%���:׿��Y1����,��l8��6��t5�,����~(H,m�24}GR�U��C��    ":�jb�-��z r� �R��[��D&��y���Ǐ��!#��n�>���m��,������Q*Q5 
��h��4��@CЈ�0���^R���#�L��cdJ��D���ݨ�0t�-P�B5:%
�l����*̘�0l�����K����p�%U},�o���_ʦ��ɔ�l���M��y:5�
�q�T��d����6�&��Ty+ ��mR]��)�V@P�ۤڜ'S���6�>��z+ ��mR]��)�V@Pڤ�P�ӆm�Ԇ��5ʱLؚ.)����4�-s�*��V[)�����ClvJ�'��?���9�є��-a���ߜ�r0��#A�(K^j�.MO?�q䥒��¿y�Z&�W��-�Y B���SD�Qu� m�k�OɶK�T��hq����j�(����|��SD:�P�w��|��) ��\h����"�Iυ���/�|s�S@.����CD�%�vei���8CL�-��&C����Rj��'6�b�)���Ӛm!BJm7�ĆC[L1��xbӡ-&��R�<��P閭!i���z��͇��bJm?�D[HhA��OlB�ń6OmC��6DKLm^cCP+Gj:�#X�4�M�:�F�1>�N���U1���k��@��>�DYs�f�1>�N}T"�4��k�@���V?�Q���<Zl�6Z����h�0��m�u+��y�j� D�z�Ŷn�u����`�k�l�V Py����S5m�u��Z$�֐D[���jk�T[Cm�
jk�T[Cm�
jk�T[Cm�
jk�T[Cm�
jk�T[Cm�&���ERmi�u+��ERmI�u+��!���4ں�֐T[�4ں��|m-����λ�/�є>���+�!�pRu9���cL?��'G|��1��M�_����Ϧ��M_���G��䵃o|�g���ăo|��G���K�J��Ϧ��ŗ���)&��?y�2�?�� �LmC����) S��9~
��6�l���2�?����LmC����)� S��9~
-��6�h��"*�?����JmCȟ��SBUlN�N:c9�L���7��6�4T�h�C|֠4�>�����O*�HP#�#�I�R�$X�
T�*�C|Ҡ��ց�2I��o(A�y�p��N{��M��e�_�����j6����	�-��R���1o��V4���yW����4�5�[� �E�@۷O>�᭹ߊ���q6hߦQe�6N}�������=w�&�!Zi8	��s��o�|������R�:��Mb��
F�B���gp�]�~��~y�\^�:�o6}��]�Wqf�xm�w�6�]����3��wu�;+F��4�'�x<���yvȏ�b�S�h�J�V?4}��|���;v��e�;+�%ŭ��D_],����G���ί3|5h~�T��Q����ᾗ-^5�V�ob�킯n�OPŭě�O:v�Y�O`iF�{�I-}�������Zz4O[��5��o"Z}�7����׺�R�����JI̳�e�ͧ����,���ݡ:���z(���Ȏ�N*��z�_�������Ҙ���cG����-��{���+fyv���:�ү��O���E��*�1��I�cZ�~{>TE��>K�M��C~����I�O���Vv�a���4;_����<9�`%jڧEB�wV�7�BJ�t�*}C�/��
�T��ɞA�g�/^6���o���L�&��k�_�AR�>-��;�%vŌ��Xk��I�T��k2|�4>�b8�8S����p<Vr7[������~h�عU�4��R;�HH�oI+C}�-:n�okn&��&�e=�����%_��AR�6�Mߝ���]�3��c�T@R}KZ9����WD��B��
��E.�q<�LvAR�6�Mߝ�;s\��OC�R���Z�P>q+ьUB4���z����h2����2��w�m�!���}h���>�����!��1D�BRM�T��#;[�hz,�M��Dw���xb�0����1�ՃU><ϋ�|�/բ؍�-�y�f��黯p�]8�X��&������@����˸8���h;�N��u��AR�6�Mߝ��2B5>`P7�(E9��J��=�-�t�k6�(�G�߳I����&���v�pR�����
�<&����������_h��[�����q
��z �7*l���V��4�^��`pZ�U?��+��'���MJ�[�L�>yC�"�P�TA���?�3?,g�n+<��5���V��-�w��>V��֓V�?�$��W�gV�����g
�`������U��.M��Ny>�^�|2\m�>W��n7���nI}M�}���A;�#�[o���V\[��f9c��J>�Gk�ۄƠ�� �^+�w��������T�'_�b��L��nu��u<��7"m�)4}g�a7 ��Ռ��d����3��d=������?{�<f�3���:�|#<�2yߤř�� ڽ���ϭ6�cB����7��7�η59�3EBo~R��h?���A�Xf�=?����"m14}�����]�mdt�C��#��M�%�N=t����o�Yn3J�Y���"�w��Zʇ�2��O�E&���̧���b��Ό�&Ǡ ������.@��lX���F��$�7j�6��Z�\�Q�ք����'�Ď��)}C���[��R��&l���o����p�zީ�=囿�4�,�>Q@m4�}F��5�3Ew�Of���1z�W��ӆ�$��mװ?���t��·U�������]�]����'D���!y�H���J�;���i���rF`�6�R+�o%�[0�d}�i�Y��i�랷�\O����u�O���x�c+"m�>4}w	*�k�X�SC��T�
�zTJeYc6dz����/�m���~����4m�<4}gN	��#���:�8տc>����:nW��6e��k���W�\��/��*e�Fnq�|�-���6:�zp�;�0�'ZN=f��F#SL���u1��Nn��|B�ƴI���������@T��2�d�(>��7��`���"�U)���T3E��㳙����&[�$>��]�g�|��պƧ���V�2g��v�O���r�<X� ҆�C�w�;������E��J�TK�Æ+����:Qܧ9#ˋo���ͭ}c4�	wX_��.���K�WK%C�h1o٪(���a<8�\����8��a1mt<4}g!�a�h�F���!$�)��ũ<LGM���iX#������z�ٛ:����t�%�w3pbp=t��fД��:l�8VʏC����~���w8e�z�*0�ugj�����`d+��l�q�>�e=ˍ�qQ���k'���Iq����L�6��v��ш"!:_[igi?f��ɜ��ɨ�t��J�ߍ��^ڟWmE�n�v��ys��6�^ȼ#��a�Z�JBt���U7����O!���ŉL\��0w_-c:4K�i4%��f��u/�|��<��&c�@ڌkh��F��xtF�h��ĐTY%U����*�&5mv��"�TĮ�S5TC�r$Uy�rA)`e�n8��y6��luaK�o�W8V�B_H��
Mߙ�v<�uT)Vu�*�T�
d6q�l����~����B\��|��e���f�B�w���z�
�IV�����TM�~�8�����l���-���f��e���65��;�%vMi�xR���I�>���],���4h4���p7f����2��X"�����Nj�]3&YL~�:�HUH��Iu�A��a�7J�`�l�$c��z;���流��HM�.Mߝ��d(��:�Hտ�`URѤ�o�����u�_ar����,�8���F�C�wWT%v<�xԍ��"�T��۔-T�-���V�K��d�ֵ�Yv�6B��Z����N�����?��d������EyZ��/��K(��%/�-GKM�7�\&���}I�g�~~S���_vD*��*V�pc1��m�&�<ukuRJȋ�� �	  0J{0��d�ٽ��\̏�1M&[����0x���4B�w;�����#�/�!t��Ƨ�ln'�f�s�~Y���͇&j榬X+��;�ps���"��؎�ec��]x%���#�����>�w�·o��3NZ�h��}5�/G���R\�E�8گxؘL��	M�MEa��I�y����q�0�T�~�%�8j��o/��vs��p��63���*ӆ�B�w&������t�?�V3$���rJ,�`��zs�z�|�j��5溷�)[y}}xw�v�2(����"^���J���p��o@�r!-�ߪ������#6��;ԇ�
Ϟ:���;����u>̖/����=uC���kx�
Y�p7=.F���*��[�ގ���d�?�����>�W��W:`S�8�n���	�Tad��¢&?J�.����,�fv���4�V��$q�����ϓ�VN��0�?���:�j�����i��Q��q6�r~���בX���'ŦIMEM��j�a�yd��C�
$շխ8�[��+�rZ��)[L�������\�E���LEM�YRo�%G�W^�!RI�MT���F���ckR�FQېʣH-�+������c�T�i�7|��r��kN��&5m5=�%v)�P�'�y��~�b�R��ƒ�=OڔD�w�f1����%g�ՂO�y�ԴQ���ݶ�;w��L�M�c�T���'��M����S����i���������0���X��d�(jh�.�
��[��(ju��~�UR�Y�)i��Դ1�6�6I� �n,WQm_�c�T�S%���PQ���X\�]�jZ��F�a�P�Cj���6�������)c���"}=)}R�o�{�-u�m�$�L���lu9��q0�E�T�6��������b�?�����/#��@%t��1�ғ�֣JL��v���u����UR9�!������&p�/��+�`�w�&��h�
F�j�P8a3[�ן��'�M]��Q-�9�I[C:(w2.|��B���j�����P�~��S]
��Tޭ��['�N�#n(�j�=k�ӥ�0m	������ ���Z�o�Y�]^<m���-�>Ć>�5�&��S�G��~�����r4Q�V�#O�h�R����5<���W��P5 }�q惠��]���'m���ӿ�w�Jj�E�Ў�HP�6��<S˸e�bu���SBVt&څ�D��JǏ���p�F���/БQ�ƒ��N)-x��VY]�؂w���Z����/���FULY�⡚���p�'|2�g�MbuE���&��N@�����"��[�J�Պ�����E.*�Í͝is
�~�d�9%���8u��Qz3��pZ1:Zq�#9����E�F�qaP����j_�
Sg��mH['6m+�{î�F��ľ�!'���.��N1c$��ܟ�9
v�hڟו��8P�O7�^̴����)��c=�4�z��e�b��h
��痝�__�4��j>��)UL���,'�q_�Ԫ�IM�9Mߙ�v��GEy�c�T4��*I��,�؍9ށ8O�B�;�z�;��n� �i3g��DyK�D��)g!��:�HUH�{!�PQ&�ՓB�FI��١�m���.�m6�յ���}9T��Yh���zîz�)�#%�C��_�������H�I=�G�z8nFjz�]��:����,x�K�͜���(��I�ڐ�=�HE���5���[�ա�h~�5�i3g�I-��+�D<��1�_�$�"��'Ֆ%F5?�՚Ӵ�����Щ=�������ǰ�SKwiA�8j���T�6q���v.4��:I��??���:�Щ���͕ͭ9M�7k�i���A��dҨ��Yuq���QUN钼�����,_�3y]m3X�m���k4�uZ?.4}GA}`ךފiA��"�8�=RE��#X�l�sܚԴ�TrRo�2uK�:�HE��T�Q�α3�]�IM�O%'��]*T4���7�HE��*�J��Be��Ӵ�ԟ��+��.�T���L�3z�
�졶�4�3����6��ǋ��"�)�<Re��.#Lc�LkR�0MM��`tE)�ԗ1D*:S�{�R�7�q��,��O�L%'��Z��5T��C��3e�O�*s�`�M���zS�I-;ΣzU���KY�)5�=��[S&��䔖صf:�uu�jЗ�/�g�jZ�B|����>%Vk"�
g��k�Wὢ�S�V��j�݂�R�l��g�a���LX���X��ݎ�[�RJ٨�K-������v�T�H��A UhR�`[�$�H(�JRHTAo_|�a�c�aR7{�>g�7���E9�Q7ǫc�H��H��e4����Ԥ�o|a���4�?�H�_�1�Ta��
��T�%?j	����G�B"���se_QY[үT��~��}��������V�F�      �      x��}I�䶒�X�
m���es���{��	��{lV_F��c!&eJ���\�I��qw����pH����\9���׿����7�%Dп���&臱N�!��08���h�M��*S3�ɚ�k<]�#[�7&?��`t�a<� Q������٬ɼ�&[�dE٪�ug�?��0���G|}dc߰a�C�+������ƿb��}���s�#���!�5����A������]�0`^x}d�a��sx!a���~�F�ɀR�?���#F_�qvž���3����M�<��L�������yW � )Y�~������f��Y�\�WJBCЧ+�A������4��rx���լ�J�/�+)�E��ǈ���(�ڒ�b�p��P5�Z�\0���k^	�W潣c�B�.��א#���5%���+��Dw�ʅT�s���`z�$�~p�}[M��z�-��R���\��(/����w�g��+2�+�
�<?�������������¯�!F_��g:��h��RJ�Π�t�:
f8� ���LG�t>�k�vz���oRء��َ��(� Y�Q��Cޭ2�L���	��;���,x���g6�Dr|��߼>3y�0�\� y��g6�6�`��0�|}f�`c�� ������L�3S���A+�0Π�l��Yw��Ʉ	D������]9�~x
}f#_�qlS
^@Ϡ�l�bMr;����A�ٜ5�J<��b�S~}fs������(��)QD�D�RoYK&2Oq?o�t��*b�=��p̣u?������'l�*&��0�(x~��g6�K��	������@6��<}�'�3՞����	�x>�[B���9'�e|8��?��mH�t.d�U"�ihGZՍ�0d��BϪ����5��LbUVj�J��uB�|Y/CH~�h��#�|��3!���OP)��B�	闄�]��:y8�g�gB�!#6�a~���3���o}E^��}&��!�י0�Ѐ���}?�;:�GjsL����L|G� ���!��>C�h��ι�y�L��|�q]X�!�A�E!�,���'B��w�� m��(G<8��Y�I�Pִs9n"����}z�؍*�Kv�^�<�Ϡu�(W�$cQ=0)N��+��.��v}���)L�+����-��!�;f���g.�Wh�����3�3���Z��x!E�=�3.�.�0lB�(z�z�>��߱A�OB�a~�1q\-m��*�1KTy�+�]��K�?2΂���g��8���"q�����C_�a�_r~�|��_�G�@ ��8
v}f����:#����ߘ�Pp'�u'��+/�'6�"���<���#�x�+�о/�@��Π�t�:��d��;�>��o�8��K}z�_��d{�s_\����ٿ}����_����Rp����
�r�k5T1W*1u<TY�U\<ߍ���hh�b�xp��xE,�![�fMX�5���;��s�F6��5���m�E\��_x�B����Sk��5[b�d�U����xp
ϡ�l�6�yH�����o �U�[ޑuK�z�zd��.>����.�G�Q�^�r2$[���h�E�4ģ��O���n~$��1x�<�S��rX�X�a�K��e���6l3�0 �Π�l�6
ᢍI���� �q,ˡ��pCj>m�-'x��l�ء@���ԉjL�*�HW+��t5Q~�ݕ�Z%���~� f.�-�Y;�t��W�ϴa?p{2�7h��4�C!>��nb+ui�q�������QIv�v���oG��
�Mڥ���6E3oq!�f���Jr3	#~��ws�=�t���*Ғ�b$�U5��Jr3	�^)�(|a;B\4Y���H�B�U���k�.����&��bďq�+d��K����W��d1$��.����L�W@
=N���#����7S�x���Ts:���QIv�,س[��w1�p�r��T�zmWf��U��QIv�|߰�|�0�^�����n�C&0.8≴0G%��f�Np�,<����es��U0<ӌ�\(|	�/ب���!?xf{�$��pA���i�w&c��K�%��T��Rd@XxX�%HL�M�O�<��wkR/3��Zr3��Ud����R󆢔�U�De#�Y�)���:j����?��}|
-����ڥ�*<-Y�������Z����>��z���W���]D�-њ���!��:j�n��B�{�\�Piz��ZM�����V4�V���Ů�I;�B�a����� �:�y�aj��j�$��-NTv	��I
� ��a�����<��$��0��2v}fs�o����9�^�����QKn&=� <���,o�,%M��*KK�4곙�1&��]K����]� =����j�B�hSݔ䱘tkFi�%tג�$q�x�1�{�B���4�B7S���Rn��������t[���L� �QJ#�̓ʧ��}SVl��o�BTX���
����
YL��-*M����o����W��YM�%z���ꥌP�ֺ��m��9F&���]�C��|�ǹ�Y�h���n�ESk�s��4ه�KԈ�3�(M��f[�UfH�t�k� �cl��)(��<�9=C�(٢RT��XQ�\���H �ch���]z>�� STe�!؂�m��Vb�4^�˾�L��d>���g�FR����դ�*�-����U,�&�=H�|�9	Ϡ�FR��j\�a&���Ѕ��6G??��jm��JVYSm�[׾��cg5!�P(�gPߠ^�X�mK=�8͔�sVkӳ�
��+�|꣦^ҹo�U�⅝���5{{���Ϡa �6���V�璚n��$;�s�bΈ�N�b�1)J*dG�����B�ޭ@�'�u���=�'��	����;�C�
�Π���e���F�������@�({Q��0 ��P�"�׊�)(-��5�0X����V�\�0�O��	:�sQ�^�MؕQ�y�)����F��4fɰ&y��/�9F�v�>��Lq�Ϡ8�m����a�Yg�H�,�.���
����3��Ae�I�Ԙ�cDY����,c���P� �����{�p��H�I��z�D�%���׍����M���������!s��U�+�2:HK�*Ԋ���>��c��,ڶ_�i��a�*�����ʝ���ggP���۲u�L�
T�$�WN�9��n��e�*y�u����(5FLC%�g�Ŋ�D�QQB�Id�|pՌ��P\O����;#4�y�*�s��e�I�]�@���J��c�D-[��i kR�sT��&#v�����
E]U���4��,͠��0qT��Mf�'9B��e>@[�K�˺X�&�͒���s^\ �u��l�W�#���/Y�t�&4��+�f�D?A�Ge��A�!��48�"�B�h��kYǕS��5^u��:*�nӮ����1�Ϡ��N�58��/F��Y#�g�(�Mj�-���Ңo2I]�m�z0l�I� ����lz �W�>y~�G�D�/��1U�i�L���QGE���m������L�*�~��V� ��3h�]���O��a�N$x���e��s�#h������ Uy��f"�	��y��e4,h�������f`���I�3H$��d�2������M�
;T�T�fӚeW��?��n�lh��)�j�Zz��MU�6�����7P���4��24z��e	Y���T�צ��!���D�5��5���R/rr�*w��� ��O�8��Pl�V�J6%���tn�bm�*5�5� ��g���(a�	�],s��:7U��G��5 �����U���,Ҭ�) s�
4A���T�f����CD���x�C����f����*m���4�f���`��Bk4�Z'�V0ײuj��&9s���m�u��'�J RPi��m�S�(�f�0�(���{���a� �z�UD�B��*35CJ����+
݋ul	*���A���D����T˸@Qg#E��6=�x3� �@C6�Mĝ��5�z$�8��I��     ��jbȄi�@�c�6r��F�jDg�����=���k�o�|ܸ����y̦���!�9*���^��'/tG	�WU�f�q*�V��B���;*
�q+��|��a����M����4��k�jCG�sT��ͽ��!9��� Yr,�qL7���ۢ����5e�i�� :�?��+$�)Mz�W��քI:-K;h�0�)7��fTg���W��#� 'q��RW�4�|B�z����{>y0�S�<�(%�Z�����H�fL�R��5�+7m11���� �R&�0&7YD��ڍd�`�QS�����w\[M�rR�>��q+�l"�	���X������[�Sb��B8K���yW�j&]�{�s֔[r�(a�e<@S1սѲ������J�<�@�)��^uK8���#Բ���&�����9��'���5ų*�i����H��[B�|.��+���ۧs�Ϯ�3~%�c�A(	����"벨3DNݐA"�k��}�GR��h�� f��.M����&�5i3PL�]S<��DarY��Π�I��ܐ<Wͪa���й��g�l�yQ��������8�i�jS`͓b1*���A1+e�6����)Զh�
V3`+IF&D����;���lp���J���|����Kbjx�d�t����;���m��>$��C�Bu[�I(2�Ptl��.�]�v,������1߃��tGH��2���K�.J��F[
t��Y���G }����M��|3�$�"��՘@`�X.{�I��^,O<�AeS�d"}b�uiqc�d��>�7�B����d��BE��4]Σ�X�z���C�X0{��7w�~@�g�|��|K:b֢#Y��Ę����O����=9�89�O�^%Ef�:4K�US2$���^/رh�f���|E4<��~��'�Ǧ)�BgVq]���b2�4ӱj�p{ė��v��<�A�xլ��#������@3�f�M�� �v��Py󊜐a�}�IJ�#�ժ�:�#N�gw�ve�ʂ�1�:�sԔ?6�2~��zEh[�yB���є#&��T��7��ݎ��J���#T���[�r��)�U��v����i�,	��o���k5gQ;�@Μ�9�'sαp�ڴ��~0�9��W��N��j��6��]#���M�����&��Z���Ñ��p[���Fv^Ȟ���L�,k�%�͌�%�lG1��Y��g�ȭ߃��^��ݶ�Ϛl#L�$MI��CX�X<{��톱��Ӂo -O9J��09L2o�8o	�)�ճw�{d�A���Z�]��Z�hH��겡�L��ٻM�F�>EA��tGH̑���1e?�m�Cd�����+t��S��$o�t����Ӓ�����s,������E/'�N�A�2L1ܗm�"���6sT�����SHh�H�����l�b�I�!*:GE�ٴ�$�CY�(��G�Zo���(MbH�T�c�r��lT�_�P��g���wUUT'����s����CdȦB�����%�Lc����ZL�ɠ��]Q<�x�4����=@|�B�t�e׏y�	^a��8V�Z��^��])	?AP��FeZd�ү�V���@�'���� C`�O�A��̺�D��X��R�k���7�s���q�}f_�I����ģ��X�iNT^O�XA�k�D��$(O�	�����	�b�&��Zu&ϑ��̣lV�,1d'@�)�m+d�q���+9�qcbh�xH�v�I)tΚbU#�cݣh/+��c�\Q��MZg�a�U�c��ۄ�"�B��3(粮j�h\.E�����L���jh���G�;���q��jt�y1��Rvk��2.9�9j��&�s)�X�A[4��Ι&��TEm�L�W��7OgW����ѡ�T>�&�}$ƴxW�o�i:���f�6�Ȗ�AE6�1b:�q+���L,/��QU��iN��O���� e�s)H��VS>vU¹�OG���{�b�ۨ��P�Uү��M���n��j@���6I`w�|�Qx
�<oQm�e? �qI���<����l�{�LD���2 >���k�ѴAt��4��(R�sT��&D�_)��rD�.]c6/.S7z-+$E��5�I[��gBͶ�=+�<�C�[��z�(�9�)�~�1�g�(��q��JD��j�k\�:uY�B�ڱ��fs�N�4$g�d�#0P7�6mcy!�U�w��=g�c���J��N��R<�Ju��o�XE{��6~�'�b��t��<ѭH�L�]���5���6J#y�;B�Ƹ'r�|Q�(Ǣ���ٗ�){�f�yЃ/��~,6=�mfD������:�*ڛM�=�4�	�&+�8��,K�+��1�8V��m��>����;�W]!9o�>��4+�Y�J������ݤ�������	:�s�l��6��_�-��
bt�v��t�nU_���ڣ�l��������3h#}�ȸ5�Ɉ��P��X�7����+$���e>@��{����¾-�g�)��q$���m%�&����B�{���T0��a�I��q����d��/F�O���WSn6�Q�+�y��T�kFʌ�	&w�g���2��5e?�m��'H�'��2[7��U�����&�*��S�đO=�j�FfE��4Ӎ*ƍ��.2��h�6������c���m6b�յ4��iʖ\���.ı��fӞ�	!�b�V:o�a�P�W��V�rai��k��U��M��b�C�� ���Z�B4*�ذ(YZ�s�S�M���!	��7��	���X�v����?�����I�~Ȅ.[��dj�*�YS�����}L��5,��XpL��%}����s�Sn6m�z�����!��h�N1�I� �n��0�]�ho6Cۡ!d( �P�5����g�b��*e�Dd�U���d�\�v�8��Vh�m����V�di�$�B\�ho6�ޥt�?�0ZH�S�;��I�q���AV�ZE{���Ʌ�w�^!�Ӯʣ�c�R=�r1)�G�7�b�G���S~�5� /��b�(ڶ�$���]U�{E��3{g�ZG�YG�\[��>�sW�ݥq������j�\n�d�`��E�l�ډ�*�OC�e0g�A��\+io6��.�R��#��ijp�5��۹�)�cV�\+io6��;�	B��	�Y��� e5֑H��L�JZ�~��쁳�=?�ԏfBF�N�U%�b[2]-�t7~�oc�#��TVB�^��(�*+�;wU	��(~8A�9!sה��6�B�gP���6�uM�$¼�#�%� �ZG{�y��{�e�=@�QD�<�PWᾧc$XQ�������l�N�#���/� -uTDI%�jf>N�QG�}�)��<����2 ݏ��SMd]�"�}o�Q����V���؆�W`F�3���oZ�m�����aֹV����:l�C��A�b��	I
ݭ�r�����B\+iw�6r�e���Bs�L���mk�a4�|\�u?���."D��K����!�PQ
�m�@0�ʈ6:�O�)��q�^ʀP3�WhY���Ѱ�-|���E:Ƅ���V�{�U���g_�Iu�ɷJ�"N��.�V��6��{ �"�W�
���/
����\L=�r�JZ���{o�Jl�r��mI9F�hi���|�YQ��rK綦r��m�	Ϡ�3�Rwu�$����@��s�IlU<��y����m�ۊ��N�м.��G�����m�&��a?�ԧ����n��u���N)��#8V�Z�{�m�� ��3h쳸���z�$uM���mM��&���gRKaؤ�9��JfY>f+d��:��f�;5��]��@��I7�u�Ǣj��V��α��ڴG�l����f�W�Q:Uc�ldE\G�^�e�5��i��$��Y���f{�D�ne�DI��u&E!Po�f����m�9$Qǂ�7�����D���(^�P�[����5%�3*r%aP~�x̱�ڂT3C
�΋�Fs���6�{�'��_�4��:F�g-�m�3�E���:�c���\ɩ�qxm��vM�l4���R�F�B�su���۴�li۱�����K�&�&�%�*��g�8���m� �
  {b�s~��4���tyOC4�P�b�x6��7��6��}y�#By��f�M�늲U�-�E�dnQ��侥|�/��%�[��F�#�f���v :w=��d" a�gP��Hf��U9���|)����%�p��{a; TDZ�c/Ԓ�&K�2�ԅ8V��L�ˍ8D���Q� ��I�J32/�1H�^�1�'�[-<�<�q����J@S�r�pR.�ޢ�t�8����d�6ڰG���@y�F�TL�V�I-SF�Rmt�����4���ʓ�"$�*1��˛6��/�=a��6
<�=O���M5�`U���b�ѵ@�z�h�6o�<|���a�U[xD^ �Fkd��ho6o�Ƒ��w���\e��)�h�d�eu!(�c���^La��i� �.�ZAƖ�(�9�Xm�E@�(x?X�md _��A�@�<W��ÖQ���#���s�����m�q�� <�ʪ�L��y�@xW�Td\SH����ڴ��~�?���P�m,�dc9g��v��*59D`�mho6���!D��A�ڛ�Wü�8�r1��8M F	��|k��lk"�?��h����g�Aݖ��i���I:�=x?O�%�����JX�D=�h���5�J3n�}:����m� ���@�FS<"���fi@Ǌ^���}�6�ݺ���)�4i2狡kߡ,�|#X��b����no~��_^��,�c���d��f�vV9�9��=����Ď=8�@(�q��<�K�-s� T.F�>�G��@~ϡ�VF�i��,&��q�9�@�V�v�����	?�"�Ȝ,e�D��u���4�P�+
��;��0�{�V o�^�8Sl�9��RT�d+й+��;�`Y�E}�i�u�{��bL�VI���:�(��G�(�{��!�M4��:m١2)KS,��a���f�}$~��TwE���+Ƽ���	�r#й(
��{��p/9���}�`\��d̘�.a��ƤS=�&N/ԩ���MNl�a,���@��*a�m"�͒�S�)й(ʯM�/u!?|y�h�2�D���C61�o�hGt.+)�6��q� �m�g%QJ�4�FK�Di��P��\�צo'����,zu�(;�5k�K���i��B��hm�E�+
1y�t$&���Dh��t^Y�M�w� d.�r3I�{��O��PԎ�Ȣ8+2֪�'|l����.��ks��!��(<�p
A�M���\F���4�v�9U����5�������n�t�s��}�g�h'�12��פ=�|�q��G��t&��)�y���$�\.��0_��,Q/D;��7i�*�Eu��U<�uJ����q�է��{"LV	/�P/�TӖ��qW��� �
�?�L�B�\�x��S)&��#6�b�ݜ�gmZ�yez~� rz�����6��d�P�+	����D�g�tB�$d��G�� ���AE4���������$d���.v9�:�_Bd��^�^���Ak۪vj�%��R�T=��&�m����	N��`L��x����r�(Gt���QKv��Nqv���W$���Ф�R	>��=[ֈ&@�%7��^�E�����y��zR2e_�y��u���%�M~+�f�˛<"v�ajsm�i���L&�J��ٛ����������Bi�b(�+7Ig)�a�ԁ�`��e�g�	�K��Ǧ��=�X{��jE�����+Rt췍jY�Cu����i��z��3h�t4���L�l��))ۡa ��]Q��:��ҭJ����D��)8�tFt)m���@�(�q	�-B�������,5,RTJ�"��a�YG�e?.Amw ��= o!9� �I��y�7<�I :q��=��������;B��5����h�1�.zL*�ڡ�)�X�ތ4��<!�l���fKq�e=�c�j-��٩r��d`�� #潰!�S��RŢV�&ab{o��:���c��@��[�B��g}�QJ�FS�x�U�*gm��x<2��A+��~�M%�5�b�s!k�s�Pn6��X��뾅"Sd�������nΦn���e]��M��k�0C�A묦|��*����&�K.�
R�Ή�ڴ���Ǿ���o���Y);����N�\�zv�6g�Bߧ>?�FMW�9i&Ҭ�u�s�\�.��P����v~�����#͊~QŢ�s9��2)��N��������:�s�S�t���E�� ���'�4�"1�H7�WՅ:U����;�L�חy�0�O7N���H�uA���sT�� {��R�82_�:�He�iO�`{k4�tB�*l���q��E���n����>��W�I8��R�z��JpG1���#��&ٯ��!d���q�Q%Z4k���;����0[0d7=l�#����o�(N=�6��]�ԛ�G	�wT�?6��2b>zC�4/1޴�b�o�ʳ-��Ier�H�f���)��~�gsrJ�*7�{��|}���v?�і=0�3��QU�^�n�)���9�*lڜ
��CK�Te¶�O �]�dL��4��ݦm
���ň�B������nT��g�S�3������F[��ϐ�d����$�����4z}�sה��d�Z�"���g:wM��%�	�Q��.��t�K`~1�ϓ��H�+J����ab!��<����y���J�:�8�;�>�9Oq�/�������D������?`��      �   9   x�3�-.M,���4���2��/H-�@|cNǔ�̼�⒢Ĕ�"Nc�`� ��      �   W  x���Mn� ���Sp#�V�@��6dӄ�/rH=}qp�DI����oޛA�э���m�f?NkBۓ��g5�^v�=m�8
�@p{�?����|;����&� CV2Q�&\Xi���Ru�ũ��O
~��q�u>?JAxw��.��T5�3V��&��LZ��V��T޾�Up���=?E!R���#f̅U�ǩ>���"t���1{�Լ�4Ǆ�j����e\�z?&O;tm��bLJ]C���gX���*�k�מUйă��F�tO���6R.x"�MU2N�bV�57�f(���֏��S8c\�y,p�➎���bE
c��--��C��      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   "   x�3���/�M��2�,(���O�������� n~�     