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
        EReceta recetaAux = new DAOReceta().obtenerReceta(Convert.ToInt32(GV_Recetas.DataKeys[e.RowIndex].Values[0]));
        List<EProducto> listaProductos = new List<EProducto>();

        bool actualizarImagen = false;
        int productosSeleccionados = 0; 

        try
        {

            FileUpload fileUpload = ((FileUpload)columna.FindControl("FU_EditarImagen"));

            switch (System.IO.Path.GetExtension(fileUpload.PostedFile.FileName).ToLower())
            {
                case ".png":
                case ".jpg":

                    TextBox nombre = (TextBox)columna.FindControl("TB_EditarNombre");
                    receta.Nombre = nombre.Text;
                    receta.ImagenUrl = "~\\Imagenes\\" + receta.Nombre + ".jpg";
                    actualizarImagen = true;

                    break;                                  
            }
            

            CheckBoxList CBL_Receta = ((CheckBoxList)columna.FindControl("CBL_EditarReceta"));

            EProducto producto = new EProducto();

            for (int i = 0; i < CBL_Receta.Items.Count; i++)
            {
                if (CBL_Receta.Items[i].Selected)
                {
                    productosSeleccionados =+ 1;
                    producto = new DAOProducto().BuscarProducto(int.Parse(CBL_Receta.Items[i].Value));
                    listaProductos.Add(producto);
                }
            }
          
            if (actualizarImagen == true)
            {
                fileUpload.PostedFile.SaveAs(Server.MapPath(receta.ImagenUrl));
                e.NewValues["ImagenUrl"] = receta.ImagenUrl;

            } else {
                receta.ImagenUrl = recetaAux.ImagenUrl;
                e.NewValues["ImagenUrl"] = receta.ImagenUrl;
            }

            if (productosSeleccionados > 0)
            {
                receta.ProductoId = JsonConvert.SerializeObject(listaProductos);
                e.NewValues["ProductoId"] = receta.ProductoId;
            }
            else
            {

                receta.ProductoId = recetaAux.ProductoId;
                e.NewValues["ProductoId"] = receta.ProductoId;

            }

            

        }
        catch (Exception ex)
        {

            throw ex;
        }

        GV_Recetas.DataBind();
    }
}