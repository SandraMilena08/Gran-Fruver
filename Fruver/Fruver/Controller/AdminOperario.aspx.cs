using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_AdminOperario : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
    }
    

    protected void GV_IngresoOperario_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        GridViewRow row = GV_IngresoOperario.Rows[e.RowIndex];
        EUsuario usuario = new EUsuario();
        string usuarioExistente = ((TextBox)row.FindControl("TB_UserName")).Text;
        string emailExistente = ((TextBox)row.FindControl("TB_Correo")).Text;

        var vericorreo = new DAOUsuario().buscarCorreo(emailExistente);
        var veriusuario = new DAOUsuario().buscarNombreUsuario(usuarioExistente);

        if (veriusuario != null && vericorreo != null)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('El Correo o usuario ya existe');</script>");
            e.Cancel = true;
        }

    }

  
}