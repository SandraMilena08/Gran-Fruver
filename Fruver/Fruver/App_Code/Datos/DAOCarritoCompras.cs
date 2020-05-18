using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;


public class DAOCarritoCompras
{

    public List<ECarritoCompras> LeerPedidosCliente(int usuarioId) {

        try {

            List<ECarritoCompras> listaPedidos;
            using (Mapeo db = new Mapeo()) {

                listaPedidos = db.carrito.Where(x => x.UsuarioId == usuarioId && x.EstadoId == false).ToList();
            }

            foreach (ECarritoCompras pedido in listaPedidos) {
                if (pedido.TipoVentaId == 1) {
                    pedido.TipoVenta = "Normal";
                } else {
                    pedido.TipoVenta = "Promocion";
                }
                pedido.DetalleLote = new DAOLotes().LeerLote(pedido.DetalleLoteId);
                pedido.DetalleLote.Producto = new DAOProducto().BuscarProducto(pedido.DetalleLote.Producto_id);
            }

            return listaPedidos;

        } catch (Exception ex) { throw ex; }

    }    
    
    public int ValidarCantidad(int loteId) {

        try {
                        
            using (Mapeo db = new Mapeo()) {

                ELotes lote = db.lotes.Where(x => x.Id == loteId).FirstOrDefault();
                return lote.Cantidad;
            }            

        } catch (Exception ex) { throw ex; }
    }

    public bool AgregarPedido(ECarritoCompras pedido) {        

        try {
            
            using (Mapeo db = new Mapeo()) {

                db.carrito.Add(pedido);
                db.SaveChanges();
                return true;
            }                       

        } catch (Exception ex) { return false; }
    }
}