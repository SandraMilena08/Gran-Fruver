using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_CatalogoProductos : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
       
    }

    protected void DL_Catalogo_ItemCommand(object source, DataListCommandEventArgs e) { 

        int stock = int.Parse(((Label)e.Item.FindControl("L_CantidadDisponible")).Text);
        int cantidadSolicitada = int.Parse(((TextBox)e.Item.FindControl("TB_CantidadCarrito")).Text);        
        
        if (new DAOCarritoCompras().ValidarCantidad(int.Parse(e.CommandArgument.ToString())) >= cantidadSolicitada) {

            ELotes lote = new DAOLotes().LeerLote(int.Parse(e.CommandArgument.ToString()));
            ECarritoCompras carrito = new ECarritoCompras();
            carrito.DetalleLoteId = int.Parse(e.CommandArgument.ToString());
            carrito.UsuarioId = int.Parse(Session["id"].ToString());
            carrito.Cantidad = cantidadSolicitada;
            carrito.TipoVentaId = 1; 
            carrito.Fecha = DateTime.Now;
            carrito.Precio = cantidadSolicitada * lote.Precio;
            carrito.EstadoId = false;

            

            if (new DAOCarritoCompras().AgregarPedido(carrito) == true) {

                // Se guardo el producto correctamente

            } else {
                // Mensaje de error
            }

        } else {
            // Mensaje de error
        }

        this.DataBind();
    }
}