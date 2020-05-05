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

        if (cantidad <= 0)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('La cantidad debe ser mayor a cero ');</script>");
            e.Cancel = true;
        }

        string nombrelote = ((TextBox)row.FindControl("TB_Nombre")).Text;

        if (nombrelote != null)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('El nombre del lote ya existe');</script>");
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
}