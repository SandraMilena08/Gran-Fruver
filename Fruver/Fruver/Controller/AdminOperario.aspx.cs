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
        //EUsuario eUsuario = new EUsuario();
        List<EUsuario> list_usuario = new DAOUsuario().buscarUsuario();
        GV_IngresoOperario.DataSource = list_usuario;
        GV_IngresoOperario.DataBind();
    }


    protected void B_IngresarOperario_Click(object sender, EventArgs e)
    {
        EUsuario usuario = new EUsuario();
        usuario.Nombre = TB_Nombre.Text;
        usuario.UserName = TB_Username.Text;
        usuario.Correo = TB_Correo.Text;
        usuario.Password = TB_Codigo.Text;
        usuario.Celular = int.Parse(TB_Celular.Text);
        usuario.Direccion = TB_Direccion.Text;
        usuario.Session = usuario.Session;
        usuario.RolId = 2;

        new DAOUsuario().insertarUsuario(usuario);
        GV_IngresoOperario.DataBind();
        Response.Redirect("AdminOperario.aspx");
    }
}