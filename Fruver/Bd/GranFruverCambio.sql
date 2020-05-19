PGDMP                         x            gran_fruver    11.5    12.0     I           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            J           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            K           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            L           1262    140712    gran_fruver    DATABASE     �   CREATE DATABASE gran_fruver WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE gran_fruver;
                postgres    false            �            1259    140792    carro_compras    TABLE       CREATE TABLE venta.carro_compras (
    id integer NOT NULL,
    detalle_lote_id integer NOT NULL,
    usuario_id integer NOT NULL,
    tipo_venta_id integer NOT NULL,
    cantidad integer,
    estado_id boolean,
    fecha timestamp without time zone,
    precio double precision
);
     DROP TABLE venta.carro_compras;
       venta            postgres    false            �            1259    140795    carro_compras_id_seq    SEQUENCE     �   CREATE SEQUENCE venta.carro_compras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE venta.carro_compras_id_seq;
       venta          postgres    false    216            M           0    0    carro_compras_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE venta.carro_compras_id_seq OWNED BY venta.carro_compras.id;
          venta          postgres    false    217            �
           2604    140823    carro_compras id    DEFAULT     r   ALTER TABLE ONLY venta.carro_compras ALTER COLUMN id SET DEFAULT nextval('venta.carro_compras_id_seq'::regclass);
 >   ALTER TABLE venta.carro_compras ALTER COLUMN id DROP DEFAULT;
       venta          postgres    false    217    216            E          0    140792    carro_compras 
   TABLE DATA           z   COPY venta.carro_compras (id, detalle_lote_id, usuario_id, tipo_venta_id, cantidad, estado_id, fecha, precio) FROM stdin;
    venta          postgres    false    216   E       N           0    0    carro_compras_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('venta.carro_compras_id_seq', 6, true);
          venta          postgres    false    217            �
           2606    140843     carro_compras carro_compras_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY venta.carro_compras
    ADD CONSTRAINT carro_compras_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY venta.carro_compras DROP CONSTRAINT carro_compras_pkey;
       venta            postgres    false    216            �
           2620    140858 $   carro_compras tg_venta_carro_compras    TRIGGER     �   CREATE TRIGGER tg_venta_carro_compras AFTER INSERT OR DELETE OR UPDATE ON venta.carro_compras FOR EACH ROW EXECUTE PROCEDURE seguridad.f_log_auditoria();
 <   DROP TRIGGER tg_venta_carro_compras ON venta.carro_compras;
       venta          postgres    false    216            E   u   x�e��1�7�"�,>ג2ҿ�.����@b��(�Ҽl�����{..e	Ru��Ɖs[Mތ� ��l��ɪ�h�B���:z��L��Z������@w�l��c�/�c(�     