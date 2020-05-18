using Npgsql;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOPromociones
/// </summary>
public class DAOPromociones
{
    public List<EPromociones> obtenerPromocionesDisponibles()
    {
        using (var db = new Mapeo())
        {
            List<EPromociones> promo = db.promociones.Where(x => x.Disponibilidad == true).ToList();

            foreach (EPromociones promociones in promo)
            {
                ELotes lote = db.lotes.Where(x => x.Id == promociones.Lote_id).FirstOrDefault();
                EProducto producto = db.producto.Where(x => x.Id == lote.Producto_id).FirstOrDefault();
                promociones.Fecha_vencimiento_mostrar = lote.Fecha_vencimiento.ToString("dd/MM/yyyy");
                promociones.NombreLote = lote.Nombre_lote;
                promociones.Imagen = producto.Imagen;
            }
            return promo;
        }
    }
    public List<EPromociones> obtenerPromociones()
    {
        using (var db = new Mapeo())
        {
            List<EPromociones> promociones = db.promociones.ToList();

            foreach (EPromociones promocion in promociones)

            {
                double descuento, DesTotal;

                ELotes lote = db.lotes.Where(x => x.Id == promocion.Lote_id).FirstOrDefault();
                EProducto producto = db.producto.Where(x => x.Id == lote.Producto_id).FirstOrDefault();
                promocion.Fecha_vencimiento_mostrar = lote.Fecha_vencimiento.ToString("dd/MM/yyyy");
                promocion.NombreLote = lote.Nombre_lote;
                promocion.Imagen = producto.Imagen;

                // Descuento en la promocion
                descuento = 0.10 * promocion.Precio;
                DesTotal = promocion.Precio - descuento;
                promocion.Precio = DesTotal;

                if (promocion.FechaVencimiento1.Date.CompareTo(DateTime.Now.Date) <= 0)
                {
                    promocion.Disponibilidad = false;
                    db.promociones.Attach(promocion);

                    var entry = db.Entry(promocion);
                    entry.State = EntityState.Modified;
                    db.SaveChanges();

                }

            }

            return promociones;
        }
    }

    public void eliminarPromocion(EPromociones promo)
    {
        using (var db = new Mapeo())
        {
            db.promociones.Attach(promo);

            var entry = db.Entry(promo);
            entry.State = EntityState.Deleted;
            db.SaveChanges();

        }
    }
    
    public void registrarPromociones()
    {
        using (var db = new Mapeo())
        {
            List<EPromociones> promociones = new List<EPromociones>(); 
            DateTime fechaActualPromo = DateTime.Now.AddDays(2); 
            var lista = db.lotes.Where(x => DbFunctions.TruncateTime(x.Fecha_vencimiento) <= DbFunctions.TruncateTime(fechaActualPromo)).ToList();
            
            foreach (ELotes lote in lista)
            {
                EPromociones buscarPromocion = db.promociones.Where(x => x.Lote_id == lote.Id).FirstOrDefault();
                if (buscarPromocion == null)
                {
                    EPromociones promocion = new EPromociones();
                    promocion.FechaVencimiento1 = lote.Fecha_vencimiento;
                    promocion.Lote_id = lote.Id;
                    promocion.Precio = lote.Precio;
                    promocion.Cantidad = lote.Cantidad;
                    promocion.Disponibilidad = true;

                    promociones.Add(promocion);
                }
            }


            foreach (EPromociones promocion in promociones)
            {
                db.promociones.Add(promocion);
                db.SaveChanges();
            }
        }
    }
}
