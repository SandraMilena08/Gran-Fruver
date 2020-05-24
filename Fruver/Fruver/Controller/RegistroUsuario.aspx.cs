using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_RegistroUsuario : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void B_IniciarSesion_Click(object sender, EventArgs e)
    {
        if (TB_Username.Text.Contains("=") || TB_Username.Text.Contains("'") || TB_Username.Text.Contains("<") || TB_Username.Text.Contains(">") || TB_Username.Text.Contains("<php>") || TB_Username.Text.Contains("/") || TB_Username.Text.Contains("//https:") || TB_Username.Text.Contains(":") || TB_Password.Text.Contains("'") || TB_Password.Text.Contains("=") || TB_Password.Text.Contains("/") || TB_Password.Text.Contains("//https:") || TB_Password.Text.Contains(":") || TB_Password.Text.Contains("<") || TB_Password.Text.Contains(">") || TB_Password.Text.Contains("<php>"))
        {

            Response.Write("<script type='text/javascript'>alert('Simbolos estan prohibidos por motivos de seguridad');</script>");
        }
        else
        {
            ClientScriptManager am = this.ClientScript;

            EUsuario usuario = new EUsuario();
            TB_Username.Text = TB_Username.Text.ToLower();
            TB_Password.Text = TB_Password.Text.ToLower();
            usuario.Nombre = TB_Nombre.Text;
            usuario.UserName = TB_Username.Text;
            usuario.Correo = TB_Correo.Text;
            usuario.Password = TB_Password.Text;
            usuario.Celular = long.Parse(TB_Celular.Text);
            usuario.Direccion = TB_Direccion.Text;
            usuario.Session = usuario.Session;
            usuario.RolId = 1;

            EUsuario eUsuario = new DAOUsuario().buscarCorreoUsuario(TB_Correo.Text, TB_Username.Text);

            if (eUsuario == null)
            {
                new DAOUsuario().insertarUsuario(usuario);
                Response.Redirect("Login.aspx");
            }
            else
            {
                am.RegisterClientScriptBlock(this.GetType(), "mensaje", "<script type='text/javascript'>alert('ERROR: El correo o el nombre de usuario ya existe');window.location=\"RegistroUsuario.aspx\"</script>");
            }

        }
    }     
}