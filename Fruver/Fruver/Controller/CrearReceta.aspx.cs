using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_CrearReceta : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        
    }

    protected void B_CrearReceta_Click(object sender, EventArgs e)
    {
        bool guardarReceta = true;
        bool recetaGuardada = false;
        EReceta receta = new EReceta();
        List<EProducto> listaProductos = new List<EProducto>();

        try
        {

            switch (System.IO.Path.GetExtension(FU_RecetaImagen.PostedFile.FileName).ToLower())
            {
                case ".jpg":

                    receta.Nombre = TB_NombreReceta.Text;
                    for (int index = 0; index < receta.Nombre.Length; index++)
                    {

                        if (index == 0)
                            receta.Nombre[index].ToString().ToUpper();
                        else
                            receta.Nombre[index].ToString().ToLower();
                    }

                    receta.ImagenUrl = "~\\Imagenes\\" + receta.Nombre + ".jpg";
                    receta.Descripcion = TB_Descripcion.Text;

                    EProducto producto = new EProducto();

                    for (int i = 0; i < CBL_Productos.Items.Count; i++)
                    {
                        if (CBL_Productos.Items[i].Selected) {
                            producto = new DAOProducto().BuscarProducto(int.Parse(CBL_Productos.Items[i].Value)); // Se obtiene el id de los productos seleccionados y se buscan para traer sus datos 
                            listaProductos.Add(producto);
                        }                           
                    }


                    receta.ProductoId = JsonConvert.SerializeObject(listaProductos);

                    break;

                default:

                    guardarReceta = false;
                    break;

            }

            if (guardarReceta) {
            FU_RecetaImagen.PostedFile.SaveAs(Server.MapPath(receta.ImagenUrl));
            recetaGuardada = new DAOReceta().insertarReceta(receta);

            if (recetaGuardada)
            {
                Response.Write("<script type='text/javascript'>alert('Receta guardada correctamente');</script>");
                Response.Redirect("PaginaRecetas.aspx");
            }
            else
                Response.Write("<script type='text/javascript'>alert('ERROR: ha ocurrido un error guardando la receta, intentelo de nuevo');</script>");

             } else
            Response.Write("<script type='text/javascript'>alert('ERROR: El Formato de la imagen no es correcto, debe ser JPG');</script>");

    } catch (Exception ex)
        {

            throw ex;
        }

    }
}