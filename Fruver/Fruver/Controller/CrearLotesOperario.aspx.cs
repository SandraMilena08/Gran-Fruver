using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_CrearLotesOperario : System.Web.UI.Page
{
   
    protected void B_CrearLote_Click(object sender, EventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        ELotes lotes = new ELotes();
        lotes.Nombre_lote = TB_NombreLote.Text;
        lotes.Cantidad = int.Parse(TB_Cantidad.Text);
        lotes.Precio = int.Parse(TB_Precio.Text);
        lotes.Producto_id = int.Parse(DDL_Producto.Text);
        lotes.Fecha_ingreso = DateTime.Parse(TB_FechaIngreso.Text);
        lotes.Fecha_vencimiento = DateTime.Parse(TB_FechaVencimiento.Text);
        if (lotes.Fecha_ingreso.Date < DateTime.Now.Date)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Fecha de inicio invalida');</script>");

        }
        else if (lotes.Cantidad <= 0)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('La cantidad debe ser mayor a cero');</script>");
        }

        else if (lotes.Fecha_vencimiento.Date < lotes.Fecha_ingreso.Date)
        {
            new DAOLotes().insertarLote(lotes);
            new DAOLotes().actualizarDisponibilidad(lotes.Producto_id, true);
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No es posible agregar el producto, por que la fecha de vencimiento es menor a la fecha de ingreso');</script>");
            //Response.Redirect("LoteProducto.aspx");
        }
        else {
            new DAOLotes().insertarLote(lotes);
            new DAOLotes().actualizarDisponibilidad(lotes.Producto_id, true);
            this.RegisterStartupScript("mensaje", "<script type='text/javascript'>alert('Lote agregado');window.location=\"LoteProducto.aspx\" </script>");

        }

    }



   
}