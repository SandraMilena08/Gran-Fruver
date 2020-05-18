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

    protected void DL_Catalogo_ItemCommand(object source, DataListCommandEventArgs e)
    {
        int stock = int.Parse(((Label)e.Item.FindControl("L_CantidadDisponible")).Text);
        int cantidadSolicitada = int.Parse(((TextBox)e.Item.FindControl("TB_CantidadCarrito")).Text);

        ECarritoCompras carrito = new ECarritoCompras();
        carrito.DetalleLoteId = int.Parse(e.CommandArgument.ToString());
        carrito.UsuarioId = int.Parse(Session["id"].ToString());
        carrito.Cantidad = cantidadSolicitada;
        carrito.TipoVentaId = 2;
        carrito.Fecha = DateTime.Now;
    }
}