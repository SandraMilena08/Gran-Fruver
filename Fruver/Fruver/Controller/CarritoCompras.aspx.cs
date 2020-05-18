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
        ClientScriptManager cm = this.ClientScript;

        if (listaLotesAgotados.Count == 0) {

            if (new DAOCarritoCompras().DescontarCantidadLote(int.Parse(Session["id"].ToString()))) {

                if (new DAOCarritoCompras().CambiarEstadoPedido(int.Parse(Session["id"].ToString()))) {


                } else {
                    cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('Error no se puede comprar');</script>");
                }

            } else {
                cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No se pudo realizar la compra');</script>");
            }

        } else {
            cm.RegisterClientScriptBlock(this.GetType(), "", "<script type='text/javascript'>alert('No hay suficiente cantidad');</script>");
        }

        GV_CarritoCompras.DataBind();
    }


}