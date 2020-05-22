using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_ReporteLote : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        CRS_ReporteLote.ReportDocument.SetDataSource(informacionReporte());
        CRV_ReporteLote.ReportSource = CRS_ReporteLote;
    }
    protected ReporteLote informacionReporte()
    {
        ReporteLote informe = new ReporteLote();
        List<ELotes> lotes = new DAOLotes().obtenerLote();

        DataTable registroLote = informe.Lote;
        DataRow fila;

        foreach (ELotes registro in lotes)
        {
            fila = registroLote.NewRow();
            fila["id"] = registro.Id;
            fila["nombre"] = registro.Nombre_lote;
            fila["cantidad"] = registro.Cantidad;
            fila["precio"] = registro.Precio;
            fila["FechaIngreso"] = registro.Fecha_ingreso_mostrar;
            fila["FechaVencimiento"] = registro.Fecha_vencimiento_mostrar;
         

            registroLote.Rows.Add(fila);
        }

        return informe;
    }
}