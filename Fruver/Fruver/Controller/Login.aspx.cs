using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_Login : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
    }

    protected void B_IniciarSesion_Click(object sender, EventArgs e)
    {

        if (TB_UserName.Text.Contains("=") || TB_UserName.Text.Contains("'") || TB_UserName.Text.Contains("<") || TB_UserName.Text.Contains(">") || TB_UserName.Text.Contains("<php>") || TB_UserName.Text.Contains("/") || TB_UserName.Text.Contains("//https:") || TB_UserName.Text.Contains(":") || TB_Password.Text.Contains("'") || TB_Password.Text.Contains("=") || TB_Password.Text.Contains("/") || TB_Password.Text.Contains("//https:") || TB_Password.Text.Contains(":") || TB_Password.Text.Contains("<") || TB_Password.Text.Contains(">") || TB_Password.Text.Contains("<php>")) 
        {
          
           Response.Write("<script type='text/javascript'>alert('Simbolos estan prohibidos por motivos de seguridad');</script>");
        }
        else
        {

            EUsuario eUsuario = new EUsuario();

            TB_UserName.Text = TB_UserName.Text.ToLower();
            TB_Password.Text = TB_Password.Text.ToLower();
            string usuarioIngresado = TB_UserName.Text;
            string contraseniaIngresada = TB_Password.Text;
            eUsuario.UserName = usuarioIngresado;
            eUsuario.Password = contraseniaIngresada;
            eUsuario = new DAOUsuario().login(eUsuario);

            if (eUsuario == null) 
            {
                Response.Write("<script type='text/javascript'>alert('Datos incorrectos');</script>");
            }
            else if(eUsuario.EstadoId == 2){
                Response.Write("<script type='text/javascript'>alert('Su cuenta esta en espera de recuperar contraseña');</script>");
                return;
            }
            else if(eUsuario !=null){

                Session["userName"] = eUsuario.UserName;
                Session["id"] = eUsuario.Id;
                Session["rolId"] = eUsuario.RolId;

                conexion();

                switch (eUsuario.RolId)
                {

                    // Usuario
                    case 1:
                        Response.Redirect("BienvenidoUsuario.aspx");
                        break;

                    // Operario logistico
                    case 2:
                        Response.Redirect("BienvenidoOperario.aspx");
                        break;

                    // Administrador
                    case 3:
                        Response.Redirect("BienvenidoAdministrador.aspx");
                        break;
                }
        }

        }
    }

    protected void conexion()
    {
        EAutenticacion autenticar = new EAutenticacion();
        Mac conexion = new Mac();
        autenticar.FechaInicio = DateTime.Now;
        autenticar.FechaFin = DateTime.Now;
        autenticar.Ip = conexion.ip();
        autenticar.Mac = conexion.mac();

        autenticar.UserId = int.Parse((Session["rolId"]).ToString());
        
        autenticar.Session = Session.SessionID;

        new DAOUsuario().insertarAutentication(autenticar);
    }

}