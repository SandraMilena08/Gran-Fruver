using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_Reporte : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        CRS_Reporte.ReportDocument.SetDataSource(informacionReporte());
        CRV_Reporte.ReportSource = CRS_Reporte;
    }
    protected Reporte informacionReporte()
    {
        Reporte informe = new Reporte();
        List<EProducto> productos = new DAOProducto().obtenerProductos();

        DataTable registroProducto = informe.Producto;
        DataRow fila;

        foreach (EProducto registro in productos)
        {
            fila = registroProducto.NewRow();
            fila["Id"] = registro.Id;
            fila["Nombre"] = registro.Nombre;
            fila["Imagen"] = obtenerImagen(registro.Imagen);

            registroProducto.Rows.Add(fila);
        }

        return informe;
    }
    protected byte[] obtenerImagen(String imagen)
    {
        String urlImagen = Server.MapPath(imagen);

        if (!System.IO.File.Exists(urlImagen))
        {
            urlImagen = Server.MapPath("~\\Imagenes\\" + "NoDisponible.jpg");
        }

        byte[] fileBytes = System.IO.File.ReadAllBytes(urlImagen);

        return fileBytes;

    }

}