using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_PromocionesOperario : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ClientScriptManager cm = this.ClientScript;

            if (new DAOPromociones().obtenerPromociones().Count > 0)
            {
                cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Existen Productos en Promociones');</script>");

            }
        }
       
    }
    protected void GV_InventarioProducto_RowDeleting(object sender, GridViewDeleteEventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        GridViewRow row = GV_Promociones.Rows[e.RowIndex];
        EPromociones promo = new EPromociones();

        bool disponibilidad = ((CheckBox)row.FindControl("CB_Disponibilidad")).Checked;

        if (disponibilidad == true )
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No se puede eliminar la promocion por que aun esta disponible, o no a llegado a la fecha de caducidad');</script>");
            e.Cancel = true;
        }
        
    }
}
