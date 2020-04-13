using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_CrearProducto : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    protected void B_CrearProducto_Click(object sender, EventArgs e)
    {
        bool guardarProducto= true;
        bool productoGuardado = false;
        EProducto producto = new EProducto(); 

        try
        {

            switch (System.IO.Path.GetExtension(FU_ImagenProducto.PostedFile.FileName).ToLower())
            {


                case ".png":
                    
                    producto.Nombre = TB_Nombre.Text;
                    for (int index = 0; index < producto.Nombre.Length; index++)
                    {

                        if (index == 0)
                            producto.Nombre[index].ToString().ToUpper();
                        else
                            producto.Nombre[index].ToString().ToLower();
                    }
                   
                    producto.Imagen = "~\\Imagenes\\" + producto.Nombre + ".png";
                    producto.Disponibilidad = false;

                    break; 

                default:

                    guardarProducto = false;
                    break;
            }

            if (guardarProducto)
            {                
                FU_ImagenProducto.PostedFile.SaveAs(Server.MapPath(producto.Imagen)); 
                productoGuardado = new DAOProducto().insertarProducto(producto);

                if (productoGuardado) {
                    Response.Write("<script type='text/javascript'>alert('Producto guardado correctamente');</script>");
                    Response.Redirect("InventarioProducto.aspx");
                 } else
                    Response.Write("<script type='text/javascript'>alert('ERROR: ha ocurrido un error guardando el producto, intentelo de nuevo');</script>");

            }
            else
                Response.Write("<script type='text/javascript'>alert('ERROR: El Formato de la imagen no es correcto, debe ser PNG');</script>");

        }
        catch (Exception ex)
        {

            throw ex;
        }
    }
}
