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