using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_ProductoDetalle : System.Web.UI.Page {

    protected void Page_Load(object sender, EventArgs e) {

        if (Request.QueryString.Count != 0) { 
            int id = int.Parse(Request.QueryString["id"]); 
            EProducto producto = new DAOProducto().BuscarProducto(id);
            L_Nombre.Text = producto.Nombre;
            I_Imagen.ImageUrl = producto.Imagen;

        } else 
            Response.Redirect("InventarioProducto.aspx");
    }

    protected void B_VolverInventario_Click(object sender, EventArgs e)
    {
        Response.Redirect("InventarioProducto.aspx");
    }
}