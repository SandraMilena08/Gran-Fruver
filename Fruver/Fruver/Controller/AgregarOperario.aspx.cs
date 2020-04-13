using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_AgregarOperario : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void B_IngresarOperario_Click(object sender, EventArgs e)
    {
        EUsuario usuario = new EUsuario();
        usuario.Nombre = TB_Nombre.Text;
        usuario.UserName = TB_UserName.Text;
        usuario.Correo = TB_Correo.Text;
        usuario.Password = TB_Codigo.Text;
        usuario.Celular = long.Parse(TB_Celular.Text); 
        usuario.Direccion = TB_Direccion.Text;
        usuario.Session = usuario.Session;
        usuario.RolId = 2;

        new DAOUsuario().insertarUsuario(usuario);
        Response.Redirect("AdminOperario.aspx");
    }
}