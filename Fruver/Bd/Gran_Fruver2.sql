PGDMP                         x            Gran_Fruver_Def    11.5    12.0 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
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
                postgres    false            �            1255    28153    notificar()    FUNCTION     �  CREATE FUNCTION producto.notificar() RETURNS SETOF void
    LANGUAGE plpgsql
    AS $$

DECLARE _lotes REFCURSOR;
		_row_lotes RECORD;
		_usuarios REFCURSOR;
		_row_usuarios RECORD;
		BEGIN
			OPEN _lotes for select * from producto.detalle_lote where cantidad = 0 ;
			
			LOOP
				FETCH _lotes into _row_lotes;
				exit when not found;
				OPEN _usuarios for select * from usuario.usuario where rol_id = 2 or rol_id = 3;
				LOOP
						FETCH _usuarios into _row_usuarios;
						exit when not found;	
							INSERT INTO producto.notificaciones (descripcion,usuario_id,lote_id,estado) VALUES ('Producto agotado',_row_usuarios.id,_row_lotes.id,true);
				end loop;
				close _usuarios;
			RAISE NOTICE 'HOLA';
			END LOOP;
			close _lotes;
			
		END;
		
$$;
 $   DROP FUNCTION producto.notificar();
       producto          postgres    false    9            �            1255    27916    f_log_auditoria()    FUNCTION     �  CREATE FUNCTION seguridad.f_log_auditoria() RETURNS trigger
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
    	   seguridad          postgres    false    7            �            1259    27940    detalle_lote    TABLE     �   CREATE TABLE producto.detalle_lote (
    id integer NOT NULL,
    cantidad integer NOT NULL,
    precio integer NOT NULL,
    producto_id integer NOT NULL,
    fecha_ingreso date NOT NULL,
    fecha_vencimiento date NOT NULL,
    nombre_lote text
);
 "   DROP TABLE producto.detalle_lote;
       producto            postgres    false    9            �            1255    28082 q   field_audit(producto.detalle_lote, producto.detalle_lote, character varying, text, character varying, text, text)    FUNCTION     k  CREATE FUNCTION seguridad.field_audit(_data_new producto.detalle_lote, _data_old producto.detalle_lote, _accion character varying, _session text, _user_db character varying, _table_pk text, _init text) RETURNS text
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
    	   seguridad          postgres    false    203    7    203            �            1259    27918    producto    TABLE     �   CREATE TABLE producto.producto (
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
    	   seguridad          postgres    false    7    200    200            �            1259    27925    autenticacion    TABLE     �   CREATE TABLE seguridad.autenticacion (
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
    	   seguridad          postgres    false    7    201    201            �            1259    27979    rol    TABLE     �   CREATE TABLE usuario.rol (
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
    	   seguridad          postgres    false    212    7    212            �            1259    27932    usuario    TABLE     �  CREATE TABLE usuario.usuario (
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
    	   seguridad          postgres    false    7    202    202            �            1259    27943    detalle_lote_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.detalle_lote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE producto.detalle_lote_id_seq;
       producto          postgres    false    9    203            �           0    0    detalle_lote_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE producto.detalle_lote_id_seq OWNED BY producto.detalle_lote.id;
          producto          postgres    false    204            �            1259    28127    notificaciones    TABLE     �   CREATE TABLE producto.notificaciones (
    id integer NOT NULL,
    descripcion text,
    usuario_id integer,
    lote_id integer,
    estado boolean
);
 $   DROP TABLE producto.notificaciones;
       producto            postgres    false    9            �            1259    28125    notificaciones_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.notificaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE producto.notificaciones_id_seq;
       producto          postgres    false    9    228            �           0    0    notificaciones_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE producto.notificaciones_id_seq OWNED BY producto.notificaciones.id;
          producto          postgres    false    227            �            1259    27953    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE producto.producto_id_seq;
       producto          postgres    false    9    200            �           0    0    producto_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE producto.producto_id_seq OWNED BY producto.producto.id;
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
       usuario          postgres    false    11    212            �           0    0 
   rol_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE usuario.rol_id_seq OWNED BY usuario.rol.id;
          usuario          postgres    false    213            �            1259    27987    usuario_id_seq    SEQUENCE     �   CREATE SEQUENCE usuario.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE usuario.usuario_id_seq;
       usuario          postgres    false    202    11            �           0    0    usuario_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE usuario.usuario_id_seq OWNED BY usuario.usuario.id;
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
       venta          postgres    false    6    217            �           0    0    detalle_factura_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE venta.detalle_factura_id_seq OWNED BY venta.detalle_factura.id;
          venta          postgres    false    218            �            1259    27999    detalle_promocion    TABLE     �   CREATE TABLE venta.detalle_promocion (
    id integer NOT NULL,
    precio integer NOT NULL,
    cantidad integer NOT NULL,
    promocion_id integer NOT NULL,
    detalle_lote_id integer NOT NULL
);
 $   DROP TABLE venta.detalle_promocion;
       venta            postgres    false    6            �            1259    28002    detalle_promocion_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.detalle_promocion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE venta.detalle_promocion_id_seq;
       venta          postgres    false    219    6            �           0    0    detalle_promocion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE venta.detalle_promocion_id_seq OWNED BY venta.detalle_promocion.id;
          venta          postgres    false    220            �            1259    28004    factura    TABLE     �   CREATE TABLE venta.factura (
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
       venta          postgres    false    6    221            �           0    0    factura_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE venta.factura_id_seq OWNED BY venta.factura.id;
          venta          postgres    false    222            �            1259    28009    promociones    TABLE     �   CREATE TABLE venta.promociones (
    id integer NOT NULL,
    fecha_vencimiento timestamp without time zone NOT NULL,
    producto_id integer NOT NULL,
    tipo_venta_id integer NOT NULL
);
    DROP TABLE venta.promociones;
       venta            postgres    false    6            �            1259    28012    promociones_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.promociones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE venta.promociones_id_seq;
       venta          postgres    false    6    223            �           0    0    promociones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE venta.promociones_id_seq OWNED BY venta.promociones.id;
          venta          postgres    false    224            �            1259    28014 
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
       venta          postgres    false    6    225            �           0    0    tipo_venta_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE venta.tipo_venta_id_seq OWNED BY venta.tipo_venta.id;
          venta          postgres    false    226            �
           2604    28022    detalle_lote id    DEFAULT     v   ALTER TABLE ONLY producto.detalle_lote ALTER COLUMN id SET DEFAULT nextval('producto.detalle_lote_id_seq'::regclass);
 @   ALTER TABLE producto.detalle_lote ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    204    203            �
           2604    28130    notificaciones id    DEFAULT     z   ALTER TABLE ONLY producto.notificaciones ALTER COLUMN id SET DEFAULT nextval('producto.notificaciones_id_seq'::regclass);
 B   ALTER TABLE producto.notificaciones ALTER COLUMN id DROP DEFAULT;
       producto          postgres    false    228    227    228            �
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
           2604    28031    detalle_promocion id    DEFAULT     z   ALTER TABLE ONLY venta.detalle_promocion ALTER COLUMN id SET DEFAULT nextval('venta.detalle_promocion_id_seq'::regclass);
 B   ALTER TABLE venta.detalle_promocion ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    220    219            �
           2604    28032 
   factura id    DEFAULT     f   ALTER TABLE ONLY venta.factura ALTER COLUMN id SET DEFAULT nextval('venta.factura_id_seq'::regclass);
 8   ALTER TABLE venta.factura ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    222    221            �
           2604    28033    promociones id    DEFAULT     n   ALTER TABLE ONLY venta.promociones ALTER COLUMN id SET DEFAULT nextval('venta.promociones_id_seq'::regclass);
 <   ALTER TABLE venta.promociones ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    224    223            �
           2604    28034    tipo_venta id    DEFAULT     l   ALTER TABLE ONLY venta.tipo_venta ALTER COLUMN id SET DEFAULT nextval('venta.tipo_venta_id_seq'::regclass);
 ;   ALTER TABLE venta.tipo_venta ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    226    225            �          0    27940    detalle_lote 
   TABLE DATA           z   COPY producto.detalle_lote (id, cantidad, precio, producto_id, fecha_ingreso, fecha_vencimiento, nombre_lote) FROM stdin;
    producto          postgres    false    203   ��       �          0    28127    notificaciones 
   TABLE DATA           X   COPY producto.notificaciones (id, descripcion, usuario_id, lote_id, estado) FROM stdin;
    producto          postgres    false    228   �       �          0    27918    producto 
   TABLE DATA           H   COPY producto.producto (id, nombre, imagen, disponibilidad) FROM stdin;
    producto          postgres    false    200   ��       �          0    27955    recetas 
   TABLE DATA           A   COPY producto.recetas (id, descripcion, producto_id) FROM stdin;
    producto          postgres    false    206   ��       �          0    27965 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    209   �       �          0    27925    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    201   �0      �          0    27979    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    212   iD      �          0    27932    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    202   �D      �          0    27989    carro_compras 
   TABLE DATA           V   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    215   �E      �          0    27994    detalle_factura 
   TABLE DATA           =   COPY venta.detalle_factura (id, detalle_lote_id) FROM stdin;
    venta          postgres    false    217   �E      �          0    27999    detalle_promocion 
   TABLE DATA           _   COPY venta.detalle_promocion (id, precio, cantidad, promocion_id, detalle_lote_id) FROM stdin;
    venta          postgres    false    219   
F      �          0    28004    factura 
   TABLE DATA           h   COPY venta.factura (id, precio_total, fecha_compra, producto_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    221   'F      �          0    28009    promociones 
   TABLE DATA           W   COPY venta.promociones (id, fecha_vencimiento, producto_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    223   DF      �          0    28014 
   tipo_venta 
   TABLE DATA           /   COPY venta.tipo_venta (id, nombre) FROM stdin;
    venta          postgres    false    225   aF      �           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 19, true);
          producto          postgres    false    204            �           0    0    notificaciones_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('producto.notificaciones_id_seq', 71, true);
          producto          postgres    false    227            �           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 17, true);
          producto          postgres    false    205            �           0    0    recetas_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('producto.recetas_id_seq', 1, false);
          producto          postgres    false    207            �           0    0    auditoria_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 355, true);
       	   seguridad          postgres    false    208            �           0    0    autenticacion_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 178, true);
       	   seguridad          postgres    false    210            �           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    213            �           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 14, true);
          usuario          postgres    false    214            �           0    0    carro_compras_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('venta.carro_compras_id_seq', 1, false);
          venta          postgres    false    216            �           0    0    detalle_factura_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('venta.detalle_factura_id_seq', 1, false);
          venta          postgres    false    218            �           0    0    detalle_promocion_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('venta.detalle_promocion_id_seq', 1, false);
          venta          postgres    false    220            �           0    0    factura_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('venta.factura_id_seq', 1, false);
          venta          postgres    false    222            �           0    0    promociones_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('venta.promociones_id_seq', 1, false);
          venta          postgres    false    224            �           0    0    tipo_venta_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('venta.tipo_venta_id_seq', 2, true);
          venta          postgres    false    226            �
           2606    28036    detalle_lote detalle_lote_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY producto.detalle_lote
    ADD CONSTRAINT detalle_lote_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY producto.detalle_lote DROP CONSTRAINT detalle_lote_pkey;
       producto            postgres    false    203                       2606    28135 "   notificaciones notificaciones_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY producto.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY producto.notificaciones DROP CONSTRAINT notificaciones_pkey;
       producto            postgres    false    228            �
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
       usuario            postgres    false    202                       2606    28052     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    215                       2606    28054 $   detalle_factura detalle_factura_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY venta.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY venta.detalle_factura DROP CONSTRAINT detalle_factura_pkey;
       venta            postgres    false    217                       2606    28056 (   detalle_promocion detalle_promocion_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY venta.detalle_promocion
    ADD CONSTRAINT detalle_promocion_pkey PRIMARY KEY (id);
 Q   ALTER TABLE ONLY venta.detalle_promocion DROP CONSTRAINT detalle_promocion_pkey;
       venta            postgres    false    219                       2606    28058    factura factura_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY venta.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY venta.factura DROP CONSTRAINT factura_pkey;
       venta            postgres    false    221            	           2606    28060    promociones promociones_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY venta.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY venta.promociones DROP CONSTRAINT promociones_pkey;
       venta            postgres    false    223                       2606    28062    tipo_venta tipo_venta_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY venta.tipo_venta
    ADD CONSTRAINT tipo_venta_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY venta.tipo_venta DROP CONSTRAINT tipo_venta_pkey;
       venta            postgres    false    225                       2620    28063 %   detalle_lote tg_producto_detalle_lote    TRIGGER     �   CREATE TRIGGER tg_producto_detalle_lote AFTER INSERT OR DELETE OR UPDATE ON producto.detalle_lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_producto_detalle_lote ON producto.detalle_lote;
       producto          postgres    false    229    203                       2620    28065    producto tg_producto_producto    TRIGGER     �   CREATE TRIGGER tg_producto_producto AFTER INSERT OR DELETE OR UPDATE ON producto.producto FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_producto_producto ON producto.producto;
       producto          postgres    false    200    229                       2620    28066    recetas tg_producto_recetas    TRIGGER     �   CREATE TRIGGER tg_producto_recetas AFTER INSERT OR DELETE OR UPDATE ON producto.recetas FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_producto_recetas ON producto.recetas;
       producto          postgres    false    229    206                       2620    28067 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    229    201                       2620    28068    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    229    212                       2620    28069    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    229    202                       2620    28070 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    229    215                       2620    28071 (   detalle_factura tg_venta_detalle_factura    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_venta_detalle_factura ON venta.detalle_factura;
       venta          postgres    false    229    217                       2620    28072 ,   detalle_promocion tg_venta_detalle_promocion    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_promocion AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_promocion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_venta_detalle_promocion ON venta.detalle_promocion;
       venta          postgres    false    219    229                       2620    28073     detalle_factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_factura ON venta.detalle_factura;
       venta          postgres    false    229    217                       2620    28074    factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_venta_factura ON venta.factura;
       venta          postgres    false    229    221                       2620    28075     promociones tg_venta_promociones    TRIGGER     �   CREATE TRIGGER tg_venta_promociones AFTER INSERT OR DELETE OR UPDATE ON venta.promociones FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_promociones ON venta.promociones;
       venta          postgres    false    223    229                       2620    28076    tipo_venta tg_venta_tipo_venta    TRIGGER     �   CREATE TRIGGER tg_venta_tipo_venta AFTER INSERT OR DELETE OR UPDATE ON venta.tipo_venta FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_venta_tipo_venta ON venta.tipo_venta;
       venta          postgres    false    225    229            �   �   x�]��
�@D�ɿT2�nm��K��eQ�}��6r�7!%��@**��N�M�^��812Y"m�
Jܔz���S�B�K}�1���sy-7�S9�a$6����(��Ǎ���fK��ʲ��U�Î��υ4�      �   f   x�mб� F��n
'0ȡ[8������������<]�x,�W�)�VR6
$�
��$����Ѵ�
kZ)�Z3ŵf�m�&�v\���Zk��O���ʟa7      �   ^   x�34�t,*K�J䬋���MLO�K-������s�ppd���硪���ԙr:���e������tNM���AS+J����� V�6G      �      x������ � �      �      x��}َ�8�����H�s��}����z�5hL�y4���|�|�������1JrJQ
eVteު�!������hF�DП�?a���c�H���ǿ���_���Sx\���ʾ�wE9?�ŷ���v����o�Sz�����ϫ0OW�69�~���߆�2�y���?���>�����_��'4���72���_��_{���2i~%�o�w�c�{�v��:���&\�A��8$��2�;���:ޛ�<<6L	�_iQ,wۧw�W�7�â�쎉�;��o��1�c��/a�a�<W�r*��o�p���1�VÕ�E��f�,�[��)��b�̍3���]�z�~ַ6�ԅ8v#��B���Sz� ����o:�6���@J,��o��o����m�-�_'&{G�m��C� �2E
�N���0��70~��M�~{~����m\�~��e�M���}��y�?l}a�>�>T��fj��.� ׽V<?ҁ'�t�I��9օ�������e����Ğ�����E��4I�v��hvOy�v�R�0jbI�"/D#)�s+lb��p�3-�0�������N��56�c�+����S��,w��+�X��(N��@:MP�e��V�	��,JD�c�V������O�Z"R$�p�p�E��$�	Op�#	J$�>J4f"��
c���%H�?W��'Q��/T�&�Kֿ-�2݄H�"ɈH8щV�IRFiʔ�Q�NÔe>VG �Q�q$"L9|j�7�����)0��)k�h&cEJD%�`��4U��%�hDB�����8YJeL9�p1�r�u����L#����)���?�C���$m�4?�EEy (����s�������o:o��
�vm�N�����ǓY�I��Q�(�:�?�YD���	��L�8�1�0�YF!�*bY����F)�o�E!����BK<��@ �em�{�x���)Q�m�h�kB5��H���հ�Z�>1�$�!1���"DS�d����4�*RQFI,*��0<�Q�C�҄g�c��BG>M���	����i��h���z!�C�$:�MM�FSX��`�� ���km))0L#fT�Y�aޤ�`�	&Dc�s
+fe"�l)L�~
K�N�Gs
��W@���hv��p����L���V�j<��x�$_0����&��	'��Q�0�4���S��L"��I�1B1�`��3�a̘Ԓ��1;�В��!@����?��x�'�/�Ø(�"t��.T�\�)�0�~0!mt�H�S܁0!��dA\��;`��H(��0�7������	܁0Iح\������DP&JJΆh��:`�&Z�`�(���X�DH�E��$vX�8Q�̰�`3x�d;,�)���4 1`uhk��x�6ƣ���xbk<1l�w�!j����g'_��KT �@ҟm�&j����F.a�w���=� �b���ъ�����	a����!%b}�W��ty�q|W���|L��S�4���P��U[���o��u	���cRaX@4�J8QrD����Rp�+�`}����`s�*<d�� b�-J5��ś�J�3�X;�%y��|FԈ�t�E��"�U��� Bδ�t�x�S:JF��!]cT?�rʹ��`AE��ƽ�t~:.�0��J�1�qhB��`�.Nv9��m��uzC��i���^���I��
	x�Pn¸]�����a���P�)tq�_[�;K�E�[�tl���`R2Px���r�a�h�fk$3ʞ ��V	�7�HM(�Ҁ�����U�P��Rn��	^S��`ӟP���E'`�H��M5�(6�=�0!xb@�W��.�� m�T���eƅ�j�&T|u@�1ȕ eSހ6i��Mـ�,M�Pdb@�W�]�{[�m^�6i~|�3�-@)z!<tB&T}q@At�a�ք1_@�h~|S3�l@���bN��P��5�5��Tp�M���7=c�(xRT(5��TeL|qDAv,%�C�I~|�hƈ�4O��S��:���~毡 ��U/L����)��[q(��e3�l��|�w��i�tbW��~<���tIx� @Ɍٞ�#A�1ѻ)�xt>�8]�|�����V��.@'v�\��Z�N�Y�m� �t�l_���'L��J�>���}��g���z�o�~Ƿ.H'v�\�GCZ�.1����� e3��-�?!U֘�c�5rG�������]�W�j��4����&z�9�O�L��0i�_�g\�9������'&y�v�$&��|ɿ�Ry;SO���Ч+��D�H�����<�:����9uv��1��*)ʙ��N\
+o����5 O1s{L<�`�i���t�wg�[C�<��ŕ���@�����m��=\���#���F�}������Q3���a'��6�KL�����60\�9\�0���F{ݗ�rœ���y�JO�ݍ�Q�dZQJ��By��pK�ž˒�Y2�^�Nt�yo�&@� :�3��>���	���9�6�з�{�%��ܽ�壨�&�7����?�V�0-��7�}w��`��w-A�_תX�w�e���h�=RO�YC9yR\eA�@HJq�2l��q�?�6���%\g�"��.��V��s��b?R^e�Dc��)tҀ>����`��7�Li+��� 5�+��?U�"@AG�(�; �k�{�:�VH�JMN����ޠ�E#4�TT�8�DK,'�����?���
Pmn<Q����(i�X����!�P�I���qiAJ*��S5�*JZA�/�h-:�`��;i Q<��B�b��H��GUC!m�Y����+�{Ϫ:i R2�)�n�j���^.�qT������L)���BDs:�Y��U\qW`�0������������������g=�X+��r�a�����*��(ӽ)&Ѳ����q��E�1��Þ.R��uV��$��G��]��,��{-:��R ��l�pM�E��}BT��ִ��y(������h-:4S~P�e3�,D11������vEl��Fr��������3�m0�q�)�JHL�fW��+�Y���B�7I��3!,D�4Ą��#���B��a9d�'�v� �r&��(f�3�H��PD�<�/�h-:&�{mP �j&��ڜ�q+,h�-�+��e�|]H���sަD�h�6����/:U�y�=�XX�����8?���)ߓ�*_�p��ڨ����ɴ?����@�F3�����ʪ@��1�+i��[�� 5�'�*xΚl#���a�rSzo��B�Bs�$Ltq�����&~���!:���*��j���F�ca��U%m8�
��Y�{Fg�v<���yR�T�yX�x���N[5�)��!�3���FWX�+�F%:�\j?�զ��3ImD�U�&�0x/���Di$h���[J�g炑`� �MR-٘���`�c%��[�GC5n���րqln*pR��Qׁ�Z�j�����O�i`1"3)lD��`�K<�'M�r0�Mt"%~��M�ҙ|��I#8�:P
{�-��WF>DW���SE���T�|?i�d5�Et�b�Os�:��;R�K�.��t!:m4��}4���Hk��L[$�'�Im�Iaۣ���z�P8�GN����2*�»Jk@�L!P"�H��p�PD�GN�h-:V�_D�h Q9S�FT�K�����62�DUl�qC��q)���K�Ye��b0��zv�Y�1�-�p�{'i�����8�����rү����"��EZ�f����Q8�qp{7��~L�첌�S�F��+�z�=���
���\�����@�𒗑��p!�y,�4 ��)f�Z]P�s��-N��$�j�_���n�I�rq��j�tŲ>��Fh��Jz!���:h~|ch���䅐
�K���b�+
��@}�^"I|��:h T<S��"+�Mj�7��@��g�Ԯ���@�-Jڠ2�#Źb�w�
j�C��@���J`�%�P�L)TF�����DΡ�v��_�Zz&�    p��$ )�)mC*^�<B{�\�B���~1H+�P�znS��g=�ZU 3�G�7�a(�]��W����U��♄U�L�4� %�\������.��kAZK��>�!4 ����V��� ��[���5=�t����q<�������b6���ӮOZ��LA�	��9�,��"�ϫ����.�����z�>`�z��s����`рz��~��)��X@�����PP'�'���c�s��A��~�����<���./�]�14��.���/i�w��U*����]�X������Q����Z4?�q4���2�)(Q����c/��#��͑�q���ꂳ�����z$��rÏ��-�ϴ��45[`���ޠ�P8[������PD��5���������	2�Bc29�]^�c?��&�wE�UtL�.G�I O:���S�S:°G
�P<�����6��*F=�#��I[�֝��j�	�Y�� jD7'�k{YBӪ(�3�L�8 :���YX�� jD'�@���� 5�?qR����wx�,�!�&Y_wi�_����ʅhg]�ш��Q�nPs�=|:h Q	�>yKu;U��
�T�(*ig!�/���y�1��ocj�0C�*��ڐV��D�'�;��b��'ho�sd�ü!m� � e���ý� ��%��FtTs�yo���& �-@�����w(���%�δ7��v7H+?ߦH1@j��S�B�EE{�G�&�SɊ�rAC.��Ə��xg*(�#��c�b?S��!�2F�S�6`J SicZŊ!�k�Ŵ3�+a��,I��y�0����0e��(D�i6�V��}B+���~�ݹJ�տ��>��y��*�i�۱�X�� jT����A�:o	�������a�~ ��#>��N��t�V� qo�}��L/�Bs�U�Q���^Ҧ�9j0%��jE���g��sT|~���S��|4L�o7�x�&�d�jO��`�5�w9X[�9�0]j����$�/�׵�TR���6	 �g�Qs���4��J6��)D��a����2}ҎF�I������f]�duK�AB�q��i,u���Dw|[�	��9o��z�>���5��.J�V��ٿ�_%�F�/�v��{�P��Cc��Mt���r�40�fz�'HuUdDTW���&D�/�J��O�����'�퀔h�cJu�������}GVt��UwF��|&ژ�Ӟ-`U��������4	��m�����G��]ê�[�<��QD��#�E밾V�Q�tuʗi��s�?V�ǣ�3���{x�~��y��ш�+C~w,�����詟lW]��$�����~�����4��;���3�6E����&��R� %7��G~&�e~�q��͆%'�B��6n!uq�����q +�W@�� (y� dr��Ŷ�R�@@]��~@�"[����T	�}��m�T�Ԇ�D����pH�89E%�o�{t�_�G�}���.\��Fn��c��Jt��:�j� � emH���w�DT���}D�
CZA����7� Qn#jb �THb9��S>ޟS��sg��ǯ��0f���׃>H�9�j/�4܇?��H��)B�~9�^K[ib�r&{�
��-h�}�'�{v��tf����t����.���]0�|J�wЀb��E�i}2n �tU���J��"'6�w�1)΅+UP�:ٍ���}4���LP�u�ЦH	@�� ���*aA�D\q�*_���8����ףRW/�q������Ut�$�J�o� ��PdCZ�_�f���B��e�U ��ƢV��\��H��&[�2f<E�	u��Ma�1>�ֹ!<~߿`ؓ)�$����k&u��m��$Z7�"]F�lxy'�U�\�\���)���h�0��|&*������Ԃ�W�dG�?���|������}2'{��������7�ѐ�����!��6@
.8e6��<����`��|Y-�Y�v�Sv��.x��2�Ӻ�.�#]�Zth-�Ge�6	 
.8�6���.#�;T�^�"�e��d�'�1��J�aLw��b�~�g��f����YpN<�8�Q���C>�{|���(��l��U�ͩ�C��j�����Jl��X�_KS���u�KW_�Ǭ�� ü��N��lf,��	!sH�E�"�7��ax_�V�(�	vܲȵVN]sq����o�+���E�6����SmAj�<�fq�f�,��}s^n/�d��n�qB:mt��}4�FtTw9����4 ����nC
�su}���F��s����l�xF��&�z�\��i�k.��!�DǄH�ы����7�<�6��Tc1ޛ����<�ﲂ�ːݢ۲L�[�X�i;.��!�D�#�i� � )�!U�B�;����m�|�myF[�S0���1��Xz0`��}A�GYҫ?�vb&�oe�o妡9��[��p�5���2�G���9��,;p����<�`�6w�OMsq�Ǵ��1�^wH�4�� 6����f�h"-�_�6\�Kg���_-{�ˎ��K��H[DU����_���[&����k~����ӣ�D��6`��>^k*�ܫ�O�����%i�$ Q����5��ĔI�c��n�)'�ct[�r�7�ݍ���~��i�.�G������ަ��������=&Io��q���.N�5,�8�J�s��jڨ���hHkхD~�6@
Z�m�+sQ-1���}�ҾNg�x��tq�l�`S�����������v�E�-d�B�/���QG�G�ƫ��9�iZ4� �mH���6��О���R�DO�j���Fə-7wP�P|�U���~�i�H�#� ��>� ��s[ 0fD����}��% ^���i�Կ��z0Ÿh=���(��'A`���^��������g*D�I�<�-�Ɇ�����K�|$龓����B���fU���ڴC�n���^���%=��U�u
����f�׶�J@W`���^�&����)����+�@��k�ϕ�g��K����T��C$u���r��d9�Eio�4��@M"W��`-�)?󐖷��f��y��4�e<L����>�x�E����5�h�x0�6�Y] A�Ę3"���(,1+O�l��7�%������:�Tӆ�]��@*�?D��ML����H@�lH�N�Lh�{����߬��x���K���H\�N�wqi�dY���ސ6i R0
�q��2�xH�#%�z	7y^������:_�PqtŎ���x�����΄�^�Fm0�@*,H��dX��աRDn;����>/�mQ�/�0����-z�p���hHk�9�«�]� ˿���Ԥdi�����Lg��i�38AO����&k^���/�z�xe�}`�5��孜����i���(}����Q62��^hp�{7���p�o��v^��|���mr�\16=q���he3�WU���O���F;��ܤT"Xq;��G�H��u�r�Z�+R&�K���l��lb!C�Z+R���v��q�?g�tg�t�gĵnK:���q�ұ���쨋]�sUA�;/����"d��g憛E���1=���n��qyO�|Ӟ[��w�ܾ�P�,4��FħKu�\����*+�SM�����N{�0R�Ű�$�n>�i R6���y)1ZJ1W���
�C �K���D�Q�sáM�r��޲iU�
vlA{�졐N��= �%G~��4 � H��0�K)t�4��v���l��Ň��.L\�N�pq?�+ѹ��jS� �3��WCʪDa-��y;�+]��|_��$,O�sAN��bz�����hHk�%�x^�n�4 �Hm��1Ń`q �����i[n;�(�_s�)�E�t�����g �	Z�d*<ӈ�~�� �m�rlN�$�&K����3���1_����5�]r3m���~4���"¼1}�17��j�ݜ�<,ƍ�;���6��Ѳ����<K�;v:�M�p�j%;Qگ"z�ƀ
Ό��s���e�!JN����>DQ��洎����hZO��    ~<���k���7I�఩'�4��&�S IH��s��y���p	�i?�ۍ��FӺP.�� }�F$�ث)^�ƀ
>�����DR�'a�'J�1��o�[4G�)�'���X*F�:Q.��A�e�!�7�m*xQ�ɋ"U"IUɃ�~P�qz�W�z{gl���G�܄NP�u�\�G��*;�ܫ���@
^�RmH�:�Bh�Z�E�<�@]3��
7	��p3����=�:������Zqb�m�������F���j�w7VDׂ�<��'|u�Vc4���b?^+�%U�zNk��� ��[�2�O*�w���KXWܪ����Tդ!�8��䄢�����vΊ|]��,�����hZ��~���JK��O�����|4|��>T��H����B���j�EVCC�X[�~Mml�s�
s�h6����T�<pSI�B�!�]�QMd�@��B,S�2�i���N�#�yq���X��+z�Ѵ��q�7�%���6���
0�6���D�5U������cX���z�]���v;,��	괡��ֲ#�V'6�T��V<yXG\�z�^�����A��@I6ϝ��i�".�#��Wٙ$ګ-d�Ƥ���U��X��R���W�\/�C��\��a{Y����6�i�".��A�dG
!�`�Mc@5���@�UcH~���6�c�G0)�T�1�?�������Q|Ȣ�No�.ڂ�wվV�_6ڼ� d�ʔ8����ǯ���X��Έ��5�U�z���`A�;W��r�d�<���eE������9�����؏�DFvh	l=�6��D@�mP�4B��M8�<���2<�ڑ%�٢VA,L����YQ�^M>�O��Y�����S��E5׏��D�u5�`����MY��P�ި�_eo��KÁH��_�1�b ���읉�+��T�A�|����➊FԀ�G<$�7^I����7��,��W4���ܬ������ޕ���t��kr-;gD2���Ec�d����~�!���I��J��=C��B>lMV���g󠪆h��k���`����`b���o�@s�_=��ƨLIӪ-E���3xKw�*��ҫ�<�^0m�
~�4��S� ����CTVo阵E�<�����?ZT������߶O�mQ�9��B2<�g0
"�WU�t$Ҋ�.0w��|�]���4_�3Ca�;8�i��\��/0��L hӘ�����{@(�ҎV���a}dGc��Kʇؾ~�k��d����zL�$�%�����d|jA�A�Ǫ��/iYW�굪�9��cE���Ș=�Z�m�PS�*`����;�<F�M����U\���xtfHb<q��}-;��7Q¢1� Pm�
b:���!a����BIU9�Iݟ�6x|�=��~|H��ĜQy�,3>@�%J��F�$C�f�؆ң�0,�,�z�m����kr����^��&,=��Œ�c䶹�=�t�?ԕ���)5զ1C�f�ؖ��T]pn�A���ճ������$ƻ��T����9�/��<u]��x��O��ǧ�����<M-3>zF�mU�C�Tj�L��&��*�,S�)���
&_������N�뫑��Vl^���mU0m�¤������!��CS6_���Z,]e#0��������R��������f� T۪`U��� >���}|Xj�m���� 2���^Q�ߪ����а���m��.�׬7�ot
���p����z��#�΍��M��GO�ZvJ��6�h�T1��V���脛���8ж>pU���F#�#���g��*>��f�<��:�k�����gڳ}���S�θi�=M�=f��mFs�T=��;����w�ߧf�v}�ӶI�M�xKT���Y$<�/߉��u���0���Z7`C��r��,��m_���p],����F&Ӟ��؏�)���1�RV6��)�?�>�*C�LG)�w������b}�e!Z�4��89;A����~�����i%}�	�4T�Tb��H�ސ�����|��:�l�<bI�v[�}02�ً��hP�즟�Wj�Ma � h�p�?a���H*Bz�~�)��$��9�s�ؠu��Mr����@����2�»>1�6�U ��U���X���>�����+�et@u�|w������Pk�vU�����T����!�z��l{ë�p�w��\�gt���fN͚6:�b?Z�j�����h�͒ ��A��6+�p�X��b�ba\�k�u��T+��]�T.��0ކ�1�Ͳ%;q04x�8��ޭ��.,)�/>uj����W0Sq����;ST���{���BZ���#o�6F�y���f��_ܗG���n�7>���n�D��a&530mL��Z���
my���9;1��x�}d�N�J�������I�u�Ӧ1���f�Ժ�,$b�mC�^IX��ZF�0�й�xT��&Tب�m��(P*��lH��e�/n���'	�R�;xN�9��c�ۃҜ����|*�������O @I�Kiݗx����m�MO���xqY,�s�s%��s���#����'3�5�j��i�^���l�}�i�:��Zɰs����TV�ۈx�@�&~���g�Qqۈ0G(��/���/;g��X�k?����i����I��|�u��-#�LX�D�y��hE�r^�by8�5�w��><��Jt��2����Uv$1�:,{�A\U�e�H��E*��]��ƕV���w�~�*���j� (�N���e�2�)|��#�bfq9�U��=�?������j#Ͳ�������^
�t���F��"_ߒ�i��҉�;؏����S�կ�Mc�,M�ڠ���H���)��r�6�ICS�j�I�Ap����o�aa}����D����,ߟ�s�և�(=]�"AΔ):���h7��(�`�ӭ�h���TZ�Rs�?��h����vKRF��_���xf�(M�NP�=�r�j-;�BO��1��=J�A䅦�ا�K5>�/fB=��m
R��Mg]�Q�Вb�%+�[B��|̲myB;g�J:�y������dTI���6�Z6#�6M��k�<�+u���A�dg+��0m*Pm��<�):��;� �Ҷ��(��]T��a[�ߡ1aǰ�y�!s�,�.m��4�eJ�і3��ƪ�֔�.���bW�4]����%�F�m�O+mCo
xh7<�eӞ*U~ Ow�4+T9>/���2{�m�M��X��V��[�Yu:��X���Qg��7T�I�*�6h����i�9���<�e˶TU�$e�ĕ�ws�<��ݖ]O)����ƹWN�*�b?~��d�}Ҧ1{� P[���:�����bQ��G��e/G����'Q�f�2o+ ��}���IՌ��9��j������:Z�u���� )�h6�[Y�~�ß��#9�2�* 4�BW�~���e ���rd�S�Qv�Au�r8��j �e��@��tNv���*V�j%���F�&ˍ��͝Ƿs}����mw�h�mat@k4N�)Lw��&��yw[�C�m��rb8Ѷ��#	������M�?�Ӿ-ب�66�ic�>�x�\��ۻ��+�69�c-�n7k��dk1�]�~{��vRsUz߲	2u��4��҈�&&%��9��atC���&��Wtw���f8�؏0	��&;RH�d8v���3Ҩ-� ��/�)믮�[45�Q2?�e�8mw����6���~<���k�<�}:h�`�5ZԠ��X�s��O����n~������������qG��N�F�b?�Zv�%�a��P�*yA4 &w�WS�dY��zܞ��ٱ���;�l����A�d���O��	nP����LJa��q����٠�5:��2W�8{Ӱi�}]�?�9�2��r ��4T��M��j�����ۨ���tD�y�;�u�]�=�? uڣF��V�se��x�ڤ1�����`@�&���ܴh���#78\-Y�<=-��l��#'��5�؏��J`$<Σ:h�`�6:Ԡb^��R���Z/��p	��
�vX��Β>l�C>�Ѡֲ+� �	  �zSu�P�*-P�]R1ӈ��P<)N`Z�b��nW�/R�Y��w�ش�|.��A�eR��еI��5�ԐRf.���5����)=��������w8̜�?�6�b?�ZvL9E�z�Dc@?^kTfn,�ט��|���xʳmJ��!����}��M�O�؏��]J���6��T�(B6� ���bڪ� �9�6yL���|����3B�ɽ�N�L�؏G��K!|r&:h�
0������-��{����K�>����WT,7�9�)6q�+�Ѡֲ3J�=���ƀ�Tb�*L-?N����p�y���d��Ey@aT�-qZS|Zg��~<���i���4&z� Ԇ3����0P�5�ݥH�g��9*AK�p���s�?ξK|Zg��~���p@v���Ɇ�1�b �Y��U.�D�w�Zw�_�%���R��#)��C'���R.��1}�����1���ۘJ��������Qx>��%��q�E�./�W���:�֗r��4U�l&��&���h��
�
��u�ոw���C�2�.{pχ�mδp�:�/�b?�7��Hy��1��m4�y��_���	?�XR7˨X]�	��َ��q�tZT|�I��V�c��O��*P�*5n�C����Ve�N�v9&��E��^wǓ�A��zS.��A�eG�q�PJ�ƀ* Tm��L�M4�����)I�t������9�~|Zo��~<���3��M�H��M5��< �U�'�yoE����ۑ����|u.�b����i�)��V���X>�V;h��M5��<0�I�4���(�X�����<�Iy�|���XNP���\�ǃZ�.(��'�ߦ1��7�h��*g��i/�%�dM����/�5�����.PŴޔ��g@ى^��;hL�	xS�ڠJSx�Q0a{��w,=�������M���}vr� �zS.��A�dE�ϛ�i��Maf��LcA�����.���|�6��~yZ��l���]lŴ�hPkّ`^��;h��Nan�Z����z�;��B��8����e�ޔ<uk��xP+�	���&��)��N	0�,'�?�������������j��-qk��HPk�q��>�;h��Nai��^(�{A������6?-��y�?�����K�bZw��~<���
�<-�ƀ
�V6��DS���FSΈ���fu^��q�.��!����ӺS.��A�dǈ�iRY4Tp���A������^���M/+��3Y��������;A�֝r�j%�0�&���6�*�,P���S�zAEE�Ȗ���'�.��|������i=*�Ѡ�M}iM����Q�.�.��"�U�����l�]Sw;T�K�a Ԋ�I��:^��i=*��V�j�y�ڤ1��GE�*�
+�<�>Ώ�$8"�L:r)O�!���<J��zT.��A�e�����6�*��"�UT��`�ߤ���QQ|�˜�xN�;w� 9q���V�S���F�Dc@���6��%=U�����"�/9������5i�������qP�w�AW����^�暍R��`����q�X�b�w�<ڝh|wA�Ӻ�.��5�]
�����&��ppo��4�B,؂�'	����ڎ�N��_��(v4nhS'L�����d���6��m��k����_c���y�v����4Z�2��E�<і�F\���h%;�<Pom��Շږ�9��B{�����-Yj[���PT�ѥ%q�e~wmɏj�tN�J�G�!=O^g�-:�̅k���#o�wS'�eU^h�*�s�yX�~��
{ �$�.W�2�J�SI�p���vS���vH���u��gV��+�^7m���~�:bd�����Ѣ1��Rۊ��J�����\���mt�/x�_^�M��ڙ#���؏��Ɖ�3�Dc@5oe�n?�Brl�����ZwM}���|CZ%_�������u�2�ŌRېz�A����f4l3�T�3L��{t��=ݓ�m�'�Mz#�sL�l�^7�W�؏W�Jv.a���?�7Cku��mC�7I�����9���l��1KO�u~�9A�6\�b?�Zv���׍�6�U�(��:�� y�G�]�Ӈ�����Y{/U���`��5�p�Է�̶��:�R�Ɩ7�(DM���Z����L5 �tf[` ��,�S/��6���Kz���9_l��2��G���m�	)�<���F�]�G��Zv���=h���6������J��t}��v�L��:j�|��H�-�֧����VЀ�m3�8H�-�n���ԧ��6X���6���m���������r>+Fӫ���d�zv�5rӓg�C��K��(�����ણH�rF��?�-���[|�Iq$ժc/�竤�1z�%6_��\��>��C�i��Y�p�1?����Y�/��V�-޽���G��`6��P�Û      �      x���I�ݸ�E��*����q�`�W�UԄ}��\}9�BY�	򃓲T���Q�H�; ������l*������������o�~1��_��Ŝߌ||	f�\JW]��*<��:.�")�-N�p�����Mٗ_���q�/"x:-�LlYI��E��d�R����/¿��)H��:U�;j�|qi3
��W�TM�R��~l��5:U�����)[I��+t���Rs���W�t�Щ�����8�\p�N��[jL�T�K�>K^Щ%7���q�� �b���s�ğ}퉜�ݰ��@�\"/H̶��b����e���hE��$�E�9U����4	�E�}/*�G���a�[V��K��P�?��
۲ܣ��y4����Dۈڢ���[�6�����E�a�����+!��_K��p؉�iY�y4��&<���4ע_���ܦ̥��BU�T}�Ny�����W�e�m̢�9t^��
�Ǔ"�b�-1�+��t�އ�M��BM��1rK��b�f@��=�s9zG�a5�؜3��
�˱;r�&h�\�s9�-�0����7�tS�B���#\����$��l�m��v���[x��4b�b`����j��^��':W7԰���C����\I�QR�]E�%:Wsn�a�/Q�
���j �@���7�Ε\c%���/�WH�UW�T�S5�N�^L�a�-�й���ϋ�BǽD�j솚����I �B�j��C
����0I�й���h��i�l��O�:W3����K86q]�.HN�F%ɧ=i�Ȗ1�=-n�"���/,�$Ǫ�]��<�\�����k@E�z�/�\���(�g���s)��v�P�핽�s�������x_⏂���='�ej+!(q�и�Q/�Le�Wc�������vCPj���1�!��� �˼(�6����X���� �b��!{�?�sAvO�Ot)pe��\�������IR�_�sA�'L�3�(�.ȹ��)'1[�D*ʝ+t.(��Ls������9�����1I�:T�+H�@��|G�W�	_�rJ�rΓJ��;�8��r����LP���:���}�"�ʖ��b I�,��{����bKP3)���8��G��+��}�e8�>@P�����j	f*���e�0W�\ꏧ(\�6ŗ{����8X�=w���\�h���r�ίй����-�g��	�9�JK���C7��t���Sú��BRq�Đ���gaX�MT�E�Q����TM����A�:AB����S�ԎY����
��IrC����V�ₜk��+�� ��+t���8q�u&�V��M��t�t:y�>Q���4�0e)��K�"�D?pK�[r�~^h�Xa]�s9�#GL��p����9���r�?���\�hx�7��D���v�����Oo��&Jw�S�b�y�}����V�E(�2���/����̒������bB]?�$��ٞ�F�U��%�Or��p]�a��\z��ՎZ�T��Jr���?B���%kHK?܋�r�=5�lĽF�j��<�O���&����F�=mٶ�K����-��P{�K��<;�'�Ǚ%+�뎰	���p���r��?B�oQn>�J�|�b����mi?�kG۵���Fu��*&��B�j��rQ�$\~���%����4�.|f�w��#>IyCM0=�ۄ]��+�h�� ���0a-#u�Z���p�l�u\yA�%O�8�f��m�Z�b�5X�2���^�� Eϖĥ�(hW���)��aL��y�5��c�$GH��C�������:ncOx{5g�����MR��2t�GH�y�;s�9\�Em�˽��D��l`��X��I!1ar�J��g$�:	�&ؘy��[6����2t�#$?�Y]J�s�����kO�bQ$s�g}�W����Ra^A+�����W4�M�s%����$c%x�Y��I�����V:.�Wx$X��[
cE���`�������!�q`/��>Q��[���V���\��I0$՝;���3�W�m315��$�<�O�H��Zʹ��u��8�]��b*g��q+:��@���R�^�[DoE*��F�("�Ha���I�*�h�Eպ�����ѻ�L���
��N�XTE�y�ǋ��|B�5��8?<���tz��ū�rlֶ-�&E�5d�K�5��#���)6h\>��|"¶����d [:�K�y��[���!�q*(G³s}�|��`��mN;Z�K�gu�ą�r����'��9�0�}l/ȫR?�Z��`/�6
�q�2�\C/��gā����	����t9L9� W�\Ͱ���"?��:W3��GH� �|���JbV��V&qNC]��4��rͽD��vyiK?�6ӕ��^�c���85���-�\s/9Bbǘ����+r%���T�5��������4����!'�vz�	�w��1�d��t3��y�R
���&X��҉�e�m�\����٘��Z������(w�N�a;ԥ�n�L8���������T��b������a�.�V�^�<4��$&���L��yu5�����IBoQWh.'�׀���n~B�)��jZQΰ6q�t3���HD{�{E�dX��k�cE䡘ai�|��8���+4gE�
,��s�0��>Ntݭ�4�X�f�u��+4߃�h�m��2��d���1�S�f�1q�a��̽BKE�)�9-���GoN�hn���;rJ����=���`｡(�"������et�(5v��T@���T]��&���%ta�ȾV	��r�n�cJݨE�/#���l��H�.��5^�z)�2�Ѽ����fy��rz���-�we��i���.)�����iCĂG s�e#�I/�߲�*��5X��ʙ��c�tJ^˓wt!g�'��(�X��E��Y�SvSV���$��74ʙ;�q���1 �KԖI�R���q��]��J��q�[��u�[.xCr�%
;nz3��S)�%Jʰ�V/<��ߢ4�J��i\�`L}j��Z�T�+�ɧi y����a�Eme����?���pB�+�g�OH9��pHҡ��u�B�3w�D|b��w/�V]G&o�g�A��^�F�O�u�1�;v�@8�}�=��`fK�f3i�X�$������pm��Ɵ��}w/�҅eC�e��5M��i�d�����UԱ�z�NW9p��u�lC17�Gr��&،r��r��kY�J>�w��4�����_*�����X1CGq�!����`��^���)�WL�	�	O+R�"����Q��\�m��+�͇nX1��3�P��Q��Q�����S�q��m��Z�q��0A����=����<b��=)���������U��u4�k�1,ifa7k,'�5 Am���	�X���s��H���EA3/�׍X�qCG9bR�`l�)Wϻ���d�2��m�X?�e���T�"���r��{�z�I��
uP�SWa(�(��Ґ�=sCG9br]ma�(�k4y]��џr�/}X�3�~�(g�(��mؖ\9�}t�('�e0�[��r��'�`W����->0�g��˙��<>��7K��
��m�uQ�԰N`�G^Y�;9F��q�N��*?�0��L<#�����_Ɏ%-7s��JW\�/	���$	���a����T7������<b�`K�s��v웤oڽ΋��嶀�nQ0s��L�`C���Pׄ�8���S��"�ʙ��?1�Zv�Lv�BR/�^U$]������aOf���8@�t�%
�b�z�u3�¯s�h>��\E�|�Ԥ�����+�{�U��q�y���l]�6|�3s�GLL4D؊�����I��~�xq���5�=2b�f��Ɏ�.�T�~�)��	�Є��+~�XU�t 3Oy��p|��'�h�e�",i\k�6�mC�9�{
��ڲ�:�l+�2�#��]�a.J�z�U�;
ןJ�3GJ�>M^P5mU�0�敗�X�1c0��f�(������r�
�>oG^��_��:�XAT�@�Q���`L�o ����O�r�����-;��ð��0t��d}�I���? ��d���y��k�aA9CG�jr�OP����( �  vQ.|)�}�!{6�C�3t�G��j4f3�}�=#���Vf��i�cS��逩U:
�u+;�|�:����DK��X--z��m	�f>����<b׈�벧��'�W�?�+�4�{7�݃8Å =利�ǰ:p@<��'��1���nX�m�|\צ����<b�����O����؅�0�r*�q�H0�CO������Oq���^P̶r�E���J�2��x�KHQ��S���M}�����)c�Jo��9	ظp}��z����'� \Z�yo�4r.X���݆=�k�{Iߎ�=E�t�Mz��5�DX��I�Ő�m�k�C9cOy4��%@?������ɯ��ͦ|  q��=E�<n�2���C�5�U�G�9��(�%)�QDzt�"�cs�\!��u�#��K^m^�ڶP���S�޳a3.�
�I��nɔ%m�3�ǶO����"�O_�')��Ӳ�L`��*�����bM_�&Aǔ�"�I�ť=_^����\�bfi4l�R�(g�*Ro
���.V���r���0�qOsF'e�\�>�+tLÛ��1��!{a׽DMC�1�
P-g		/���5�*���0�
�a����|AI/XH}6W��2NQR�5�+�SOx�;�,�O�D���G�'�,��M���;І�e�c:��1G���3�ʮ��Nrڬ��L<�c�3w�6�o����+�I��t��E~�F�/�#�벏����d�
�u5�؉t��okC��y����
׉'v��J&jnS��TC���0���1���A8������t�Z6oY˒*��<��+=�;�Gs�u�r.QWFY2�[_�q[�QMuQN�E/�>b
��m���/�_�%�P��b����-����!���-��_x?��      �   9   x�3�-.M,���4���2��/H-�@|cNǔ�̼�⒢Ĕ�"Nc�`� ��      �     x��Q�n� >;O�񛐜� �.���%��%��d�?Z�hݴ]&![��c+��<F\����Z�q��,3�y:L�<�\H�ArG��G$֓��=�;wMvBL���Z���^u�VTtZ�&�p��#��K\e��?�x�&��Y3x�U53�7=S�Ҵ��Ƽɯ��7��٨�2Ӵ-lE�ٰ$</����|�U67 ͘RƀG��5x;>�咰�ϛ����p�n��l:��sk��_���D>�%Ĕ������;˞VU���Y      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   "   x�3���/�M��2�,(���O�������� n~�     