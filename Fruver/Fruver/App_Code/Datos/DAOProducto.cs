using Npgsql;
using NpgsqlTypes;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOProducto
/// </summary>
public class DAOProducto
{

    public EProducto BuscarProducto(int id) {

        try {

            using (Mapeo db = new Mapeo()) {

                return db.producto.Where(x => x.Id == id).FirstOrDefault();
            }

        } catch { return null; }
    }

    public bool insertarProducto(EProducto eProducto)
    {
        try
        {

            using (var db = new Mapeo())
            {
                db.producto.Add(eProducto);
                db.SaveChanges();
                return true;
            }

        }
        catch (Exception ex)
        {

            throw ex;
        }
    }

    public void insertarProductoNuevo(EProducto eNuevo)
    {
        using (var db = new Mapeo())
        {
            db.producto.Add(eNuevo);
            db.SaveChanges();
        }
    }

    public List<EProducto> obtenerProductos()
    {

        using (var db = new Mapeo())
        {
            List<EProducto> productos = db.producto.ToList();

            for (int x = 0; x < productos.Count; x++) {

                productos[x].Lotes = obtenerloteProducto(productos[x].Id);

            }

            return productos;

        }
    }

    public List<EProducto> obtenerProductosRecetas()
    {
        using (var db = new Mapeo())
        {
            return db.producto.ToList();
        }
    }

    public void actualizarProducto(EProducto producto)
    {
        using (var db = new Mapeo())
        {
            EProducto productoDos = db.producto.Where(x => x.Id == producto.Id).First();

            productoDos.Nombre = producto.Nombre;
            productoDos.Imagen = producto.Imagen;
            productoDos.Disponibilidad = producto.Disponibilidad;
            db.producto.Attach(productoDos);

            var entry = db.Entry(productoDos);
            entry.State = EntityState.Modified;
            db.SaveChanges();

        }
    }

    public void eliminarProducto(EProducto eProducto)
    {
        using (var db = new Mapeo())
        {
            db.producto.Attach(eProducto);

            var entry = db.Entry(eProducto);
            entry.State = EntityState.Deleted;
            db.SaveChanges();

        }
    }

    public List<ELotes> obtenerloteProducto(int id)
    {

        using (var db = new Mapeo())
        {
            return db.lotes.Where(x => x.Producto_id == id).ToList();

        }

    }

    public List<EPromociones> obtenerPromociones()
    {
        using (var db = new Mapeo())
        {
            return db.promociones.ToList();
        }
    }

    public List<EProducto> NotificarProducto() 
    { 
        DataTable notificacion = new DataTable();
        NpgsqlConnection conection = new NpgsqlConnection(ConfigurationManager.ConnectionStrings["Postgres"].ConnectionString);
        List<EProducto> listaProductosAgotados = new List<EProducto>();

        try
        {
            NpgsqlDataAdapter dataAdapter = new NpgsqlDataAdapter("producto.notificar_producto", conection); 
            dataAdapter.SelectCommand.CommandType = CommandType.StoredProcedure;



            conection.Open();
            dataAdapter.Fill(notificacion);




        }
        catch (Exception Ex)
        {
            throw Ex;
        }
        finally
        {
            if (conection != null)
            {
                conection.Close();
            }
        }

        for (int i = 0; i < notificacion.Rows.Count; i++) {
            EProducto producto = new EProducto();
            EUsuario usuario = new EUsuario();

            producto.Nombre = notificacion.Rows[i]["nombre_lote"].ToString();
            
            listaProductosAgotados.Add(producto);
        }

       

        return listaProductosAgotados;
    }

    public List<EProducto> Promociones()
    {
        DataTable promocion = new DataTable();
        NpgsqlConnection conection = new NpgsqlConnection(ConfigurationManager.ConnectionStrings["Postgres"].ConnectionString);
        List<EProducto> ProductosPromocion = new List<EProducto>();

        try
        {
            NpgsqlDataAdapter dataAdapter = new NpgsqlDataAdapter("venta.f_fecha_vencimiento", conection);
            dataAdapter.SelectCommand.CommandType = CommandType.StoredProcedure;



            conection.Open();
            dataAdapter.Fill(promocion);




        }
        catch (Exception Ex)
        {
            throw Ex;
        }
        finally
        {
            if (conection != null)
            {
                conection.Close();
            }
        }

        for (int i = 0; i < promocion.Rows.Count; i++)
        {
            EProducto producto = new EProducto();
            EUsuario usuario = new EUsuario();
            producto.Id = int.Parse(promocion.Rows[i]["id"].ToString());
            producto.Nombre = promocion.Rows[i]["nombre"].ToString();

            ProductosPromocion.Add(producto);
        }



        return ProductosPromocion;


    }
    /*public List<Carrito> obtenerProductosCarrito(int userId)
    {
        using (var db = new Mapeo())
        {
            return (from car in db.carrito
                    join p in db.producto on car.ProductoId equals p.Id
                    where car.UserId == userId
                    select new
                    {
                        car,
                        p
                    }).ToList().Select(m => new Carrito
                    {
                        Id = m.car.Id,
                        Cantidad = m.car.Cantidad,
                        Url = m.p.Imagen,
                        NombreProducto = m.p.Nombre,
                        Fecha = m.car.Fecha,
                        ProductoId = m.car.ProductoId,
                        UserId = m.car.UserId,
                        Precio = m.p.Precio,
                        Total = m.p.Precio * m.car.Cantidad.Value
                    }).ToList();
        }
    }*/

}