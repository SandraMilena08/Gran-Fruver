using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class View_MasterOperario : System.Web.UI.MasterPage
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["rolId"] != null)
        {
            if (int.Parse(Session["rolId"].ToString()) != 2) 
            {
                Response.Redirect("Index.aspx");
            }

        } else
            Response.Redirect("Index.aspx");
    }
    
    protected void IB_CerrarSesion_Click(object sender, ImageClickEventArgs e)
    {
        Session.Abandon();
        Response.Cookies.Add(new HttpCookie("ASP.NET_SessionId", ""));
        
    }
}
