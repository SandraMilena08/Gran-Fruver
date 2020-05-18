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
        if (!IsPostBack)
        {
            ClientScriptManager cm = this.ClientScript;
            List<EProducto> productosDisponibles = new DAOProducto().listarProductosConLotes();
            if (productosDisponibles.Count == 0)
            {
                cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No hay lotes');</script>");
            }
            else
            {
                List<EProducto> productosAgotados = new DAOProducto().listarProductosAgotados(productosDisponibles);
                if (productosAgotados.Count > 0)
                {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Existen productos agotados o apunto de agotarse');</script>");

                }
            }

        }

    }

    
}