using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_LoteAdmin : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        string productosAgotados = "";

        List<EProducto> listaProductosAgotados = new DAOProducto().NotificarProducto();


        foreach (EProducto notificaciones in listaProductosAgotados)
            productosAgotados = String.Concat(productosAgotados, " - ", notificaciones.Nombre );

        cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Producto y Lote Agotado" + productosAgotados + "');</script>");

    }
}