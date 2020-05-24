using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_RecuperarPassword : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if(Request.QueryString.Count > 0)
        {
            EUsuario usuario = new DAOUsuario().obtenerToken(Request.QueryString[0] == null ? "": Request.QueryString[0]);


            if (usuario == null) // Si es igual a nulo es que no encontro el usuario
                this.RegisterStartupScript("mensaje", "<script type='text/javascript'>alert('ERROR: Token invalido, genere una nueva solicitud');window.location=\"Login.aspx\"</script>");
            else if (usuario.VencimientoToken < DateTime.Now) 
                this.RegisterStartupScript("mensaje", "<script type='text/javascript'>alert('ERROR: El token esta vencido, genere una nueva solicitud');window.location=\"Login.aspx\"</script>");
            else
                Session["user_id"] = usuario;
        }
        else
        {
            Response.Redirect("Login.aspx");
        }
    }

    protected void B_GuardarRecuperar_Click(object sender, EventArgs e)
    {

        EUsuario usuario = (EUsuario)Session["user_id"];

        if (TB_RecuperarPassword.Text.Equals(TB_PasswordNuevamente.Text))
        {

            //usuario.Id = int.Parse(Session["user_id"].ToString()); 
            usuario.Password = TB_RecuperarPassword.Text;
            usuario.EstadoId = 1;
            usuario.Token = null;
            usuario.VencimientoToken = null;
            usuario.Session = usuario.UserName;

            new DAOUsuario().actualizarUsuario(usuario);
            this.RegisterStartupScript("mensaje", "<script type='text/javascript'>alert('La clave ha sido modificada correctamente');window.location=\"Login.aspx\"</script>");

        }
        else
            this.RegisterStartupScript("mensaje", "<script type='text/javascript'>alert('ERROR: Las claves no son iguales');window.location=\"Login.aspx\"</script>");
    }
}