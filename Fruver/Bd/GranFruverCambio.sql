PGDMP                         x            gran_fruver    11.5    12.0 i    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    140712    gran_fruver    DATABASE     �   CREATE DATABASE gran_fruver WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE gran_fruver;
                postgres    false                        2615    140713    producto    SCHEMA        CREATE SCHEMA producto;
    DROP SCHEMA producto;
                postgres    false            �           0    0    SCHEMA producto    COMMENT     6   COMMENT ON SCHEMA producto IS 'Esquema de productos';
                   postgres    false    7                        2615    140714 	   seguridad    SCHEMA        CREATE SCHEMA seguridad;
    DROP SCHEMA seguridad;
                postgres    false            �           0    0    SCHEMA seguridad    COMMENT     7   COMMENT ON SCHEMA seguridad IS 'Esquema de seguridad';
                   postgres    false    5                        2615    140715    usuario    SCHEMA        CREATE SCHEMA usuario;
    DROP SCHEMA usuario;
                postgres    false            �           0    0    SCHEMA usuario    COMMENT     3   COMMENT ON SCHEMA usuario IS 'Esquema de usuario';
                   postgres    false    8            
            2615    140716    venta    SCHEMA        CREATE SCHEMA venta;
    DROP SCHEMA venta;
                postgres    false            �            1255    140717    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
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
    	   seguridad          postgres    false    5            �            1259    140719    detalle_lote    TABLE     �   CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL,
    fecha_ingreso date NOT NULL,
    fecha_vencimiento date NOT NULL,
    nombre_lote text
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    7            �            1255    140725 q   field_audit(producto.detalle_lote, producto.detalle_lote, character varying, text, character varying, text, text)    FUNCTION     k  CREATE FUNCTION seguridad.field_audit(_data_new producto.detalle_lote, _data_old producto.detalle_lote, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    200    5    200            �            1259    140726    producto    TABLE     �   CREATE TABLE producto.producto (
    id integer NOT NULL,
    nombre text NOT NULL,
    imagen text NOT NULL,
    disponibilidad boolean
);
    DROP TABLE producto.producto;
       producto            postgres    false    7            �            1255    140732 i   field_audit(producto.producto, producto.producto, character varying, text, character varying, text, text)    FUNCTION     f  CREATE FUNCTION seguridad.field_audit(_data_new producto.producto, _data_old producto.producto, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    5    201    201            �            1259    140733    recetas    TABLE     �   CREATE TABLE producto.recetas (
    id integer NOT NULL,
    descripcion text NOT NULL,
    producto_id jsonb NOT NULL,
    nombre text,
    imagen text
);
    DROP TABLE producto.recetas;
       producto            postgres    false    7            �            1255    140739 g   field_audit(producto.recetas, producto.recetas, character varying, text, character varying, text, text)    FUNCTION     �	  CREATE FUNCTION seguridad.field_audit(_data_new producto.recetas, _data_old producto.recetas, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('descripcion_nuevo', _data_new.descripcion)::jsonb;
				_datos := _datos || json_build_object('producto_id_nuevo', _data_new.producto_id)::jsonb;
				_datos := _datos || json_build_object('nombre_nuevo', _data_new.nombre)::jsonb;
				_datos := _datos || json_build_object('imagen_nuevo', _data_new.imagen)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('descripcion_anterior', _data_old.descripcion)::jsonb;
				_datos := _datos || json_build_object('producto_id_anterior', _data_old.producto_id)::jsonb;
				_datos := _datos || json_build_object('nombre_anterior', _data_old.nombre)::jsonb;
				_datos := _datos || json_build_object('imagen_anterior', _data_old.imagen)::jsonb;
				
		ELSE
			IF _data_old.id <> _data_new.id
				THEN _datos := _datos || json_build_object('id_anterior', _data_old.id, 'id_nuevo', _data_new.id)::jsonb;
			END IF;
			IF _data_old.descripcion <> _data_new.descripcion
				THEN _datos := _datos || json_build_object('descripcion_anterior', _data_old.descripcion, 'descripcion_nuevo', _data_new.descripcion)::jsonb;
			END IF;
			IF _data_old.producto_id <> _data_new.producto_id
				THEN _datos := _datos || json_build_object('producto_id_anterior', _data_old.producto_id, 'producto_id_nuevo', _data_new.producto_id)::jsonb;
			END IF;
			IF _data_old.nombre <> _data_new.nombre
				THEN _datos := _datos || json_build_object('nombre_anterior', _data_old.nombre, 'nombre_nuevo', _data_new.nombre)::jsonb;
			END IF;
			IF _data_old.imagen <> _data_new.imagen
				THEN _datos := _datos || json_build_object('imagen_anterior', _data_old.imagen, 'imagen_nuevo', _data_new.imagen)::jsonb;
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
			'recetas',
			_table_pk,
			_session,
			_user_db,
			_datos::jsonb
			);

		RETURN NULL; 
	END;$$;
 �   DROP FUNCTION seguridad.field_audit(_data_new producto.recetas, _data_old producto.recetas, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text);
    	   seguridad          postgres    false    5    202    202            �            1259    140740    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
    id integer NOT NULL,
    user_id integer,
    ip text,
    mac text,
    fecha_inicio timestamp without time zone,
    fecha_fin timestamp without time zone,
    session text
);
 $   DROP TABLE seguridad.autenticacion;
    	   seguridad            postgres    false    5            �            1255    140746 u   field_audit(seguridad.autenticacion, seguridad.autenticacion, character varying, text, character varying, text, text)    FUNCTION     m  CREATE FUNCTION seguridad.field_audit(_data_new seguridad.autenticacion, _data_old seguridad.autenticacion, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    203    203    5            �            1259    140747    rol    TABLE     �   CREATE TABLE usuario.rol (
    id integer NOT NULL,
    nombre text NOT NULL,
    session text,
    last_modify timestamp without time zone
);
    DROP TABLE usuario.rol;
       usuario            postgres    false    8            �            1255    140753 ]   field_audit(usuario.rol, usuario.rol, character varying, text, character varying, text, text)    FUNCTION     @  CREATE FUNCTION seguridad.field_audit(_data_new usuario.rol, _data_old usuario.rol, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    5    204    204            �            1259    140754    usuario    TABLE     �  CREATE TABLE usuario.usuario (
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
       usuario            postgres    false    8            �            1255    140761 e   field_audit(usuario.usuario, usuario.usuario, character varying, text, character varying, text, text)    FUNCTION       CREATE FUNCTION seguridad.field_audit(_data_new usuario.usuario, _data_old usuario.usuario, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    205    205    5            �            1259    140762    promociones    TABLE       CREATE TABLE venta.promociones (
    id integer NOT NULL,
    fecha_vencimiento date NOT NULL,
    lote_id integer NOT NULL,
    tipo_venta_id integer NOT NULL,
    estado boolean NOT NULL,
    precio double precision,
    cantidad integer,
    disponibilidad boolean
);
    DROP TABLE venta.promociones;
       venta            postgres    false    10            �            1255    140765 i   field_audit(venta.promociones, venta.promociones, character varying, text, character varying, text, text)    FUNCTION     �  CREATE FUNCTION seguridad.field_audit(_data_new venta.promociones, _data_old venta.promociones, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
				_datos := _datos || json_build_object('disponibilidad_nuevo', _data_new.disponibilidad)::jsonb;
				
		ELSEIF _accion = 'DELETE'
			THEN
				_datos := _datos || json_build_object('id_anterior', _data_old.id)::jsonb;
				_datos := _datos || json_build_object('fecha_vencimiento_anterior', _data_old.fecha_vencimiento)::jsonb;
				_datos := _datos || json_build_object('lote_id_anterior', _data_old.lote_id)::jsonb;
				_datos := _datos || json_build_object('tipo_venta_id_anterior', _data_old.tipo_venta_id)::jsonb;
				_datos := _datos || json_build_object('estado_anterior', _data_old.estado)::jsonb;
				_datos := _datos || json_build_object('precio_anterior', _data_old.precio)::jsonb;
				_datos := _datos || json_build_object('cantidad_anterior', _data_old.cantidad)::jsonb;
				_datos := _datos || json_build_object('disponibilidad_anterior', _data_old.disponibilidad)::jsonb;
				
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
    	   seguridad          postgres    false    5    206    206            �            1259    140766    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    7    200            �           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    207            �            1259    140768    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    201    7            �           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
          producto          postgres    false    208            �            1259    140770    recetas_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.recetas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE producto.recetas_id_seq;
       producto          postgres    false    202    7            �           0    0    recetas_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE producto.recetas_id_seq OWNED BY producto.recetas.id;
          producto          postgres    false    209            �            1259    140772    auditoria_id_seq    SEQUENCE     |   CREATE SEQUENCE seguridad.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE seguridad.auditoria_id_seq;
    	   seguridad          postgres    false    5            �            1259    140774 	   auditoria    TABLE     �  CREATE TABLE seguridad.auditoria (
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
    	   seguridad            postgres    false    210    5            �            1259    140781    autenticacion_id_seq    SEQUENCE     �   CREATE SEQUENCE seguridad.autenticacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE seguridad.autenticacion_id_seq;
    	   seguridad          postgres    false    203    5            �           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
       	   seguridad          postgres    false    212            �            1259    140783    function_db_view    VIEW     �  CREATE VIEW seguridad.function_db_view AS
 SELECT pp.proname AS b_function,
    oidvectortypes(pp.proargtypes) AS b_type_parameters
   FROM (pg_proc pp
     JOIN pg_namespace pn ON ((pn.oid = pp.pronamespace)))
  WHERE ((pn.nspname)::text <> ALL (ARRAY[('pg_catalog'::character varying)::text, ('information_schema'::character varying)::text, ('admin_control'::character varying)::text, ('vial'::character varying)::text]));
 &   DROP VIEW seguridad.function_db_view;
    	   seguridad          postgres    false    5            �            1259    140788 
   rol_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE usuario.rol_id_seq;
       usuario          postgres    false    8    204            �           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    214            �            1259    140790    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    8    205            �           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
          usuario          postgres    false    215            �            1259    140792    carro_compras    TABLE     �   CREATE TABLE venta.carro_compras (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL,
    cantidad integer,
    estado_id boolean,
    fecha timestamp without time zone
);
     DROP TABLE venta.carro_compras;
       venta            postgres    false    10            �            1259    140795    carro_compras_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.carro_compras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE venta.carro_compras_id_seq;
       venta          postgres    false    10    216            �           0    0    carro_compras_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE venta.carro_compras_id_seq OWNED BY venta.carro_compras.id;
          venta          postgres    false    217            �            1259    140802    factura    TABLE     �   CREATE TABLE venta.factura (
    id integer NOT NULL,
    precio_total integer NOT NULL,
    fecha_compra timestamp without time zone NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL,
    carro_compra_id text
);
    DROP TABLE venta.factura;
       venta            postgres    false    10            �            1259    140805    factura_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.factura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE venta.factura_id_seq;
       venta          postgres    false    10    218            �           0    0    factura_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE venta.factura_id_seq OWNED BY venta.factura.id;
          venta          postgres    false    219            �            1259    140807    promociones_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.promociones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE venta.promociones_id_seq;
       venta          postgres    false    206    10            �           0    0    promociones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE venta.promociones_id_seq OWNED BY venta.promociones.id;
          venta          postgres    false    220            �            1259    140809 
   tipo_venta    TABLE     U   CREATE TABLE venta.tipo_venta (
    id integer NOT NULL,
    nombre text NOT NULL
);
    DROP TABLE venta.tipo_venta;
       venta            postgres    false    10            �            1259    140815    tipo_venta_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.tipo_venta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE venta.tipo_venta_id_seq;
       venta          postgres    false    10    221            �           0    0    tipo_venta_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE venta.tipo_venta_id_seq OWNED BY venta.tipo_venta.id;
          venta          postgres    false    222            �
           2604    140817    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    207    200            �
           2604    140818    producto id    DEFAULT     n   ALTER TABLE ONLY producto.producto ALTER COLUMN id SET DEFAULT nextval('producto.producto_id_seq'::regclass);
 <   ALTER TABLE producto.producto ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    208    201            �
           2604    140819 
   recetas id    DEFAULT     l   ALTER TABLE ONLY producto.recetas ALTER COLUMN id SET DEFAULT nextval('producto.recetas_id_seq'::regclass);
 ;   ALTER TABLE producto.recetas ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    209    202            �
           2604    140820    autenticacion id    DEFAULT     z   ALTER TABLE ONLY seguridad.autenticacion ALTER COLUMN id SET DEFAULT nextval('seguridad.autenticacion_id_seq'::regclass);
 B   ALTER TABLE seguridad.autenticacion ALTER COLUMN id DROP DEFAULT;
    	   seguridad          postgres    false    212    203            �
           2604    140821    rol id    DEFAULT     b   ALTER TABLE ONLY usuario.rol ALTER COLUMN id SET DEFAULT nextval('usuario.rol_id_seq'::regclass);
 6   ALTER TABLE usuario.rol ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    214    204            �
           2604    140822 
   usuario id    DEFAULT     j   ALTER TABLE ONLY usuario.usuario ALTER COLUMN id SET DEFAULT nextval('usuario.usuario_id_seq'::regclass);
 :   ALTER TABLE usuario.usuario ALTER COLUMN id DROP DEFAULT;
       usuario          postgres    false    215    205            �
           2604    140823    carro_compras id    DEFAULT     r   ALTER TABLE ONLY venta.carro_compras ALTER COLUMN id SET DEFAULT nextval('venta.carro_compras_id_seq'::regclass);
 >   ALTER TABLE venta.carro_compras ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    217    216            �
           2604    140825 
   factura id    DEFAULT     f   ALTER TABLE ONLY venta.factura ALTER COLUMN id SET DEFAULT nextval('venta.factura_id_seq'::regclass);
 8   ALTER TABLE venta.factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    219    218            �
           2604    140826    promociones id    DEFAULT     n   ALTER TABLE ONLY venta.promociones ALTER COLUMN id SET DEFAULT nextval('venta.promociones_id_seq'::regclass);
 <   ALTER TABLE venta.promociones ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    220    206            �
           2604    140827    tipo_venta id    DEFAULT     l   ALTER TABLE ONLY venta.tipo_venta ALTER COLUMN id SET DEFAULT nextval('venta.tipo_venta_id_seq'::regclass);
 ;   ALTER TABLE venta.tipo_venta ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    222    221            x          0    140719    detalle_lote 
   TABLE DATA           z   COPY producto.detalle_lote (id, cantidad, precio, producto_id, fecha_ingreso, fecha_vencimiento, nombre_lote) FROM stdin;
    producto          postgres    false    200   Z�       y          0    140726    producto 
   TABLE DATA           H   COPY producto.producto (id, nombre, imagen, disponibilidad) FROM stdin;
    producto          postgres    false    201   ��       z          0    140733    recetas 
   TABLE DATA           Q   COPY producto.recetas (id, descripcion, producto_id, nombre, imagen) FROM stdin;
    producto          postgres    false    202   q�       �          0    140774 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    211   A�       {          0    140740    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    203   �      |          0    140747    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    204   Qg      }          0    140754    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    205   �g      �          0    140792    carro_compras 
   TABLE DATA           r   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id, cantidad, estado_id, fecha) FROM stdin;
    venta          postgres    false    216   �i      �          0    140802    factura 
   TABLE DATA           l   COPY venta.factura (id, precio_total, fecha_compra, usuario_id, tipo_venta_id, carro_compra_id) FROM stdin;
    venta          postgres    false    218   �i      ~          0    140762    promociones 
   TABLE DATA           }   COPY venta.promociones (id, fecha_vencimiento, lote_id, tipo_venta_id, estado, precio, cantidad, disponibilidad) FROM stdin;
    venta          postgres    false    206   �i      �          0    140809 
   tipo_venta 
   TABLE DATA           /   COPY venta.tipo_venta (id, nombre) FROM stdin;
    venta          postgres    false    221   j      �           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 66, true);
          producto          postgres    false    207            �           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 35, true);
          producto          postgres    false    208            �           0    0    recetas_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('producto.recetas_id_seq', 2, true);
          producto          postgres    false    209            �           0    0    auditoria_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 2314, true);
       	   seguridad          postgres    false    210            �           0    0    autenticacion_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 846, true);
       	   seguridad          postgres    false    212            �           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    214            �           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 32, true);
          usuario          postgres    false    215            �           0    0    carro_compras_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('venta.carro_compras_id_seq', 1, false);
          venta          postgres    false    217            �           0    0    factura_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('venta.factura_id_seq', 1, false);
          venta          postgres    false    219            �           0    0    promociones_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('venta.promociones_id_seq', 115, true);
          venta          postgres    false    220            �           0    0    tipo_venta_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('venta.tipo_venta_id_seq', 2, true);
          venta          postgres    false    222            �
           2606    140829    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    200            �
           2606    140831    producto producto_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY producto.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY producto.producto DROP CONSTRAINT producto_pkey;
       producto            postgres    false    201            �
           2606    140833    recetas recetas_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY producto.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY producto.recetas DROP CONSTRAINT recetas_pkey;
       producto            postgres    false    202            �
           2606    140835    auditoria auditoria_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY seguridad.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY seguridad.auditoria DROP CONSTRAINT auditoria_pkey;
    	   seguridad            postgres    false    211            �
           2606    140837     autenticacion autenticacion_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY seguridad.autenticacion
    ADD CONSTRAINT autenticacion_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY seguridad.autenticacion DROP CONSTRAINT autenticacion_pkey;
    	   seguridad            postgres    false    203            �
           2606    140839    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    204            �
           2606    140841    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    205            �
           2606    140843     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    216            �
           2606    140847    factura factura_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY venta.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY venta.factura DROP CONSTRAINT factura_pkey;
       venta            postgres    false    218            �
           2606    140849    promociones promociones_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY venta.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY venta.promociones DROP CONSTRAINT promociones_pkey;
       venta            postgres    false    206            �
           2606    140851    tipo_venta tipo_venta_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY venta.tipo_venta
    ADD CONSTRAINT tipo_venta_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY venta.tipo_venta DROP CONSTRAINT tipo_venta_pkey;
       venta            postgres    false    221            �
           2620    140852 %   detalle_lote tg_producto_detalle_lote    TRIGGER     �   CREATE TRIGGER tg_producto_detalle_lote AFTER INSERT OR DELETE OR UPDATE ON producto.detalle_lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_producto_detalle_lote ON producto.detalle_lote;
       producto          postgres    false    200    223            �
           2620    140853    producto tg_producto_producto    TRIGGER     �   CREATE TRIGGER tg_producto_producto AFTER INSERT OR DELETE OR UPDATE ON producto.producto FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_producto_producto ON producto.producto;
       producto          postgres    false    201    223            �
           2620    140854    recetas tg_producto_recetas    TRIGGER     �   CREATE TRIGGER tg_producto_recetas AFTER INSERT OR DELETE OR UPDATE ON producto.recetas FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_producto_recetas ON producto.recetas;
       producto          postgres    false    223    202            �
           2620    140855 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    203    223            �
           2620    140856    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    223    204            �
           2620    140857    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    205    223            �
           2620    140858 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    223    216            �
           2620    140861    factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_venta_factura ON venta.factura;
       venta          postgres    false    223    218            �
           2620    140862     promociones tg_venta_promociones    TRIGGER     �   CREATE TRIGGER tg_venta_promociones AFTER INSERT OR DELETE OR UPDATE ON venta.promociones FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_promociones ON venta.promociones;
       venta          postgres    false    206    223            �
           2620    140863    tipo_venta tg_venta_tipo_venta    TRIGGER     �   CREATE TRIGGER tg_venta_tipo_venta AFTER INSERT OR DELETE OR UPDATE ON venta.tipo_venta FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_venta_tipo_venta ON venta.tipo_venta;
       venta          postgres    false    223    221            x   �   x�u�1
