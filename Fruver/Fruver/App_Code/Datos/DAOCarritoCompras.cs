using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOCarritoCompras
/// </summary>
public class DAOCarritoCompras
{
    // Varable de mapeo esperame  ya me llamas   private Mapeo db =
    private readonly Mapeo db = new Mapeo();

    public List<ECarritoCompras> LeerDetalleLote() {

        using (Mapeo db = new Mapeo()) {

            return db.carrito.Include("DetalleLote").ToList();//se me fue la señal del cel jajaja
        }
    }
}