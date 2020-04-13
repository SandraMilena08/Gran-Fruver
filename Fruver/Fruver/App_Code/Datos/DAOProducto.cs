using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOProducto
/// </summary>
public class DAOProducto
{
    public bool insertarProducto(EProducto eProducto)
    {
        try {

            using (var db = new Mapeo())
            {
                db.producto.Add(eProducto);
                db.SaveChanges();
                return true;
            }
                    
        } catch (Exception ex) {

            throw ex;            
        }        
    }

    public List<EProducto> obtenerProductos()
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
}