1E�?wY�L�AK��b3.�]X7�j�<�3�&�/~�����fxa�c�ֿ���f�2����JK��n��u|��n��b���ޞy�;B��M�`{~Xo�D�������O�<MF�} ��0<      y   p   x�36�J�K��/�L䬋���MLO�K-�����s�pq:g$�dޘT��Y�ސ�7�*�(�\� L�	�czibrbI*�2�(L�)�sjR~N�iPA��=... YvI�      z   �   x����
�0���)B�R�����CAġ�u�6G�������g7��:8����r�}\!YP �YCb�;#���r����Ə�#�W��B;P>.|��� ���ҿ1�����iG��'�VC����`-u���y�@��{��Ibڷ���$+�&�L���ͺ��u�~���T���Gç�L�[��e����}      �      x�ܽے�Hr-���+�깛�K>Ij��ΘzL6��26fm��
$A�v���7�w 37@$�بꔺKR)I�����p��pg�a�τ���_�x�U��P�i���������V�Ut\��2.���8f���������*;�����:ʳu�K�ů����hwʀ��_���o���p� �+53n��!�F��7�"?�����u�W~]��Q2{R�Y�0v��M�O�m��gI��HX?;��{~7˫<:����ʬ,W���`��K��,/�1u??MW�,I\�����V�z,U�����=C��lWOW���o�t5������aV�`~�y?�?�h�G}�"�}�S?�b,�ۢ<T�����)��E�x�W�gZS%�����_���]��������Z-q �,�SFQ�h;_o���	ma��7N�*���������2JV�.�~��_�Yz�Q��3�~}~�R�x1#�epe�����+=x�><Y/��y<�}�qX! �;Dw�}�M���F��M��4Y�v����_����z���%����2=��h��Ga����gV���p�����M�c���Rw�����ӐA��MւOJA�"J�DF�8ISb�"6KI,R��F���xd*�q��4��Rbp��O>k�"\i�Z&���U�\�1MeJ3�Xq���8�T��W��9�q�DJt�k-*{��R���L2%�������m�O$�L������q�F:Q�QC�(s��1� "5�[��r	C�Ϧ�⾱�Gc
�{O�&ޅ	�HM���aRB
�e&щ�1�Yd�1��I�dj�q�pIc:��Ȥ�6J3�a��AD����-�_@���h�!i�C��Lq�y=�s�KV[8�N��t>�;;23L����2}��dFЪf>�3���J;c�2�݇��s�$&t����9���$�	�0��,�#�M,��yfIY���&q�H�d�?�ShI�|"j��n����|P���Dn0��4ܞ���P�f�5ҿP��-,3k?1�,�Í�(�K	�I�s5Oi�97���%*��X�3W�d�H���ܳQM�#�Ϧ���v���tt d6M�ͼ2�!5�=;�mM�gS9�)��� ���'��(6ZQXF6�s��3
�&3���*%<!&Չ�c��JbG�0p���i��ٜBGf��g4��:<����y�P���B=��a>�+ѯ�θ���'L�0ɈH�$VQb�fJ3�I���9��$��Y�S
�\h��J<�s
-��2S�0e���Ղ��v�UJ��|���|Ѕz>�o>57O�gLĢ.1MCa��$L�ʧar �a�=0�j�
�tr������az �I�4�V>|�`z�ab�g3J.��&ww�$�	O����q�HéI��v+��L18aMD��dzN5�X���\P�%6Ş6�QO�]-�O�����t�|��B=�ԙO
�������z��糳�/��ef��":�m�K��%'�I��7\���x����%k��c�'4.��&܁�WAgJk�]��_�Lt��[����. �t��Kɭ�P��֧2>���b���+^��-�5
#f�Ji�%/@,xxS
�i�����z%l���>��~1��^K����+���Ij�˒=,H��̈�Ջ;���w
Nܟ��\�� �J���J�و_�H���/��J�vl�D���w�-��*��oQu�c�D:�kvY]ĥb�+�-���F�j�	��z��-ղlF��	6��C���Vt�/����W�o��F
}�?����g�2��|�9"���������n��0!�hd/\< 
�'�
�o*��P��}�
�P�^r� J	�9X[p�O���6�30Q4�^���bx���P���E'�K� @�4��]@���pK�Ā���@��(P6h��>ߌ�}�jfQ�M���֢kpo�-�6�o������2
:c�j�8� :�pb[&D(�4�}3/���2��Sɩ�P���˚��\��C��o�E�.��Iqe��fS�1��٩�"�}$��%/���j��b�>5���Z�N�o��"@��.��U�8�rx��٭<���e�����|�wFY�tbW��~<���tI�"@ًp=%�D��j�P�d|>�$[�rK�YQ��}-�Љ]%��ֲs��]0�m����W╀i%�Ѓ�R���{v߈�Y���Y�[�/����Β��hH�5%<|�?� ��E�{K���ԁ5�z��%�H�C�X7��O��A~*���$q�����{+�
�hx�d��#��|�zƤ��>�ë?n^���Ƀ�MR�?ϗ�O_*oo�)�c���e����=�����ʳ�7��&��>�ɮ�/�t灑�\(��]�'���
'o����7!1swN�P�m������g�;SԾ���/���������tYw��>#��]6��l����/�"Iw(������|�e�83�m�LmO#�}��aL�A��Z˴�y�y���j_�d�>K��$df�q9�yK�Ǿϒ�Y2�	������� �K@� :�/�#}R��2Nw�������{,�*9?�峨�6Z�������?�?f%��6��$��w��-���F�}�[ūg��+�c��*ك2�:�ϔ�*��Pl��}��^bJ��h3ϗ��� �v"�?�>�#��]v�,Ճ�B/�z�܁��W
R��{�� ��X��(�����J	 
:*\@9X�3f������		~5@9�*M�Z;4ʲZE틔��RM�䋾���(�����'n��|e��WC���	"�/�zi~0_�v e�S,��|e� �C��s�����4�(}��A�SL\��᫪g!�Y����#�zi R�"mR��m��Y���\����}Qĝ��1�H���4�ȳ�̓����vF9�p<�������;�ۻ���^w}6�N�����wf��Y0�_���~�;�b��dw���[<?F~��e�|+�u�J`W�l��∸����M�~oD�[+�iy�)��5�#	��l�/��E�sU�mD�3+L�ԥDŋ�����|8��Y@�"6_P��8��� 0勒.�]x�QS����Jh֢Si�L��DՋR�\că����E<��(:l�B����^@T�(� *.xa	��>�!ڈN�@[��yQ�M��z��+���� }4�EWZY�wi Q0����z������sƂ�|�N���8?����Bo��|����V��`?�C�}���O �B��h�L%uV1̈罒���%�NR��}�R�[�m��?mAn��䍺��)��)�K'��1"��S�{�/��U��7����А�W��o��P��;��������*��܎�k��F��=��^ֵ��~_���jp(1�Z�>���Z>Ɵf�(ϳ���)kSd���:����ղ��WҲZt)��av�K���]D�+73�1"���H�Q���2R�S�`hUƐCfBtg�@ͭc2�Z���+'��8�>��qGL�t&LR|�h��!�oF}w_h3jDgP�0�ǥ�͈�h�"ڔ3Rө�r����3��
s�]@��/-��Ѐg
�"���o�����W��C��mD��n�DtM��r�����.���Ct�����hDщ�*�/wH O����'�c��$'�/���s����p��l���*,Rܢ�T�� ��%6�X19z�i#��#ڈN%&x�?� ���PQ��%�L��mdj#��U�����DH��3�=�r�`�?�`f/���YS�[�|�yӳ��	83�������a-o��'=��lh�y1-/�����;&	����v��l~Y�I�g��t,J����>8�"��?��m�?�o }�~�^���HgFJJ6� վ�Z�30JJ2�-I酥�z�_��Xn3�Z^o�r%}a���7���P-�R���p=4�}���P�+c�p׊W�xԾ(�W�]zM4���P�Q��#�;^�Mj�7��@m������@���]P�    [Ii�<���ϡ�b���s����� ���T��g�����gA��i����B��uI R�b��z�z��+|���YH���/i-=Q���cʡP�%���̰���&D<j�k��@���XK�\W<����B�KH��w�VP3�~���~-H��*$Ѥ�@�/���Z�h�k����#.�b7��i�[�M#/�9������j2�tȶ����e^-���^le��Y�S����R� F�G#�D���y��~��
D�8�|x{���Am��3F����P�}�����ݾ�à�.U��Y�˺�G�Kv��a����.|�G�Y���LpId��:4�}���>z��2r>��6|.��d��e�l�"Jr�W��p<�>�#�|���x�/�� ���*N,�Ǭd�埅��~!8�'����8ً}�m݆AϤ��Mg�h�؟����"�.:eA�,�$�'�����-4 �Y<������Ktˍ��ǑC���dD��P�h3��ﭯ�uEѱy�p�0�BY^�א�Dr �����N~ �֨�:���l���#��>� ��F�v!�`�*=��@���5�O�͵���fq�"��>D{KT�F���g�΅V*p��C�j@��[j:�ª7��j8@���T�"J�&��Y*�;�Z4i R�r���҄�|��������ڇ��}X0�m����4�`c0t8�����N�ׁE��@�[��o�@�(È�LJŇ_?ho�����Qt�C�	3�]���n�>W�\T"i@��kz�N��VK�h��$7y,���{SA�13�yL}��`ʾ��n0�v�ӥL`�]L������g1�M�J�Z\��=�� �05��~hE��~bϖ}�?��C�x�#ۯv���[�iOt���(/3,8K�u�N��ъ�QQj�����%�J&$4��ϋ*J�S��$�_	E�(�t��}�`���5ڛ^��֨�כ������Kk1e���j(	�?�b�ר��5:\�����(wǎ�x3p90�d�j�@����k?�]9��
�N�׽I�_H�ٹ�!م] T��V�>�\x(�9c�n��|�k���zh���]�W]�ҡ�eG�_�y{F),�v��M�;�m��T�p����YlQ��ͥ�!���x�_�_��!���J���ȇ������0��vi`2qy�Hm]�D͸��k?��#J�Ϋd�yF���7��)ђ!����׃M�����$�넑��h		~&M
�Nvz�����bby�Kt��<K�Gq��j-q3ֲkD�z��=N�~h5�
?k����|���M���J�����b�?��~���L���o_�|q<5��=��Ckھ?����NzZ�v_<�'n�*!���I}(2�ί�T�M@�x�ވX��W��&'m�"�|��۸���}�F*���Ng�%tH O��@�+!�Cfl��EǞ�׈��t(�%��΍26$XإH@�]H16�D� ��L�*>����Ƿ�5�y��7�B��׊m�a��>�nk�EWF����.@jRхT�Q���'վVl_QifF��A��o�4D��(� f�M���	�����A�{��}<��%���}ЄJ��j���h��`"U�W��w��@�֮c�K��
*�h�}�g����=��,b��1�k�7N�}��+v-�Z�t��W���f�@:��tf�+;��Ub��cZ�K_���5����hHх�$�f�K�2��>@��23��e0q����0����ݖ�2���z�A�k�7R�����N��Ai�]��N\H��+�²��������}H)�X��ɐ'�=4 �x��dR���o��τ�#�ࡰڢO��o��d�	��x+t����P����\f�89��<�Y�>y�._�qJ��>Z)Pt�g�*\)h@)$@�HeݕVH�����Ѧ�η8I��M���3�K�}�������EۂRAB��4 )��\����7l�8���^��(.��v�]�&��>H�u�}�G����bf��E��$ (��\��֏�V�=��~��<EہH&~�0�P�X�l���OE1��3QL<ETw2�`VR���^h̟|}&ߠ{������l?4"��W/�/�T#������樉�u4%�[����Hx[��PX���R����_�K
�fVF�k��E�u�>����fQ)�;���i�k>�c���Ct��z(إ��Ҽ��u?S�5�c�f5��v.�zͼOz�u��ּ��jM������T�̂�����~�%���"ö���a�A�[�SUw�z�k[�!M���:��Kg�>�+y\v��<��}{^�.�tey��z�i�Ȣ��huB�I�,2Ě�Ҁ:��k\H�q���;��ɲ}���f5_9g�U	��fK|Q�iC�>��!�E��i�ҭ��o�TPR��Ԅ"B&"�h�H�żd�U$n�muJ����5��|��CZ��%%6�6@JR�B��f������7=׸�^l�r�z���@f��;�z(U`���`Лn���K�ܸA�f��;V�}����Acm~F:?�M����X^���@���,΋��x{���D��z��:���~�Kz� R�B�^�w�Fi����eq\y��_ղG��Y.ok���hj�û���*�����l��V,N[ɏ��f�`���x��EWBɠF]���V4z��c�B׳��q�'a01PȐw1�g�����-�ފ�8����73��\}�G�L#:Sڲ��E�f��ZOR7�f����uz[J��Nר���;���ߘi#�>�!mDW����4 )h�t�'i�"����1�2�,J_���w]$���d�X��aU.���~%�B\v$�E�^���e���^f�ȫ��H�x��1'�@�TC��)���뒍Q��#�M�p�*�R��H|#���?������<p�k�(�� �5#V����%`A���k�4��L1���gp�2#��	 ����/�h�_�����oH�;��y uW�V���	�D�H�������8���5��K�]�Tv~Ѓ�Ɏ�n���||!@��+������#sЃ��M�Zx%x�8`���*���� i�?Ϗ_��»c�	Ԍ���W/4�S�G���/J�h��q��Il3Ô�)��,#~�m|�ܟb�7�>�a�4_���C#��X%�xx��!}h���_ޖK��p���D'*N�a^,��bE��l{���mʹW>�c ���D�M�5�H@*\H��BY*��˝$s��,��z�/�z��e�t�p���xH�^�
�CڦH�(l5FHMm�x@:��m��T\��=]�|U����i��>�#!}](��.̺4`f�T9��l����aR�n�'|u_��,�]�W_�;m8��}4���pT�K���*��	.|��������?��k�����s�~N�E����<@`>Dj�Ow��_K�����:�풉�Z���Nr�s�)yx �����-���Es���O[ӆ���vf^	�5�P 4��q��u�
>l��χsr;���@w�Kr_����+�g{��^4(z��@�aui`р������ĴX;��g�(�Q�~]3>Uˋ2J����.�F�ʆ�0^����1�9G�"���϶�K�I���Iv�Sv��.z�N<Ɏʎ��ſ֕-�kA��9lB8���m��r�����7�>K��=��o�N{���޷r��ի� ;������=4�rRׂ�uf��e�B:���3�m����z�K���ݓ�3�RN�!��ó�N{q��CI�<��.B^�ti R	��G6�K��������,��^8����Z����]�T�օT!�Z+;l-�l�����|MS:O�_��� �6��>~�עK�h��.@�_h�3b�����2|�)��L�|����)[�ѩ*�%��/��a�ѐ6�k��ui R�b�kX�w� llRQqU�ӎ�3���5��2_f>    H������ :cʪ���GU�� u-RI�6R3��^C�O2�I����鴢��z#n�\z_ZM���i#�䄉`Lh�uP]�[2�'=���8ov�-�W��}��ٽ����d�H���xPkٙ�aU��4*83��.���S��Q�U����9�qB�m�I����֦dZO��~<���Z쨷IRp�̃~*�c�3E4cË!�2�s�%"��~�v[_IJ�u�|��A�&;�\ҠƆ]|(�P�0��QM�N&�+ί	��o�[� y5����W�i�(�Ѡ6�ß�[�.�
^�y�X�SWcaf�M�ݓu��݅XE�=��8m#/�ӺQ>�#A}��iԄ�C���eLR��R���=�gQ:�V�]�n���v��7<�p{�������u��ƺpi<���\�FΫ�z)��(�k��*�^}9�L�u�؏��Zv͍��ڡA��RT�=�f�Ҿ|��k	�"N���G��/r�Ɔ���{T������ĕ��g��a�WE�H�6���</�u|Y\�Q�|�5%�z�>���F�Չ�5V�]�4�6�Z[���Lt� X�e���0���7�C���V]�ͳW�:W��؈Wf2W�\k6���Y��3if"���]�1md�0��A,b.��4�˖����i^^w�St^n���5�dڀ�������ZH���W�L�����H��f0n�ي�~���&�,v�;��n��xA�6$�c?�Fv�&ǥ@@- ��=�7�Lj&��ӕÎ�蜋C�f�~ݖ$�/r/�t�x������]v��j)ڥ��m�B�vAUx�S�]��
��b�Y��n{�_�˦��wo��N��j-;1`���\bkPi�T����e�E���	,�?������j�������u���]�>�����S����,�Lr�{�N~�S��)Q����ޞ�)��vQ�3`������r��yr#�e���˒��wM���Pv1���\D@�]P��YB���p��d����Z�(S���gE��i���CtP����f�Ȯ��|Ki���Qs�A��bK2N��F��{���FgZ˟���'��ѹ'�`����6�A�x��ɚ�������z��=td-���������}��Q�g���oŅ/����N����'7�K����:4�'����_�r&��d����3̳�8?(�ۓM�?��<�+i0�m@p�i����bb�ij�ڙ�`�:�� LYӺ�	'�����#ݳ��ԑ^� ��ByWT�4�L���~QEs�S�U���y�hQy�o*��8>�tEexsl���D�?U�a��9�����|�/y�X�� QY�̴�v>��7�Zv���~tip�� �vA��F0.�����v4��A�������gl߰�ط}f�R�_rN&��HWR���V��&�c݆ԗu�+S��oi�XQ�#2�̠u8��|<���W�Bws넩DO�\�%�<���o��5�8V�	-�p��}���6���y��:)��p<z3B)���������L����� T���.S!�δ{�iﬧ��u�B+0��� �@u�*�����3A]8,�kU����=�	��٢\[��W&f
|��@����^�݅�";޲功�7Ц���?յ�S�B�zuip��c���-n�JJ�4yn�]�@ԭ�5L����	-�UU����9]���"�N�t�c��科]hNM��C��c_wM�� 7�
|a�G�T�M��"��|����]D�W�g��N����O=�a�~��,p��7¢�v�!�����C�p�X����Z�|5:(��%�����R�.8�����# ��u�$e�� ���G�c�j�k����ä
N�/mE�a��O�O�ȡWqܵE$�SL*i�`>���N�Y�d{9E�}����:ew���T�9C,��{������V�l\j���J��x6Ю>>���w�q�Fل})NQ��urf��ru&�f.7�,�1�kϴ� >�㵧]H�:�=m�<�]�o��/���,C����Y�����iפ��+��r�}��@�+t���>�v��Д��7�@n�H酭��m�\��8\��]��d�l��Y��+��< X7̥����n:a��[�hM��K���������s1�Țg��M���i/-}�ǀj�Ȯ�5:�N�K��
 �9�b\HΘ$F�|�w�����t�ė-]�"�E��>Zc_�x؏e��mAy�.*Ж�l� �>D��~�=�4����ܒM,��Cr�����@��7����Ɇ&�4�P�����ʾJ�!opy;o���*a��:��[��tΠ`W����.U��%֫�H2h��w7�.פ���z<�
&v7�jִ�Y�њ��N4$i�K���T�Z��6V�ne�Œ]Ţ�i����V�E�U��W3�����m�^�5�����=�0����}�)�:����uGc����|�ښ��{?gr�����?�nO���(�|1��>��$�9cr��=�D2��ٵ�^Գ"0t�}z���'�͚�d<_,rQ	�s�n�Y�S�J�g?zC�a�!Z]/uip3/�݄���n��$Ruw0�{4���=��8�n_�=��ud�Z]
�k��N���n�t�|��fBpm��;�ջ��Zs'������^�S1&o�'�5^���)P��:c�]/��vu���jw]�,/˕w�O{��c?~�ײKBD�Y�@�k����"$v�����Z����Y�]�5�%��կVX�3v�����k�����eL�X̞���W&d�����կ{W��8��?_���i����<������)z���+�p(F��p�x��ŉ���QnDR�/��p�C��^��؏\��Me�%������䅵{�4����	�so\�eӳ�G,��(������EA)�}Q����a�%m�9�\���^������������q[�����Y�.%��[yc��2���[���m���	<�G��FvJ�	j�إAeKS�.����h52 fbޠ���?iH�֝X���0(i���qV�(����&���v��:l�	�ւ����eJ��Z|�kQ��
��c�V	��:4��0���̴e��2��C�b��Z���n�gq��t�u�4�Ѡ6�K��
��(��Ǧ&��|�j�t���z[.�)�ի��Ɇ���ek"+Q������8��N)��<���x>�㧶�]q����48��i�Ĉ'����|�i����]0j�z uiT	���%~�δ�}��	G��k�6l~���芋�ۉ9?�p���3�k�T	8µkb�o5��h=�rf��8������#��ws�����k���y��5�������X�����'��WxsB���q<�:�H����x*�z����U������yY�0Z�Ju�v��)�Om:��x��?�����"�hս��;���x����ɚ�n�A����}� �Cv(v�Ze"�;R����63��~�]ˮa*$٦K�G�P;&����`S�q!�Z������#�`���?yV���B0U�>~Wؼ0ӱBmSi�1��`O����ȁ��g���.|l'�S�f:�c���%�����t�N[��V�,	K{�厹���SNGsK@t���$������0�-'��f�������v4���E%�)�����W~��Q�]���3X�q¨@a��·I��Ợ�b\K	K�љ�w��Ix�$YF����/l��8�����q���|�����;�C=�����6
f1�s����ݍ��lF�g8l��?�j�J?�lF��2�جAK�`>T����|�7r��Dl��x%woaM>mB��������CLHBg�~a���o�6�7$Õ��lG��4N�2�l�ծ("�x�$3��ֲsi��n�AP��k�kh@����ni�۟���X����J���"��^P����j#��Z�h|�jT��^	�1|*0���"]��rw=�    c�"c�M�UL\���~<�����X���juA� U�1�_.�$%���ݒ�5��u��˼��Ĵ��>�?*^�a��~�4*�z�
o������T�͹:���+*��wk����'�N{��c?�Zvi��R0�mN�V�c�I%����#��4Z�DE2�V��|�Jb/���p�؏���Ό�D\��� �`���(4�RY�0�Z�*�1�,��p��5X3��9y+�i�}�G���n���C��
 U;�6�̴�k�.>-+0�IY��ە�ˌm7k��61�ݢ��hPٕV!�{]��V�R.�m�!��o��RUY�6`.n�ݾ���k��ic�>��!md�\r��4*���:�
|��̩�4��ݱ�绌�O�yt�������bZ��~4���Z]�wIR��	q!���@t[ݶy��Uu���|�猉ʿ�N�L�؏G�]j�BR5zhS�RS)q {N�Ak*���q~�\�+)W�EI�Δ������hP�������@���KZu(%�c�uAsͭ�OTa	o���7��8a�\*��(�Tz0��(�{����<H��eǼF��և�?���ؠ:�=44$ jˇ��4-z�q.-<Y����@9�hK��s�?��VXrZ��~���@vF�	���AP)�*P��J;x6.˻�/��������ӑ����i]8�ј��>U���{�AL`*]L5f�Qj�p��D�ꖯ��N�y|*�rs�����i]8��j��h�cᠶiT��[�o T�G�n�$������Xr�*(���7=n�=���.���8P?dTЮ��A/�շ�T�*�e*�5`Kݮ�r}%�������'�א���z؏���Z�Bʉ�� �@5�������O��P����2���Z+�_,�u�|�G���N��A�.�� T�*��e���Y˒�7���i�����T��xc�rZ'��~<���J
��uHRp�Z}�� �uu-%�`ݬ9�巣,���J�|}.��:K/��:q>���EǷg!�o{hSp�Z��0Uu�}��'�\Dyt>/ϋ��.\n7��N���xPk��R��3tiT�Z�>@�b�5`:�	�����V�W��ݣ�q�>Pմޔ��π
�3�LЍX��[����Ucy[����2(Dv���s�^�������[�]M�M�؏��M�0oʥAP����U`�G8�y���N�ù����~U�K!�|�L���մ�hPىA��{hTp��tA��H"�p��B������$I����lO2�k��xPkٙ�<�6�
�}t�В�L�n�����ߖ��f�_o�t{��~M�֝�	j#;�Y"dH���)�]Pū�3.ῃ�&���xy[T��~���,>��_5�;�c?�Zvƕ���C���;E���h
cZ��hʙ�s�ܮϫ,:�7'Y��Xx5�;�c?�ZvJ$S�&�C���;E�����V����.��e*�l���Jl���{�uZw��~<���
�M!�p]*FP��S	�V�J�r9_ͫ�V2[]��2����W�zT>��AEٱ��e<x���֔�W�Q1�j�Ѧ��'9�Vb+@�5[��dM�^P���|�ǃZˮ8��
�M���GŘ*��;!�p.���4f�-,:v9U�!���J��zT>��Amd׌��l�.���学wT�q��#V�hex$#�r��&����}`�X��Y�����7t9w�RՍ�jؐ���Ir����E�����JO\G��~�TֲsmD���@�S���.�$��t�����H�R�J:���߫MZG�)%8�~x��{5�p}��M�1r�:������[nD���5���'wo�k=�S�c?^�kѵ�c5|�jӠ��S�\W��Wf��P�GF�s�S;�S$ҫ�0���yK=M9��4�a���]��iy����Jq�i��fk��1dyވby?��v��M�y����1
��:Z�N-�7XG�4����pמ��6:SR����?�Xf����� �jt�N�_0�_��:-��ƩDPh�~6難�v$'��\���g�=��Y�AY�pz~	y��\*�
{�I\�e���w�������ݶ<���!;oׂ���t���gݴa9���ʮ��S,�ӡ�}�Եb����18� ���ș����R&��5ٖ	�o��8zڰ���xPk٩���4*j�k�aO9��5z*�[۷��o�o�-��y�Z�V~pG��DV/������*2���1X��0��n��l�η՞-�ٍ��	��[��1m���~��ײKGtp8��U��5�D���)��`F�!�V�s|;����,�v���yA�6H�c?�Fv��M���.��_�p�:̅���#�����Ϻ�/=�You\ap���$�O��µ�����r*��r�)�͟4��R��>��m�g�`��{B��:G�F*\L��~	����r�[����(6����Q��Sʼ�Mz�����5��N���7n�j0�� �+!�Z�G�hOYjٯ�n	ǏaGe���dl1�`�m8�6S���2�V��O1..\�E��B���$�w�k�4���YIG{���O��UV޳_=�v�}J�-�Y�ɣ�_�n�j�D���N\u�&.�̖7QfI���GZݳ0�����/s�b?pa���9��rF�yg;�L���Y��o�._Fg�hj�o��Z�����Wi�y�<���Nz)�K��%��r��&���x؏9S��7�&Z(r�vi�L�=���1����\�j�0�f�+܉A}�]h�B�	Z�`K�:5�A�%:f
l�?�`D����a�
5�xqigoe�O���[�߹@��ud���lZT�\_�'���Vc��Q��D��P??뫽���F��/^�sj�S[}���p`�b��dϵ�)b0
�?
����� ��\�l�<�g�j�|�B�[]�t8C+�P%������iSF�9:x�����	��ҥ��A�.�X5g[�ԃ�§A�6K�Pi���X���� wiT\Ǫ��03>h9�b�\f�PȪ<�K�����S�u�bX����Fv!�I�� �x��v#�d3b8%��n���x�����X��hN�|OO^H��a����E]+L���A �k9�q8m��q/o��").+���rI/Yzbޛ3����x=�egLX�K�����h	�W�PS%7f���ӠN{�51������ �`�i����Eo:�X_U뇻������?���[����ͧ�v-�ï	�k�=��1����$����>�o�[Jo(��v���2Nt���"�$?Q�(��7��i쀆���(tLV��oͪ�nQ�Η�.[^����WsYD���f�R��#�w����ܐviP������֏H1��㺤*�����z�3�aq*6����ջ8����mq�v�?-��*�%Ŷo����c���X��U�F6&�5W�(J�^���Ǵ�g�vOW�*��7jy^#���(-\����]��:2!M���o�t5��H�\���׏�F�R�%��Sݧ��)>_o�{vg~M.B��4���̴��>�#�Fv1SV�Mj:n�-�^��^8��IA-�af��~����Kp]����rrO��̴�a�1���o�c���եAP-��]P%��JJ�*"r.�</w">��e��˂y���i�>��A�eWV[�vi�BO[�Z?UӲ�����N�k^�Y�\���J��k�ӆL|�ǃZ�.#Ao�4*Pm��T�ݐFtXiY��7X��"�?k������N����M����]n�vgtI*������>�E�:d�m~����|�ǫG-����}�Ҡz�m�j�����\��*��]6���T��\�E�?D��Q��|�ǃZ�NJ�� � e.����j`t���ȑ��,rA�by#��m����6��c?�Zv{R�El�! )��.A�I}�kd�����w7��\�cx̂�>.��_IHo��V*�C^���Cp������    
���I=�5N���c���j��z~���M�W�Ml��Pon���g�ޓ4��AGa�5�a��KrczG�q!����k�(�{3�Gܒ?s��Zl�5hV1�W���C������uO�~o��-q�a[<�K{-���,%��<?�s�d�����6R�c?�|�rA�*swi��M��.��ά2��\�g.�-��%���)�7߮�y���K��C����x0Y�Na�����+i�zz�2V���5yvR�T��'���yZ�*j�`�H��$b�S����̄4�'	:��h��{#Ӧ�^��H�u���ϴT�t��IH�$����\�>���+a���Z)(��	--7/�1/�%�vH"���:���>r�癑�O�ý�/ܺ�c�i	h��0"�ߢ{qL��o��
A:��[>*c���1?n�2�ݶ��5_%�,�V����	�N{��c?�ިegV��ۥA�P j����ZB�`ۖ���Bn�����|�l�C�2ａ�����~<����P-�Am� �@�O/c����/4�ЦI�]��u�<Yׂ)9�����r����'�_�@����<<��p�����u��z1������x���Q����1ra�ܻb������b�Z�L3�Iץ�c Ԏ��jf��۞�'�K��,���{��������a I�~3u\�+jF�մ���M�G����e+�z64L��!����W��v��C��pM7N^	��J�{3�z*�	�;!�G���C0#��u���30\+�CR.M�ÏT�Zc�;������+b=UϸxV�[&e�,��sj. ����&�	4M���c|3?-���\����и�!�i�/|�G�	��|rlE=Р�������YЊ�3*H��*by�_�7'�u돳L��J@�5;4�6p+}[��I��Ȍj���k��8
��lFI��1����F��|��p7���c��N,��u����e��|/w�����ᶿ�ݭ���U#���؏�R�E���0퐠��;5.��U���T�ȑ{nC驳5zC���v��"���S��Ѳ���2����G4B�U�b?b�w�h����?D�����&#6$����@_s1�̌36�������W��I���ے�lF�����!բSp邺uipK��)w1�x�������gG����#MpM0
�4�!z��TQ���ƭ@��0u)��pD���&��EZV<^]w�K�/���T`4���؏y���l-;�$�T]�����*��?�|�i�5l�e'\�c�� ��ʳ���p~��b0����\�x_�/e����5]m|A�'��~��c�����AW���U�B���M|$�]D�b��mq�V�$�e�02mV���xPkى����?�� ���0��~�R��2�3��u08M�u�q��J�6��L��+7i���h�ũ����I�C>F������@���mb�=Р��ɩ����܍Z�Tj��wB8����^�[�\7�����-�Vt}]m��2O�x>O�s>�-���8��CvJ��a��.�9�ʻ�
=�4b�1�>�tos��<�5���cIm��d������7�,�<$�.:��olt���'��G�UI%W�������F^�����622�堏�E��?d���u��Ҡ" U��J,�
N�~0zOJR�ˢb�L�yR��y���ebd�躏������P!l���� ��洋ο�*ɌKc�ފ�T;����Ԓ�S�����i*��=֊�{�J��d���<1�]y�v�����p+�5���y����r��)N��7�N����yԲ͌q��4�)P���6 V��}��c��M���KZ��bS��$�k/�ӆ�|�ǃZ�n`Q���� ������5����t��Ԃ��e�e_o�Ӳ�o2)+��N"��i#:�܄o�4�){�2���kc-DJ��~�H���p��j����);���P���؏��]kAXȍO�A� *s@e��*����� �sq-W�9Z��9�y�gt����hLQt:�L����]�T ����b������["���/�a��"Z��0:m���~�9��:x�?� ��8�q�2�XTWJ5xݻ��o��\wt=��]u[oH��X�6j�c?�FvN�	>��$�H]��#�LjP����~;��\��*]o�{_%F�u�}�G/�Fv����uiTp�ţ�@_���l
��Gm������m���j��j~��G���{<�G���4*�Xv�A�ChԺ��LR͇A=�/;�ڑ�$}wp1�y��^60:���c?�Fvn����>� ���
�Z�[m,<��㍟.���y.�*��r��Qٴޔ��xPk�5�T��ڦ�t^�uA55����z��R�<���t�UE4_/�-����c�zS>��A�e�38��� ��MI�j���D�8{tK�ŧ�zy͓2.W�x�{�?�֝�yP���3�.�C���;%�*#��q��`��P���1-�h��E����JeӺS>��Amd�����uiTp�$s@�34(�bؤ����&N���%^W�<�nS�
�16�?�c?z�c_Z;3���@�ߡAP�������E8�"�7�~KY��)�/���v�D+��Ϧ��|�ǃZ� jJH��o� ��MI�BZ_+�Qf���=���3�-~��`KKqhT�tAhu������a�٭����M�/�Æ��H36�?�c?�Zv-���ڦAP����?%0������ˑ;;d�8-Μ\��&[8��*��&dlZ�Ǿԡ^5@��ZcA�PPhT��O���OV[=xL=���O���6�3c�.�A�A���?%]J�� R�A5���]y;��*I��}͓#YD�+��i�)��˿�]0%Bc�>�J>�S��g?F�`�o�n�y�����|9����^���uZ��~$���dƔ	��rhT�BT���
#ܼr9c �F�g@2»�m�hZ�T鳺�����!�}S�o(��$�VVFrC���v[�������bu>޳���_��i�8��{λ�RK�`�K�3��RTQW����(��R�c\��V��y��O'��3��c?~yԲS�U`�!N=�pؙ�b!Nba��6;��3�lR,w�r|�%,�����.^��z��v���sRlWo���u���>�d�3ItX7�.N&��J���:p,>��t�EI�~��Ϲ�N��ui���������A��pXam൑K����*8C���|�t�����=/�y|���.e��s���r<�G�
ε�3Ͱ�D(�4*8�J��6i%�*�D�3�rѽR���UR��>�o�e���N����j�zHn�4�ٱ"�܉$�^����������JK�x��1�.�����XSyjP�u���K�2�B��tiT8j5qAŪ� )V
�Ӝ�iq��Ḉ�u��v*�''��ޯ��xLes�GuP'�.b
ޯ�.�
�9�ã��N��6�h$)�;�*q���ʴޯ��8K�Cv�5*>ץ��)��j��/�����r��A'�㹚gQ�fk����|��>���������쀉Ӻ4*P]C[Էc���<��~'�2^W���.���!&���������m��*�K���#�]C[��a34XVD�yw,���z/6�-��5�IdbZG��~4�(;����O�� ���j�Ж�����cJ��XrN����]�.��Bxˈ��3=�ǃZˮ�GziݥAP�%Ԯ��Y\vƬU��s�|�Y&��:9�*���<'��_L\���~<��)%�ePC�.b
�v�i�sL�[�]�e��ru��et���Xk�2�$1�G�c?�Zv�ThқK���G��)��'���v����	�Şo��)��0oz��֝����Rqx��� ��Ni�bZ7u%�APw�e}�k����ծX�kTq�A5���~��A����)�3\�)C\P>3R
�'uZjzPk�%�����
���.���W�<�����L���yu(.�jN��؞�9    orZ��~<���s��Am�`�8�sA��%���H�$Y����&���_s�5%�u�|��#j�J(���� ��U��J4J�ho��U"����ĻD0�w��Q�$�7��D�U��כM�^ݯ�js=y���i]8��S�������@�S	.�.�3�~�.i�/֛h��O��,v<��&.�u�|��CZK��x��x�AHQO����Q��Ag�iP�u�U���%�5�	B
�Q�����ԪA=�-��~����Sy�&�>���9���c?Rl��ٲD��� ���g|�$��.gU�\l�~C^&�XmJo:����j-;�J���4*�o��ߘ��83^#��m�J�M�\ovY��Q����u�tP��ֲ�t`:�K���g\�3���'�OA�C)��e�vKV	?΋2�{�����hP�)W"0�ťAP����'��h�Ƞ�Q�aW�`�^��%=�I��~�xZ��~4���ئ��=qiTp��g�!��L5\�lu=�d,[U�[Ώ��DbRx���i8���6�c�",��wh��.8p�9�b*�����e�;%U|,��m���r��M��jZ��~4�(:��ˣy`@ܡAL)`��L1�Zg��9�^�qx�I�<���s��f��W��'�Fמ�8��UD1�Q������2��c?n2?d�vC��z]�Lp��}&�
]�Кaѐ�q�g�Kr�/�H���)c^�XM���؏�|���k�޺4*�q햓5��6Yq����˃͖�%;f�u��hQ���/n����P��d3^�n'�	#a��5�
�o�5��R�I�0	`��t_���gcj�w0���x+l���O��^,��V��C�|���J+3ߑ���:n7�aǖ�M�Wi������iC>��6�ٙ-$d֥��A ��UJ|d���ȣ���V��va���རS��"|�Gcڈ�-56$�ܥAL%`����~Fe�
�x��"(ٔ�k|��x�<�k�^m��:m,��~��|���1*e@,⑆(ޜ`
@���nB��T��t�/�*���ee�}u����ԏ�6�c?";���]R	nC(�4�P�*C�,-1���"���,6�]�iUr�J���U��"|�ǃZ�N8%& ;��A�sJ��J�l
2���{�o�d�����e��Ӝ���]5m,��~<��i��Mv�Am� ��E�zn"��[jg�(p��@-�t�,�$��Q$�$��,)�ɹz�X����=�]vP9���4�����
33����i�uu��zY��}/�rq�-�'�z؏��wٕ��&pOuhT�"[�H�@��M��.�U���N�r�٥%���]�7zڠ���xPk�)'<$㹇Ae �u@�*+�Q!G��|%j*��ԃ��*y���{m�E��]y���o�t5���i�	^�������r`��`�F�wb_)���YC^�P�"[�Z�����)���sBwy5��d��X��dS������M|�Gn���؊���~uIP�R�@*�@�°�`*�����.���p���*"�-Yz/��ą�<�GC��.����Aw�2T�g=�aw��D����uS�����4�I�;��0��V����w�4Xa���'6{~aqQ\sN�9������6=���c?^Ij�9�,��@���ޛ�H�#i�犧H�9�@R����A����A�6�hؾ�j�}D�f�fT�+U��?0�B!3�ũ�QHY)BB��3WePɀ�V@��j�9:�=Χc�҉Aĺa���"��1��P�蠁ˠ�v����/6멘_�	��x�/��&o@ �|k))x�YH4	�����Y����w�j�ڔ�n����ǭ\+�^ǋM5N�W���-������s@C�Յ���6�8]�M��j}���؞�2]��n7��4�{UE�oj��4�A@C��J�T�{��.1��G�	~�V�V���yj�یV�����=��wyop����M�������]��2}w�ihw�%D�[�%:.�S���@�{����2k����f2v�=jsսVѣg�F8b˷�S�wF%�WJ1�T�E�Vr�M�F���[�Ni�� j2����jr������尋C��["G�o�5���c�LB[�(�CH�
g�I���܆���7���x�W�]���vE�y�$���C�y���� i@C����TG�~o_R�4�����R2�Y=��u��a�ԋ	m;�|M�������7��b��ʓ�\f��m
f�3b˷��z����V4$jh�	ㇻ㩬�����sO���v�	[�G��`m�i�4b˷��'�K�� �?��0���A�$���z���{��8_��ĺ��1jPټ�l�֐�A��R1}�!P����JC�m�S	����U��z��|8����괉��m^o9�|{P��+tRπ
�e�T��)Ԭ����������ת�'��a��"6)+��q�x�Ah3W��С
iÕH䪪x,W��!4[�A"���Bs=.S���D�_5z����p�~��t҉ڣ�?.��h~���7��X��ѣ�7F[��Q.x��nH=�/4t�����u�v���J����)D��y���l&���+�q��7F[�=��wp�����@�jh:K�����ZI�/O��JM�|~ݏ.'~��uʢ��74[�=��wf���>����Ќ��RB�o^��K!GS�Fy9�Gg>9���~�S��҈-�TM��2�C��������q���iّ���o�)�qj �uڽ
(�,�����ٵ�e��x��xp�����"qy"��[ol�;�~=�жr�4�z�o�l�ƤƪhkBCO��̡+�2��l�]�_�c�U|#�'�YD�n�́����������0����A�L�v�2t�q�LbF���k���1۫�ۿ�N��.9��I-��4#"��cL>�C)\V"�Lq��ދ-��O?����<���{W���d����`w�q�g�h��e~WY���x��\���W���@L�2��:�O���sQ-	�G5>gjks2���(��h,vBm����o�\�������.:ڧ-�e晆d�@�eP%�84����M�A��Dɮ����|t�Dk�\ޠYl�v�o��Lb�yHC�*��
NM�i]_br�nO��bw����׻��;�`-1qy�f��[�J�s�X*DZt7�!P��X��ȃ����v����6���Z�G�����F/b˷�Գ��9���05�)/c�lGHJ	�)�]N�h�S�oE�~�(��)��oʝF���V�W��V���J � N�S���=�#�]D��]���d<;�o��I�<~;�|k�+xW�Bb	NHCRgT(�J��P3�{W�]��tW�]��=��B~P�ˈ��y#r�)%(���6J�d��a�g]���zuY����M�������ň/���wTА95�!�w������ӷ�}E�/| A�f\�^��.F���OWa�^d�yM���<���ݰ�`����c�`yCx��ۋ���0#SZ�W���o�#���2u �+�6m�_����t˖|:����n�>G�x�>�-�T�XA�?ܥ_��4*GPC��jF	z�}�~x6_S�����������b��_�v�u���7^v��N���#���n��� �H�w�8.���?NH�����v<�N����~^��#@*]��v�~?�\t���z��p�?i�?t��x>-^]�'*��_A�k�������m�C��~����n�{V�r3�����?m�+��ŷs�[(�u~@A�������1m��޽''�?@����ն����*�e� ����p?�+ү^�ց����g����nKO�B�3
�{�"ML�~���(����E-0"ÿ.b��Q��ˠ��K���x���6���d4��6������2��%����c˷S�[4P$�D%А>*��r�ɝ��58/u^�����4��5Y\�::o�8�|K�`]K!SFlU��x�kb    ����˱޷�N�7q^f�K��<.7���p�Ʋ����Sc˷��nD� �*PU�
F�0iϢ?�G��C��Ձ?A�qf$O�o��^��՚�&���Ȧ��t�q,�,o87�|�=��#��%4����}U�	Au�`h������-7ǭ���~x�/��h��FA�΍-�T䝦�8��$���@%I����R�$̢��7�zޭg6�f��q5�7�[���,xg���Ǻ!�J6ϫu���Y1����,�ʹ?��6��d��,�C�����X�X�pel���>xW~�C����y5�}�=����?@�x$E�����v�!yw[��Q�a���������mg�JT��Ʌhą7�3����9ـFl�<\��e '��fd�)4x��Ɇj�F��@�nTN6t��@�jtN.L�ބTa��d��:�M� �asr��&l8d�eU},�	o�g?�ͫó)qل��6����x#FP�۬z�gS��@Mn�jr�O�7bu�ͪ�y>eވ��6�6��Թm��s�U��|
�#�f�=T��L?����L?��/�G�qK�H���_�O75�ͪ�E>܄�ؕ4���<�	[љ�uS~��z*�5��P�zN!�7+ R3b�:��B�ߞ�)u�b��P��ɩ��<���������w�"���u�\��}p�֐��g��&?��E.��rT>�`�#j��2$�nQV�C��B��Y�TS���ZL.t�?ˑ�z/T�zQ��tr���,C&�А#��f�g9�Y�����gry9�(�$>�]Yދ�!K�!O�-��&C�og�#K�m��hhʓ@�r[<��Д%@�r�<��Д'�<�xfӡ)O
y�m;��C��gI#K����|hʓA�r�<�є%� xn�g6!��6�mC��6DC���������G�⩗7�k'��h��K�C��	�x���	&�)���L�z�f�0>�C<�Rڈ\҄v ��>�D<�Rb"�N�����L��,�u���@M�+4�'x��X��FL�j���L�+&�F<�.��<��5M�u#&Py�
�ݞ	��j��&L jk�U[Cm�$��EVmy�u#&P[����h�F<��Y�5��֍�@m-�jkȣ�1��Zd�֐E[7� jk�U[Cm݈	��"���,ں��!���<ں��!���y�u&$jk��d4U��;{�*^�[S��jC��?��oN�.�P���ߚ�'GB��i�~ob��r5��y���}r�!T����&��k���4K�7�ON<�f��y��	~��eh%|��ߛ�'_�F�gy�ߛ�'�_�!���)  s��{s���m��9~
��6��?Edn~o���2��5�O��ۆ�ߛ�Ђ�mC�o��S�A�!����)�r�����)�J6�Y��X�ZSҳ��\�X
�d4|�����7�>���o�'�D#A���O�4�j%�>�U�JV��xHOx���>P+(�V�
� %�'����hS���;V~k_w'���:R���i>��� _����O��������vh�|���F0د���ݠC�F�.q�z��~�}�����,5��i�R�K�t����C{�s�~���_�*م*v���&*=�B�c��g�/사�^��ۋ^�ͦ���QÖWqf���*~?��6Q�蒼u��?�POY�g�m\m+�U�2���e9�̆��itX��j0�� �m�[�q3@���;�N���.!���h��>�[���4�thƮl=�)���u_�I �ٰ��[Pk���I��:t>�*�o&?�%t5��Z��,�h�c�N���R����jBV-�Ӗ��$���L�;?��������k�O)�����nߊ ����R�����c���X}�ΪXU4r���ޮ���z�����/?Ѡ�;c\Suѵ��~�$��Ɲ��߻��t5�}��;�ҷF�O���E�i+�)�H�cY���~(��b�,݅���|�W��#Q>M�H��E����PN��[�>]��ÐC�5�8���Ui����)��J_h(��T��~2�1(��vJ�u3>���vL�n|�br;t��cԼ�Lb˷��q��l%��TA�?�&�L����8��j��ev�FJqԼ=�c˷��έR�vFL%�*�ВV�zo[t���yn���ƫ�z0��R���܏����l���z�50�jGOV�������r�/
 ���Dw����W9W��d3�EA���?�|{P=��q�~�>��!}����Օh�*!j�T���e0���zqVC�_����	���~l���>xG-d��JU!���B� ����m4=�ݺ�	/����� �X̲��|�nuo��_f��Z��a7��M�y�ǖo�Þw�b��{@C;�������֊&q�h�?����Ձ���5���aR���l����>��I�탊�z�O��2�B�*慠
t�����ut8�����?���R\Fe*�|����e��P�3#�HH�R�ʐ
�aܲ�xBŝ1�ܢ��$��E����]~�I-��cy�Yr����~nHj:�~A~�S�o~���O����
�Y�zKP|��]��^��nl�.�+b˷?&�uíe&��<��A��)�1U�S�ID�^��R��XQ[�j'�6��w��ˏy5�ci� ��)�o_u_QX���>`��;�*d���jt�h�N� �	_������a���`���M���M>ĖoZ<�Ӊ�}@C��!�%���t��-�^�����Y��A�7C��R.��߭��^� ��V����ٕ��FP/f4�mh�smv����v1`��P��ny����h��f�D�0_l��B[�n�T�}��Jp����
��d�w��d˯��+
���U���}>�/4�qez����k=���|,(����Ƈ���Wڷhe-�'���:���~�������\F]�7t[��AA��z�mb@,�����Ў���z�F�N�4<,Ŋ�r����]�B[�R����\�M;��n+W��i��a�^ۍOQ���-�^��O&Y�l<Q��44���i�\���ƀ�Q����w%C�LC��Z��R��6SY��wǠ�x��O��L�&7�&���gPt_�G�����;��9f�֡@-%:Nft��O�;�]��t�^��)lz0�������Ėo#��7ލqB�h�2ɻDPMT���$��5�������PN�T~(A�y� 2Kѭ�e�O}(����X��z�XV���<����7Y[��y޵`,Ɇ)Ӑ��\ *j*�e�	�ɉs`�#�������7���QL�'b˷ƔXtE3��B�iS��0b���:����'|�\m~�\Kd��G�>_w@ˏNxQ�8�	7��I��S��������|���0�M�Nn��r��0*�y��[K#��s��d� !��'���`��m#�e)��
���%��㳙,��!�w\��D�d������r����$���*Ĕ�Y����'"���BF_���¿wo�]�+���Z��'���z ���� +?rO�u�#�{����Ŋ�f�9?_n��V��7�[��I��3!�K)U/��Y��A�T�n��:-�PuV���Iz#��`���������?�/�]]� /�;K�&N�K�e��a=9G����v:���]�)��򭅰����l�<��:�4����Ei5*�2uQ!��58	���z��o/ҟ#���.������k[V�xD�-�n*��Юr�l�`yg;���;�*0퍋4�CpR��� #���֝��i���c�2-����oŶ�8)�
�l?�U��C��^٢H��O���"����3�ʔa�3�#J���=F��?_I��+>�X���kl���Y$q��AWҋ&b�Y�*���$�y\e�#|&���OA��r!D��Q�^k���/�w�8@5��d5-<V�������t[��(*ک��F�L���^,�v���d0�hx���    c˷���+�wv���P1���2��u�0�b,7�y�M@��"�ZJ�)5de�#�* �kA�Vק���p�A�������np�-�U�7�[�5��PtRa^��@�A�׸q\�Fr��c�N����)�;g��JFKa o>1�|��O�Cǡ;))�2�
�	AՔ���3Q�r��؊����T�Sw3���:��vț��-�Tϻ��k:��4�DPm��2$˭�/��w| G'�ߍجǯ�X��(/���Ėo��]3&YJ�LC����BP�Y�8���ޮ�ۈ��N��d�o|?Qd��@͛ȉ-�TϻD(�Q@��@�w&�*�t܂ⵒz]����W7���zAV�rWTy����+*�;�{<�yV��@E;U�8U�Ԉ*��Дr������R#�Xd�"\ג-�v�`].|�j# ˺���
���$����˖��&��D���>�5����ϯk����x�o�*�*,���)��>O}����n��QB��]'k��mo�_���6��x˗��|<�G��C�dJl�vw��wEE
��1	]2�	!����L�~���(S����^M�����R��*uE��҃I-˲��/O���(\�#?�����֭"?�^�EB?ƚP�]��Ͳ���'-��]������zw=�F��i�_�A�7�[���}��r&u�x���~`����J��S[K��N���e��eu����n���*�b˷������b���:�3���r�J�`���~R]���?�����4�\�����i���j�~/��d�U�A(V�XH�6�J�x@�{����=�&����}0�o֫io�xl�]쩽_��A?��W�ꯐ ���������V|�.Ϻ�����F��@�
*�R����ʶ�|!9�no�Ӽ���u�����[F���"˷�O<�Z9i�B!!�'$u��'�\�4��Hh�4s9;�Χ�@��v����0���7[���W���Ġ]HC��9�����{nu}��yq�\���DM������p�S#�FBc˷�Ԃw�Q��&�4* �a�����F/��7icP�FB��ʓ@��+��I�ه4*����P����է���7�Tϻ�x)���LC��F���w	�S*8E�v�!��n���&bu����s>9���捄Ɩow�޹��^M�7��������,ęb�Ūm�v��x��,���pq����專��ɼ����m���;e�S"�e]w)ʠ*ֱ�S�)7�y�>M@���@Ȼ�\%5�)��h�JA5h%��B��2y1������3��݃�W���(�y�	���K��]��2��-����I��~J�n��r��+�w����ˡ;\^/l~�n'U�&Ėo/��w��48��44���0��=Ve̱�����2���];�IڿLC��G%�¡������_M�t^L�Wh�8oM���&���X8a3]�׿� ����$��d�K��"t(P�dZ���EƢ��
#�f��F��N��(��>��}2��T�	�@)V���Xß��ׄ��H(^�{�[i�4T"]�g��?�;��G�y�}l%* ��2L��u������1MC���A��T'�>�P?���f�"����*��~�� ʿh�T.Ex� /]�)�/��aFU�'���h-!.&!��)�3�`wEJ�i��MF�NPI9I���҂�������<|���d�GV�Q�A[��6��!�o�CB*>uR�×���B�R�U��N@�����"¬L�!��L�Q�;R�?F,J���Bsgd��.�M��S��SQ�i�����%�S��)/��"%�Y`aP�5If�P���d�3Wߣ��O�7��ݧ+x�V�VI��^hȧ��yr����)Da��
��{�]�4�����~4G��̛Hʹ��;�c�fI�9^h���)4r�'w�?���5��j��*u�z��e�[�g����a5o")�|kP��Z��,��A���B��Y���˄ϥ��Q��K�S���x���7�[�M��$�������|��@U�{�P�!5�B�ZI�F��a������t��,o����q��&�b˷�Ԃw��Li�(�����AdP��(��ׂz���x���6���m<z��3%�7�[���>x�L��w���ig�@�v�r�~�YcP�&���yGWV�tP�4��ԃjT�j}ߨ�ag�1͛Gʏ�g�
�����iS�����!������p��/3�:o)3�޹�`R��2���Cv��:�Щk������1͛Fj�i��*X�hҨ�4R��0E�ߨ2����IWo���p5��m���p���˚GM�׏�-�RP�kM�p��NC��gt ���;�ek��Ơ�����Z�.����e�)cP��	:��$�;55�?�Ԃw�P�$�������eP�D=��,;�yݩ��YWR'�G)���L"z�
U�6�4�3�Rϻ6�����3��Δe�ҏWa��� ij�~��A-x�^줂�BC�R����pUo��K�;���	2�QQ
����mny��T��:������e�Q�O�:�HP�W��(zrV��*��l~�ו��o��8O��S"!Hё�Bj���r&����z޵f:��r�A5���G�3�I磒�GZ���5E�K���Cw�*��{)���UԞE+��������d�i�h]��[����x�
��T�@TmounL3�=��@��D�`r�`��F@�%-9$���f�/�u�0��0���߳�9q�]t��LC��@P] *���U)��;�!�x���DHC����X ���ĄKgʵ��j�)�<G�*&�ïs��@Q���_)��:�����
����(+������b8�!�7ޥ�R��BH��B���J�&jE�yz�H��W�8��??�ާk��3w!R���zWw��	�*���������]�
Oz�T�!!Bk��T�G����쮣�}a�4P�}�L��4*��΄��_�QPE~I�}a�4P=��@�iT4��A�4���mM�s�rRMw}��ݑ�ʟU�x�/N��KQ.c�������,���څ��j�2��i]Ŝ�_6A��&�;��4���UԖ�6������6��~_�5�*x7�:$����,��\ʑ��|���"�i�z��I�P�!P��jP�~x^Gq)�KIA�EUZӬu�,�~���_'��K�N8����AM���z��1����7�k�@�׼*|���TC!��{���Őe6������Z>��y}i���5���r����h��h�j4���͐�,�=�'g4�W8��)��v]�
ܸ�U4$Dpi��s\�*?G�[_���(�OGk��*���=mS�")H);Jht�r��;�#�x����r��1�A5�0Tzn�Q��o����4�1���8<t�����@���	���Z@�%�:��k�o���J����#o�a��P�SE�p۔]r_�,Ir�3\&�!I.Z�<4!�Ow�A��TOQOn��}X/�� �JsJ&�S�O����~X�A�����]�l���QD�XT�)�.�/��&�w�h.k��?Ӑ���!B�$��x�J� U�n��]�B#�
>MG)�з��f~���w�Kz9^��ͤڅ���F�g�|��N_R���NKh����I[���Dú�̡ط�4����oA�W+͢�c'���\�h�"���P�U���2�R2�=<1J��m�)oD4}آ+熤6�׵ %���B[2%v�J�#��I�5���[g��[iD�+����w�8�d �yc�+i�b�U�P@h#H�c�y���u췮
x�����3	m%^|�?җ�1jC�=sd�uM@����er煆@%9����V�e/t��:���]�}���:�!P-�Zs�Ч����G���q>x7 !��eHC�:54�|���o����PJ��Id��μA����6��.��ֶ)�ALCPC�����Ɖ5����wޱ�$�_hT    �����Ol���L};�Ơ~�8�w-�c��4��a%@��MBS�`�1��:*��]J�l2�/4* �<UQ�u%�a�-^���S�	�DC╄ E�P�2�R�ᷜ�?���#|����I��4*z�BP�^0&d�P[u�k������`�4�2�ǒ�ZJ��4�֎�w��Mu�9����Ճ��e/�ѭ��=��M��������������pO�����z��v6+?i�.lo?�뿗~/�k��J����Sx��gܷv���xb!�+	�Ajʐ*ձZ������V�C��ȅ�����~_�A#<��7U���_Δ��u�:8R���'��hH���X����*A�N�<��}J�T�r����>�W��*ZvY1B���Fe���C�6�s���tG�H��+��KxX�M��Z-�7ſ}� ���/̰9�`H�a\��H�Weؔ�BӓjaS�ՖȊ:�bs�-��z;&�,�8&�'�!�`2�*��Ǆ$C���[�tAm�Cu��^t�)�����g��AW!_��)󂗵A����y�'_��+��V�Tǯ^��|�@�uM�:~Y=��a2:�F�ԣB�rIp�-�q���.{��}����xIش�v@B
Ͻf!����P.{ �Б�Rϻ��Ҝ␆nt��4A����v�m�۪�2�D6G|�L�")Q���%W}�ՠ!�=|h�)��ͪd�9	�ƻ4
3[!I*�~�<���`����Hf�{r\^�uP���MKZ�9*��4����҈N��)/�(Mmqi�	�DI�]�ʹs}$�Ω�7ޥ¦E�C%:�*�Ș�]��;g��S=�t��BB�Sbj)J��5_R��lᓼ�)*֕xׂ:��'ɾs��w)Pͤ�EC�Au��Vc+�q~�tf�C��
E#[?e����8t����37|?�p�MhS+�q��o��������BC���5�I��>�^vL�s��u�N���1-kd@	���F�EoBK�O�:�qz%�{3�s��w��LK�4��AU.��K�b��y�]i';؅4�EPC��N����V6+��8�	ul�nBq���6��o�*x��/OvU_hh/�p�%��R���8B�����6�\�*�Lt��J��#d�"�Ɏ�a�6�U5h�4bJ�������w�Il���$��^V�ב�T~I��a��w�@$�4*;6�)_G�M����o�(x��M���@5�є���ʯ�h����S��x�cN}*�ot_74�p]?�&�ɿy8�`�%�s,�$$A}���5��0���nnH�����b~8�����$5=*���?�(@u?���[���čA��^z����I^z��@E/�y6�Uhz�f���B���-{�
ށ9�R̖iT���G<@�Q�*t����+"ϳ
�e}���Ο����I/���H�Q���D��<3��
��&��668�-N���K`�tW�=/.�(�y����A-x7J��� e����E}�ċ�VR��*�z��A�źh3�u+���G��y B��%x�S[�����E���̀Ǻ�u������̼�r������%���L��]hA���JP�E �A��-���`��e�dhA�w����3��θ��68�����oe^=�Vz��v��[�LC[	�ihbIA�x>о�������%�g�O���5"ᲖO���Mc��g���wiU�=Q��H4�@����A�ƀ��гZ�.�J7��IR������:��(����'���/g��p0��f���v�B��?�-�҂wQ�3&Ji@C�j��J��9����x:=�a3d��|v鞆��e}�DA��ǖo*����"%��Bc���	����V/pJ��`ꄜ�ru09_����p0���G.W�(������-1}��*1:��Au!�4a���T�}'���l/OO?����W�iE�_�@��R�-Ժ����aԟ����4�.���Vۨ��#Ėo'to���4>�LCBG�� Sz�)�u�������B�8BvP�-pm�NrH��CPE����S�֏<mj^>?��w�yjH8�!P9�
eP	y��>Q�Լ�|P��`< B�qQM@}�!P�*CP�`<Z�ɋƠ�����yhm�tP�iT����g$ Q�#�(�]QA^W3���ΙEC<Ԁ�@Ew�� T!i�#�	��������*�.;���c/���nrS���x(��!��n~�d��:I�b,���l�W%�y2e$o�"DVO�k�24σ��~ũ��%L��P�o|�2���cH<=�[��B�_V��;�vf���Q�������t��ct�A����b������:x �o���cu\,�?�/����xt���J���/o|�~����U����_�a+/��[o���|>5}���?�)��O�~Jk-��#;�2C�zL��CRn����ڰw����CDr�ib���3Q�y���'B_+B��"�|k��B�^�w�t~�-V�Lo�A�4]��h��F�b˷�k�AN*�,��MnSbJ�^����ݍA��kj����]�TJEw��@��(��X�f�6��Լ!�� ���I�\P�iT��B�(�h��g�?�;��6������7^��ʼ��x��(>L7���_R}����I�W��:��$������L���<^��m�7=2X��14d�^l��ם�]( ��n�� ��!��O�W$�V՗�65o�+@E�A��d>����u���1C��t}�Z�uto�b������b�UԼ!���-A-x�T9Ò��iT���Ԣ۞j#�A�����Y�!12���
�
�߯YƠ��75o/;��`�H� _IR���R?4BY����	/J��pY�gU0+\m�V�Ӥ�����VV��h�?�Et'��c˷�IϻI}k�4��
A�!�4V�����״:�
$�_a$Ӻ�s'�q�D¼ԑ�t���F#�����H��֣�iHXd��g�������'0o�9�	��k�w��'�N�FPUhfŃa�x�T���/;:z�;-��y�#��}��#�����WT��*!oB�@��-
}z��<���e���eB���Z܍f^���{M:<�;�;�|�|VSJ1���7 ���!ށ��Ԣ���n���:_j�q$����I�+C�}�=
�j-��m������o�	rD֋�M���"k~Uw�Q��Qx��CC��?Ey#��O���Ob~8��SDWS�1�)��$���ZjLꅁ��(�̯R]2T����r��;|W�դ���1��v�#C��]}�P�C�7#���y�9z
�g����Th(�&u8����M!Uy���!��s�29��L��*��>���3�\�����5u>N[W�1�����u<~��n�����aGr������	ltܟ��h?��P�(�yme��:����f��������}Td�fb˷���x�JK	��iHh�����s�/��
�̩v�9pщ������Ck�y(�c3i���xe�̼Y�&�Yw�<6T�J-u�7R��ͤ"CP-��C��1H�B;M閬-����Rhg�-��J�{2���JW���<��!Cڏ��<`Pk�ZI��Ʒ��<8����eu�co3��OQySQ���I���@��2I:Z��ӎ�*4_S����Һ���q��E���?��7	�!�4т��o�k0��C�=�66�WW敤VYߚBn�1ݍՉ]�p��-���~|������������wE�&��0�LC�A}�tT�*
�0cAզl'b���:���E����i2�nWQP�&�b˷�|�o�A��l���@�]� T���>B��}�>Ow�_�Os>����|s��(�ys7��[�Z�΍I�h��@��A5�������7U�]^{V�1
��K��ӅD�ѐ���LVa|hY�=�� "�Q�
$y�V�)�ʼ��.���M�`/k]��
�?2D�#�V�*�aW��y3�N�R�	�w�U7*�y�.���    ��wFq��+�����APC���jB	�ɬ�m�;�f���:������v�DTy���[�Z�.�#J���BC�Z5�6i~��X�wN��u����ڔ�SZ� (Y�$����v��&�%�oz����Njy�
Pސrl����3G�~�Z�iH��N��߂I�n)��XG������ʄF/H�9q���[k�z��i��@.���m�e]��ǶVg�Y���z��X&���L�[�bڼ���`�1�ѐ��wCa'��j�W��:�g�^Y6�ʊ�`<@��6��4��9a�',�y:P��V�`r�n�i6�~o�������x'g���e�k���2�m�lJ���K�A��d��m�u׌}g^��w�8,��]�CG	��6�q�������l*�#9�t��$zX��b˷?,�w����J����@PC�H*T�̚��rGK�c�C�UY���m��y�H{�=O� �S�${Z/4��6�SY)�t�7�&��*fZק���`��������XEyZy��,�:��>�Ψ	}	�Qz*L�n����
���<�?eHA2��ʆ���Z�)�����>��cU��Nw~�*2���q�9~y*�>Z�VEC���ԈB�˾���'�H@�]�*���݋��6��y�I�Y���z�����qɛ��-�R5?x��nI�4�4tdP�YA��$h�8���uy�iV��N�c�]p_W_�.L�b�����v�]�����I|4Q�������qIcv~�W���ka�[S�U0���I�?Wx?��&�E�=5k^9%�:�^��^���d��D�۵�;���%�{ѓ�7�[��I���ΔJ�Y��3G�΅�:z��$�:d��a�̶;5E�4>v�QԼ�����A���/��W�-_�H}`�"
\�Z��!͛��i��T�'�N+��A��4Zx��.���c����p�n�z�io��ЙGCE�oj�;���d�腆@ujhtҌ�ɵ�o]�el�z�?�,�{%��<��QI5���D�o��9�c��跸��οZCW���NSL3��ɍi�:e��_�iS�\h*SbX#jO����MV�0��N��f}��&:���\Ɩo��ƌ�<��(�!P����"�G��75od0?��wa�KjS�!PA����1ej��55o��+@����~�%��~�8ʑ0K�j~9����;t��1}�!P�qt�Δ��'7u�yI���Ơ�u�2�Z�n:V�����@EgʹT�������חʏ)��h��0}�!L�z�_�Т>��ռ��W���6UM4��%Ty�*�o*�՚��Q��O�G�P��1Β���iU*�z��rO�y�(��6���n�=ti����R�o�	��X���^ȼ��@�8��
��R��k��e��]k��w������P� U�D���gϮ�m^�2;��:�QR'��BC�rU��Jʿ�<���ڿ|�� o��0h@C�
U��*򅴲R����R�z�]:�=q���zx\M�% 6�#���-K �S���"���PBU�*K�)����0���$��UR�2�*	�W'Ⱦ���^?4�1�y��̨>x�J3H�4��"Tm��!/ӂF�);�y����z�7e5�!T5��ʨ��딓	�盢����
T�w+Y�L�2�J~&g��{督eUk4F5���U��)
T���2�J>���P����y@JU{�=����u3Ym���vÏ��(nY��3c˷A��u�u$�a��Z�!T�*BT��ι��b�Quy=������,�me���c�g�<7�@��vhR��47F5�k�UG��h2HR1D��P%��yp�GUjBU1����׷ʎ��w�xҽZ�!Tѷ�O���&�O����9�_ӡJ���<���M��8KU���f�u��o�!��*.%[���$��yb���H
���ܨ�u鲣J�CG��������P%��yh)�J�	|��Uk�5F5�K���܈�n�%��1�L%ɤ#�c�ס�
Lə��&=#.���Ru���޿����G��סˎ*�&VJcRj��4�*9tϳ��U}�R:�X-����¶��v�]�fj=�&��rE5�C[���;�c��%P-����=Ow,P��ej��񅟦g6�Oz��iw���QT�:t��ۣ��Qo��Y-����=�w,P-&J+Y��:�^�ZL���lx��3u�n��X{�2�g�,�Uϻ�̥x%z>�(�*����w�%�.���!�ΫL�'d}����:mG��p��]+6��j���
"˷���Bk�R" e�\�*�GY�jji�q�����ŋ6��y5�o���7��]��^el����&�)��2�J��Y�U��=s�0�N��[�o��u��b~��O�c��byݻ��Q%�!ʹN��B�ܻ�a���i�<��ٽjw��o��N��l���&�uռ�]l���zީ��8�eB�ܻ�i�T��H-$�Eu�ݫ�h�����v���m�n|��+�׽�-�TQ�Y.�N���4���V�U���Mk�x�n�O]�bM�n�"lh��鿺�-�  . �?Rp]�3E���X����n���LlW�K�J���F�o)f�9��,�!1#�X��� ���֗���\�lΦ�u���<�m��X�o�2�0#˷G���I�h�4�*�*�U]�~*U��m��A�]�jr�\�j���Ey=����QՔ3L%ʿ�HU�D��0U>�����|1��/��m2��n9��n��(����D�o�i��»/�=W��P%^�"�Sz��4Oh۶�]'l0:,��w$?�O��(�*���Ɩo�j�����*i�n��Z�Pd�*(z�h�������vb�əMz�sw���	�]�������[�Z��*�hUr5A����u$CUVk��Q>���a�&�9��Њ���<��[�=��wa���>���j�Q��*ĩ�0��Fۮ<Ǘ��Z.f��Rш���0�|{T=�sbX$�!T�ՄW�Ȓ���Ɨ������z�0��fw����nt�E�*��ӌ-������a�JB���	/Q�FL�	.�6��Ӽ~f^L�x��4<�{iU�3������PR�14F5�[�Uϻ��u����VI�ZW����ƨ�u���J�8�q\��Z�2�Jn��!�ΏYGcU��U�Q��Ktͪ��P%�J�8V���QD�[jnj^�*3�֙�AhT�$�r�<A�n}Ik�&>�$%��}���~Ь��?1_��ԛ��]�ae�.��a>]�o�?E��4"���da@��S�A.���̼�ƥ���.�'e����Y��~4D^�8��(x7�*&�4� �X� U��^�9�Lmȡ1�y������"�2�Jα�� �����AcP����A-X�^��HR�	!�uKJI�ou6���p7�[���E�\��,�qy=����1-j�$�EK���P���Q�ހf�f(�����^��	�3KI�3�4��vI�d�)鲾������=�:3�'&�B=� (��2<�	�ncT�F��y4�-1���AP<@�(�����=���7��Ղw�P��jUBB�"��+߃�wВr�o����l^T�3�XbUEHC�ҵ� @����`�P�ӷ�B���|���b���B��)�j�Bl�֨�3� 1���Ax������@��h�u���)?/��v���.;��lE5o!�|T9��wZ�X�4�*��Ŀ��m���m!w�%%�>;��q�#.���C�z���?�*�.�b"���F2��U ��i�}�*�����Q���4���ș�{��6�(A涰��[�Z�.���xw�J�����;���CX�t�ù�R-�a3�_��42~^��sT[A^�3�|�5f�y޹�J%� /4�*9�ʆ��'�e�^V���͏��]���LC���\�*���L���]��`���p=쐡�Ft'���Gm ��[Ŗo}�k��H�?U���[i�*)PՑ�u}q�����L1&`���    h0���b�W��SP-xGI�<H��!Tɷ�<D�xn�����6F5�o��$Y-xg`�LG���P%�J�U��w�Hh�5=mG7~U��r#������FF�� �k[�=��uC3i�M��\+!��&rTh��/ƻ_���0��'mb����㑆|x�X��F��DSs��C�@Zr�4c�����4ގkqc��H���۩�6����u`c˷6	
ޕ"%[[AC���zj�}�)ż�+4��UcM��xX#;���!L�ވ�4�R��v-5��o��pw9]V��z��\z��h��E�3��[��v����l���BC�I��������V$teZ����z1W��|0ߟ{����{��+Sd���z�ɸ�ɇ�Q��9��Q�ZNH+x}�v���[�z��hs>��[,6�yռ�sl��j��,Ky�X&!L�o֯�H1"Ot�V\���󃺞��m	��e�<�,n���J���c˷���B�ҙ���P�[հUMO��u�+f��v{��k��p�6��-��ɼ~sl�����]H)�
B��f�CT��+@�Zo����l}�nXw��l���~��(�y�����Q��K�uJs�
B��f#BT�O�~�LrF�3�g���<ڝ.���c���ST2��[�=��wn]�T�
B��f!�"���y;�b�F�և��#�l�W��ͱ�ۣ�y�?�)S*hUr>�P�*� ���Ϛ���qn�j��*x 8O��4�*9�F���&J����6�~��O�9����2yۜqT�t��ۣJE�V�4�!T)'it����8�Ɤ��:���y:XG�9�r.g��ռ�Ul���z޵�e�e���P%�ʘU����N֣zO{ݵ:�������f���6���YŖo���]X�R�T&AL�U�T_t�*���1��R�wY��N��g�ҟ��%�o�᥼�-4U.����4�����-"Ș ����qk$n'�I�tڟ��lĘI��OYT�2V�,�Zƈwz8,�L���2�4M�i���8*��H�n޻L�����n6r�Ĥ�Χh�Ie~<Y��ED���"�M��/4�*y�6�4�(�$tB���DL�r6��Ŭ?���r��u/����ӌ-�ZVލ�V&[�/4�*y�6�4A�[+��RmTD���r՛mOgq�m���j��yo��ӌ-�Uϻ2ʤﬠ!T�^���	~v�1L��ಜ-ƃ��{]N�|.bs��vѨ���iƖo���]	���hU�4���?���C�[]k��ݚo6l&�^︚Iq����ӌ-��^��yg��--,Z�!T�Ӵ���DωKj�&�Ь�a>�ܙ����������C�g���:.����쎇+������?�{����x�٬�������g������_l������3����{\�����l�U�sS�5E/����߼�R��S#˅J)���΋�l�'�ͅ�7��z4�qs wyq��Ŷ�]Y�d�ؾАؒ+ou���'��/��-UW�F�w��՚m�KwM����|l�6Wl���]H4=SW��P%Wޚ2�Tc��6F5�+��*�qK	��iUr�Qu�JE������9��8�{ɇS�����t^W>�|���q�KI=�iUMIR���Skjd A�M�q�vG��`;_�g��q|���Yռ�kl�v�z��v�Zr:�x��N����X�����N�zi�j^�5?��wМ��~��!T�p<@UX_����>�w�������p>���b����G�y:�X����n�;�
Q�zeB��W'T�i.Gg������Q�<47��LK����JΫ�2�R�O1]�|Ey���Ɋ�@PҰ_��ޣ�*>�u�-���@~�{u:�E�S=��$L�l*�����V�wh�F��2	�GՔQ�\��}O"���͖� t��d���
�	͒�/�\�@`85����Fc��%����"�q�5B@���BC�	�PK�Ǣ�Ũ����=����y %K��CB������c���~�Q�<F6;��wjÓ��,���P��b�- 8B�3
𑤌k@N�#g��p��P��ί���o.�.�e����BC��Q�%h�fB��Ǜ���^�����W����4>v����̼�dy#x���ˢ�"9Ő�Bի�n�H�%ڎM��	<:6ᙍ�дH�����ǹt����,4 
8��R���K���r�5�R��ç�W�7֔���~�R*��5�WCs���-�|��b���G��b؟�JM6�͎]`2�.��'�7�[�%�����&Zc��	U�J��:��	�u�c���m,�ù菗��qŢO.M�XSl���
��옐,-3���P!���RBח�6F5o�)?��wtmʠ�
BUP�xt�(i���O�s�J�ˎ3�����iUI�� U��Uk��ύ6F5oP$;��zs&j�w��J��
Q4��	�x��Ҧ���G���=����J��CT}ٮ^_;>��񶞟��<�7{���tr���7t[�eb���`x��E���@%���8���6�ȣ3�~|ScT���Z/�w�UG[.uZT�ɢ��P��UAii�vʵ&@cT����Q��s�'���LC����]�*D׊���n
���Y�U������geՒg%X *X�ߦ�S"?���:�F|V���!�LC��g%x��d�!;�d5�g�Ղwn�Ri@HC��g%D�����,��vUcT�zV�QU�)�<�HS���*Re\ZQ^n�i^�*?���,Y����BC��_%d��҄�֒շ�k�j^�*;���J�5ZAC��_%T�*9`��{��Q��W�G��.i�mZ0�!Tɯ/~��,?ݪ�Y�߱��ϱJ@���H�'�Y~��PE�J>T)�:��%,�x�V}�8���ge���?��s��	t?1�Ɨݡ��ڡ+x��A°D�#���$�N�UI�`���5�[�s뼣
]�y�!Pɟ. �f�_�^?㬷vl�a�^Wn��t'��(�J��u�b˷F�x�T�ɒ�L��:r������D�D�>���d��\v�\VG`�)���(����F�o�i�;������J�� U��R(zʕռ�\vT�wJ$HjEX�!Tɝ�J6�#�q��-�Q���eG�x�4Ҥߪ/4�*9t !��⦃�jx���b0��pv�\V�<��]Uռ]l�vq�7ށ;+Ғ�!�J�:t����@�P.CNo����ٽ�TyahG�����ۙ��t��L8$�
zbm_HC�I�$���)3�?�+nO���b!xnq���#�������ו32�����y�<���+����Zw��@f�ӝ[ iP��X�S�CHr¥Q5~���z��g_C��N��⸘�A�z��np����	�-�U�;��0
hU�<%���D;�����Q��gG����'�,)����P��V�z���̍����YG��p�$��jyj�,Q�3�>3>8�d��e���[	h��v4����KϻR` �]hPC2r¥	Q5x�w�	�N���etvT=�RX�~B�HSr��k(N�dG���bcL3��΋i�;t�`i�c�iЭ�.8�H��U�S	t)�џqkbc��~�(��:Xz����u���&��*��L4w�Mr�Q-Z�
�fG5��U�;~�Rɨ>����(�jȀW���7��Q���G��.�cI��4�*y�
BT��GG1W���1�y����z�����J^����wS��M��o�E>xNq�,
hU�"�
Qu���hmT~��[{�޹s�$+�B՛ :@Mi�&�aP?G�1��ڍ|���X�lн���H*�j�w���ʿ�C���1��݅4�*'�N�·�*�9#���?�˿�Km��������k�o��i>x6\u��SA����;�
j�S���uO�_o�3œTo��$���癠��4���ž������]<�>�+ߓ���<��`AQ�I��L5LOq�}����u��(.tE�>��,̞�9������^l�N��+)]�4B�)�ͅ�>�_�%Ɒ�XXu S��>�-�    ���@���5�b���]{����"x���������T�A��:wg������7�j��%�h8S���ъk��s�~�?���OA�gIx�JSV)KwR#�gU#�?��p��m�p�f�`B�@�'R>��ֿ�i��>݇�k3~���Ж��BN��ʛ�]�ە��U��dg�_�@�.�|N�_�S���J�����T� %��a_�P��8+X��j���
���p�)QE]���_�Q��a�!QLz�6)�[�!T)�kB����pPx�X��a�!�;WR�d]�BC��bB��KY��G(����y�8*���LC���3��N÷t�I�~�vST�oܷ@Ȼ*Vq+R"�eB��&��)?j���<�wST_ܗ��Z�Ό�,Y[����Z��Z�y�7�另���ME�㌔I��2��-����Y��\�ϧ���MC��֘�V�eDU0z�����<��Ƿ�Տ���z��I�E%1
�u�=9"~_�6m;=�]�t�2m'iM��O�k�·˟�<�Q�b6٤{�!T)�aC��:�q4����u��l���x��W��i7Z�{<�j^�.�|�uN
���u�OJ9�iUr�l�ԁ��X��w���שk�j��ﶣ\Jv�DB��KgC�N�=�qh�����Ӽ.]vL�%8��?�LC��KgC�Nr?[�pQ��1�y]���r?$�Nz�ᅆP%�Ά.���Y�Y����G��Y�4�+�L~�!Tɥ��K'�_*���֥k�j^�.?��w��K*�*��d��Х����F8�_V�t�Q��3��D�]�BC��KgC�N�x��A5澢6[�"W ����&�&�ܶ{��#�M4Y1����F�h�3��
��`���;Z����3	�P�Ǿ:<���I����DcL󺑙1}�.�H�%W"!Lɉt,Ĕf��e'�؍!��C�Գ.��&Q�4*����r?��h�dvo~���j�;�yL'��BC���D���l����L-� �E�W@[���.>|kg���"T#�m�GU�Jz׃?�D���ƨ~kw����DY�oRQ}�!T�u�&����U
���|kw���ZDq�,�PhUrG�Q�~�������l1a����ewS��/�s_�֗(�y����-���+�h�4�*��΄��A��*Y���.o��v���j���.V���E5�;[���zޕ�J'h�J���$�{bU������;Y�fӿ�Λy��Ⲛ��-�Ղw!�J�T�!T�u.DU�:��Ԃ
���6��`��\�/uo�dǎ�_KO�q�;v`�ʚ����a���BQ�E��89�w�3����!3w��P�D���t�r��I,| �5 k�/�F��/O�����Yi��(�4u!���U�OPI'\/�O���E����vH�(�ڸA��i5c�jUi��X�`\��}=���9̝,gQ���~��@u��В+�T#��u��CF0��
�,w�C#0��
f9������П�������{v~v�I���]׹4|�sg;ϼ����`�PU1��w>V�ڹ}wT�܅��2�T%P��ܠa�VLg:8�<2���fҁ��)k�Yt�>�����\}����맏L��7g�Ί��׽-߼��ܥ��Yr��SU�:�m&y��-h��������������������������hK�6��ru1ow���a��_���zx<����C�ø�ƿ������Ƥ�?�i6<Ckv�H�=�$�)lx�&��w����]�!����\���vGxO������������i*���~+"�o��7A)��:�L ��7���tf�i��Ⱥ"��7`TgnQ�ir�-���W�Q����0w�sV�ʇ0�(7��Q�P�,E�T-�d����;�-�i7���g�sj���y�@Q kyūo)���������?�G�tq�����7\�HWi���n�&��z�~�g��HQrG�ٖL�҆�rHG\�èZ-_]�����/�؇ow7�������+Q\ξ!���[�����э��r:��bTûҁ~Y�}�����Ӈ�w������Ǐ?����ŗ��o��4|;�a��z�+������QUoz�岮[���c�j���^���e�r���q��*GJ��rK�ը�u�Au9Ե�;s�t-��o�*K�ƨ��R+��.���p).>}<�q�?^~�xs��T�Q�X*ߎ�P�A1VM �� Sx�Ř�Ѝ�kR�������ӧ�kuǾݽg?�x���8�.b�7�T���sGq+U�S��+�؃���wx�C�Oק��o_��rq{�A�}�&�ή����)ߌ*��Pd��jV�}T��!Z�:��r�jT�z��Qs���*R�8=���p>D�|H{�9ZbY��xA���>�k����ٻS���W��j_o�4|3��;�Y��C��ξ�����6 ӃV.w^:�����=�al������T�'��++T 9�f���?}��?��{�������7j���!���>$�r�m�]������h�f���!��O�������T��	��Es5�}���b���*s��o�*�L��*4��ʻ����\�j��9�]����Zf�P��)b?Sq�sf����^�����www����|��V}�~%�.K�������Q�ȪpZ��ܢ�B������Bc$M��^�3�3q�o�������{������Rc$c������Qs'o��jZ�}T�g���T�D�4n�9�jT;���Qs�\��2<�7@���{��y"�*��S���x��}�������狻��?���1��g��o�U���JTzD�7�~��1�>DD�W�}V�����j�;��׆D�o�*�L�"T9����Ws%���R�X�m���tA��۟�����*��<�H-�P��z7����};7!Z�/��wnD�&���I�!Q���9t�
c�1���~���u�۬�ð�d��m�r|_xq����}�-���n;<̾pj3{��o�m��Qy�7�Ja�u��u/z7���y�c1�2v�E��3�7�����s�Ye^A�� MH��
/�ӕ�Z7q��b@)�~Ʋ��c�	�CEY�B�ŋ��{�o��s�d��j#r���H26"*Y촔J�&��ky����G��i�[�lx~���mB��SRz/����W��Eb�o���Gu?}C~�O�0w���7�g�� ����m(�N0���%�������o�?���g����B~�y�jߐ_i�FT����2�����7@!?%cTo�Ym�r9���ھ!���"���$��ܫ�7���bT]` �u���jT������.���uw�o�j�w����N2��6z�����'��?5�7��^�0s�c��E�4�����@m%�d����I��;��"��������C�K�y���V�����;Z��;�ym&���g8�jf��A�CetM���*�]����ʍX�K[��}��}�v?w��uk��E�W�v�h�@)q2�����վQ�ΨsW;ﴯ,�T��,F�w�r��*@h��AD͙�~���#�{�������oߤ���㧺�����}c�����"��S��(Y��D-bT�d�J[�$-�}�S�Qu������BK�PEtJ�U�Qq�
��/JW��7��a�J�!^������h��� ��b�0�jT;��tG5�]�M�Ҍ����QE�$���'��Q����Gա�
�f[Y2<���v�3�]��c��F�,w,Z�����wFu���2a�	�0�F��P�+K�hwL�z��1��8�kA�}T9*̺��*�z.�i��*�j�������z���9s3he���1��W�>}����'L]y�*�&��`����7��_#r��Kb9�k5�}=��sׂ��3y�	0�;o`�I��F��(�1�����4�]Ii+���� U����ï�@'�+����[lbб��y��8�q���g�?Oo�>z�|w��,.ng?�0��ť�kg���b�o���c�ݹ�_i-FG���^�C!�C�pG�TD    ���-�G�A��\yw��������y�ם.߾�a��9]�P-���=o���Z�����jT��ӝQ���>U)�o�*��y�l��{'���F�s���[.���E� U�����+�Uv�=r�W�Q��NwGsGnӲ�|�P�;=� �_�����o�ւ��z��AS�^���O�ʎe�cP��^���ը�������,��W�[�����y_uؘueQ��;�}���s�V��3���͜�Uǯ4"���R�Q�ը�u3���7���o�*�þ��OxT�UFX���}͞����skP�}C~y ~�a[�	T-v�;[[I���y؇\v�!�^k���zm���=�V�>�]켴Zָ"�o�����<�C>���t��b���U~�a��IZL[������g5\XyEG�zq�����<l�PEaq����W2��g�0wt}uQ�P��y�?{@UU-��ˍ5֢z�~�P���̪�=����<�=�
c�)�����HN���'@���B�Bcz�D���	�qSv�pr�椷�����Ǉ��ΙdU��o����v��J�g0VH!���?W����w��O��v�VA��+�\4G(kv��z�C�j�!O��:��x�a�sRW�v�}���ޠ)�؀�2��l��oxb@��nw^H^o�̾�O�؀U�����-Gˎ7<��:(˪�S�7@�	���+������6�e�����+]��.��R��qT�%o��k��'����$��Hz�PEt��ָƸQb��V�z�P�"؜�1�Y�O�B�L�z�O�����Yv�1�a�k���b~8�������D�(|��r��ըypb�� j�5�5�7@��ö�/�D�L˝v���V�z��	��8wrv�4�Ƒ���@�N�eP�pd�5\��^5�s �b5���ݞ�2���(5To|����=��ld�k�3������x;awsgRȪ��7ؑ��L�*���3���?���s���}͝L�PE��g�2;%p��&n�����'B��݃Q�o�`X'�ΐ�Y�қ~Ck�G�TE<�C���au|�	��i�4��-1�y[a���|5}��*�#��Æ��?�5k���=����ѿ�s�;���5�n��11�Q�!�PZ��ā��g_n�٭x�����\=~SO����̔�oG5�]ɫ���o�� �"BU��*�z��jT;����0wix]s���*���Q�p��j9��������{q��A}Q������_����͔�ϡʫP�T�@��jT���WU�*z����r� .������_�.>����ӏ���j�hDi��K��B[�h�Uzx�7 �flfOs
�9\UY�hO_�w����~~�x��_<�}9e?�����F��o#�������x�o�*�x0��J�m�&K��
�o��Ǜ�%�1J"�P阶���K�g�5�;V�����@��Q�E���~���lE���
'οJ���J ���a��B�S�k��&_r�
�B*s"��i;l^�E�?Fz�'J�S��8�Y����ڰo��6s^�'n�7І�P=|��f�hJP�|��s���Bh��cP.��$���W���GW/e��k���n���P�~��t@Uƨ\�H�4K/���c�P�����b�@�����b��籵IbH�#���E����y���������R���dg���޹ma����ΝT�.4��7�N�G�r�և��%W�*:ס�j���Ue*���"�*��.
�&u[�P��-�fi�����1A��v4�L>s�.g|�^��p{�'�N�0�U�]��7XO�e���6�GF.%�L��8V�ڹ
k_T��˝��b�	0EPV�Sɇ�r���;��˟��t��VVغHW�PE�A�l�!%@����/��Wgg�J}>�.��J\�;��������ʖ�oCu?w��s5_�oHI�^ :!D���;�$^`�^e���wןN�.og���+��ß_>�O������o�>eɝ\LJ_�x:j,
����r�'CW��;��i_�v:��+Q
���4r�YżK��Ќ�+�PY8�����w��[���}�#1$��"���n����;̝�2!�L��.�aRT�@I�E�^�{=������>���Uϝn�vXR�,�A�Vo����Xw��N��Y�QҴ*�y�b����o�|1��_����<��Ѻ�64��5˶Ml�������װ���v���)�X����a��x�8�drj���I\�,Ra��VQ�����oG<(�6acu�,��)�m�A�#�ot�q�}t��,\"SC/g���^}�X�k�a�V9UU�5��6�d1�*����ڴ�L�W|��l����2�M��}���V��^����9�5���L�6TU���yT���_���������=�.�B56�ux5D�ҞnCUgP̓�J����O�S���G��ZT���6�%g����P5)��`��P�_��`�\�o�5������ͺՀw��������1�k
��C�j\JɸF7orPyl���j��ֶ��5���n��UU�7P��@�q���9��G���k���	]U�$��b���.�#�eǽF�ި����*���VUi��7@a;��H�w��z�*����G5�]{����oU��Þ���F�w�`}:4�k�=]sW�Cˢ)�χf�ڊ��*��6�2<@fJ�猾z<l5��������B~x<�}���#Σ��j<\=y8t��#0{|�-���?���h�j4\S2[_��ș�)�|'I�C�Fð5{#�e�^�LG�a�z�X�ǃo�Cd��e<B�H�,�̛@���
]ϥ�E���� ���M��"��A��Lɰ?�n1�hv^<�Cs-חP3�R,�b@:�x��sJ�/Lc�V��t�.����r����~ߗ\ݭ�a��hU���|[?�qƶ�Aie[��a�Sq:�:c��M�0�.�����7c(Bh�D��̽���Uj8?:����h@��_�GF��Uj�(:�H���δ���}��ar�$�G���m�ߠ�"2�}���Y�(�x��0��&cb@j���ƫ
�Qf,��GI��5�MR$�T�iz[�6��mM'����Ө�Cu:��Q�1a)�;GΕ`n��Ws;B�j��l8�!IZ�>�bV�܎�o�Bs1ՎxHy�޾������Ж.>�#D�j}��Gݎ�o�X?x�J�n}�ɮ����l��]�wF4�ul}��Gݎ�o��W�	?�^�[m���+�-.v/Q;.���uw���	uwه�koY��>�N;�*�����1m6�7�j���� RӜl��W�:(���R;�h�����cƚ�*���iwC���������~U�=h��� �����sۡ���N�Y7��U`������'�T�j�FE��g� ��amD����V�!3�Szn'�׍�#wB�
�/ȕ�^>��@�7�la����yZh��A�N��o�ȏ�e��ea<����C���yU8m^gP�o,O�����m��M�Ѝbyb�[�d�����D~.k}H��&�E�byz���f"/lb\h)��'4�L���S�0�;L�=mF�|�Q-F͐F�! �2*����/�a)��&Jf���K����2܄�t&�j<:/����X��0&I�^!f�J�!&�)��m��w�O��r�%�P���k��8.�+�PƵJ���Zgw2?n����P<�N��xv��ٮ���l
��e�6��]S�w��u�3�.ϳ���4�Z-���d=X���)ZO���m�x������^��q�)γ�=Wۘy���S�e��F3�bW#C��
'��xaS3C$Y�p��N)+�R�l)$���*����;�yw^�\
�/K�K�6sɏψ�H�%�aȣ�{V{��� FB4!:*�3�cԃ�E�2aTəe�3j�k�
��a���+*����ַ�EWL.�	�*��h4t_v%�%&nF��58��J1��&Fu}_+��1��Eah͘�0��Lf�C�j�F���    �+a�k�M&3셡I<�h�)kH��נ�F�Lr���s(��:
,l��y�00�d�6[����N�яK�*^mqx#h��8�����8����{<y!>n�l|�I64�:>?�x �]�<�w�ظ�B���6���ϓ����c�1�N����<���8���>%[cǵ��ve�N��I�厃+�j;s5m���$�k��5m��=y%;�mCg�����%I���{�T+��m���$�V��� �Q�W����$�OǱ��M���������+A����d볂�����>���x��X��YAG����`D�_�x�b]������{�f�aUY<vN�y��:��o6����8c�e����z��͘<�NK�����G��6��)J��7_l���Zߢʝ_�S�;�՘��~>��bPE��&�j��}ݷ\�Z�y���?>J��u�Fe��\}-��	ZPQ61�z�2��B��-(�^�Ը�k�!��to�h���#|�N���D�J���;5/�Z���\���4UC�Y'zyZӑhL�V��M�`ZrL���!os��r�f���k	r�k�W����^2�v8F�5���1b�r��vJ8�x��Ɋ�^�=�XƐ��ӯR��򪣃F]�F��ֵ��"`
ф)�3F-]�5����zP��S�g�[�<�i%T� -�^@?�y����S�a��4�t//t~�O��1t��4g�F���z!v��LG�v��H������I�z�\��C��������z��ϓ�g�4>���!����ɾ�m1�ڍ��>�z���d�{��������i�ͯ�F�c8T�������9�O�s�F��߫t�>����J�]�3��sB���ј���+���sBi�wi��I���>a�9�����U78�\�k�ാ�u,*���87�#������c�<iy�ukg��K'����;��o�]:�@�,Ga�ml���m*b���';b��5ˑO����vt��s�����%.4�1f
�ro�&�f9�Ci|IDո�h_s��~o�F�f9��Br����\�W`�d+]��a��FޑoiM~��m��N�<�zttZ������y��@LR7&�W���s�GÓ��j�W ��稏�d�Fu� �u��(Q��u� X��	PjZ���� �u=�/P`M��Cn�W�1>�W`�ym)RU|}M�����:�x���������r|�\�l���*���dr+jݫ2�"��!��f������Q�:pPh��Ѱ��Ѩ�tl�t���h�(N�'�Fi�����nqP��̧��K���V�X::��`{̓���0F5P��ņ�;8O��ÁB�-���b��7�����ҹ���v�p�K�Yk{0$�n�cG��m��`�Γ�N�R�ȡE�����"�wπ�)�����Q}ܙ���+J�9��Bѳ�,H��83��8�~8�N��J8흜y�b���*�"�t��<����y�e������8�N��J8�"��[q��]&]�)�d����,��ފ�\��+�dJ���(�����������*��t�$�e�Sb>oj�vz��Pv+����L��@��@��Jٵl(��21���W�4��x+m��)�H���Y��Nݵ�'��>�O�Gw�Y���f�֏G��#`W�����Tm�
!�z�f�F~~�s���������{j�#ѹ�u��������XG�x�k0�q��V^�&�ֆ-_�����T�A؄�]�x~�v�*���a�6�q�6!�*�&l�J�u3�6/U�Y؆�Zga	�#Q����x��Zkh�^��BEU�|��zS��]��D�j5���,��0u�<yJ�5fz�p���F����Eg|�mk���;|xx�z8����aXk-��3����ᑲ�8����D�Gպ�������h��\�����?�&/�uo¬�d��h��^�v"�z'⏠C2���C��>�D+�������tt6\���ڭu�«S�8[qZ�u䏀�kT��[qZ�?�G@�+>w�5���4��.�����>�����9Kw��;#�V����?{�%�I���85<�|;5�p~����?ي�Z��؟=��5�_����;a��� �����e�x��&v;4W�2��YgG�9�ᵚح� %$�z<�Ύ/u��-5��0�a4���cE��K	�]Ll�xh��&~5�2�rp��ܑ`8��pѰ�)�����cK	֜��|�N��9íU݋!c����~�\�UU1���)����L�R�Pu\���n.�P���s��]��t�acC`8$z��FT�_��6�e�6���bg������k֊Ml� �3����k��&&� �C-�c�0�M� �g�T�1V���&�� �v����+V�J�&&�,w̢���T]���̜h���BY�p�]F�Ҩ��Z;�,���2��j�[&�\�1�>��yT+5��/�b������nU
/�b���(�ƴ��/�b��%��O�'�м�4���`�f��%>^�ywu1�kv�Ȋ��v��z������;��Ix�J���T~�E�Uw�[K�7ۭ�ܥ�^�Z�u��ְ�rI"T_�����E�c�d1�C_5pd>�Τq���^�|H���`մ7n_�|h��a��/�B���"V	�B�Fr^�|���*aU3��t��y�k�'�)V)��֠*��z��3,������66�>�s5,ً�D
������ȹ;̝#0 ����pw@���<ŉv;�\���9y�f��z�{�z=,$<�!O��	'Q��&�G������3OlR���o���*E�Aʠ@Q���rq�ןN�.$�����s�����x�������خ�ϷW�=�����J���S��T�	c;R޵��|z6L>D�K�x�0�����0��՚���{<8m c�-��������iZ�C�5����/te�4�K���W7���}�W�5|𪱡�>/��#�Vțf�7)���+_�H0aLk���`�;,{��Cs��ahΙj�g^�~~��z�:t]�18C�'Zl�8�� ���<"�sZg��5����#�MCk�v2?�����s|ʞ�[��\�x�1��x{+���!�<�<����8�"O&e3��T�-	gZ��d��}K©yJ�ƨ�VWU}K¹yJ�0x]ߒp�E�T��i����p���-J�����N֗��ۧ/��gW�?����W~u��c��r]�����N����rNV;Y���ɂ1"ʤ_!
�D��XHS$�&��x(�v�"�P����hx����Q��U�R��	W��� k��u�3!\�B�l�Z&t�u��ր��eB؃ �I��=1c˄���^�0p�L8{����k�����G֖9֖;�4o��R�� ��9b���muu��;�OF�3���s�0��hmk��f�$�ÃgT��w�5U���Q`�'���l�F��NJT�z��F�kT���G��k�F�n��d2���HD#ۨ�膧d��������_O?��鯧�O�����o*B����8}h�l4*ҷČ�A`��E>h^�f���T�Qc�1j����Q	��x��M�8�LB��D�R��d�wq���pz�*�񯗷�8�*���[�%*ڶO��,���:�CnO���D�
�ѱ���0��쩰$:�Z��Ӥ������M&d�"�d���[\D���X��N�3&UHU�V����84���W�R+2>��`Q�v���&�V����[�R�����v�h9�Xy�� �,�*o���p�A�w�]�ty6-G�Q�f�!#�E�M}�-G�Q��e��4�Y�M^\�Ѹ�G������:�g��쳁9��&C�E���uy�u�0G+��Ș�'gٶma󗊲˥"8��8Sak5v��G�4M�4ilO+޸\ia*�l��:Ҧ�Ӧ���[o��ѡ�_D�Ym$N�'η�i��IJ�6>�S��+.\����Ȟ&Ϟ�p��7��|�~�����6wm�@��ٗ    c�בAM�A7� ��y%��f'��bG�y� �D�b2����;��ͳ���6+N�$�Ȃ6aA�ߐ�kRk����Y�Y�6W[�ك�	S��o�s��^"�F���6��0:�'��e2h��y;����6��0<)~%�J�3�s/x��GG��	Q��`k�e�~к�x�i+,:�nq�|�k�P�V1���,��d�2���6��A����mIvvaI��>r�K�r�B�#�@fm!���G�v	in� �^!8U�����"�)�R�M"����"�`n�gF������F��F�k̲��2)�F�9Grt9r��x�Fhˍ�}�=��12�H�.G�o+����PD�)鬡e���pg:R��Q�&A,�df%�eŌ���$�r$�����!�uaa�it�I���Mb���D0�����D�sD�M�hat2bt�gґ*}�*5���ނ7�B�"��Ȗ>Ö�������Ί ��g�� >�є�b��^��g>�g"h�l��%�PD�BN��F���|sA��>Ú$9�o-$�9l�K��sά#o�on�H�S�(m�+�sn��g�S�� ���Cgtiy�u�N�2ܹM�{u��z�Y02g�:��e��(
��HZŭ0�:�ׁ?m�F8�A�o[8�/(n�&){�ЂL�F��*Ld!B�CIM��f[��ft
+X��$;��M2�!�+�-J�P�L��
��7�M��~�(�䘔D!۰��0�f^i�G5bہJm���UMv���q.�*٠�\j�t�A%�o� )���Ktȷ#�&YT�E�N�WRzC�SH,�(w��$�j�0��Hcr�e!�}F�#�&YV� ���/�wJ�#ݎ���Yqu��ח�ᬾxl�8�)�mz�$=I(��Usܵf�9��t:��C�@	�$�$�bж���|g����L�!��~G�OR�~�0 �$cl�i��n���C�$���\�T�t��,��Οu��
r<Oh�
a$�$�m��Ib�6il�党i���L���p�/=�D�4�<�E:a��$�m�4Ĥ^2ì��*��L'���$�X��Z��H�T}!
2郑�D�ax$e�F$^�x�@�I
�(6�����\y�  I��0� 4.BDG�ӹB߼��C�Z7
�3��e;�CD 5�
Rs��C����d�vH��H��F����	�#_\��q/x^;D*d�I��fi�A�F�m�}#2*�$�m��?��̟�^^���C�ݶY��(��#
�
�C��]�v���"�� �\���!I|��d6&`	OF?�8�^}�"�}��4��_�:|��6��,��7�/�'�op�s-[:����kb�s�Gfճf��G��o���Ji�$mo �6�V-v��Dy�ͻLs�9*�$�o������lRʝVҐ5I[_��?�W�ZL��~�4P�I��q;�����lP�!�Xz�}�m����������H�h%]c
��s�9*�$�o���0l\���X���c��YN�(���E�\J:`�=GŘ�n�F)T���L #
�X{��1I����O�b�*D�5��$�QgZ_N/ԅ�c�HG�
��3(�f�;A�a,�-dIGT<�l�N7
�����$���C�4"�k�9��<����2i��Iv�(�i}�>��
#����F\<�l���U:�;r*�sD[���T<�l�#6
C���~2�+�i��#�&ic���ı���`*,T��#�&�d�	Z�%Y�F���x��$�l��x�4x�LT%E)P���#�&�e�4��w�C���W�2�&)e���>�kAT!ij^���J;c��#�&�e�0J�ֺ;t\p_�R�ҩ�(p��$��I�M��Fi�׍V$'�n���R�"�sF�6�A�,��U�"J�y"J�6�.�AM��qb�啚S�ȶI��fi�E!&�p�da�"J�6I@�.�.b�\��-S%�l���h���p�'VWĒ�%
V��t����RH�z^S�s �$M��w�Lj���g�Zvf.�aqr�Ĥ/
�h��f�:���y�f����N�cyM۽��[<V^�+�w���.���$�~����������Ͼ��[	�P�����s��JPi�ƑsW]�}���pv��E����Z���y� +9��Nb�j4���Q�[����R2�q�^z0�aFc)Im�eҀS�D�A2i�j����̙��آ��$�q�4�<�IFE
��:YT����9����m��]Z^��E5KI��fi<\2;��B�R�-��Fc)�|�,Y%��݂�YT���$@��h�����9ü*�*ZS����?�RX��M��Q̥$�q]2�Zp�f����I�$G��2���5.h�1�m��!R&��H&Ga�i�V�T'���D*�%��{�I"�/�&,T���3���2Oſ@��T�{�LF=�$Yn�FX�m��S/�Spc��d�I�� ��6>%7�U��\��z"I��,�.9�]�����ɨ'������jM�2���BA�X��z"I���^�Fw6ho�S�P�r�KFU��_����ј�[Y�y�I��0<�1�E}�����I���(���T�5�'���ϡH�/U�+�����Q#�n�f{�;4c�CP��8x$�$�IV*��A�X����;Ir���.�#�0�}���Y�ȧ����t�w�F�>���ѴP�uG��Q�Rs�0�}���Y�v4Y��ڮp+k������8$a#�-�R#+�d��4�@�.I���Z5v�4nG�Kr�z/��B��%i��(��Qg}1���.��$0Ȱmn��R{���.����DO��'��)���(p~��wI��(�W�����h�n����B�����wI��&�S�ca3���C�h�������@�.I��,� ��#����Y���<�
�$ms�F��H���u�+���]���Y�d~I4� E!�����]���]�Ё �쉕J�t�F�O27Gio5i�Yc�1$���J�>����3�����;0~��9� ڛ�/6�H?J��'4�"CSt��}��ٕJ�=�4w�IV��J%�W*U�*q*9��K������oO�o����_�|�������
ji��{�i��i]�5+��B�D9��+s"͎	���ۿ���R����/�>�~����������ETeWTK��P�U���Cr4�Q=��BeFɸ�����?���{����)�������͏w�*�>���.�����@��_�/W�N�ov�w�r�T*�yw#t~y�tsz��9^�2Z��:t88}x�vwq��B'��h�|����͟�o����êݞ~�L�onN�������1�/R���V���U�&���w�������ˏ/�Rܩ���������U׽^�����K����o��a�E���W҅�eP�N�=�.�O�.��Sy���/�Ί�꾠�o��a�Jz�DV���@�i%��AQ�4=zǌ�VK2���s����i�0��%&9�]L&���^!�(e�O�Xe�7)��u�["q��%3טaR�R��~3����g'�ᅈk�����,�&��)�F� %��,P-�5q�[%���QTp�H,�ϋ��w�Tw����Ï�g�_~ޒ�R<����,�|>1wz��>�������N���DwT�1�:�]0��C5��Z�*#Tuh���w�~�jT�6���0wx���� S����!P�>��\u���b�b/^X�$Y� E��"�FH�w�k�����h.�!���w>��y��_(��y���0B���h��=��y<J*\�b�c�q^,��(��r(�5�(/Ԋ�B�c�q^+b/��7F�����E��(���VDa��9��V��R��<B9�"���v>�B��R�8B9Z�B��X��)����<P)��S�SE(���R�^�<k�쾪���9�%)�4��Ik��H��YrDc�o�2���(��u����e�h-#�����$���[2v�-����x�}�g�_ MX�<�����q(��K&
/~#�02�̓�a�%    �
��B�R��H?�ԯ�l�pӺP;Y�Ps�0r���i�%���eS�e���_��v�0F� �-�"@�˞���_������m��e�4Q�����T���*ϻ��[ӻ����_�9�@Z�4Uu�4��9W�ԥYN�Y�K�͕Z�K-;�s�Y_�L����
{+�Ch�/9��C�9�q��6b�;�U��AEgxCA,�Í���o�$�\ۍjUź�I���c�1JC���r�œ/��k��
�������u�fiH[�thvD�R��H��zU��c����ȶq�v�b���wԫ:V�����s�8��Ѕ#V��bձ��.M�͟�H���U�#�iQ���Q���Ui�5Ҿ�bձJ�!hTc��ս�ժ�4lHZј
V�}pЭ:O�����܄�x��7�bU1j��]+]{ξ��L+F�U���G`��֢`�L�q���#]���O���o�#F�7y�� ��ѣ����#Թ������r�ӹ[^��~���ɶ]E\A^��	%Eic�02�ɳ4g+�2Z rL@]ܕ���y�Z�g84�bmAؖHۚ݅>�q5�(�:t;/P�Õ�;�5���ڣ��+k�&���>
'(W}������¼�@��J�R��A���(��`��,A{ͫ$����
f��YHUy��P%��y-������j9��<�}k`^q�fr�>���d� �xc:��2/��2��h�VN3]�,����ռvG��J�2�X3S����&��H��ZC#}����z:* 1�y!����-��3����!ߖ�`��˵t�l�b�
���a�J����{�9����īB��q9����'��0�G ܴ�<0ͦ?,������q���W}
��L/���/����9D2�|_Dl@��K�͕S��jD
����N.1�D�P�7 �����#�r�d�����%ַœhƽԾ���� �9@^��C`�Ĵ�@�z����d9�M���m�X��,�5�n�_Y��7�X�zt�_��Ⲁ�6�J�K���iP2������s��	�r�.1d<��A�����2�]8k��~�k�C��U��?���Ax��z��9U�1T����a���-ݷ(s��[��5j��U8���*5Ν��]�N��!�T�Q�[��;����/"E]����Nol0k�B�r�MwT�f�j��P�+U���7@50@lt�Wj�v�����I�a}���c�x���[�I�$������>�k�n���cCq[(k+`��W-=������a_�P2�.�L��R��y�y�]��5�,6l���u��� 5��x
=����Öx�z<K���A��j�A=��M�j�ԄAa�{����
�T�r�g�-k�ō��gyf������`�a�̸aإV�
��Q���X�RkW!�|�Y��6�P�����<5ᒻ;(��l��(�(O�B�_#�j|b'Q�ר�HI��@5�����q��9�H�Ww;�o���v�0w���+YW�'�v*N����+�Sh��XX�bYս���{�z�Z���37���cP]���]l��yټ��Zr��F���!v�W�����i�4��"l�AE�{
i�I��˒�tA��>/��<�GɎ�.	��b煭���e�[b���l�>(Y�c�m/���yz4������]!UX�Iӊ<=ZR��q���¸����E�"�%}��X��,�$�aXM�.t5r)ny���+��f	f�����[X�t8�VFV���9z��3�<]m���W�K���2OW�]b�@�2GV
�u_���:��1ֶ�+�&�+e��hd�\c/,*]�O1ht��([L�N���Q�1�PY����e�T��Evl��)j�]�{�L ��=_˄��	RcC3���j�{M�ڇ��ӏO/ש�_׷�����/��j"C���j�����R��f��Rm��D�������pQշR�Wu�*�~�\��Jx�7pU��d���	��1e+��F�o������Kε�+�T���M�O�ւ��-^U�<�+}�C~���L��~{��o?^}/�ڷ�hi��������3#e�^�}T�.��,D�P����J��A�[_�?�a�D~�ӪA=��B��؈�O;�7h��վ�E��Js��	^W�:����R�������8O�jB�����/[�E�x�a�P]g��P�nN�tzvwsy�΄��b��N���'��I��f����E�����(����e�!��.�޺*p�U�[	u"��	��ӵ��jW���Z�
~�bU���^�*8\�U�|w�xz�jA��nY؄�[�WR��H�j Y�g�SxA����rθo)��̞Z.�_���G����cv�!������
���{8��Ku��ܚn��7�ƞ3���;O[�떵S�֮|��_�^��t׭^z��6w̫.{��G^�ε0�j��V��$�{����^m�!ËT�o�E�;����7i/-����ިp����:��ѾU/�[�����-j�,|\s���oR�{gj'���._b��rǧX�A����8"�j�]��i82�։�C���$B���ҪY>ۺ�yN��1BF�Z1�Cd�9Fe1C�����V���0}�
:��a�rgV�Վ���ap9���h�,�ۅ#J��!������t�m��nT�s���gQ(H�����UǯȆ�QQ5>_�B��݅qlM|��
�9��ˎ=��N7�Q���%��7�[�Yw�Vp�1�����=F��f�`hTo�����!�?
��ӵsT\�Ǭ���A���54��6r��|6��-����s�J�TL�lo�����#��q&^1����vl-`]yf1�ӭ�Bi�v7҆��yjhg��?ݚY�XіK�v���yb��]L��o��V>���O��Z6>�V�#U�3�� ��I�0���9;��|�ټ�a�1�=p��p6o�l�J���1�)�c�-[�	��>��xu�����qv��I?}�p�^�ྙ�������K20\e~m��ఢ����Z���վ��kP�xa?��H.��F����j>D-%��7;]���΃Қ+�ax�?llWI�0l��6�N>��j�&���ji��֗ٵ��$��ZF���Ʋ����P�K��0.VL��Z�֕�>�J/Y��0�.VO�%������j�	۪����m��&�a�/�h���Sΐ��B��awNG�����+mҠ�]��ۚ�V�� �?���KI��ق�7���<.�-�_w��=>��3N�Q��4�a�����4��ϟ}����)#��,��S�g��|� 6�P_���@3`�I�4�NZiM���O��I'��ec���H��C�6�H�g�H`mks��5 �	n_2N�:s��`"��|��I Z ^pǤ��I�*�6>�v)�2˟����(�n��"E�:#�񍰺18��HH��BH�����R��j���:&2Th��ƖK��4Ek�>&!2|�Mk����b`d� χ�ި%��F�Bg�g�8�d�3"i%���ӓ?I��c�l�_V&�h��i�kV�A�<+n�@X�Û,Ux����3�yft�76Y^�����,�Ў�`&E�rd�8� �sc��h���N���t��g���WX�A7�<-:C�醵��A�<ϋ�[���x�Y�X>`y�7H��./���3&~�yn��6{UXG�����f>14ϰ���_.�w�t���o����O�����TW?��о�FJ�7?��N'���B��7���x�����4y�mg�L82�8�L�gB�4O8_�I��$�u���'��Q�PYPy�
&��j�t�H�Bz�h	�]�	��� ��B��B�}��E���!�����>k�I�Dl�!4$�,5�k�I�Dl�a��t�Ht@��O�Z�vZ: %g�P_N�P$Z`���ۅ��I#�k��6���F�H�W�
���I'�<or˝h�����P��Q&�y�ȿ|�U��<{n�Bp�3�*nE�x>d���e�?��A�    зY����dɷ���[L.�,*��_�=K ��JG�dM�f������E����y/O"�|�AA&�@)c�
~�򛴛̳�)h�w�f'+x���o�o2Ϧ�X��'�\
#���m;46�sW(�8����e¦C�I�e�.n�1�:s3��x]%�:H�i��_Z��*aԭrp��?fn.b3�]%�$��l�h���]%�:H"�n�8�����Vd�R6V[5R�1J��,هs01�J�u�,��8��
l��U®�$N�Fߚ�a'���?�w�s֙8E%�U��+�:Y��ԁF�4�JXv�^��-�u���p��&����A��.nP:I��H�2�+�X�duP�oQ��A-̝�2��~39�A-�Q�;�_�n5x�ݘGcw:�c�2y�D>��$�h�Er��ތ��C�ܢ���U���0���������h�m4�BJ��<[��@�&�G�,$rs�y�\��^X:ҵ�"M�Fi�v�m��6�|\ZUr�"m;��$?i�4(���N�|R�I�� ��R5^S�#ZJo�
O�#�;��(�I�0��#�5�;m��z֙����9WY�<�����g�_a���~ �Y��F�QU![*⎉������ƓNf3���}��Q5�LQ5��8E_�DQ�4�C�j2��$�r4ē����M�8�7�1A�F)nd���V�9eKV�\�N�5Jy�K#o���z��\���4����K5���4���X_����\����4N�ֺ���I���a��'�j2:d�8��x�R�v��_m�|=i��^P�8\x2j,���7W��	�z4���[�XWt���[���s'�&F�ְ��@ÆEN4�Gr��|#�[Fުb p&׉1�L*�&
��Z��&&� �Mt�Fa�"*ȥdZ�B�$����m�U�J��NsTd1�ے0��d~�D�li�8Ȋ���363P&��&�d� M�`��D��8�L��փ=kUı��5�#P��%���P�<w�9�Ɠ�u�.�!M�[,H�FG�4J��L��'=�r�d�4�^^�9M���9�j<sh$r7\���#m<)Zs0J'��Z�Ŭ�Պ�oU��v��A�D���}EP���P���fi|� �D��!K���ȘD&E�bm2����EW���u�F�,MY�']��(ؚ�B�t����()��7�͋2w�n�,;A�"���B���@����U�fi��YK�\!usn"L����fYc���^�4(<ltc"�`d
��^{_�n#�<)]�Q��nd+�rF�P�S�'4�̓��9��I�!�gjNK���9>������p�Gq�w��)�S`��f���O�X�(��3��s۷f~�������C�t.��O�J�W�~���PqIsY�q�K�'����!_E������N�U����\hY4]7%�)�I��D��h�xCۼV�r9K� �嬑�P���Sd�?Y���G*�,�,��`e��	Ս�k�	�	�Y�Y��cȍ5A?�/x,��0�%�e�4�AeX�%�e��� LZ�\휀�-��s�<�]�r�e�8l�*֜�F��Y��%����!��pQM@V��G��Y��:4����z+޾���+�0wMr�z�{����P6(E	$�4>��F�#�Ji�Ҟ�T��%�%�C��X�� )^�ݲU���,#./�H;����D�ⴿrn]+(^��� ������w��G�t�4�Γ��n	�8�lcm��d	�8�y���'2�n�*� MW�X��>�9Ot�Vqh7Ҷ� ^�/X�s�e�Jx�Z�J�5Zu��}��y�$2]&���T˶�j����9ٵ'��h$�Kl�޲p�"�<)^�p�E�1�/�/6�\�xm���o��0B��.q�7�x-��HTK�<�zb��}�^�{��
%Sx�����j	�A'�Q�V����n�*�Wx�`�L�F�p��'�+�2�C6jkm��ł��n�1�5�: ���bL!���I�D����j5�䎔�!�њb��H=O�W$�e�8d6ˊŚ��I�D�q$��X����璬+�.=N�(bs�(���p�y���DkѤ�Y�! r�e�4����R��������02O��i��@��l�vxd�h�؝�����o�_ĭ�����w�o����/L5oߪܥ��Gs��T�y�o�y�"���Ƴ���z�zK&�,�ӏҼQ~�^����4o�d�A�Ik�C�\IÔ�,���y�\�I�2��o�XмQ��^�K�A��:�u��b��'�e_�����jC��*+�p$O�j���I�Fi�=��;W�X��>i�({/m�Ɗ<.�������o�H=O�7J�ދC��.�I�(V�)����;*�\6��I���'ڡNm�.�[�%��A���N��E�@d.L��ʳ��j�U
��ʳ��Ͻ�ɂ�PyV� ��ɘ��b����&���ʳ����F��dAI�<+��X{k0n�F39Td)\��5ɤ$T�����׵B�E�TDndF��D�d�*O��Ҡ�C�R�w��"t��q�֨"���lIn�q���X�L*Bg8Y�����)�?��ӻϏ���ݞ����M=޳kU4��6�)�j��N������?�S'�ţ`���3�[��f:�V�+}���h����R��͔&+-�B��i�DW��}n�Z�|_ٴ�YN��(#���P���\�".;<Bt�-�!�<}�������N?��o߿}��=�Q<_���ot���[��<_�78_�wQ�$�`+9��ꏯ�_�{�9��斿;z������-�Q�U�� Ԅ�n�}T���r�D���(�m��������٧k����ӕ����kU���S/߈�4w�X�C����F�j�&{�Hr���77�;���-��ZTg� �`F�U&����j�D�5�V����z�}T�587��	c'�-�����/������x���Y�ۧ��������n��/I������O��7��OV����������o��nb��/o�nN��1����V!,��Ӈ�ow����o��P���l����������������.?c�s*�$#d�_��z��)^dHІ��&B�0Jo��n�����9Cf�U��	���j�M&�at����Ii4��	�x�(�;@C�2�&w<��-.�=Ca�%6����~w�O_Nُ3��}�t���}�ȗ�od�a�|�=�l}6@�%�iB��'R�$�-���Z�\��xv��������y{W����,ߨ���3Ì��]�o�jث"�*y�Hj� b������q^�b�Q���4d�4Vm���-�z�C;ȇzh�X�����{���>$��P������(�=E��r-�Q��5.L�TK ���S�:���c�4>��`�$�q���N�-.�IL� �%Ԛ[٣ȱ�VI]z/Em���M�� �V�6fA�	֖�+�=��T�|��"�6�X6��)������yB�޴JcɽcR3�u� ����y>v�5�BC+�
+o��'�`�lLV�h��q��l��7H��y�3R �n�y2��r��MܸT�����X�lҞ�/Z��|�^��&Me�\�AIΪ%�1M'KEs#u6i*�'�-k��|1h*��c%���m.��6�(���+�I7�;To�S���̬AQ��C�H}L���x�0�>.��Q1ɢY�=a��q��+�K�zs�1��0�?����Ѣ�����./ދ�O��<{������P|����/��KR�U�b�ߐ+��R.�(���%Y!v9l ��/���?��y�����������j�׎��/?��sg��,�}TA�.V�bL*u(X�6�hk��/� �=?�ӿT�%ccqE�0|Q�~���t�*|�=��%���6x`�{����_�ӫd��i�ʲM�O�σ�m�`T���]����!�������������å~wVĴ��ni�vLi��_����s�P�!�bSM�h�¨\@�����齼��>ݲ����͗�2�}�vK�7s�0w{t����7@F��-NaN�%����ZNv���py{��    �eR~�ee�ge\ѐ�����)q���u�<���������Ax����׮ɧ��ߗ���k����5�ݺ&p�}�Hv�Վ<���5	[�zM�W���B�:���%݉&����Z�_�͇��?]|8}�AHq��{ǊO]��(��5�0w���F��hx�>�$��ic4��k78�����/�o�����M���Iy�4�{����Og��׏w�v:	�u��a�����Z�7����ZzCI���<�������cim��D�s�9X�C9r�t����i�7�R�mi�C:.=�̬Y�R�l�o���]]%q����5,݁�[�te�7��L�GH�/���/�.�^��Z��/ܴt�#��G��;ɡ:[�έ[�L��g��+����\�x�p���)P�ry��m��;޴t��j)f���-]�Z�Դh3���-ZΊk#�`��^�2'̠����崭�q���]�^ܟ~o���+�����m����#5'X=P6T�����x�'��-q̝v�c�:$s�	�p��d����Zg;ǹ{N�6��Dd~���%"#����'��R
]����W����.������\\?|���>���Q��x�t�;�ۃ������r�*���ḑ��2��M]������K)��Y^���w�������͗}���;5���;���aTe�X���T�ˋ�1Ȗ����o�����~�������t�����w�_����ԩ`���	ǃ���������s��n�a�s?�����y-\�pݯ=Z���qq�xzss��7w��/�S*g��sN/�|� ��K�d���3[r ͭ���=uH�����Z2@ܝ0��h���ȴz��}�w����Q����t����6BUж��-_LdZ������;��;�y��ZTg��>��Q�'��et{���eGT��%3�֩���`�����
�z���AgT��[���K�����:�%���݉b;�,��F��;��jdђ!�jD�o���3�J$<*KS��-�#X�j�w�Q��Δ�/��o���3�d���+�ִt��^{K�,m��s�2z|�.�5�Gq$��m}��*N�s&��Ff�5�w7�}���{n���R�ʓ}�=����QU(^ �e����7��U���Y�k��� ՐO�RT�F�c��ܹ�_dX���箼ԕ�>�o�*�����+�@H�{�w��1;���KR����7@���r9�J��Grf���jP��Y�U���j��w�� T8����x����w��;j�s���ֈ���7��74G��G*@�W�o�V�z�~�4w�8)�jT���;E\�B�&h�ڛ����9�]
�T�-}Ta<����
~'Q���!9����*Z�.q�[���o�P:�
@�.	�Q�B���޼cG�wNs7V�z`�P��)b�
ީA��_Y�c�C:��NW^x�� T8V�}"�u'sHȀc�ݱr��9VK�~�ϝI�j���'�n�a��=�� .u[|����K/�R�|�L�v�":�3W\3�4nq�,#̆3۹f��?w�{�{�;����-2�{N�aϏU}"�U�ms�x���0�P>���N��p[���g�ɚ��f�{=9 ��M�FG�� Ux���K�"�dN
�}���uB��&���բ:��P�z؁e@բE9<�;L���B���Lףz�P��x�H&�:y�J��Z�Q=^71 4����ξ�pe�(N
�|vZ����ը���P�;YX��84�7@n�a[��aH4dZ2#Z_�B�V|nvq���]=���>^���(�x�xpt`0->8��<��I�
	���H%�~�������g3�6� T(f$�v�/A(�p�b�By/L�"B���Q!�8�FhE��H�
�}� ��9��<�8��=�.
��i���.�/o?\޾�644z{��P����|�x����;�yw�B!��!�!h|�_�&�J5Ě��� �x��]�א5E�^"�x��������ٽ���Ci�+l�\%9*P2l�ʗ/�_O?��鯧�O/�&�:8��*1���"��g����3�˘�g�d�˔�PeRJ� �ן��=H}�c��0u2�J,�͠���e
k�@{q_�!j��Ub�oE-��A-���-�E���$�
�!�*��7���Ti6��Q�v{-����Zߌ�Y�ZZS5��~��˽�T'�f��J��گ9����[��U'6�f��+��5v��}s^�6Љ��6�:'Ծ�F�	��ߦ�B:1�7��W���@�C����f���x�a��sF�K�շ�QA��9`k�A��#��M}�;.�N��$Ac��
��Ӷp�3�]��I�M����։� C�w���BTk��hqM]�!��BY�����s!f�X�[gb*g2�T�0��ˬ���f4���q6! [3�����/L��#�����9��޺:�r>c\��D���ILӭsq�s9�0�8R�8+�@&����W��0`�¬���`��ĲCB�N��������������]~|����ÏO_�?})�Ar�������Z#�]Imx���7��4'���nQ�s�Guq��_��獲����_>ĳǧc�#��`
�ӭd�������w���ɍ���$v��$����S�5S��NoO���_Wc���I�$6����<�.�O/]+�.<���M�/��<�M�O��a��!s��7�a�����-ʃL�ٷ)�U����P�Y����,:*�М8w���RM>�lU��7wG����"�����)��1fP���7�6�Lg�|=�yi��t78c�^{U0�� Ib�e�~����%�A����[UUo�q���*�+��[5,��M,������𶭪���;�p�?��j #���E�����������+v�Hd��lb5XXRY+�>�h(���^�c�!,ib28�o�iMS��j�t�L~���.�Z�AՍ�Q����L�g��oC�X��}���~9f���7�o��U��7̝[UN.��bA.6:t���SQ|1_c5�}�����܍5�>_c�PE��v�Jx��M��"���˳�����4�u��Ļ��!����FCԤ�W2De��Ο'����hΆ��?,�	'$�uF0�>���5��"zHjsN���������o�;3VVU(L��AE`�Ŷ��'L��6�x������O���z���}����ߔ�VD�ojei�v�s��KW���7@�Q�:��'��4�P$���K�,w2�Y�O�}��u~�>~�yz���������Z\�o߯ߗV[�M�,߸��ܭ��W��E��j\�:��b7��X���վ)��Qs'G��������(�g1�:��J�Esw5�}S>���n�ⶒ��o�*"9���
�c\J�X���p��Q߼{����(�=>�a_�]վ)�����0wT85LW^�D� U�鼈P���^4�I߫Q��|b�U{u��0��W����
���U�_9I��"�F���bT�ܵ���M��`
+ګS����h�/\\�i� B��?��J��ZW;�����Q���Z��^,O�վA��;5�])E$Y���7@AobT4j�-a�������׏�#��N/n�Åx������J÷��0s�3����7����)�4G&�Z~�վ��T�v��u�i_�y7�����_�"�h����U�u���:L]0<�u��:!�حBc{4�Ъ�N�}������0��j��@%�J�ثAq�w�YU�����jQ=�˪z'�� U񷡲S��'�@�u�ԾNUP�������&�`�އ���i�w�i����О~����;y�;�?��_i���:IK� jT-U�O܋I��ͦj7U_�r�:��Pg���UU-U)�D"��O�W���Jv��.y6��T3�j�JT[$���V�w #����ȅ�P�AUk�C�Rm��Z��*w�#��$j�����Z�Ƴ�f��Փ���.O!�X�j@���+f��]��y��n�O.V#{���g�U�6P�b���e��H� �   = ?�Y!{�Տ�4r��F�2��6�q����y�&�n��S+՞�J�f�.S�U�bŵO~���8��1����c��_׀*�*h��G�Z�ܮ�M�qfe�ڳW�Ef�ZՀ*�*��*N�E>Eu����r�|-���t>�-����Iߗ��.U_�������]�(�x�m�5�
�
IQ���}䶹W���kV�T�=bT���P�Y�T[_W�YM�3�wS�5+�={Bvۺ�k@u�^_�i�k��      {      x��}Y�츎�w�*rύ�(�Ϯ�ڇ�y���)����Ţ�tN�''%�� 	��v�[���''�������?���7�J�!��� �"�%�c8y:Բ[Ue�WQ1�q1〬Q�Ã���b��?=-Fwn ʸ�q��3�G2/���<\Q��Ƀ���?��a≙Em��n��7l��֓`F�A�l�+6�牄#��-���C�m�����n��Wl�l=�c3��A�l�7l���C�A�l�WlD��)��u���[6����쉅`B�ܓ�Ȅ2	?{{�rO����I����F�� Y�v�ˊ��F7��0|௔�:�OO�m]��	�7u����%��zdٖq��_I	(/��#��&OP��n9�&��)O��75���χ��v���'�>ѱ� [	=�C���B����iƃ~C|�EQd���+w��-s.��?�>1q��uP��eW5cV�F���Q��+y`�(/�����O�=���+�	�%�>��G�f��d#�+6��O��otG�CG�OJ	����#��Q0�`��m�t�=}�	tO����ο�ЖCOp�َ��(�^���:wI�zQ�δmh� ̘͖ӊ����x����l�Ɂ�a����p�d}�d+��6���=���V0�aG6�A�l�l���8H!�~�p��39���
�qlt�F�)�\N,9�0���A�l�6x_��9��g#_�q,C
�Mu�=���H�\N'"���g3�)�0�짃�\ݳk�Tx�O�8��A2�&,P6nqM2A;o���*"����E�뾒�@������I9}��1����ݳ���?��;�?�=���	�mr�d�J�5�`�o1�����e�	�2~ڜc$tаuaͩ�E�CW�4/����|�/-��E��Fx�V?�3	�,/�&�I�,��o�B�x
$�a� ���!��b����'�_Bt�@�da��{B�!#2�a�ƶ���_�Y�Z?�ec*t�=����g°��̹C���~�;:�G*cLaa���	��x�Γ3d]>�*ݪ��cS��/q�?��!�A���;��M��!G���J{��;2�e�#n�t�0b(��9�77�Á�m��،ʖ[v�>�G�:h���O��/<���c�_p/NL��#wu	E�0tO��)6L�'��{���	��Q�;r�ž�r���P�Q�����l�тx�r(!�t\�\aȀQ��u����wl���[�� ާ��vi�KM���E��)����[��?2���K���~�#65����[6}�������ù���_�G�@ ��8rl����~��3���sCG�����Ė���Sx��%Xǁ�c�P��I��+�z���Wt�|_ ��a�{:�S6�b:螎Cǩ^*��UG��T���\�������/D��:|�/�etHa��	>ηw(�6��]��2��8o�"}X��Xԑ~1e��!^�"w|"[Z���[�,��$G�I<T��:�M�"�lX�W�BZ(�p0z+�|��x	p�[^<����O�!Gݳ�o�@�!|b�6�?@�nIC�-��nk�ļ�!�l�r�,����e�D�tU���b����z�!�1U&�WlA�!�;��!ڈg�2�k�����f��}Æe��؄[��g�_�Qp�OB�7�4��ue���O���F�l�7i}�Ɖ
6�ۈ����pZ=��5AL�*?ys%�R	){:�p,2�Y�E��1Z�uƹ�gZ���͞��Z� Ͷ�����,��ec6���q{�U�{C%Q&��R�oǅ�����\�n�V��nX�q�=lC%�M�ȃ�$D���¦�Ŗ�Q�xD��'��%z؆J����>)��yc;Bܭb�����VoM� X��a*�2I�>��?����4y|����n��x����r{؆J���a])�8�~�34vulS��<��Z�C�i�>lC%Q&���[K8��A���ԝ�&l(q��+�������(�\�[���;�e���}���@<�f�m�$`���i�3stPӤ|��\�pu�iLx��a�/ب\3�1C¾�� ����]:�yK���b�H!{؆Z"�V�[�6a�a��"w�lۨN�2Nq���2��m�%�I!w��%#T��#^���g��^ѭ���u~�r�%�B��E1�K��xX�Hk�w��1�eR��4j�c�!D֚6>M��Gk�os�ޒ=C-Q&Aa(��bG�z������-�)iq5���V������ʤx�a�8�g;An�xI�`:�[^7��[��1Ԓ�0(A�}`�ݳq��{7I�;�)���{6����$<���z�'��PKv��| n[�t�P��Y�"�2��o�&&�\Kl��Þ�F���Z'���ߊf���z�	��\K�Ip����w����F�ݱ*�&�y�R�/����tK��v�;A�Qߍ�H�!�m��l�tߨ	��̖�i�Z�)�����!ޚ��­fc��7r���������d\��[��Q�c�'ے3 3�L��]%��V6�AY�q�zq�h��.��u�r:c9�A�|�E�8�AS1R�����f�bT����t���P!(��<���7?s�jc,/�[
<"�]�wa�	j۔�)ͳ����[O��p�a���P���tL�c;��y.�]��/2o����	:�T,�&�=��8:h.�7&�E�T��NIN����-�p����@^2��>Ͻ<��5�ڦx~`l�&�ȡ 
�q����
��;�2����QŅ�3ViӒ���1��K�dh��\����.����<k�T�+ �:��ȼ�Q[�+�N͜��k��\O�Dpx8#�i�t�1�f��2�9��|�f:s=��aT�):�'WHCg�'�d�`pUA���H$��(���q�&�ܾn��\QTR�~�Q-�>Jʂ'ٔR��=�ڮ��*6W�=��~ڎC/k����(Dez�d[����"���T3Xحa��'���4�Q��<�w`.Sls���ƱGY7���8�8����
�����3��,�<��>i{��8��mY�4 :sU�2@�7F	|��;A�l[4��71����M�{=Tވ9��mb\P�Fw�6����$�P�G<G(��'��U�Jї�͜�;A�$�5�g���%I�:��&��b��&&w�,�؂�|Yy��k�Ou䢌�Q�r2���(�r.�]��Zw���4�C�{s�c��+p����8�H�s	X�w�PP�x,�1�1MJ�{<���PQ�M��b�_�:(�V�����l�ծ��dUt���l2"����8
�;�7y�*�Eq\���nՍ�>Le��d�$G������8�,ӵ�±Z��~N�D��t�L����6��0�`�x��x@}�v<g~=͍���QCEQ61h0ܘ��]�w����s-k��nH�|ֱ�I@Eٔ{�r�YcԲ�����F�8�$@ ��PQ�M*�-�-G�n[�d�ƌns���/*�3T�ݦ2���-����P�X��>XZSE�0��:j�(�M!C|F`=���=���X���,A��:h�M��ۺb�2�PMˇʱ3�#HeD�g#��*� �&��]oE�J}Vz~��\Zj�*/���(�7	u�V(�{A�9,zcU׮*f��۔f��	-T5CW�]�lU�/�+֙���T�e��a�!j� �u�}_-]5v�U���ytf��kS�e�d����j��D��tI]/brf�*/��L Sp-D�4v(��z�We"�Iљ����gj�mA �u��[b7���<�e������LUv��� ��	?�o|�������ٍ�� �y�vf�*�M�F�%��G���A?vu��:�V��}H�<��3Ӕ�$e�b�i���q���a���P55v#���\S�'����nk����PDUH���\X�b�ڤ���ʫ��BX��T�kY�$H�i��4T]D�w3W��ud
*������@���)_�<�2�(
7W�i���!�����ܠq�dM��^���I�    K'Y�jb�����@^��q�x0�-Q�Nn3�3�*
���-y��{����x1ӹ𶱟�x�H����PQv�*5V3A��r�q-RRm8���.�|�����*
�~+Q{�t8�� �B��_s6�k�ʉ�@g�(�M�F��b�O�W�^�-�nET�f�&7�eS���w ?��;�eC�#^��[C��aY�n	㆚��d2��8;Խ#��Q8	�0��|z��n�)�OA�%�/w�"�k��$����G}V��5�27e21���t*"��4%S�a�� ��2Ԕ���Բ�{���RNr�&��o)]�͍�f�@g�)Ҧ���bk����r�㰍X�4��Ϥ���5eNՅ�ߦ�	ҡl��+�IǬgEY�s�3�iSe������,-[y���Q�Ws���әk�%U�S1.�B�Z�-�k2gy�de��u�әk�%��j1�u�JB�d��4nb���74]��e�)���*����ղЄ�&e6���e���$u�i�k�%O�(L.���Z�p�x�'���:���s�w��UŒ�B2��/��2 �P���$J�qJ���t����Y	�i�)���*d@,�8Z���0��d������~��6L��mXD�SJ��e����$��Jx�dư0�l�+��)��
�C���ν��?�}��t���a��˦��Ƅ����X���uU��>��Rx�H�-:sU����W |�\m%S��d�	�����!8F�鲻MJ��dyb[eU����ԭK���Ӓɧ�FU�\h�7'Z(�YAx�MM��&]���ay?�0a�eSw�¦�U3OP�laC�5mH\�+�&�Q)��Ua*8?�Z�-�4������ɇ��*/����fw�\N�'���&�	bHޤ�*p�Y��r�\? C@@3�f	�W|�������AĐx��-
�9W�i�6+mu� �C�C��;�!�F��IJ�#�٪Di�Q��˦�Yx2�9��4t���c��'��C�w��y������OY�	-G*d�W����Ro���E�ts�,y��m��
�l�7�kS&Y�2Y?@]��|��zN��9�s�a⬴)�����8ޯ� i��r�_6�Z��������t��*L�&�;�F�ve�#CE�2c�Bv�î����7-k���5՟����sg���Z��ރ8��PXo[��l=L�0�HU�- ��0y�e��c��ہ��E<�(*��y��%u$5?�0{�eSyv�ttޡ�%��'�'I�7q��&�a��˦�^��ȶߞ���?�"m�i�ھ��<�h�u�М�V��>�oHR��:���%鳍M�n#�a��ˤ#�׈Lz� c8wE�+n�:Y���\3T�峪}Q��rGR� ��
c��>!5��e�)+:>�#�CZ�(����Zn�R�~ ��t�>�n�I���&�����8#��k��e�z�s�PQ���єCN<>@MxQ�ێM�@��f�@g�(��e�p��t'�/mEh�״}R5.ϱ7�1̠�6��a=)�� (jxUģWK�6[Jp��Sd�z���@�086XuE1O�XB Y�Ex��5��و�ҳ�Tw\@aO��;4�}����H�t��9,�rx��_���#ʭ��\ �����r3�c-��͔$�k�d�{�Zٲ� �����VH���F�*s�C��ܮ��.,�&�_L@g�)R5l9�-�TZ�=T�y�&��fEǆq��Uܕ�
�eS�|0r:(�^��hq��e�E�yQ �Y-�<B�0�8���w����s9,Y��k��#�� ����6���0c��A�ߣ���H���¯34eI� }�tr��)�r1?@�];�^�}�v���_�a:��g�)�<m$StP�e��%���8�;�,ɀ�PU��6'D�TP��e����t�\��޲�C�7y��(��~C�U�b��e�>@(�<lW���g�<BC���a�l[��	��p�Ԩ�ꥇu���%���Ue��J��0q}�'�������h����m�M#�3Te�V��Y�u����ր�K��h�q�r�(&6Ԕ�2�4X8:�j�֖�t���k���k(��)B�z���!�=n7�C��oQ�%%.�2�Ǭd�M ІY��M�>�C�u�0�M+���@�@T��1̢}����7�#v+�y� m��cQ4��og�E��i+� _�Q̒)�� 	�ڍ��Kq�%Йk�^WJ#6y�;B�ĸ%��e�R��ק��̍|�暢J$0�σNk�;�}��]PǓ�m;�E��f�a�nS�Dw�6�m&t�;E���x7{٘�Rĝ�0��eSex
����'�-��㼎Z�8s�u�����]|���O[�E�/���\S��R7l,�=�Z6�69��cݴc>6���9Z�ά<�n��b�B��.��6����(���%��At�h
S%W�m���e��{:j�QX��{�h!\�k�A�,��Q (tQ�>5�SlY�
F��L}����0r�Ƌ�in�~j�`��wSv��*ʓ�0���u�IS4��N�8��-̧��5E]ޖHX��۰�k&�Y��QVxe1�U+�L:�r;�#A-������4�(�"�7��2��]7̢}�TG�s���p��:�1n�қ
6C�$n��f��6�-v,�����x�[Q����(Kp�G��Y��&�uYt���:�/��f�;v)�F��}��p����O�6���bso�!���H�r���,��24A=��bw�j��d��*�XS�Muy	�	�A[�"Z�.v9�[]�6��C�3�Sv��P� y�vG���u��n���&&�i�nӑ�l����b�5|FEPT^��C>D�Y�{�	�&�!�PX��Tuue�V��Q���AL�hw�LU)�Z���	��a(�0뷼�D�Y��MKN.d~<�{�\5y�O5��[��������Q�x�u��P�a�麡�]=uu�a�@g�*�+��[�2[:�55|BӸ��K[��>�3W��qY�����y��q�6���e�'iU�lqG*'����5�*�9CX�әf��6�l�A)���J�(�p�TS��s;F�X9A|`�I��T��-BL%��/|?%Yޗ�uM�0L3iū���3�]����4�i,/�s/K�%�e��\UT��5�����q^z�S1��z9S��\Ul�ş6'�h�����b��b��AU\ی�5�B��&�;h�<�����[�m֝ �*��%q���-�}��yяi�ns������/w���O�0��,�f����m�/@�����_� ���e����9O��xe�R����nq�i&�^ E23�蠺�����lK�$x�P_�-�:�LZ�j�!k����e�'$L�f-h�-���|�LZeSz���,,�ZhN�������l0�Wޯ\.?���?��-�ҡ����!%u��&~��j���j�-c�Rr�c��-kN��mI.nq�! a����
l�KCl�]X�Ʈ̃�"ɖ�4¼�8���ʦ�"/da����Qw�׆qԦ)xҕ�Ȝ-�写���[�y%�|�ua�R�Q�O�7U�fE��[�%�ٞ�n��"0r�&��AA3mxcS&�F�8�m5Q�3;�y�$2+�S?�P�"o��:�d�C㎼L�Ê`��Oy�䪬&�p��j���u�f�uNܡ"2��`�I+m��[�'��eY:�o� O���|B�X���G�����d�숀���P���e�e�b��q��+D��l��e�Q�EǪ����f�֡�Ӽ
z�s��3�w���Ҧ�J'�����ޑ�������,J?�x�i	df���d�0˓3��W����e�E��$M]�ʻ�@g�)/�*� �P��X�Йxu�/E��[����5�VyǱ)�A,�\4uJ�MC͋<F3̣�6�W�'��_Bue���ز�������}Z�<ڗM�]ɩ����6��z���H;�%-�"p]X\�h_6�>��v���    �E�DU�=���K�b�G��)Tb,8� 5�4��$���a�pw	*x6�곻I,�?�M��P�$�4�U��9e�X��u��y)/��H�&�X_�4f�na�W^��>�z�w�Tw@g�'�M&l��������"�W6�d�*w�R�3WG].�6���v@&P��r�[�XT�Q�q� �Y��I�܈�g�9���4�����4&�B�	�n;�1i�'{W>�u�+� A,�Д-bfK0n~55�֟�m2$mȫf�:PNP?E@S���ҋ������=����:±�P.�ףy�n�$U���/�=ajW���������OY��}�Lx��"Xz�h_6�K>V�� ��0XUkx�	V�L^��r��0�v���G���P�z-*�8�����[���оL�4`
�]��	���]��d�㆕�����Xz�u�Z:�&A��0趘ґ���6X��h_6��6n��j;:(�ӑ%�<�#�)��|�fV���)ϋ�#ή�
�Ŕl,��e^��eM	x`�ehw��1���`4���E7o<=o�q����=x/��di",����u�$�x�P�E�\�~T�$w���.���ڦ���NP�"�����xM�l�U>�q܃U�vYE�F�}�����ȅ�u�T�ci;����}^6�<�H0���*
�d���6(�&��f�![B}A��_:�~:o/��e�}
���p��j��z.�3Vy��Ď58>@(����(ȼf���lI1zH�����i���@fF��|Z�(���'�C �Y���&W��	� knd�,\��˦.�ah�2W.�w��aXX�R ��]}XL���8��^ҜN�
t抢j'.�-���W6cK���ܗE�G�����"��#y�Y��c�+����_����Y6��K�01�R^��9?��� �M��nפ}RzM1������DQ�VUR�"�p�{�{�`\�*o��4-e�e��h(;^уe����D&i�n�|�1�C�������b
t&��k���.$���;Ak��m�1Hy�$����t&;)�6�q� d7eD��!
y�ђ-~q֥Et&��kS��%s�3�>BM�{�����*	���g�A��hm�M�'r0y�t$ n����f�Ѽ��OQ����h�n������[�#��}�3?�Ә���C�W]ЂZbM���"|p58rt�`"xe�/�0g~U�|�"9댲hm*���}~BF:Vk4�s���ĵ[�cd&>ʯIy��)�m��#�Q:��+)�I����ys�r�}H�:�`�Z��Z\E�Z��/��ż��c̓sE����j���7¼<������a��ċ��	U{%���G�fk�;���EX�x"9��f�?�kS.�Of��k< ��}ײ*	��!�C�N�x*s%�2�X� �/}�m'HCg�$De�#���p��jk�Oc��IJ�ȱr;�:��ɣ�7�#��6duL�Z�E=Tɒ�Q!5ʞ��I��|[%�#^㶪��7�#��@g�%ʦ�)Ξ6GY~G⼝'�C���ږ-�OC 3ԒݤP�^���z�!/IjZE�����l���
�b�%�&�����&���`�d���4c�6��V0*�2gw��i�������#�M�v�I��U�q�a�U�=�d*-�b��4t&�ΏMٛ�_[�Jw�j�
#Ly���o���^	�Q��M�p����>��S�T�Ɖ7�Y�U���+
�Y'�^�T�7�#�d�B~V)��nr�����c�3Wu]����>B���E�e^�XT� ���+��.Aeu ���G��d�8D�T�I�7�'�
�;1ʝ=��Ӷ������KZnu��xcź�}��HcM��jT1"���bpAZ��+�M[��8nq�Rk>��F���&m�<�1��yc��(+��V�w
d��5�?�c��M $��ZZ�]��m�Ώ�R�5)�bU���_����&�ZY��[2�^A�t���ω�@g��6Uz,��!Jc̲1��- 9�6� �ɾ�M���3��:h��!Y�0Ox�V�����B���ڔ��ԅc!t���C'T�RvH��i�L�z�M���G*��]���<KH5�j��W�8���<�7*���ʯ��A���8m�"]��oX�e(`-7ʜ=�\ؘ#�wHCg�Пp[��"�Y:�V^&�3ľ;p�(��5ʜ���*�L���<B�����Ń����� ���P�|Uˡ�qd�C:COEٔ�O���m��4t����6/���7�E���������P��Ǒ�U!�C�y^��J�,G/��=e��6�܁(�� �@<1�����eI:^�͸���0�0$=d�#����G��p�v�A]ҦY��m{�n�*?6��2b}���K��qj�l���-���K��䆞�n������/r�0'Z:CU�m��=��!X��Y��{]ioK^�Di�U��\�G�Lp��4t��ʏMS�r =��U��l+�"ص�p�1Ls�0�Q6eQHU�#�����es��8��L�ә���:l�9�\�ܓF?�I�����}����5E������&�|����5E�K��Q~}�g��\ST��Oc|�t'�L�+��j�	�X�"o�v��錧8V}(9,�6�����3��Xm����������3v��Ty{۲�Z��$���&S���}fi�{:c�A�䯓F�Ow����8v�B%)��#L���#ʦ̉��� L�/���nr�W�=��O���-�m<�e�jո�!����3v�u��Ek�{:�pDٔ+�� 0�Z��8��;˼NG`lk�{:sU��;�tp�~���3WوRf��L�����ә��*��ȓ#����ܓ�k�%w��Iv��@�g��\S,uk�<	|q�rg��\S�W�M�!���|�n��YmU�3L-tO�����CU�ҫ���{:sMT���� �����5E���bC�}�;C�t�"Tn��lrOf�(�$��}�*�Z��\Q~o"rf���;A�t�"ԵN�ʀY:��\Q��%3&�jX����E�YB�j;:䎌���5)�%x�Y�y�{����d���JpJ�w����d��2#����XOv�\.g�9;�o�=�������;���3V���8�,�l]���=���H�X��v,뼽���+��^q������g��XS�M�|�[ao/���}�)�k����;C�t�U��08Z!t�g��U�X&~	�|�;C�tߨ�,�O���בy���QY���{��y�;A�tߨ
W�]0�� ��{2CMᯊ��y��/���3��*��'%�>j���PS�M�3�������3ԔݦZ�-DNo�{:CMQ6)V%�e�+�	ʶb�m�%E�@�j�Q\,Ã����\-۶O��PSv�\�OC�r�3}�4t����TE�(�����j�nS�9���鎐��PS�M��e|c�+��P}�(������́#�!3�%»R>+�A}�%,/����l�J3/.���:�ӱ���-��(N�-;Zyq�9mB�y��S8%K�5U'ʐM��+?�[�Ce5��EvY�����U!��	�j(�"2�8�A�ݞF~���x��^y�> ����nK6Ŗ�B:c9!��
����e)�B:�#��2]�9�~��i��|v�j5#%����ˉL�P����9ǜ�wHCg,)`S��gOaL4���XRv�rjٖ�h���ȫl�G0|�a:(�ܶ�����[�S���b�Ѻ۴T�lb9ǣ�wHCgx��cSvbew>�����LsZ��^ ����)Q�j����9.�����^:"Zx���������qޟ�i����2�lp Ky����)�h�Mc��H1:cEڴT�p�(�A:sE�;O2L��t��ѐ��	U���)+���hUO�[-}���U4G�?���L3Zw��!�E�es��3��
-S�a��4t�^�������� ���B�r&�ئ��ܓ���&ٗS�]G�ѐ    ����Vɦ�O�E�����~3�l���Q
>4�=��ɏM
+�����%�@"��Ow�ҽC��v��ns0Ui�-�DG��!6�yg�M��{9F�]�w�5eA�.�ZI�]9F[/@g�(�M&�L؂X��A	��fk��aa�_&S��mt���l�����lr��P[�i�V����I0Vc��>:CE�m��t�����;�k�rT�M�&�$<�sWT.�*��)�H�)߾�	
�ț�,K�5�K]L.)¶��ը�M�r�j��5ޡ��.iK�7^�`�3�x�>�Q%�_�L��?��x���[���m�2��-u����e4Xf�qO`ޡ�i���eM���S�S�K��XU��D`<p��ק;AsN���4���������L�Yw���aKmq�'HC����M.��t��
h���QW�ek��q�;��el�}�XS�]g7��3��c�3����w�n���e����	�p���Й+���'����	QQqdmǳ`$��A�EU"ژLMdٴ�Li���DuY��.-.��;AY��1o��l^�z=�F5`m
'ʆ���AM�P�<�'K9���xܡ���z�j�;�)��u�� ����{3B�Ɨ���[�%bFF>5mS/AΚ�̽�}��~�Jt���0������B� �o\Vx_ءH��!����?���Ӷ�Bi�������Spf��!���(���P�2P.���\S�*�'5|V����j����T�>y�/�Ow�4t�Bd�Pay�o]�N���\S�>,ֈ���4t�>
�u�8zʭ'z�v'hb%뼼�ӄyd�3\�c���`�8�l�f˲���u"� �����Gؖ�'�t���\UTN����Bi��UE��2���`�!���P�yJe�$��ӝ ������#$鑀�?$Z��k�g��$U��e���_"������]������3T�ݦ�.00F�N���PU�Mf�l��� ��z*�M��,qBG������սN.Ϭ��=�����6���!� Ǎ�w��PS~L�p�(X-tOg�)�&U{6c��}���5�Q������TU^��6O۠���׉W%C\�@g�)�M��Y
��G��<�3J��[ک��0\P��4}v�)���4q��+�E:�uq�f|l�5��4y�Q�A�f$�uJ ��q]����9l�m	*�FQ��3T�ݦ%��9�������E07�0WyߔA�ڱ)��PQ�M*���o���w������kB����e��q:CE�m:j�Rr�D~�x'�܄�gu�zIV����ؔ%�1�L�m��(*��ªf�����5�Q�ˈڱ��c���bc^�S��v�Lv�Y��4Ԕ�&�+�,ty�v{����@9J��n�,kƂ<�i��nӒbܺA8�i����:�U�5��C�T�KsE�T����:��<��%ؒ�IW��w=��n�:�z�ʛ��>7x�ZoMP���-��)�#Ig�)�u��	��Y7�p�Ж�`z��8lD�.:sM��]���Iutnx����CǓ&�kV.�:��Y�u�D� ���.�x٦�*�l�9�6M�uT�DKF��Rgߐ����h���V/�ۤ��&�i����rϗ�� ���H��ɒ��E��A:cE�{��:��"W���3Viӑ�O��ip�4tƚ"7Md��'��C���3M�U6�TAh�(�����3֔}[Anxَõ���XSd�UMQG�!3ViR��@(%�7�#f���$�+�(���9����&��6��2A���:~�4t�B^� �@��� ����!ʞ�6�u���\S�3������]!����?�4��8���
e%a~��yY����Ga�tf����������a|�ְg^��"��6��ࢹJQ������6�1��o 7�:�L�8�x�c^��������6e�*��"}�����\�6`YF��[����/�ʏ���ۮ�#����C��n�<ڹ܊y��b�?��)T�#l��i��Te�	J%�%b-T�A�c<�CDQC�d�7#��Up�m2�ds�W�B�'ș�ANhZ'��b�ڗM�rBdn���Й����OM(��#��Smx��R6,�����0�sh_6mU��"��:|��)��&Z��D~�M.oz�3ˡ�mr&�`�#��Ax[��[�������˪(�gf%S^6U/"�X�}}�3T�a��E΋$�~��eS��a�˦����Ⱥj�	JF�r�9j�)�X�&΁�\ST�jD�2�p����m��%u�%,���R�3�T^6��{�Pj�-+˶�Ua�VFNX�&)7���/�Bn�2��ö�(���d��6�-ڦ]ӥ�=�a�˦-��b�9�~��8c=��i��i����Ж��5EU�T��&o��Ͱ搖GA��q�4�Q$��Y��ݦ�9fÒ���Йk�*���P۲����c�O^NQ:�e���̅�3�����e	�h!��K�9�1�QӲ�e��v�\S�+%��_?�Y��sk>�0�f�ǤɊ��qi�E���[k
�`�A1��?M��.tiH�o�=�a�n��>�Y��@9A]�-I[ԓ?�M�ZD��37�S�M��Țc:VҔ�Y¶"��e\v�>�a��&�{4�:t}�'(g��e�e�4�1k�2�n�aMؗM�lv�S.�RfE����	�s2�f]��,Z��%:�'%�i�y���E��j�4(#��yc�1�>�a�nSfÃw`#�]�NP���\�Y�X����]eXCM�m
�E�+a ��.�"⭱�U^���,��5am�F36=V� ��fѾl�ί�E�!%��uN����_7S��Q�Vx����`�}(w�+wlǲn Ǳ�'�u�F��y�g�:ƃ��Ut���ns�oa̱��z*ʦ,V�e�=G\�N��y=-���y���q�����=e��fx��7���3�T�M��y�3�cl�i�UE�T�mA���N���XU�M.7� �a�:2O���lO�eS��S�����(�RL.q�����3̥}�T{��q�__�	��F?X޳Q�9(��m���6(B?CΓ�m:��$nX�si_6�<qd'$[�荴���aN|X���B��Ҿl2Y�9�ZHCg�*2�X��9�ZDi��UEu����*agH����UEu�&���^&����?�M$�e��@��q��Es��MO�R��tƪBT�e,<!v���	�:cU�o���0G��fӾlr�O�`�h!�����%�%�s����!���Ȯxh�v)8g:HCg�*d��0#�� 2cM!{�8G���Wy�4tƚ�!%�^��t'HCg�)d�b�O&Q���{*����>�%:HCg�)��eP�@��Йk��ˊ���=���3̥�m�ccK�3�ׇ;"^J4y.k�p�nҸʆ���I��l`Y-��Bw�¸a&�nI�T�'ʵ�=���`ձђ���˝�{:�=�ݦj{A�c[��QD�0���s6Gy+:sM!r���LA���+��3��G�x�_��+��3��*�Fl|U��C^yô��X$,p�-�}�@g�)D��[��J��4t暢��!�a�:��2̤ſ}���,}a� �����c��\:�C4d抲�ʖ���(�A�BCg�({yT��bL� �����GU��p[i��E�+�yLa-��3WU"�;2��X��Й+
U���Y6�A:sE�w�Tf���|�4t�"_�^`�&D���Ҿl
�����:2O���PST�e��@�Ǒ�h�5e7)d`ʑ8�L� i�5EٔǎF���rt��0��e�HYf5���j�n��W!x�����3Ԕ�&�3Y�C��HCg�)䕱��� o��i�l�t����21�3��4t�wt�ʓ`L\������7m�-�ק>@:������1�;���FU�`�Ƒ}�'HCgx�L^U�a�;�cv��'�mNI����_��E��a��FU�<PzZ��O�#�o4�!u[�:�����FS��n+`,�)�	    ��}�)L����:^� i���J�#�,��ݢwHCg��6U� c�\��	��3ͥ%�d3��o��ѐ�{){�?YH�p�A4d�z�r�ds$K�� ����e*0e��������\O�:{��αC����\Q��Tv趏-}>@:sE�Itr��3��A:a���,�=�vGeE����q�6N&�ĳϻz:sE�Uk!��r렴ܢ�ͻ��UB���EUM��P[��tX5� ��vߡ��I0�IM��_�����2x:�<Z�S����=�� ��-�:����&$�CW�f��W���0�:HCg�)�W��6�+�
�a	/�d�|���^\��5E�T�����s�4tƚ���^���h��<C~/��Ne��
/��XSdgHK�"�':HCg�)�*��(�'���;@\B:c/E�$r�	Tֲ�%���b
�!Zq��}���XSv�*#S$t�OB�o#��u���.���3�u/Dz>H@ �t�4�_fcħ>.�<_I8d8��h_6e���S��;��3V��O��e��:HCg��۴�
JB�wyD���B����<� )�ҥ��2�F�2��� �u:��Џe���u�6B�����5E��l��BB\��	S���<Q�U��z���0�Ѿl�2�A.h��. G�ai����;�額wY�q�$.'9�\���1��FS��i#��
vB�ɾQ�
D�e�:P��=�a�M&��;2�V��Y�^���U+N���	�3򨮫,N�0�*�,1Çe�E��$r�rv���J�xEp\p��Y�e�V�o��;�S��^��Йk�r��V�������X������u.��@g�)��,3B���Йk�-�a�Lb�ܾҝ ���ت�,����9:�B:sMQIܲ�(�/v�v'HCg�*Ҡ�9$��o��i���GF��yZYL�n���oS��f^9��G��2͢�mJ�x:���4t��)j�Vo������ЙG?�ʡC�؆�C4dƚ"�JG�k!�����"#���y��
i�5Eڔ]�d�,fs���5�mfJ�l�X�l@g�){+y�Ω}�O�B:cMٳy���-Ki�5e/�L��9��4tƚ"m������tOg�CKTU"�d�K�A4dƊ"�T�S��3Viӑ{4���Yt�4t�BTF���Yׇ;"2sEQ�{��cJ�y��
i��e/,[t������ț2�ͭ��¤�s/-��\QT�`$�Ķ�x{�G(˖S�ӌ�E�F�.�0��n�AKT���*!�@��4t�B�=n!�7A��Й+
U}dā8ut�=�i�nSՇ������\S��=���tGHCg�)�����9o�\!���Pu���u��B:CU����?:�?#X&�h�EE�]�;�Dv�ᇚ�gHHHCg(*�Mu.��j�~�4t���^��`E��;��3��&U���wHCg(*�M��SS��-�0M��{�pP���e�@�����PS�Ok<�t���A:CMa��q�^�_?�	��jʏMy��N?�����&U�oˡ�w�4t�H
W[&�c%�3đ�(�H
߫�ZHCg()����ԅv��<Cr�ICg()?�ǹ#�6P[i�%��$ѧ��z,=��ә���W��Oc�h!����W����v�c�wHCg�)�MU��Zw�!���k�!E���}6�l���PS�My%^�ħS�wHC��R*v�B��L�*�y����s�Z�xZ��[�3���۔{�O�Q�P���c���i�8��2�\Ǥ�@g�*\����3��x}�
H,��ŏ�4��P�.ZG�3Vi�2,����A:cU�E���x����;��3VU�[y#������lu�����$fI�!/�|�3�H����9Ω\�;��3V��Tҋ��*��%q ���1V��QQ�� (���Ze���>Μ�>��Cw�>	��s�B�Ȫ��9�Bx� YSBH�6���jB舙�~e��a1�/�v����E���V����h���1S�O(��lV��:������ʩϭ�%��5ż�Yg;d�BQS�1�^I&���%��5żC$�Ů>��%����Ek^���P��Ԕ%��5ż[�C`��1K!#*�y�T�;ه�"gK ���)!&��p�P�~n9,!���)�Uℵ΅�ZaBGԔSG_���S����]���')�׵|���R�h�����+/0�#j�}͚�hn�x	/!���)�5l�X��s(�\��on�0�};�EQ?�~::���WE�B��db ����Q�h�1�;�i��/3��J����v���>�]��I=QSl�g�@k��%��;T昱և�
�Ǡ�۳?v��*�����ϛ@'i�}�ΆT+���SU�P�R߮�l�Ӻ�M�����*�U%��P�Z�>m#��fd�Ӹk�F��Uug�7����yǄO��?]m�뚃�V��o������l�"Й�`�f��Vfm�R<���림���n�:\�@Gtd�Q�u>f��#K�#�GƘA��#,vA�Țϳ�'�KZ���w:jm�9��j�7�~���!tdM��DD�/,��+B舙�3&?B�[K`BG�TB�x�-�M/JB�;*sL�4p4�B!���?����/O�T�BG�����|��OJ:wl��Q��������~��~��s���Б5��f�a=|R�?BG쥍1��t�|�:��w:j/m�)��Lx�-�B�s�1&�皕��8�Am�ޞ��q��|,�e����|���*2�����<��YBq.�S�Ux|�4�̡M_�}[�ծ:^�f�w�T�)�І��cj��\yc���:r�cK�&%Ⱦs�:���x�8!9e9!ttU�Q�LX�2��ZB]UtT*�R\	�B]UtL��S�9
}��tU��n�!I��B��J����(����sӈZ�)��?�Ӂ�\��1�%��Fa�(���u��Y]���񩺖U*��s�v.ўg��A�i]�e۟��}}*�sx6m]���\������,��O��������\�r��7���>�wU��;�C���!�B�\n��R���{���AW
�qW%����r�>G��BG�N�c�.��tW%�:������p���{�3��z�7룸n7=��)ԁ=/�#��+�h��o�(b�����Tln�C۵[>�װT�ݴsLF�x��\/��AL=�zY���u��AUq�'���n��P��oJ9��0L�gw=^�}|n�?8Џ~���Jy�9� d�=��-�cֺ��%P5
-�~ڏ�v�G1Lǝ>\�@G�T|�3��rʡPY�����.A4���d�ft�L%�4hp_z���X��e{\�B�JOeɂ@;z�⣩n���BFާ!ul*��&��KHU��չ��;)D�~����9�>-�t�Kc��;�A��z��yF
�Ġ�t�^Z�2��A�H<M�BG�R f�"��$�LK�#�>�q���L(�!t�,e� �T��=!t�,e�U�tx�,�!����@+���B�(�� ����@L��2�%E9�Бk�9f�s�Z�BG�xۯb���6�Rr�#�>����!�Jw2s�+��6�Ƙ���WR�l�6�:����c%�#�[���B��w�_H�v�БwT���0`�X�f���Q���U%6k�3�*�����EUtܮ9�f��L ������b5��1�A2b��^���TedΖ@QS�^���?=�BG�T��4_��г�0�;��ֽ)�w��C�K�#j��V�h�t�BGԔSXM��k�@1Sq�7���Mb���:���W��vZi��%BG���5�r��N�i�P=t�8ܮ���5��8^����@�����s�M��9�B�~Q=����be&BGܥ�c�{�+?s�%����*��N���A�:].|��>4�ie[=�z�9j7���T�z�ŠGw�֡&��Q��Jl��9T�@GW�������YB]U )[c��:b��)�W�$#[K�ɏű�粻6}'ʮ�4�!����*�]��#B� �  ��%BGW�x�.�`Jo<� dtM�/�� ���%�:���8�jW�v�`BGה��Ӭ��[|���i�l��<�����߷���?G��}���t�g��NG���1�d�sּT��L ���G;�4�7Ęd"m	!t�7?sLŷ�9�A�/�"<��Q�c�@q�6Ɣ1/�ܙŗ�@q�v�9>;�M~�'BG�S�c:�~Bf�
!t����{lA��o�B�~Q���q�Q%�-!��UQj�����O��N�~Q�r��u����}B�/�ʼ�����]�� d��)0�i,,��W�	!t��CV�)
��v�Б�א����r����ux��T5}Y�˦�wl������Ƙ*��Tim�CYSx,q��F�t�#���������,      |   9   x�3�-.M,���4���2��/H-�@|cNǔ�̼�⒢Ĕ�"Nc�`� ��      }   �  x����n�0���S�bH�?K���[�͎�h��*���q�bO?:rR�i�2�?򣄽o��O����vӥ������i|L�k���
g���1��/B*�C݇�O�a�Ch< C�db����I�,�*Uiz4t�����BA����s�u̯� ��k?�!�PU�g�\����1�*�"�X������S�(�1�=bƜX����ۓ��G�Έ�'��=w�@(�����W��Z���Ε S��<T�Ii*X�$.f��@��:iJex%��'zO�ݡXM�f|�	Ϙ��VR�y?.�a�I���h�b~��CE����BșN�d�@t�9!Jn�e3o�uh�>���l��%�Np��T(�}��ː^"�5���KhcB��v)�Ws@�n`CK����Ɍ�����留��f�p�g���on������w70-C��ڈѪ�*��?���%̥X�}�z�>'S�7���b�	[0r      �      x������ � �      �      x������ � �      ~   E   x�U˻	�0�x����܋cW���8���$��N�`���F$��Ǥ�܉��������^/_��-V��      �   "   x�3���/�M��2�,(���O�������� n~�     