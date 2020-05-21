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

    public EReceta obtenerReceta(int id)
    {

        using (var db = new Mapeo())
        {
            return db.receta.Where(x => x.Id == id).FirstOrDefault();

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
            recetaDos.ProductoId = receta.ProductoId;
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
    
    public List<EReceta> ObtenerRecetasProducto(int idProducto) {       

        try {

            using (Mapeo db = new Mapeo()) {

                bool ignorarReceta;
                List<EReceta> listaRecetas = db.receta.ToList();
                List<EReceta> listaRecetasFiltrada = db.receta.ToList();

                foreach (EReceta receta in listaRecetasFiltrada) {
                    receta.ListaProductos = JsonConvert.DeserializeObject<List<EProducto>>(receta.ProductoId);                                        
                }

                foreach (EReceta receta in listaRecetas) { 

                    receta.ListaProductos = JsonConvert.DeserializeObject<List<EProducto>>(receta.ProductoId);                                       
                    ignorarReceta = true;

                    foreach(EProducto producto in receta.ListaProductos) { 

                        if (producto.Id == idProducto) {

                            ignorarReceta = false;
                        }
                    }

                    if (ignorarReceta == true) {
                        listaRecetasFiltrada.Remove(receta);
                    }
                }

                return listaRecetasFiltrada;
            }            

        } catch (Exception ex) { throw ex; } 
    }
}