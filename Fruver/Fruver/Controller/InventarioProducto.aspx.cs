using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_InventarioProducto : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        string productosAgotados = "";

        List<EProducto> listaProductosAgotados = new DAOProducto().NotificarProducto();


        foreach (EProducto notificaciones in listaProductosAgotados)
            productosAgotados = String.Concat(productosAgotados, " - ", notificaciones.Nombre);

        cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Producto y Lote Agotado" + productosAgotados + "');</script>");

    }

    protected void GV_InventarioProducto_RowCommand(object sender, GridViewCommandEventArgs e) {


        switch (e.CommandName) {

            case "Ver_Detalle":
                              
                int id = Convert.ToInt32(GV_InventarioProducto.DataKeys[int.Parse(e.CommandArgument.ToString())].Values[0]);
                Response.Redirect("ProductoDetalle.aspx?id="+id);

                break;

            default:                
                break;
        }
    }
    
    protected void GV_InventarioProducto_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
       
            ClientScriptManager cm = this.ClientScript;
            GridViewRow row = GV_InventarioProducto.Rows[e.RowIndex];
            FileUpload cargue = (FileUpload)row.FindControl("FU_Editar");
            string urlArchivoExistente = ((Image)row.FindControl("I_EProducto")).ImageUrl;
            string nombreArchivo = System.IO.Path.GetFileName(cargue.PostedFile.FileName);
          
            if (nombreArchivo != null)
            {
                string extension = System.IO.Path.GetExtension(cargue.PostedFile.FileName);
                string url = "~\\Imagenes\\" + nombreArchivo;
                string saveLocation = Server.MapPath(url);

                if (!(extension.Equals(".png")))
                {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Tipo de archivo no valido');</script>");
                    e.Cancel = true;
                }

                try
                {
                    File.Delete(Server.MapPath(urlArchivoExistente));
                    cargue.PostedFile.SaveAs(saveLocation);
                    e.NewValues["imagen"] = url;
                }
                catch (Exception exc)
                {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Error: ');</script>");
                    return;
                }
            }
        
    }

}
