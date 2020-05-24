using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_FacturaCompra : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        List<ECarritoCompras> compras = new DAOCarritoCompras().obtenerFactura(int.Parse(Session["id"].ToString()));
        double total = 0;
        foreach (ECarritoCompras compra in compras)
        {
            total += compra.TotalCompra;
        }
        L_Total.Text = "TOTAL A PAGAR: " + total;
    }
}