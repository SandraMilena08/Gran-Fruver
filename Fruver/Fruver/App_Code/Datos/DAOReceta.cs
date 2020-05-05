using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOReceta
/// </summary>
public class DAOReceta
{
    public bool insertarReceta(EReceta eReceta)
    {
        try {

            using (var db = new Mapeo()) {
                db.receta.Add(eReceta);
                db.SaveChanges();
                return true;
            }

        } catch { return false; }
    }

    public List<EReceta> obtenerReceta()
    {
        using (var db = new Mapeo())
        {
            return (from rc in db.receta

                    select new
                    {
                        rc
                    }).ToList().Select(m => new EReceta
                    {

                        Id = m.rc.Id,
                        Descripcion = m.rc.Descripcion,
                        ProductoId = m.rc.ProductoId,
                        Nombre = m.rc.Nombre,
                        ImagenUrl = m.rc.ImagenUrl, 
                        ListaProductos = JsonConvert.DeserializeObject<List<EProducto>>(m.rc.ProductoId),                                               
                    }).ToList();
        }

    }

    public void actualizarReceta(EReceta receta)
    {
        using (var db = new Mapeo())
        {
            EReceta recetaDos = db.receta.Where(x => x.Id == receta.Id).First();

            recetaDos.Descripcion = receta.Descripcion;
            recetaDos.Nombre = receta.Nombre;
            recetaDos.ImagenUrl = receta.ImagenUrl;
            db.receta.Attach(recetaDos);

            var entry = db.Entry(recetaDos);
            entry.State = EntityState.Modified;
            db.SaveChanges();

        }
    }

    public bool eliminarReceta(int id)
    {
        EReceta receta = new EReceta();

        using (var db = new Mapeo())
        {
            receta = db.receta.Find(id);
            db.receta.Remove(receta);
            db.SaveChanges();
            return true;
      
        }
    }
}