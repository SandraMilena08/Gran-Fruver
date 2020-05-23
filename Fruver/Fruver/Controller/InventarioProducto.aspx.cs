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

    protected void GV_InventarioProducto_RowCommand(object sender, GridViewCommandEventArgs e)
    {

        switch (e.CommandName)
        {

            case "Ver_Detalle":

                int id = Convert.ToInt32(GV_InventarioProducto.DataKeys[int.Parse(e.CommandArgument.ToString())].Values[0]);
                Response.Redirect("ProductoDetalle.aspx?id=" + id);

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


    protected void GV_InventarioProducto_RowDeleting(object sender, GridViewDeleteEventArgs e)
    {
        ClientScriptManager cm = this.ClientScript;
        GridViewRow row = GV_InventarioProducto.Rows[e.RowIndex];
        EProducto producto = new EProducto();

        bool disponibilidad = ((CheckBox)row.FindControl("CB_Disponibilidad")).Checked;

        if (disponibilidad == true)
        {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No se puede eliminar el producto por que aun esta disponible');</script>");
            e.Cancel = true;
        }
    }

    protected void B_ReporteProducto_Click(object sender, EventArgs e)
    {
        Response.Redirect("Reporte.aspx");
    }

   
}

