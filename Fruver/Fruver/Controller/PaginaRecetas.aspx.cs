using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Controller_PaginaRecetas : System.Web.UI.Page
{
    private List<EReceta> listaProductos;

    private bool Resultado;

    protected void Page_Load(object sender, EventArgs e)
    {
        
    }


    protected void GV_Recetas_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName.Equals("Delete"))
        {

            GridViewRow filaGrid = GV_Recetas.Rows[int.Parse(e.CommandArgument.ToString())];
            Label nombreReceta = (Label)filaGrid.FindControl("LB_NombreReceta");
            listaProductos = new DAOReceta().obtenerReceta();

            if (this.listaProductos.Count != 0)
                Resultado = new DAOReceta().eliminarReceta(int.Parse(GV_Recetas.DataKeys[int.Parse(e.CommandArgument.ToString())].Value.ToString()));
            else
                ClientScript.RegisterClientScriptBlock(this.GetType(), "mensaje", "<script type='text/javascript'>alert('ERROR: No se puede eliminar la receta);window.location=\"PaginaRecetas.aspx\"</script>");
          
            GV_Recetas.DataBind();
            Response.Redirect("PaginaRecetas.aspx");
        }
        
    }

    protected void GV_Recetas_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
        GridViewRow columna = GV_Recetas.Rows[e.RowIndex];
        EReceta receta = new EReceta();
        List<EProducto> listaProductos = new List<EProducto>();

        try
        {

            FileUpload fileUpload = ((FileUpload)columna.FindControl("FU_EditarImagen"));

            switch (System.IO.Path.GetExtension(fileUpload.PostedFile.FileName).ToLower())
            {

                case ".jpg":
                    
                    receta.Nombre = ((TextBox)columna.FindControl("TB_EditarNombre")).Text;
                    receta.Descripcion = ((TextBox)columna.FindControl("TB_EditarDescripcion")).Text;
                    receta.ImagenUrl = "~\\Imagenes\\ImagenesReceta" + ".jpg";

                    CheckBoxList CBL_Receta = ((CheckBoxList)columna.FindControl("CBL_EditarReceta"));

                    EProducto producto = new EProducto();

                    for (int i = 0; i < CBL_Receta.Items.Count; i++)
                    {
                        if (CBL_Receta.Items[i].Selected){
                            producto = new DAOProducto().BuscarProducto(int.Parse(CBL_Receta.Items[i].Value));
                            listaProductos.Add(producto);
                        }
                    }


                    receta.ProductoId = JsonConvert.SerializeObject(listaProductos);


                    break;

                default:

                    Response.Write("<script type='text/javascript'>alert('ERROR: El formato de la imagen es inválido.');</script>");
                    Response.Redirect("PaginaRecetas.aspx");

                    break;
            }

            fileUpload.PostedFile.SaveAs(Server.MapPath(receta.ImagenUrl));

        }
        catch (Exception ex)
        {

            throw ex;
        }

        e.NewValues.Insert(1, "imagenUrl", receta.ImagenUrl);
        e.NewValues.Insert(1, "CBL_Receta", receta.ListaProductos);

    }
}