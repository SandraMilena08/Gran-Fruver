using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_InventarioProducto : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        string productosAgotados = "";

        List<ENotificar> listaProductosAgotados = new DAOLotes().ObtenerNotificacion();
       
        foreach (ENotificar notificaciones in listaProductosAgotados)
            productosAgotados = String.Concat(productosAgotados, " - ",notificaciones.Lote.Nombre_lote);

        cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Producto Agotado" + productosAgotados +"');</script>" );

    }

    

    protected void GV_InventarioProducto_RowCommand(object sender, GridViewCommandEventArgs e) {


        switch (e.CommandName) {

            case "Ver_Detalle":
                              
                int id = Convert.ToInt32(GV_InventarioProducto.DataKeys[int.Parse(e.CommandArgument.ToString())].Values[0]);
                Response.Redirect("ProductoDetalle.aspx?id="+id);

                break;

            default:                
                break;
        }
    }

   
}