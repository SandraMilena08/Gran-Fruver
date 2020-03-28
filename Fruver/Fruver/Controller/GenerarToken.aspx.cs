using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_GenerarToken : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void B_GenerarToken_Click(object sender, EventArgs e)
    {
        ClientScriptManager am = this.ClientScript;

        EUsuario usuario = new DAOUsuario().obtenerUsuario(TB_RecuperarCorreo.Text);


        if (usuario == null)
        {
            am.RegisterClientScriptBlock(this.GetType(), "mensaje", "<script type='text/javascript'>alert('ERROR: El correo no existe');window.location=\"GenerarToken.aspx\"</script>");
            return;
        }

        usuario.Password = "";
        usuario.EstadoId = 2;
        usuario.Token = encriptar(JsonConvert.SerializeObject(usuario));
        usuario.VencimientoToken = DateTime.Now.AddDays(1);
        usuario.Session = usuario.Session = "Sistema";

        new Correo().enviarCorreo(usuario.Correo, usuario.Token, "");
        new DAOUsuario().actualizarUsuario(usuario);
    }

    private string encriptar(string input)
    {

        SHA256CryptoServiceProvider provider = new SHA256CryptoServiceProvider();

        byte[] inputBytes = Encoding.UTF8.GetBytes(input);
        byte[] hashedBytes = provider.ComputeHash(inputBytes);

        StringBuilder output = new StringBuilder();

        for (int i = 0; i < hashedBytes.Length; i++)
            output.Append(hashedBytes[i].ToString("x2").ToLower());

        return output.ToString();
    }
}