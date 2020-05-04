PGDMP         )                x            Gran_Fruver_Def    11.5    12.0 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
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
                postgres    false            �            1255    28369    f_borrar_notificacion()    FUNCTION     �   CREATE FUNCTION producto.f_borrar_notificacion() RETURNS SETOF boolean
    LANGUAGE plpgsql
    AS $$
			BEGIN
				DELETE FROM producto.notificaciones;
										
				RETURN QUERY SELECT TRUE;				
			END;
		$$;
 0   DROP FUNCTION producto.f_borrar_notificacion();
       producto          postgres    false    9            �            1255    28153    notificar()    FUNCTION     x  CREATE FUNCTION producto.notificar() RETURNS SETOF void
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
						IF ((SELECT COUNT(*) FROM producto.notificaciones WHERE lote_id = _row_lotes.id) = 0)
							THEN
								INSERT INTO producto.notificaciones (descripcion,usuario_id,lote_id,estado) VALUES ('Producto agotado',_row_usuarios.id,_row_lotes.id,true);							
						END IF;							
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
    	   seguridad          postgres    false    201    7    201            �            1259    27979    rol    TABLE     �   CREATE TABLE usuario.rol (
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
       producto          postgres    false    228    9            �           0    0    notificaciones_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE producto.notificaciones_id_seq OWNED BY producto.notificaciones.id;
          producto          postgres    false    227            �            1259    27953    producto_id_seq    SEQUENCE     �   CREATE SEQUENCE producto.producto_id_seq
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
       producto          postgres    false    206    9            �           0    0    recetas_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE producto.recetas_id_seq OWNED BY producto.recetas.id;
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
    	   seguridad          postgres    false    201    7            �           0    0    autenticacion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE seguridad.autenticacion_id_seq OWNED BY seguridad.autenticacion.id;
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
       venta          postgres    false    6    219            �           0    0    detalle_promocion_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE venta.detalle_promocion_id_seq OWNED BY venta.detalle_promocion.id;
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
       venta          postgres    false    223    6            �           0    0    promociones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE venta.promociones_id_seq OWNED BY venta.promociones.id;
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
       venta          postgres    false    225    6            �           0    0    tipo_venta_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE venta.tipo_venta_id_seq OWNED BY venta.tipo_venta.id;
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
    producto          postgres    false    228   9�       �          0    27918    producto 
   TABLE DATA           H   COPY producto.producto (id, nombre, imagen, disponibilidad) FROM stdin;
    producto          postgres    false    200   |�       �          0    27955    recetas 
   TABLE DATA           A   COPY producto.recetas (id, descripcion, producto_id) FROM stdin;
    producto          postgres    false    206   ��       �          0    27965 	   auditoria 
   TABLE DATA           d   COPY seguridad.auditoria (id, fecha, accion, schema, tabla, session, user_bd, data, pk) FROM stdin;
 	   seguridad          postgres    false    209   �       �          0    27925    autenticacion 
   TABLE DATA           b   COPY seguridad.autenticacion (id, user_id, ip, mac, fecha_inicio, fecha_fin, session) FROM stdin;
 	   seguridad          postgres    false    201   �K      �          0    27979    rol 
   TABLE DATA           @   COPY usuario.rol (id, nombre, session, last_modify) FROM stdin;
    usuario          postgres    false    212   j      �          0    27932    usuario 
   TABLE DATA           �   COPY usuario.usuario (id, nombre, user_name, correo, password, celular, direccion, rol_id, session, last_modify, estado_id, token, vencimiento_token) FROM stdin;
    usuario          postgres    false    202   Mj      �          0    27989    carro_compras 
   TABLE DATA           V   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    215   �k      �          0    27994    detalle_factura 
   TABLE DATA           =   COPY venta.detalle_factura (id, detalle_lote_id) FROM stdin;
    venta          postgres    false    217   �k      �          0    27999    detalle_promocion 
   TABLE DATA           _   COPY venta.detalle_promocion (id, precio, cantidad, promocion_id, detalle_lote_id) FROM stdin;
    venta          postgres    false    219   �k      �          0    28004    factura 
   TABLE DATA           h   COPY venta.factura (id, precio_total, fecha_compra, producto_id, usuario_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    221   �k      �          0    28009    promociones 
   TABLE DATA           W   COPY venta.promociones (id, fecha_vencimiento, producto_id, tipo_venta_id) FROM stdin;
    venta          postgres    false    223   l      �          0    28014 
   tipo_venta 
   TABLE DATA           /   COPY venta.tipo_venta (id, nombre) FROM stdin;
    venta          postgres    false    225    l      �           0    0    detalle_lote_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('producto.detalle_lote_id_seq', 28, true);
          producto          postgres    false    204            �           0    0    notificaciones_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('producto.notificaciones_id_seq', 5473, true);
          producto          postgres    false    227            �           0    0    producto_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('producto.producto_id_seq', 22, true);
          producto          postgres    false    205            �           0    0    recetas_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('producto.recetas_id_seq', 1, false);
          producto          postgres    false    207            �           0    0    auditoria_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('seguridad.auditoria_id_seq', 501, true);
       	   seguridad          postgres    false    208            �           0    0    autenticacion_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('seguridad.autenticacion_id_seq', 265, true);
       	   seguridad          postgres    false    210            �           0    0 
   rol_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('usuario.rol_id_seq', 3, true);
          usuario          postgres    false    213            �           0    0    usuario_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('usuario.usuario_id_seq', 15, true);
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
       producto            postgres    false    203                       2606    28135 "   notificaciones notificaciones_pkey 
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
    	   seguridad            postgres    false    201                        2606    28048    rol rol_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY usuario.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY usuario.rol DROP CONSTRAINT rol_pkey;
       usuario            postgres    false    212            �
           2606    28050    usuario usuario_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY usuario.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY usuario.usuario DROP CONSTRAINT usuario_pkey;
       usuario            postgres    false    202                       2606    28052     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    215                       2606    28054 $   detalle_factura detalle_factura_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY venta.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY venta.detalle_factura DROP CONSTRAINT detalle_factura_pkey;
       venta            postgres    false    217                       2606    28056 (   detalle_promocion detalle_promocion_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY venta.detalle_promocion
    ADD CONSTRAINT detalle_promocion_pkey PRIMARY KEY (id);
 Q   ALTER TABLE ONLY venta.detalle_promocion DROP CONSTRAINT detalle_promocion_pkey;
       venta            postgres    false    219                       2606    28058    factura factura_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY venta.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY venta.factura DROP CONSTRAINT factura_pkey;
       venta            postgres    false    221            
           2606    28060    promociones promociones_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY venta.promociones
    ADD CONSTRAINT promociones_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY venta.promociones DROP CONSTRAINT promociones_pkey;
       venta            postgres    false    223                       2606    28062    tipo_venta tipo_venta_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY venta.tipo_venta
    ADD CONSTRAINT tipo_venta_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY venta.tipo_venta DROP CONSTRAINT tipo_venta_pkey;
       venta            postgres    false    225                       2620    28063 %   detalle_lote tg_producto_detalle_lote    TRIGGER     �   CREATE TRIGGER tg_producto_detalle_lote AFTER INSERT OR DELETE OR UPDATE ON producto.detalle_lote FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_producto_detalle_lote ON producto.detalle_lote;
       producto          postgres    false    229    203                       2620    28065    producto tg_producto_producto    TRIGGER     �   CREATE TRIGGER tg_producto_producto AFTER INSERT OR DELETE OR UPDATE ON producto.producto FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_producto_producto ON producto.producto;
       producto          postgres    false    229    200                       2620    28066    recetas tg_producto_recetas    TRIGGER     �   CREATE TRIGGER tg_producto_recetas AFTER INSERT OR DELETE OR UPDATE ON producto.recetas FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_producto_recetas ON producto.recetas;
       producto          postgres    false    206    229                       2620    28067 (   autenticacion tg_seguridad_autenticacion    TRIGGER     �   CREATE TRIGGER tg_seguridad_autenticacion AFTER INSERT OR DELETE OR UPDATE ON seguridad.autenticacion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_seguridad_autenticacion ON seguridad.autenticacion;
    	   seguridad          postgres    false    229    201                       2620    28068    rol tg_usuario_rol    TRIGGER     �   CREATE TRIGGER tg_usuario_rol AFTER INSERT OR DELETE OR UPDATE ON usuario.rol FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 ,   DROP TRIGGER tg_usuario_rol ON usuario.rol;
       usuario          postgres    false    229    212                       2620    28069    usuario tg_usuario_usuario    TRIGGER     �   CREATE TRIGGER tg_usuario_usuario AFTER INSERT OR DELETE OR UPDATE ON usuario.usuario FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 4   DROP TRIGGER tg_usuario_usuario ON usuario.usuario;
       usuario          postgres    false    202    229                       2620    28070 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    215    229                       2620    28071 (   detalle_factura tg_venta_detalle_factura    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 @   DROP TRIGGER tg_venta_detalle_factura ON venta.detalle_factura;
       venta          postgres    false    217    229                       2620    28072 ,   detalle_promocion tg_venta_detalle_promocion    TRIGGER     �   CREATE TRIGGER tg_venta_detalle_promocion AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_promocion FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 D   DROP TRIGGER tg_venta_detalle_promocion ON venta.detalle_promocion;
       venta          postgres    false    219    229                       2620    28073     detalle_factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.detalle_factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_factura ON venta.detalle_factura;
       venta          postgres    false    217    229                       2620    28074    factura tg_venta_factura    TRIGGER     �   CREATE TRIGGER tg_venta_factura AFTER INSERT OR DELETE OR UPDATE ON venta.factura FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 0   DROP TRIGGER tg_venta_factura ON venta.factura;
       venta          postgres    false    229    221                       2620    28075     promociones tg_venta_promociones    TRIGGER     �   CREATE TRIGGER tg_venta_promociones AFTER INSERT OR DELETE OR UPDATE ON venta.promociones FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 8   DROP TRIGGER tg_venta_promociones ON venta.promociones;
       venta          postgres    false    229    223                       2620    28076    tipo_venta tg_venta_tipo_venta    TRIGGER     �   CREATE TRIGGER tg_venta_tipo_venta AFTER INSERT OR DELETE OR UPDATE ON venta.tipo_venta FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 6   DROP TRIGGER tg_venta_tipo_venta ON venta.tipo_venta;
       venta          postgres    false    225    229            �   �   x�uα
1�z�_"��]�|�`$��w�¯7Q��"��<�A$5�St�@�X��'�R�Mx[��~�U�v�����m���l��A�Y0�/�I�ˇ�\�)s�����6�.O+F���(���c�
6Q      �   3   x�3517�(�O)M.�WHL�/IL��4�42�,�2517�*i������ RVm      �   s   x�32�t�H�-�<�1?/���.&�371=Ȏ�A��+�K�L�24�tJ-J��J�KDU�,�22��M��/JFS��2����M�+��CU��f��XT���fD�&F��� ��I-      �      x������ � �      �      x�ݽێ�H�6x������|������Ӌ�N���<J�HQ"E���ϰ/��dD$�]LVu�TewgG�dn��������o�gD�L�/��2��؊	E$���ǿ������MPe���bBٷCY��UR��ݗEX%��7ɹ����_�A�l�}\�������Sĕ��������0k��b���%��7�߾��ٷ��_������k�GI`�QYUI�0v��.��ud�**������2����&y�U�ǔ �E��uV��Fi������b�w����Y�D�M�� 
N�);�ci���>(F�Z�U�o�+��?�2��[�c�&��b�̍3���M���oCĩq�F�ͅ�(�c�T� �8�O�/��[�b��������?��|�m���0��?�jm�b�<%H!1�������=��Fq_�?�?@���C\?~�	�,���/I��!��d� [#���u�5\� �����+?2�'Ó��I��3u������� ����w�'6��ύmȍ�IƵ�>����w�n(�F},	~E�ȕ�HJ�<
�Xnx&�)�K[�>��~��~�ͪ��%%|�1���g��r����a�"��AFq��H'1
Y��4U<�
1Aa���Hqc�H��v_�p��Q!E�	�
ZD)�C�':���D���Xc&�� R)�aBX�d�k+*y��b�JŊ�$s���Y}J���Y(1':�
�$e�āLX&X�$HX�`�:X �F�ơ1�0��l(��q4��x���`�C��)�|>L�qF�DE2�8�!	�V
�3��D�	��8�i�X��A�1�D"�q(� l����?  J�I8*�W�bI�៓}�p���X�|�wvh�c7$e�NK�
!��|2k>	z�zE�&ʹM�g�(D8%�j�yJ4�2
u�1Lt�a��
Y���FA�Q��Aa��t|>����4�����ƽ��A	���p�锨���l�Єv6{����W��`Yi-���$��8���!��8MEE\')U�
SJ"S�4��IE���<M�:��l��PL`'��NK|fS���+!�b%ɳ��ׄv6�5�N_�HNb�B%�e����$M0��D�R�D�h�T,#Na�L�TD!�#�)8Oa����l.�#�����Q�N`����	��tU��O�0���W�WT�f�&��'�Ea� �4���S��T"s�I�1B�`��S�� L�Ԓ�ȱ:�В��� @+��>m-�O`'^9�9Q�E��]h�S��SR��|�����%"�/LCp��	i�4L�-Lz&X�T��.��f�>no��}&	���)�� 604���%g�h��;`��Z`�0���XEDH���G$NX�(V�L��`3�IvXbK�9~�i @��a���)_	�pϞ�7]h�[��`cp�Ô?��C��|v��%C�D��H��m��Z�D�D�+.a�w���=� Ϧ���hKy���ƅM��0{`��ᕐ=c}�W?]�=������-��6����i(�@�SCTC1�}�oL�n���VDs��%'@�{xS
.q�����xEl��
?��~1�]K��M�+���q��˒<,H�BԌ/Ջ=���w
��ү��� �L�JG�/qJGɌosH���/��rn�<�P��q�:Y7U�9���E�	�5�i.�Ґ����]rC�[�q�ōzg��ji��B�Y�֡,��]��_��o�����F�h����#~m��4�6�?��qDv��I�@���>a�h��h$/�= 
�'�
�ȏZP��}3�����:��#��`m���,��ډN�D����v�Pl�{DaB��h+:]�8zڧi7wiʌ/՘-���2c�+ʦ��Ӵ盲կX�4AB���_�Vt	�m�yڧ��|����W��C'dq@�D�NlM���o�!Pb ��S�Tu@�e�JQ*����@��7���P�Pjq��͘�∂�XJ�i�>����Fl@��� 
!�4����ʎ�g��#@��6�ꕉ8�|zɧ�VO��R��=����N�:I\�.�*�������.	o@{$ (ya��D�HgLLJ���mU�WIٰ�}˹Ѕ]%�����Sl�;oD�4 )}a����+ӊ&'}������c�3��y��?�|�tag��~6���#��h R��޽%�g���3z,�F�H�C��0�qL��A~*��L�$̀���D�5�����!�i�&m �+�+���^�q����<��a�$&��|��t�򎦞b7��OW&�;�<�:ٍ��Y�읁�7���9]v�|aj8���L(g�;q��TXy���	y���s��n �n'g,�}<�ݚ��=ğ\9�M��O��>�K���
as���Q��e��_|٨���a'�X6�K,�Ǚ�o�l`�p�ze��Y)B�t_.ٖ���;��|�4��ƃ0wY2�(%B+�W���[2.�c��̒iO�Nv�W�O�m��	�c��?�'ٟ1��t7��3���>Te�D���_>�����o���/���?Lj��"��U�������N�C���,7���S�$f��Ap�AWBR�'��8�E�?4��bt��4�7�<����2���T�w�1�XNz
�4��SR�^1H���]��tc�b�ٕ	�Mߪ�� �������"�k<y��,����W���T!��Ak�FhҪ�~�|Q,�\|����� �3U؀j��*-�F� ���me'�鋪Q�� �.-HI�s��E� ����D�,�ɠ�( �_����$.RE��Uճ�¬_�Nv���wU�4 )y�z)�m��YT��\����~Ȟb�3�4��
�i�g��'�r�#\�
S��<x���1��\�wa�w�������fk�o#�0�b��`P�r��ez2�$��h�T��-L��B��I�k���]	슒���8#���>gS��;�������f��k�m��E�D��1�lM'/��EtpU��D�+͔�4�Dً`������tZٳ��El��FrX�t��~���/��`*��S0��Xͱ��WB�s��d��( *^����D<�/��X��!jD��q4��;J��!-D�0�iD�sǟEt�C�B�v�c��7���^�z@S�{=�a��-~ď����)��q·4�(M�FT�rr��N�9c^~�y�N��_֟8?����|o��|����^�o?�C�C�g��<\!�^$���6�)f��^Ioz�ܒO'����y���6�?�6/7eb�f]Й)��)4�N�D��\/m�ѱh�Wٯ�Dg��S�}B_C�߾Q􂱰��ڒ6S��������r;ޮ���yS�P�yY����}�$�j(S�CNg�=�caѯ���s���W�T�Hj#�_�Z!j�O�e���[(�=ux��R�9�`&�p&�s�TK6'��7��IЌ�곩�wN��qk�86/8)h��h�B�mF����	���4��)lD��`�K��'M�r0�Ct"%~��M����I��Fp�J)���YD�r0�Mt��~���h Q�"��(�O�,Y�&ݢ��m���$'r9���=9�]6��>�Nt���s�-���Hm�I�أ+N���g�\6�8�Fr��Q����P�*^� 5� ��i6�y�eÑ�#ډ����@T�(l#*�#CNLz��62�kD�Ul��B��q)�3��r���?�`&/���f�ư�(��䛤g}%&�	�ſ���i-��6�p�=�,�r��~x���4C�Ƀ�t��$�da��IX�����bv�9&6�!D�pW��9P]��G^F��x�8��c3�P��b6��� %8G��ޢ_H�ow���m�M��ls��j��Ų~
T� fh�@��B�s������@%���R�]
4]�YPǢ@_	�w�%����m�@�/JX�RdbEB�[��A�f����L��5��>� �pDITfr�8WLMQς:��~1P[�X{D	Fh T���*#��Z    ��t"糠���_�Nz&�p$ ){QچT�R�"�:y��,�cN����	���1e� ��E�P�
d�r���Nf1<�k��@m�Ǧv���x$a�m/[�a�i�����o�� ���B
�� U���V��� m�[���5=�v����q=�������_b�����]�^i��3I�5�l�f������u��ȥcyC?���V�Nxΐ�=,P���Bf�> ��T��m�YP��������c�@�/��/��\w�O��]�2IZ��˶��Kr��1u�J���c.�3�l�&z�(G�SG-�߾q��=BeJ)R��D12}.TUm��CƢ�bA�s����x���t��	���#A=}A���/ZXp��-p�rB�dP�Y8������PD��3�����G/P������p�y�
����*��c��8rHx��l<���#{��?�������]SŨ�qd� �`7iѮ�CR-��G�b|D����tm/�Bh����D� ��-��.~ ���:���J jj�xB�@��ޟx)SU��7��N� ~�e�v�#fI�u!:ZWb6�.�?��i7���>#4��D����*�zZ*�O*�h!�/��o��Ɯ3���G�@� RjC�^a�����C ��A��#s�i� � )� ��X�1(<�}R1Z\��@jDǰ@5�[��o�@�(1��N?�}���_g��M�����o� � ���x��"�=ʣ^�[sbu�mh���f�xU;{�����b�������|�]���-ϐ0%���1m�bŐ����t4�+a��*I����0����0e��(D�i�l�6�#��1�A��?�C�/]�ںߎDw�?�y��*�i{��t�CR5+JM�� u������F��Ǻ	���|"��G|D1��-
�m��ɀ��kt4���Q֮7F%>gɐ֨��X��!G����^�����t9�N�G�����[��a�Hf���T�Q	�~f�C6�lN.L�ڥ�z4���u';��'�pH��ګ�G�a�h%{}�>"NNA�'���S��փ�����*�R����=;������G��ԓ^n��mW�b�9q�[�A�����E	��a<��쯒� �7Aǧ��}l*'�1��!:V{y�C�L�<���-2"VT����M�6#�J�Λ(�<#�������h�cJ���������HVt��mwF���L&�1)�=!�=ۊ�5��V ˃_�*,�$��﫭�� HϮa��-P��("�9��]�=+��n�m�,9m���ϕ����+��n|z���'��~G#ޱ��:u��#��C?ٱ�?��ǞN:��_<�'���w<����=	��W�TJ�G�x�[W�L�Y~��	E��Ƶ������H]��l�����x;�W��� (y �"dr���v�Rؓ�������NE���ѩJ��4 �H�����4���!9�	O,����m}�q������p�O�y�;�ϱ�:xZх��*kH�j��!�z��Г��ID����A���bH�g�A��7� Qn#jb +����iO�xxI� ϝ��~=�1KLG� ��y�T{���!��?�Djj���L�a�Z�rH�P�39�U`��A�����KQݏ��B��1��c7O�]��+v+�`������W�(��f�@<��t&�+��GD���S��ڕ*(]���A��>�Nt&(�Y� � ��ҷ�*aC��D\�i{:�|[]��mS����������<H]�gB�.:V�z��i R�S(�!m�X3M&�B��e�U ��ŢV��<��Hً	L e�.�y�L�ڨN
Ya|��@x���a��L�Ē�*�����Ar���p[�&���L
~��r{rn]������}�R�M>�J�@J�RjA��V��#9��vur��Q��n��Ɂ�}�l��l���}6�Ft�-0f���nH��N�) �a{3=� =_��{��Ҥ���w!��=sA����>��Dg+�����7$@����}���`�����H�)(&"��O�1��J�gØ�(&}*��>؟�b�SD'f�9��c��F������ȑ�Ϋ��C#�j�9���PO5�Z`�@��Jl��X�_KS������X_��U�i�u��>���\���B�������Zt��}�lϧ��9nIP�j�B�^�lt��}��ÿ���^�4�[�ֻ�'´��&ȿ�k��x�f�'��vZo^�L5bL5mM�16��h�tM��>=���9�_�q$y�.��l���}���Q�k�Ǯ�����0lH��o� =�cI�CN��.K����հ��
�W-�sq�i+:&D
��h#4�}S��ېrS׌	��dJ ���^�59e����Ƿ�7Uˆ�\��CڊN9F��>@�RbC*�^���Ϸ���^o�N#�CH��2:l=��F0��vCz�j��_��h7V6+7m����^c���[_cz|)s{tK<�C~M�戃����ufDX�]z�lL��}�Ӷb�ƈ{�dҀ�Tؐ�׶?�Q�����
����2g����Z���#��m-uZ#mU+��zz�#MUf��\�r���[�>�V�Bjٰ���|�iELp�RBC�
����	�������g_c[OL�=�}^�0�pRV�m�N.n卝��s�̲�O��3ӉN���'�0���O�����B&�d�z��oN7���W��|'R:=�l���}6���B"��̐ -��ĕy�(�xN")�=K�I��Cg���h�`S
����OևCƛ�]�(�_��M���Oj����L�x��1�<�@�TC �t�y��V���S5\Gj���T�T8(9����%�?� �-�?i8�||���8��s[ 0f�
i�t?�xIP���Ӳ�~�1z0Ÿ����KGϧb`�3��l����o	�ߙ�����$`p9����
E~d��K�|$��y��{��U��sm������?|��I��T�~��||�C��k[զ�+0�g,f����h�vJ��k����*�=~mr��2�<?~�3�oq%H�G$+����ޟ`�FG9,�(ã���6�I'[)"�GcI��g��mw���p^����t'�:��6:�%5I|��0�=�A��P���挈�	
N���cZn�b���-)���Z�R��}�������i�##4 �H�i��	���5~��(��n}���0��۔�����x���v���yn�i� ��ף�@�Z3X��D=ï����Sy=v�t]��Du��e��.�3!}�	)����4`f#�TX��Ұ9`�����Jz�hv_�趩�}�WW��l8��}6���Q�UsoH�������Ajô�ҋ���t>��U�'��߃��vȚ�����uwD������qy['�����������Q62��^hp�'���x�n��v���|���>����^8��}���������gH��Z�)���$v"��0��G�Ȉ���r�Z^�	ܥl�wQ6�W6����m��L=;k�*��|��|��$���mI�dG>eG\�7�ؓ��쨋]�k[�A�'/m��&dF2�r�bn����+I��q��]+w�{���;�$�]��|�+���=B+�@j�����T�ic�YH��pxR�Ͱ�$��_i R���}�Rb��b�Ф��,��^8<�ThO+:��2�wC�����MۢXpb:yd?鲁��R]r�WV~H�
�Tې
��BO[A���[�N�8�it\_�&��������+��Xi R��{��:HY�����ӏ1og|���N�&NMy�I�|���_��φ�]�UngH�*��6,�3��ldR�P4���3��5�E�o�ˆ/\�R���O��#�h_)h��)��Om���ܟ(�Q��T��t��q�ݱ�%�ηB��/\�gc���)"���>	���͉��b�x@�K�x��[f���p���^��r00Z6��b?    �Vv��_]�!��e{��ϓ��G�4���;�a��i�����s��1Z�Sw��j+��{;�})8l���2m�I�H2���o�p�"Z/j�c�/\E-0Zօr����`DR��Z�i��C)a�jJ��H��$̼�����v��k�7�=.W�V��u�\�g���?B�o��4T�ԃE�D���QӠ��m����X���TNP�u�\�g��.;�ܫ����@
^�RCH�:�Bh����E�wDo��~B��ر�~�g4<lq{ڍ�L��ۍ��J�pIs�+�)�����v����kM�&�_]��-�u�����VvI����ڢ1:n����t�Za���d}�%��v��idsj+�p��Ҡ0`���x;�u�/�kD���b����b?{�X[�Fk���էMc�\\M>������_*qw���Դ���B�t�kEVφ���B���ذW�*��l�6m]�6�y��D�K�� ��Ȁ����X��d��l/
�MEq^_��)8ov����a�l`��~^��Ct�8'~��McV�L���2+iM�d�nW��^�n����n�c�/NP�������y5\�)� }��ɛu�%al���q��Ap��1�t�5��u�/q��y^���$�^�)�4&��`-mP�yފ��o5Y�.��l�9�}qM/��eW���l���E\���ʎB~�&�ƀj,e������&��m(Ǿ�`Q���c^��}�S������Ŕ�><]�,ﶉ�&Ŀx��*���U����S!G��}�U��*��3b��=�U��*ӏ�����YU�r���<��沥��e�O����������^DFv���zm,���J��2�����"�\;�{�<��v�,A��ba"L�����NI0�B6-j�K�����GBR"�Xu5�`�}��Mq��P�ިu��T��HӧG�9��I���쓉�+��T�A�x��ɚ➊F���x��>tx+����Bv�>�� <�S���[y��+��e�.����NvΈd��I���ɰz�}�0_q%MR�R�C=����/���ɪ��h�5M7u��zZ}��2XX}�*�z�9د�ΆEcԇ�d�i��"��������U~�Hoo��z�t(*�	���/�x�J~QYw�c6����d��ѢR��WT�q|bn�J����g|� ������DZ���NR�OU�š��:cg���<:7�e��\��o0��L hӘ�����{@(_ҎV���a}fGc��Kʟ�}�b�>��Ɋ��9��<H
[ACI���Ԃ�79ۆf��d`]���f���O;"s�L:�%��CMŪ��M��9��9�l��ۨf�cU93$1^�����썾�L�(aј�^ ��ybz%5xwτ�*��%m�&�t����5���C�v+��3xgј�� �m(Qj7
�%y&Nk֏m(�5;�m�	K��j�<�򕰕 �u:�����d�1K�[���9Bn�k�{N��S���`��RSC3�����ܪ��=�sSm���.a��'�p�m�m�K��x�%�u�z�������g�O';�My^�Z4f~���U��Rcf����0��U�a)x��qt0��mU0���h�)~��~�j$��τ|�j[L����訞~#��C��zs�#�֛��_�u�*����/�VvF�����hL5+��Vk+�M��1����k�VKm�D�&�Q�o@M�J�v����}oרm�pdN1.�f�)�8Q��3�Qq9�C���:7&�*s���T:�)C���{�1Kŀj[e��j��*����@�����J���6y��t:��ζљ\�MvF�.�;�ִ
�ڳ�ݾ��|�iEgܴ��֞>��sP�6��lj?������4u�?�f�v};�m���������HxZ_��'�ٷ#�ن&W���t�=�/$��,�ey�n6�2s��d�W��+��< �Y�ʦ1+���A�e��+"%��.��z���V��e�-M�����	���.�s@U�?dH+�sM0�1�2 �X��_������8J���T��K��!�sV�����w/��A5���^^��6���=�Y��9@nZK ��\�qq��8��5�k�)�.��!�l���~�����rՆw}b�C� P��4�#��cō}�+��m=W0�����j��������vU���߾���-(7%)BM���������/��50��ԩY�Fg]�gkV';b0P�<�!��,	�
Զl����(*�]�8[��K�����ک\>a�9cڛmK��`h��u��ѐ�d��;S������3��`oߣ��&�ii

�|=ڛ��+Okr�����~<:>�vÿ�ɸ�( �u�%B�3��+�Lu��vt�mў��z�����Us��:]���8�����;���gHc6�B��:P��g���y��p'a�G�k9���6�Q��;��F���ӡ@��ҳ!��n#�~q�\0/?Ɋ1*հ�����˟9־=)��8>/{�O�z�!3A���Y	P��RZ�o7E^d��>i������ɜk�{%��k���#������5�j��i����־�}2j�:��Nɰs����TlZx��mD��@�&LWO��m#�\]��4}�f�~9���������L�'癤��ϾOѣe$^�	K��6�.nIzZ�P�+�cQy����Yi�.{Y�b?s��ˎ$�^�e4�������owс��vνy%���������ߣʀ��o[" 
x!�i��~
� �(02Q/f6��k_����K���?���^���Cm`����t2|�����C�z�o�:m��-�5�3|J.\�`?{�w�cL�W��!�Q6�4�j�#)f��g`�<�:�M�I'|������ن�5
��W�ab�h;����s�v�-�(i.l#g�]�z��~���MU0���Z4F�	`*-L�y習�h=��	�eFNa���Kՙ]�$�;A]�&��~6���
-<��ƀj�(5����~j������b��r�MA*^�鬫0��Z�E옱:��4��U��O*�%+��i.�󧶕]P%���4fj���)h"��_�Q_�iP��O[�VvF��j3�1�r ն,͇�J���펰0h��m��{RB�.*�;����1a�pxx?�C�LY�#\��i
-V�))g[�d�fZ_>�lZĮ�i�1s�Gf���6�Vچ���qx˦=T�����iV�r~^�# �f�H��[G�Ng�N��Σꌶױ4�#?ʣ�D/o����U�8�M��2�c�ؿ��v�-��j[? )�S%��P�QvL��]��Ex�JZ8��eS%\�矕��!"|�O�4� ����mG��z^,�� �J{����p�Z�&�=��mC`3_@�>�z!j`ꮚ$elfg���v�ׂs�,@�=��MV�>��ϯݕ��p-|���Q�K� Nq50 u���i9��)�	;碆:��/9�u5 1��: ������^�Fkc��J�G�O��^�����۹�O�I���;m4�6��0zEk4O�)�x��>��y�P8C�m��rbx%�C7�G�)�_���t����P&�Q�mlt%��H��q�s1o��o� ��8ε��ݬ�w����vѦ�A��I�]�ǑM����i��Fl21)^��Q����hĊ0����,I��pt��a��Cv����p�1z/_H����]}	N�tu� ٣5�!����.Ŧٗe���.���b?�Vvʵb�>#4T��z�:P��X{rM�O�NU����}��]Q��.�W%u��l���lP;��Lz��Gh�@%6���1��z,��T��k�o���,!�]��-\���~>�����ib1Bc2a��U�� �ɕRXMG�i���t/
����f���ٛ�-{��b�3��.�N,� ��l�^��7PY{�KnzUNT���T(>�ˆ����m���	��^5������+ӿ��>�N�^� *5�6$�E�V8(p��X<i��%=dQ�u٫F���v��	���*���N�    ��e������i�v�0<^�t�k�3����[����~6���p��T#4T�JԮd�T�4b����LkT���v��:!�n�~�Ŗ��s��j'���'�nHb Ǩ�'���2�X�p��ɷ�ti��	N;0׷��P� u��l�X���lH;�1�y����x�-P�y�h^\c>��u#����}B�c87���q'[֟r��j'��^w�C�|�ِ��.�i�:�h�܊<"q֜�4?��UJk���Δ��|D[ѹ�'gb��`� Slaʹ��ނ�Қ
��Dw�1�ϻk}EuV�k�t��µ��g����(����P��0��8�BNf�U�:��!�on��a]_��iM�e�)�����3�����И�P{�������R���)E�[7��Z�n��p��}���Δ��P�{��S�7Bc@� *�@��\
���!���<��Kޛ�R�O�w�C'���R.��1}+�)$���=Bc0%�)�1�&W��?���������8N�S�׻+ŵ�j�/�K���U�*
�j�ƀJ_h��
�
��]��xr���C�2�.p���gZ;A]֗r����K�<z��P��5�yU�r�V~걥YXo���󴤇{�fN��/�0�`?�Vv�5�)t9Bc@� ��@��í���6���)M��]�������ײj�*_֛r��j';��{�R�4T�jTf*�h��t�-��}wHH'۰��O5ߜ�3�Ǘ��\����.8�>�Ԁ�@
�T�������$8��蔒[~�x���W��s��ۜm��.�M���G�ݼ��i�:Bc0o�׭�Sa�H�����yp>o�눜.��5��uYo��~>���r�}�C*xS�v=�r��0�������p���&�`]N��X֛r��PAv"�W��e��6��^eL�����%��urL�vs(�݅��Y�\,�M�����M`?oʦ1��7��*3���>�����	����5ۚ1�n7����X֝r��j';̫p���)�mP���q=]ϱdYqPx��(������8�ĭ�˺S.��Ame'NpP�4Tp��;%Lp�X����
D����������b���-vk��LP;��J#�}�9��P������2����5/���ۺ�ևut8��t���G�bYw��~>���
�<-�ƀ
�V6��DS��LFSΈ��M�=gIPmw'^V)�N�_,�N�����#N��Ie�P����U�V�Z"&'���>�ly��d�Է�����9A]֝r��j+�0�&���!�*�,P��S�&AEu�I��9g��Iv=�o��/���\�g�jd7��5�����F���� ��`Tm�:*ӳ}rO-Kt:e�` Ԗ��	�]�ŕ�e=*�����j�y�ڧ1��GE�*i+�<�>�+Nb�s��\NMr�1�9�R����lP;�%��+-uH�J��Am1y-��6��r��
Eg��.�5���Ar�/��Ame�R1���ƀ
aCPMKz��W#���E>rVy1����k�/]�+���������p��"�3����V�w�m���X���5ˆFwgd��{�b?_�[ѥ��������NѯD��-ȏ$��4|������S�a�w?�d;7��� ����d���6��m���0���^�t�M�6�+7�3#I�#�0�Չ�F[.-p������X#�@�u�Octvj[����ڳ4�Ͼ߂���%�6E��]Z�?�wז����袱�$x�x����꡶EG�yp��t���b�d��l�=����u~�N?� �m���$�.W�2�J�[I��t�����O��vL���Z�����׭��[6@�b?{1��s	�y�hј}�h�m�Pަ����'A�v,'|��kT��1r� ���|P[ٱ`�x;s4T��Qf���SH�-s0R�\뱥/\+�dP��ak�Z��][Y�PjRo8hP�?� ��ی1g��y�]��'r�e�.�9�#���{�X6\�b?_�[ٹ�#�;��@cT�L�mԱ��H��$�c�d�sx������9K��.onNP�W�����<`���sHc@�/��F�Ig���3�����Ϻ����Y{om���`���p���oG�m�1�vv���-o2R��>	h��\��>��<f�`�3�{�	��?�F�l������q�Z��~�����b;��m��罏\6��b?{�w�#��8퍆j*:�̍m�qi��V�g��H�d>��vy��au���bn}*omm8�6S���R�v��O}*�l����jC!��0����J7���x�W=^��Q1�^�g�'���i���F�z�hx�W�(��%�C�`1��(�����fK�(3�_nR�W�j5r��U����%6_��\��~�隆�t��^q����y��|�����Jb�D�wo���z�r��W��C+�y:?m�v�R�<9p�a)�M�v^�˅+�8��9S��7ѕIy��LҘ3��^���� ݽJU�6K����L]�wٙ$����l�^�7HMՊ� [��9�A����0���_Xw���`D�������s�����^ӝ�c5`�s='�(�F{MoF����1w��{�iW]�Ϧh4
�|=7�S�"��{�x~�{Q�'��yO�Q��Q0���f�x�<���g3��j�[���[aV��`ӡC��LL>{��X6e䙣������ �b&CsxP��)$��-���`�Ӡ.������VvS�ѧ���լc1�1�0:i9�r��$�X�>okLh��˩q��p}(��FN';�X��6H����F�F����MBZ�š�$��n[��j�(���t�F������8����i�@�-G�#+
����������1R���$�8o
Բ7�.��������ϫ�!���Y��0{��h*�JM���e��]vD%�>w�C*�g٠Ҷ�37�X�����]�[��A+oW�dkת��x��_��݃���%�޼�QX�y�d�Ӂ����2J��}\�\Ɖ�����f&	����@A��uE��^�Ж��l�ɢ���,�tޯ��|����r���R^�ֲj����3�w��}nH�4F�%`�lLu��Ӥ}\�4u�t|���e�9,N宷@�M��.�*��.�*ٗ��.�,_Ee1�XhzU��&%y���01M�Y{�5,OҮ���/e�~L���q�2z|-��-�I}
�ҶJ�I�E2����A}�GQ�Yz���/�!T��/�{i<J�W�^�o��'��|����N��]�q�8��e�]�gF��l%4�6�,��f;��¼����gX��fR��G~iȽ�%IS���=v>]R��]��*���njH�Ĭ!�U����^c������y�gau
7eoJ�|e�������]h���#:�1r�U6���1����TYMX~䴻���D�M�;��,BN�I/2q��j+;gy�A�P1��G@հ�"� hFӑ�5�yϑ$,����)o��JG��{=��$��tа�M��.QC�쐟��c]��1�o��Y�R/�q�����"�U�aHc�l�^��7P��}��E�.���'��ļ<]7�����1�7Έ�^6��b?�Vv��W*��@JRbC��2�
v�I��I.U^��3�>n���s��z�����|H[�	�I>�)H��m��@N���N����~ϼ�xw{��>�G48h��R������6�b>��hW>u���Υc��Oߟ����ć8��Q�j�{��OPb�{�K���ؤFq��ĦϞ��fθ|&��=IS�t�I�Fܯ]wI����0.����q��hF�[�g�`�S�����ʘU�B�lp���v�u�n9��uO�-~�J5��!�T�ȗvZj�I���<?�q�!%g���\6R�b?�|S��jdi����CL)^i���֒�\�k2>
�4��R��o
�]a�*񙗚��ֳ�����m;��W�V<X<��iKKH��O<֤I�8��^�O���ԶUԁA0��I�n�    Ķ9L�$�b\��$h������L��y)3"	��ڶz�$t%��hx��H�<%���0s��D����Ic��J1���\�y�B��b�D�NI8X�̼�x��O���9f����o��ն1C�I��4�y	������"��ۯ��~Cs��]��r��H�]ţۭ��<��$N�k�:{r�e/�]�����DKE|�t�4F'�:�7�y��5�h2���Y�\���3��wQ�Ø8���׎.��AmeG
K�j�ƀ*ԁ���e������,�e�@gh`�tO�%#�ϵ�ȸ�c?z����I�Sb�p�v��?���640x�:RB'W�!��4�Ǌ��=��t!U�\1�^_���_1]�I"��ɤҘ� ԁ�fԬ`��#�O&��Y2q�K� ������C@����ڸX�̫�5(������C�V��o���;hC-��ECӰ�q4�6�(zE��+1��,�@��脸;O���ǌ��֭�?#�)@(�a[�S��~t�b���1/�(�d^�"2R���g��gR��J|J<����|&^�٤%B��)������&<����g�^6���~������'W�V��Q0�a�!¤�,HA���ac��/�����u�Y��I9�a�
c�����[����!hEV���5�F3
���F���1��t�F��\��p����c��NS*����LO�F���u�����p��g���4��es�\�gn)�S���zH���;V6�䕡���ȑ{nC��5{C���v��"���c=��|���2��6�h��޳�~D��(0����~4��'�����ؐ��� }!�ƈ�gf��駎U�_Η�H��8�#��m}�`��Cвy{.��7�Vt.�W��!�ْ0`JmL�9� r�4V�˱#9k���&�&&
@$��F��X`���6[�G��R&D���)��]p?��nh�]��K�o
W~*0ZT�]��<��t��k�W�nHc�� �b����~*�4��& >����ʎ(�+�:�1��+O,DB��[�������v��f���}s����Ʈ�8۹z��/
���<P?d7U�=s�m*��D٠���gO_���
�wT�:����&�5�]Y--���b?�VvĸB>�O�4T�e���>aiK�?���e�qǆ_�&�;�(�d���6��DLw��wq�	�`�W��4������!A�^S���V�NvA�m��=�ۓbT�2���0j�S��O�	�9'���6�er��������5+6i��a���sΗ�Eu��g3|Ȏ�f�/ܦ1sn@�CP�\�4b�1�>޴os�,O�]hx�XR*��"���w����g�m������uj�@�L�G�7QóKq�n��-��KE��m#A�^���Q��Cv���W_�!�Q�rTn
��S ��ޣ���nH|��4��-:o7��L-]w����v ��#̘�Y]C*�9����r��\鹷b#Վ]��'�d�T켿�Z��|����`0��g2��z�&�_y���������n[«�y��N�?l�/������eC�.��7�Vv$�b>NҐ�`� Tm��M�u�>�ٱb})bĚt��0Y��
]Ol�u��l���~>���
�W��!�4�_y�s����%��$�l�i��mw�ԇ]�y�V�eC$.��1�D��*����`J^X��}�)�ڦ"�b�?ZǛ]r�e�_��̔=ڝ'�ˆH\����.%C���gHc@� *�@%�<�g�OwǛM��sy�����k��_\%�	^6B�b?S#:^IW��!������T�0
�*&���)䷈��}wX�c�,�\R^6B�b?��d��1��h��80�q0e�MQ]���uovHo1�\�x�6�mw(bg,/5p��j';EBy�R}� Hm�>�ЊK�Q���~;��^.uulJ��EupU xY���~���dg�J�Hސƀ
N9{t�+R�;� ���џ�{��7.�"��m��&=;ãx��=�3��]v
�U,{Hc@��IԶ�ߊcI�A=�/{��Qpb��;��eZƮ�/�������j��/�4Tpp��AmS��TMSIu������1�y������,�M�����]b��?�}����6���^�@gY�6��^ě�)�t�3\^cW�?B���\�����w|ˢ1��7ő�6�%�1���G��$<U��5������rp.��;�b?�z��*�|]T�ƀ
����78�2�&�%�:�7U\���&>O��۝�J%˺S.��A�d����i��Nqb�J������i�*8�ɍ�8��%�6�<�1	\�Y֟r����M_Z�R��0O�ߢ1��?ũ*1N�3�ވ�,�L��)I���|������e�)����9�#���$R�8�!m��(��EĞ�tYo�H������7�b�P������K)���%��N���>��plv͡��;�*"MȲ����|P[�%�+j�ƀ
���)fY���~9r'�d�噢KR㨀�e��5!!��S.�c�N�:h�d������ƀ
���)����J-'���A]���	P�v�Nv����'�?h��Oq۟b�E )᠚�S�UὉ�kt���DP�*s>�[֟r����;��7�jј�x�O�GJ����7�A5�+�]��C�F��1���S|���	�����LP;�ъ�};e�P������R�S�'5����d���6�f����=ٝ]�N]֟r�����e�k��3C*�S۠����x��FyL�Kɪ����֤�<,��ɽ����\��kj+;FRxFSI��M�o�4	Ŧ&&Ұ��}hʻlAm�Լ�b���<��a��u�M��>��;Ee����jtY/��~��x���8�~���4f2���U�1\��k��M�\��"<�9���MPƹ��.��;���-���֞786��8�-P�/A��c�䛣�����y٤ᕥ�����rЅ��8���\�W��.��>�P�������X�'ri��\k<!G�j�%�o���]��.���)���į�趍�%���=��k�T�e=Q��jщ�5��i�ZL��)1y�HKS�xiP��D���KB%|��i�p�Jd�j
������T��t��SN��:h�%�ɩ�����:�.��1����^M}�4SpD%�1Ʊ2%q��p߳�A���,�1k؝'Κ$�:�.��,�ّ�ثܐ�0GTڶ(|�����rIݫs�&A'[����|�>[�u�����쀉����4TpD�mh���
S��S��=��p�\P��p��c�"�S ��#�b?T��F��ސƀ
���m�^�c���L� I4�}U&��z/w���䚸*��#�b?T#;���xu2�P������Y)F�������P���>���]�f�w+l�DI������ѽ=i��J��6	UzE�ӝlpz�m��a�K����zN���g�Gw�����zH��zHc0�P�^W�9����</0�nw�	n!J���b�8��e=B�����c"|��l*x��ѝR��iɥ��<�ء�qDh�>�":�bv�RD��RlYw��~&��sA���Mc0wJjӶ�*�pPM��o.�;޲}��d�2cנ�n�j闀���J�s*�8�L��i��N)d��̋!����.�O-j+;ǜ!ϳߢ1��?��*75��#�O���4M�xs؟�cy96)*bV���g|Y��~>���RE�A�Ә�m�O)b��͇��sp��:ʣ(#�]]DAZ�U��Δ��|DuW�� � C�(8S�Z��6�"��'��>�й��v�����nvד��_֙r����]�$c�y����)�lP�IOWt�8�Q���l�����i�c��/�J��χ��\0����@c WJqRabXH`%'���A]֕ZT��0��SoL{$Rp��� %�\!���������|����c��R9�(|YO��~6���I!E̫zԐƀ
���CP��5�}�d�/��	7�:���H�(`ٮv�H�e=)�����c.����@c@OJٞ �  a�K7�'���keQ�7������&�c]��.�#�`?�Vv���̑�i��J)ە�Ĕ>�����ͱ�|s*HX(���x^�A��:�˺R.��A�d��{��4Tp���J1b�@$�h��/�u}ܗ9؆��u��[T��m�.�J��������~�#l*�R�ѕ��5 �>1]�+����d���*��P�Jg�T��+�b?�Nv��+�<�-Sv\)M,PMRY����e�?EMX���V0��x}�X֙r��������34m�L����A�m*%�S�s{��瀴ovF+w�g�Y|k% ��tA���<�l2�&�6��&u/�e�8�y��!������զ1�	N\���2��L�&�$&�g����%��6��gi��Ųn���P�����+�lHc@7�߇���.?Mj�Y�x�ѿ&U��&���]>��b�-�:��;-v�%��=!ȯ����I>C~��m��?^,M&7L�tH?��ݫ؜���/|�s<��΋?!��/kw[����ʼ�R����NMU���lfq�;����eC.��6�ى�'d6�1P�*�汌�r�!��ہqt̲��"��tt^��ec.��1�D�+���L���Z���������      �      x���I��8�E�a���		����N�����t�V�<�lpc�6%�)�/Rp��*���_�ؕz�
�*�/��_�������_��b�����f��K�k�=/�g��UHv�dzQ�^h¶�ؒ����oʾ������A���^�Ö�4��ҍ�).�]������%=Co��5J��we����[5���s%~����j�Gj���Uz���g譚��Z�E��H��3�VM~�������U>Rc6����o�z�Fɇr����?!���Gb������{��C�/�\❐�mc?%j��e���h������ ��ʩ����@FD� �Q�!mT{%ą~d%�D^}J�˝|@I����
�Y�dV��E׊�B�/�>B�2�2.���$� �0z�łk !�����ɸ�S�u����D��ܵ��(�RP_���o��LU/%��L��.��D��J;�����{��#1�W��K�|i��'�N��S���Ԃ/&���{�^�~"�0�3��z/�>��p��R�z/ǿ�|�r����!���P�W��W�G�8D�7�2�eC���E�腁����
�5 �0^�{5�fr�|H��|�x��}�$��x�轚���`��� ����j�5�@���'v�+�J�_"@���@���j�����ĳ��2̺�3�^�~����\�~p�ޫ���%���g轚��ؐ�'��̣g轚��X���N^��+��{5g��}	�J���'�"1�RM*��-��2%���Ӆ;������1�c��,��<㟨9����s@I�|����%Q�� ��R�>�&|!��#{B漏�/��˰ƣ�����9q^�W)%���!M���b�Ө��v�n�{mz��=�1�E�mqB��J鵫L[�)+�u� �D�}1����'>��~@��g�X�KA );E����X]X:y4�g� |&̖3�K*O�{9񡜇���x�r���><֙(Ρ�wDg���L�����(?C��g��dp@�����r������cM���'���?�q
���w���g��0l�\!�P��6̀�M�T��K:���.��II�d�����mÐŅNF�� a��׋`�R�U]�	cp��K�����J��Ul�A|����W�^>�
l�p	����j�5�ha=��П�Oδ���°=��E��W�?Sü�£�����p(�D�m�;��R]]�tU��>v��G � a��k���8�of�B�3�V�#�Q��_%	�8!���3��=A	g�ڟ���ҙxW��c����8�H;�<d
�(Y��L0���!�E��M#�x�#���/�@̰��{9�D���}��z/'>��/��]��Jދ���������|�I������i�C�S�d�~���$����ӹN��>�������E�s�D�F ���R/4�hXא��w�%�\0�f�2�g�ڑ�����{��9E�LM�7�G[�&TGɮ��'��	y�@�s�^�~��6���p�H��B7(���l���'3D��g�ݦK�8�w�WTM3�W64=a򸝆d����sg5~��?"}~_���N��g��9܊a�֞v�p��5j+�@2��3�^M|��1]�9	�^�В$Q5�c�b>�ZL;k�	����`�U��ov��P��Eql�]����&..���p��A��	���س��d۾-TEb�\|�ve�7z��=�#=Eq���^�j�Ʃ�+�04]|G'9B��r|~��^��d]�p��Y��S��ut��Nr�o�I���?����Ns��2�@dl.G&@��"��'L~傒�E������F6�!l�VNI�e�"��ɏuրq�'��y�Ěe��a&T>�Q9�Q�_����BJ�W�
=����#2C[&�\�V)�om>Ղ�E::��Q�z~��3<��������n0GC�.��I����`���a����J��~��J`\i��kqHG'���V�XN3��!8C]W
��Ґt�.<g�5�H�5n�LL̈/��P$��EȧM�<+�9���E:z�,�)w�?������Y[�u^�nK�u��t��[H߮"3�VgH/;�3Q�|��&ʖ���>&���K���������S�.a��Ԯ]���J�-}	��is}����c^a[˻��{>����	�h�.���!��U������������\����x/�d��%�n��Ҿx�a�����º����|�w�viO{���8zɟ��*pF|�A��轚p��o!�M�)'��Ws�o�����^���^��Kn!={Bz��,?�<cM�n:�*��,��	e���K���W_����m3]yﺛ�"	'��#ò��{��8�<�>�{D��~��44���i��������r�Z��0x�{@U��8̗A�TҾ�l�(���`�
�N,렯h�gՄ[�S�w��ҽ3T(���|>��Ӏ>��=��lK׫>�b�g�Qq��
P�13�u�V`n%��rA�0�3��~	���>lj�r�vb�&{v��8C�6��1m��ۢ�h��ImV�s�M��[�3_�3��t��P5;@�Yz��3��S����W��Rr8Cs��B`�����G��}2t�/��Pg98�� ��/ΐ!Q���m�F]EK�fa��IW�Ę��a��,8CKM"S��qm�)���풣\����I8!���!އpT*Ry�v�m[_��B���0f_t(�Y@��҇ᬡO*F��I����9�����B�Hzߌ�J�JUL}��k��͢Z��h^��M�f�(y}��[�%�u��T|NQ�r�~¬!b�#��p��	�ɰ�aԱ�V|�Z�ѻ����s4������ȹ���e�QLUѢ��,�Sv��n�&/a�m�r�r4��6 ?E��IQkQTs�y����`�U��(�>oy�A���'t"眢��ӛ�8�<��:i��5O ��(1#�f:�(�~�p,s*�Jb�Vƌ���9�˴�Su���U�]��\��U��Ǣcy1����e�r��m��w�3|����Ѻ�	�h���.U%��o�]�Xm�s�"w�v��-uQΤU�P��|�����pk���/�<?�D��ʱ��x	۶_��iK[�Q��*�Xo�r�@�p�Ժ�nϷQ�m���Y�	6����1�X����s�3�wg�N�����$�"��(��Hd��|��A�(���$ъSw�x΋��H��9:���lA �/y��f��دq+�v�L�5�9:��}�$��{{Eq�*҈(�s��v{M�l�� ^n��KZ�_���4�i֢'b\��լ��gۀ���� �)د�bٔOd,�A(��y��~�;:���c�M��_E|E�l��k�ƍS�Ֆl��A��i�x����g�ݙ��	@�P�����=sGG9br�ma���Ȅ}[�)2ߗ!���(M�st�[Lm��q��{D���1���<dY3�bU��ӷ%>0���)z/��*ޱ��v��3���I٧}��jR�����=vr���'��s�P��s��0�Ȳ��(V�cJ��\�;���v'�
ӆ�I:�(�q2�I�4m�W��Un1mX�z��5�4���v{S��z[@-�Pps���~���U�?��M�i�uh��?-�lS-ʹ���1�X0M����,�^פX#��2���aMn����&���S�dj6I�5BEMX͇���ؘ�NMz�p��5+za(RS�K֕q�rn�r��W������GDQ�/a�W8p��L������b��m�|�.�}%&��&dl�j�?��V�M��Sn!9s���m��bJ�p����t-3���)���l�ف�'dc�)�I�>�Y�sQ6�����Q��*i�A��Ǟ_�T���1KJ3�\�S3d������Q�Ѭc[P9q���wWC�Y��D��E�;
��l�$�_����0�½؊�'a4�K�pGG�6I�_5)V�\�u��9���°&� #  6��<.(��(�ON��/��n��T���_t��q�i`���D9GG��<Z�q6�ً�="�l6]�f�IM����S�ptj�Vv������ն8^1�Z:����rR�|D9GG��<ڈi����'�e4V+�4��Z��qV�@��rĴ��0;�A���+��)K{C7���">�k;�0��)��`+*O�݇�WR���X��$I�Ȩ}E1�z�����z
�`��8{~r(c���Ÿ�XW󘍕��=�~wn�fbn�ŝ!�3u8�Ŝ�lZ����z�9zʟ�phy�k�?��s��n�����C7Q�s�ӷ��kkz�0�y�gP]��u��Q��Sn�鱡��0x@S9��l�Z5]i��dU�s���e���{�BY�!��8�3��%W�$R{u��Y��4  |8C�5븧|+�J���+Zo[b���S<�f�ʸ@�P�N£b�M�wy��,��!�B�s����j�����e?����u5�i8Tj�P�6G���=ų_�8.���Z�t�D"fV��f@����Q��U<�(d��̒�o�0N�q,�23sI�H�u�ED�ӱS�;�qB��Ap�ږLS	5�Z�r6����*{��pW�q�7��`	��\�d�d�>�8;\�c��wL��_������Hݪh
Ϣ�|l㜯�]�vl�����mc������ѽ���)�mW���{�r���	��`���ځ����g`i��EjL11rl������h�g�g�j�q�J�O�a[[��0�ke��W�v��?	���R�f���qW�q=�8�c��0��8�A��Ϟ���bO;6oe��:��<�Lg���O\���d韢^�e>G�ЬY��tHM���.Աi�S��|%<��I���؝�cӔS��3(a�
�M	C�t�e�n���9�'��P�5$]F��$ܳ�~���3�fmLv� ����]��+9�N��o!9����Veg�D�95�}Ǵ+W�����Љ�����	pq�Q��VE��V�q�F�xm(�4��'�n[�ѥ^n�=�u�Kڭ��~�$��Ӆ:����6Y2�:Y@C'6��q����f.�&�1��8kc����(�1�����ȹ������S��Mޖ�R6i�t�8�2mhO8rta;V�q����{B������pN��hMb{��c�,�V�vރ�0�����^,��#�4�X�ɞ`Z��<�S��^�������L�L�D�m�-�<ű{�;��	`�>qxE�K6�U�3��B�.ʘ�@pl����۬��Dʗ��G���N�sՏm[���f��
���K�����M�mS��vZ���!��p7h`����!���l��	1�2�A�4оj����){����x�9�.
NQh�f	�	��f*ǂ��"�st�[L{����k��e�D�m�^����4���"�s�Qn1�fuDb��"w�jZ�f!X9��Z�u�G	�c��Q�����=�����$��0'�Z�YؠQ��Q<[x�3,x ���= ���*����Ǣ�B�hd�9v�ژ�Ѥ�]9� N�:��܄y��[���6e8�(��'���̀bbCOѠ�2/��B���'t�ƭ��ژ��s�y�qA�}Hf_��Z�X�$��Q�6Ӓꢞ.̱���.�'CyB'rΎrl'��y�z���MusQ��ۋy�f�uM�:A9gO�}�"6�g�V�@�¡͓!��y�g�s��Ҿ�'G[�{Ԏ*	�0+=�dL��Ј�U蘥1�0�̇� ��
ժ&���Z�E6�$��,A9�Z��#��;���~��5&6�\�i��-�J%���k�r��r�)�Z���㑌|�K�1�t�Vd�
ua�|ruv��j�5����UL��G}�Y?����h��+�[L{0�U�Zp��|�&+h���NPT(��*��nN������|@9g�R��0Ѻ��;�
a���O��qz��Ǩ��H�*���5M.��~B#j
Qα�9b2i���L��ѢhI=���@��kFu,��]�38N�$�����XM��bA��K�gIa�����11k%�ʉ'�ߔ{Rvٖ��6��LҘ�R$
tL��)B��G�`?8C�4���P�e�޴@�z�8�9�)���QڽC\��~�����3�5��:MUCi�ڱ���N�<`��34�K�ˆ�0|Qw4�6k����h�c�v��O/r�(6>-�I���Ѻ5>;�.����ɠ��P��^'Ej�0����(��)��p�AiL��{$jJ{MCU�:��l�n���t�����<�a.Ei?���6��"��)�5��:�.�[L{$zp�\J��P8g�� bX��:Z넅˅9v�~�<:<}��S�"���H�6��)��*��]�%�%s�:��v�_%��'{~B'r�B�б������ݣu�}�0G7m�e�vW�"ʹ�r�	�a��o׻�������v�dIG׌)�r�x
G�0)e�|3�{9���o��!8E��!?Y����H���0H{4�}v3�� Bu��,T]���җ��OɒD�9���bڭ(W� ���-gU�Ʉ��(�r�T���=�ؼm�����i��`���LV���do���ئcn���矡�k���M����s��e��c�w��S A�7<���GJ���ff���D���E{�i���h��Q:?�a�IK7���d�
YU�B�]�GL|������8Cb��JB3�l0�
��tmQ�9O�1ّ�L��޼�9gO�1�Z�5��֩K�I�~�CS�����r�����ؘ��	������x�4��m����.R�s�Sn1�A�>�˳�G$��}�M��c�V�t;�r�.�[���� ��u]��9|!:�M�2�#cU��E{;~����!NQچfn�6ͪuoey��)�0�.�[L8N)A��O%+k�i$��w5�U�k�-�g����b��B�u��{,�疛���9#Ǜ�����Q��L�>xF��y@��N�p�H6�mEY�P��U�wG��pf��t-Ob�˼�u�S�C�Eʹ��1�	{血��5f�vZAEٴ%���v ���1��e� B��{9�N�[La\�\��{TdY6Ӣk�o��d�N���>p����<Jo�3B���<�q\�J�ufCW�k'���c�g7��|u���FwQ�TT����Nʹ��q���S����|@h`��+��U4�z��G
�g��*�h�W)a'�D��S��"l=E��3��m�/t۲,����Xw�2�A����b�~ ���˨{@Q����\�NѾ�cB�F�~\�ho1o��	���{@k�q���R�"ƩøO��>���/M�{������T���I��1̰nu����b�����3���7����vkA犌u��s����T�=C��cg�\g>	���t��C�N$¼��\;i��6s���z����bc�ouGɲ�qv�q�������ґ��gDS�)JR['0��*����9z��5���BxE�֥�{���{Zfc�Z�k'�<� iWi���Eϐغ��J���
y����8���GL�9�nȢ�	��pη��3�&$l)�.�w�\.�h�g�      �   9   x�3�-.M,���4���2��/H-�@|cNǔ�̼�⒢Ĕ�"Nc�`� ��      �   2  x��Q�n� >;O��7N{�i�^{��Ғ��t�?Z�h]�]&![��cK8�4D\�8G7�KA��䨡��nDH?����
���޻i�څ���v��Ɵ�8崡��f���*Ix��i�P��n�c�R�?b�����Y
��1a�5�X�PS��Ri�"Ze�+��-���ߌ?�g�\�L�5�y�Y��^z�B��~�l�@�R)���5��9��Q/5�l��Dt��r�p����e,�R~�+{��@�9�,W�֦���Y�������+{�M�V��@�x��ۚ�;+5Q��W�[RU�a���      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   "   x�3���/�M��2�,(���O�������� n~�     