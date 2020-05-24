using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_LoteProducto : System.Web.UI.Page
{

    protected void GV_InventarioProducto_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        GridViewRow row = GV_InventarioProducto.Rows[e.RowIndex];
        ELotes lotes = new ELotes();
 
        int cantidad = int.Parse(((TextBox)row.FindControl("TB_Cantidad")).Text);
        double precio = double.Parse(((TextBox)row.FindControl("TB_Precio")).Text);

        if (cantidad <= 0)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('La cantidad debe ser mayor a cero, no se admiten valores negativos ');</script>");
            e.Cancel = true;
        }else if (precio <= 0)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('el precio debe ser mayor a cero, no se admiten valores negativos ');</script>");
            e.Cancel = true;
        }

    }

    protected void GV_InventarioProducto_RowDeleting(object sender, GridViewDeleteEventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        GridViewRow row = GV_InventarioProducto.Rows[e.RowIndex];
        ELotes lotes = new ELotes();

        int cantidad = int.Parse(((Label)row.FindControl("Label2")).Text);

        if (cantidad > 0)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No se puede eliminar el lote porque la cantidad es mayor a 0');</script>");
            e.Cancel = true;
        }
    }

    protected void B_ReporteLote_Click(object sender, EventArgs e)
    {
        Response.Redirect("ReporteLote.aspx");
    }
}