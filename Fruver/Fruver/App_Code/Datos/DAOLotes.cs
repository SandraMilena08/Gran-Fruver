using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOLotes
/// </summary>
public class DAOLotes
{

    public ELotes LeerLote(int loteId) {

        try {

            using (Mapeo db = new Mapeo()) {

                return db.lotes.Where(x => x.Id == loteId).FirstOrDefault();
            }

        } catch (Exception ex) { throw ex; }
    }

    public bool insertarLote(ELotes eLotes)
    {
        try
        {
            using (var db = new Mapeo())
            {
                db.lotes.Add(eLotes);
                db.SaveChanges();
                return true;
            }
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }
    public List<ELotes> obtenerLote()
    {
        new DAOPromociones().registrarPromociones();
        List<ELotes> lotes;
        using (var db = new Mapeo())
        {
            lotes = db.lotes.OrderByDescending(x => x.Fecha_ingreso).ToList();
        }

        foreach (ELotes lote in lotes) {
            
            lote.Producto = new DAOProducto().BuscarProducto(lote.Producto_id);
            lote.Fecha_ingreso_mostrar = lote.Fecha_ingreso.ToString("dd/MM/yyyy");
            lote.Fecha_vencimiento_mostrar = lote.Fecha_vencimiento.ToString("dd/MM/yyyy"); 

        }

        return lotes;
    }

    public List<ELotes> obtenerLoteCatalogo()
    {

        List<ELotes> lotes;
        using (var db = new Mapeo())
        {
            lotes = db.lotes.Where(x => x.Cantidad > 0).OrderBy(x => x.Fecha_ingreso).ToList();            
        }

        foreach (ELotes lote in lotes)
        {        
            lote.Producto = new DAOProducto().BuscarProducto(lote.Producto_id);
        }

        return lotes;
    }

    public void actualizarLotes(ELotes eLotes)
    {
        using (var db = new Mapeo())
        {
            ELotes lotesNuevo = db.lotes.Where(x => x.Id == eLotes.Id).First();

            lotesNuevo.Nombre_lote = eLotes.Nombre_lote;
            lotesNuevo.Cantidad = eLotes.Cantidad;
            lotesNuevo.Precio = eLotes.Precio;
            lotesNuevo.Producto_id = eLotes.Producto_id;
            lotesNuevo.Fecha_ingreso = DateTime.Parse(eLotes.Fecha_ingreso_mostrar);
            lotesNuevo.Fecha_vencimiento = DateTime.Parse(eLotes.Fecha_vencimiento_mostrar);
            lotesNuevo.Fecha_ingreso_mostrar = eLotes.Fecha_ingreso.ToString("dd/MM/yyyy");
            lotesNuevo.Fecha_vencimiento_mostrar = eLotes.Fecha_vencimiento.ToString("dd/MM/yyyy");

            db.lotes.Attach(lotesNuevo);

            var entry = db.Entry(lotesNuevo);
            entry.State = EntityState.Modified;
            db.SaveChanges();

        }
    }

    public void eliminarLotes(ELotes eLotes)
    {
        var db1 = new Mapeo();
        ELotes loteProducto = db1.lotes.Where(x => x.Id == eLotes.Id).First();
        if (loteProducto.Cantidad == 0)
        {
            ELotes loteSiguiente = db1.lotes.Where(x => x.Producto_id == loteProducto.Producto_id && x.Cantidad > 0).FirstOrDefault();

            if (loteSiguiente == null)
            {
                actualizarDisponibilidad(loteProducto.Producto_id, false);
            }
            using (var db = new Mapeo())

            {
                db.lotes.Attach(eLotes);

                var entry = db.Entry(eLotes);
                entry.State = EntityState.Deleted;

                db.SaveChanges();
            }
        }
    }
   
    public void actualizarDisponibilidad(int idProducto, Boolean estado)
        {
            using (var db = new Mapeo())
            {
                EProducto productoDos = db.producto.Where(x => x.Id == idProducto).First();
                productoDos.Disponibilidad = estado;
                db.producto.Attach(productoDos);
                var entry = db.Entry(productoDos);
                entry.State = EntityState.Modified;
                db.SaveChanges();

            }
        }
    }

