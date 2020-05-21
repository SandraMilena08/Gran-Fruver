using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_PromocionesUsuario : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void DL_Promociones_ItemCommand(object source, DataListCommandEventArgs e) {

        ClientScriptManager cm = this.ClientScript;
        int stock = int.Parse(((Label)e.Item.FindControl("LB_CantidadPromocion")).Text);
        int cantidadSolicitada = int.Parse(((TextBox)e.Item.FindControl("TB_CantidadSolicitada")).Text);
        bool existeProducto = false; // Para saber si ya agrego el lote antes
        bool bandera = false; // Si excede el limite

        List<ECarritoCompras> listaPedido = new DAOCarritoCompras().LeerPedidosCliente(int.Parse(Session["id"].ToString())); // Los pedidos  del cliente

        // For para mirar si el lote ya habia sido agregado 
        foreach (ECarritoCompras pedido in listaPedido) {
            if (pedido.DetalleLote.Id == int.Parse(e.CommandArgument.ToString()) && pedido.TipoVentaId == 2) {
                existeProducto = true;
                if (pedido.Cantidad + cantidadSolicitada <= stock) {                        
                    bandera = true; // Si se puede aumentar la cantidad
                    break;
                }
            }
        }

        if (existeProducto == false) {

            if (new DAOPromociones().ValidarCantidad(int.Parse(e.CommandArgument.ToString())) >= cantidadSolicitada) {

                EPromociones promocion = new DAOPromociones().LeerPromocion(int.Parse(e.CommandArgument.ToString()));
                ECarritoCompras carrito = new ECarritoCompras();
                carrito.DetalleLoteId = promocion.Lote_id;
                carrito.UsuarioId = int.Parse(Session["id"].ToString());
                carrito.Cantidad = cantidadSolicitada;
                carrito.TipoVentaId = 2;
                carrito.Fecha = DateTime.Now;
                carrito.Precio = cantidadSolicitada * promocion.Precio;
                carrito.EstadoId = false;

                if (new DAOCarritoCompras().AgregarPedido(carrito) == true) {

                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Se ha agregado a carrito');</script>");

                } else {

                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No se pudo agregar a carrito');</script>");
                }

            } else {

                cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Error');</script>");
            }

        } else if (existeProducto == true && bandera == true) { // Aumentar la cantidad a un pedido existente

                ECarritoCompras pedido = new DAOCarritoCompras().LeerPedidoClienteLote(int.Parse(e.CommandArgument.ToString()), int.Parse(Session["id"].ToString()));
                pedido.Cantidad = pedido.Cantidad + cantidadSolicitada;
                if (new DAOCarritoCompras().ActualizarPedido(pedido) == true) {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Se ha añadido la cantidad solicitada');</script>");
                } else {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Error');</script>");
                }

            } else if (existeProducto == true && bandera == false) { // Se excede la cantidad solicitada para un pedido existente
                cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Ya habia solicitado una cantidad de ese lote y esta excediendo la cantidad de existencia');</script>");
        }
    }
}