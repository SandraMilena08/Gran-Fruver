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

    public EUsuario obtenerComprador(int idUsuario)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.Id == idUsuario).FirstOrDefault(); 
        }
    }

    public List<ECarritoCompras> obtenerFactura(int UsuarioId)
    {
        using (var db = new Mapeo())
        {
            EUsuario usuario = db.usuario.Where(x => x.Id == UsuarioId).FirstOrDefault();
            List<ECarritoCompras> factura = db.carrito.Where(x => x.UsuarioId == UsuarioId && x.EstadoId == false).ToList();
            
            foreach (ECarritoCompras carrito in factura)
            {
                ELotes lote = db.lotes.Where(x => x.Id == carrito.DetalleLoteId).FirstOrDefault();
                EProducto producto = db.producto.Where(x => x.Id == lote.Producto_id).FirstOrDefault();
                // productos de compra
                carrito.NombreLote = lote.Nombre_lote;
                carrito.Total = carrito.Precio * carrito.Cantidad;
                //acumulador
                carrito.TotalCompra = carrito.TotalCompra + carrito.Total;
                carrito.Aux = carrito.TotalCompra;
                if (carrito.TipoVentaId == 1)
                {
                    carrito.TipoVenta = "Normal";
                }
                else
                {
                    carrito.TipoVenta = "Promocion";
                }
                carrito.DetalleLote = new DAOLotes().LeerLote(carrito.DetalleLoteId);
                carrito.DetalleLote.Producto = new DAOProducto().BuscarProducto(carrito.DetalleLote.Producto_id);
            }
            return factura;
        }
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


    public List<ECarritoCompras> obtenerCarrito()
    {
        List<ECarritoCompras> carrito;

        using (var db = new Mapeo())
        {

            carrito =  db.carrito.Where(x => x.EstadoId == true).ToList();
        }

        foreach (ECarritoCompras carro in carrito)
        {
            carro.DetalleLote = new DAOLotes().LeerLote(carro.DetalleLoteId);
            carro.DetalleLote.Producto = new DAOProducto().BuscarProducto(carro.DetalleLote.Producto_id);

        }

        return carrito;
    }
}
