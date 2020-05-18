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

    public EProducto BuscarProducto(int id)
    {
        try
        {
            using (Mapeo db = new Mapeo())
            {
                return db.producto.Where(x => x.Id == id).FirstOrDefault();
            }
        }
        catch { return null; }
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

            for (int x = 0; x < productos.Count; x++)
            {
                productos[x].Lotes = obtenerloteProducto(productos[x].Id);
            }

            return productos;

        }
    }
    public List<EProducto> obtenerProductoCatalogo()
    {
        using (var db = new Mapeo())
        {
            List<EProducto> productos = db.producto.Where(x => x.Disponibilidad == true).ToList();
           
            foreach (EProducto producto in productos)
            {
                double aumento, AumTotal;

                ELotes lote = db.lotes.Where(x => x.Producto_id == producto.Id).FirstOrDefault();
                producto.Precio = lote.Precio;
               // Aumento del 20% de cada producto
                aumento = 0.20 * producto.Precio;
                AumTotal = producto.Precio + aumento;
                producto.Precio = AumTotal;
                producto.Cantidad = lote.Cantidad;
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
    
    public List<EProducto> listarProductosConLotes()
    {
        using (var db = new Mapeo())
        {
            List<EProducto> productos = db.producto.Where(x => x.Disponibilidad == true).ToList();
            foreach(EProducto producto in productos)
            {
                ELotes lote = db.lotes.Where(x => x.Producto_id == producto.Id).FirstOrDefault();
                if (lote == null)
                {
                    producto.Cantidad = 0;
                }
                else
                {
                    producto.Cantidad = lote.Cantidad;
                }
               
            }
            return productos;
        }
    }

    public List<EProducto> listarProductosAgotados(List<EProducto> productosDisponibles)
    {
        return productosDisponibles.Where(x => x.Cantidad <= 1).ToList();
    }    
}



