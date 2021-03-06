﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_LoteProducto : System.Web.UI.Page
{
    
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