using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_ReporteAdmin : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        CRS_ReporteAdmin.ReportDocument.SetDataSource(informacionReporte());
        CRV_ReporteAdmin.ReportSource = CRS_ReporteAdmin;
    }
    protected ReporteAdmin informacionReporte()
    {
        ReporteAdmin informe = new ReporteAdmin();
        List<EUsuario> usuarios = new DAOUsuario().buscarUsuario();

        DataTable registroAdmin = informe.Operario;
        DataRow fila;

        foreach (EUsuario registro in usuarios)
        {
            fila = registroAdmin.NewRow();
            fila["id"] = registro.Id;
            fila["nombre"] = registro.Nombre;
            fila["username"] = registro.UserName;
            fila["correo"] = registro.Correo;
            fila["codigo"] = registro.Password;
            fila["celular"] = registro.Celular;


            registroAdmin.Rows.Add(fila);
        }

        return informe;
    }
}