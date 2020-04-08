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
        EUsuario usuario = new EUsuario();
        usuario.Nombre = TB_Nombre.Text;
        usuario.UserName = TB_Username.Text;
        usuario.Correo = TB_Correo.Text;
        usuario.Password = TB_Password.Text;
        usuario.Celular = int.Parse(TB_Celular.Text);
        usuario.Direccion = TB_Direccion.Text;
        usuario.Session = usuario.Session;
        usuario.RolId = 1;
        new DAOUsuario().insertarUsuario(usuario);
        Response.Redirect("Login.aspx");
    }
}