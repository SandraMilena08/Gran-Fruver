using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_CarritoCompras : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e) {

    }

    protected void B_CarritoCompras_Click(object sender, EventArgs e) {

        List<ELotes> listaLotesAgotados = new DAOCarritoCompras().ValidarCompra(int.Parse(Session["id"].ToString()));

        if (listaLotesAgotados.Count == 0) {

            if (new DAOCarritoCompras().DescontarCantidadLote(int.Parse(Session["id"].ToString()))) {

                if (new DAOCarritoCompras().CambiarEstadoPedido(int.Parse(Session["id"].ToString()))) {


                } else {
                    // Ocurrio un error actualizando el estado de los pedidos
                }

            } else {
                // Ocurrio un error descontando los lotes                    
            }

        } else {
            // Hay lotes que ya no tienen las cantidades para vender
        }
    }
}