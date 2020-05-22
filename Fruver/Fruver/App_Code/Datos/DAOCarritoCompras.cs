using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;


public class DAOCarritoCompras
{

    public List<ECarritoCompras> LeerPedidosCliente(int usuarioId){

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

    public List<ELotes> ValidarCompra(int usuarioId) {

        try {

            ELotes lote;
            List<ECarritoCompras> listaPedidos = this.LeerPedidosCliente(usuarioId);
            List<ELotes> listaLotesAgotados = new List<ELotes>();

            using (Mapeo db = new Mapeo()) {

                foreach (ECarritoCompras pedido in listaPedidos) {
                    lote = new DAOLotes().LeerLote(pedido.DetalleLoteId);
                    if (pedido.Cantidad > lote.Cantidad) {
                        listaLotesAgotados.Add(lote);
                    }
                }

                return listaLotesAgotados; 
            }

        } catch (Exception ex) { throw ex; }
    }

    public bool CambiarEstadoPedido(int usuarioId) {        

        try {

            List<ECarritoCompras> listaPedidos = this.LeerPedidosCliente(usuarioId);

            using (Mapeo db = new Mapeo()) {

                foreach (ECarritoCompras pedido in listaPedidos) {
                    pedido.EstadoId = true;
                    if (!ActualizarPedido(pedido))
                        break;
                }

                return true;
            }

        } catch (Exception ex) { return false; }
    }

    public bool DescontarCantidadLote(int usuarioId) {

        try {

            ELotes lote;
            EPromociones promocion;
            List<ECarritoCompras> listaPedidos = this.LeerPedidosCliente(usuarioId);

            using (Mapeo db = new Mapeo()) {
                //creo que ya
                foreach (ECarritoCompras pedido in listaPedidos) {

                    if (pedido.TipoVentaId == 1) {

                        lote = new DAOLotes().LeerLote(pedido.DetalleLoteId);
                        lote.Cantidad = lote.Cantidad - pedido.Cantidad;
                        if (!new DAOLotes().ActualizarLoteDescontar(lote))
                            break;

                    } else {

                        promocion = new DAOPromociones().LeerPromocion(pedido.DetalleLoteId);
                        promocion.Cantidad = promocion.Cantidad - pedido.Cantidad;
                        if (!new DAOPromociones().ActualizarPromocionDescontar(promocion))
                            break;
                    }                 
                }

                return true;
            }

        } catch (Exception ex) { return false; }
    }

    public bool ValidarCantidadLote(int usuarioId)
    {

        try
        {

            ELotes lote;
            List<ECarritoCompras> listaPedidos = this.LeerPedidosCliente(usuarioId);

            using (Mapeo db = new Mapeo())
            {

                foreach (ECarritoCompras pedido in listaPedidos)
                {

                    lote = new DAOLotes().LeerLote(pedido.DetalleLoteId);
                    lote.Cantidad = lote.Cantidad - pedido.Cantidad;
                    if (!new DAOLotes().ActualizarLoteDescontar(lote))
                        break;
                }

                return true;
            }

        }
        catch (Exception ex) { return false; }
    }
    public bool ActualizarPedido(ECarritoCompras pedido) {

        try {            

            using (Mapeo db = new Mapeo()) {

                ECarritoCompras pedidoViejo = db.carrito.Where(x => x.Id == pedido.Id).FirstOrDefault();
                db.Entry(pedidoViejo).CurrentValues.SetValues(pedido);
                db.SaveChanges();
                return true;
            }

        } catch (Exception ex) { return false; }
    }


    public void eliminarCarrito(ECarritoCompras carrito)
    {
        using (var db = new Mapeo())
        {
            db.carrito.Attach(carrito);

            var entry = db.Entry(carrito);
            entry.State = EntityState.Deleted;
            db.SaveChanges();

        }
    }

    public ECarritoCompras LeerPedidoClienteLote(int idLote, int usuarioId) {

        try {

            using (Mapeo db = new Mapeo()) {

                return db.carrito.Where(x => x.DetalleLoteId == idLote && x.EstadoId == false && x.UsuarioId == usuarioId).FirstOrDefault();
            }

        } catch (Exception ex) { throw ex; }
    }
}