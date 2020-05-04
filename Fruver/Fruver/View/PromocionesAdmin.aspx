<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/PromocionesAdmin.aspx.cs" Inherits="View_PromocionesAdmin" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        &nbsp;&nbsp;&nbsp;
        <asp:gridview id="GV_InventarioProducto" class="grid_view six_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Promociones">
            <Columns>
                <asp:BoundField DataField="Id" HeaderText="Id" SortExpression="Id" />
                <asp:BoundField DataField="Nombre" HeaderText="Nombre" SortExpression="Nombre" />
                <asp:BoundField DataField="Imagen" HeaderText="Imagen" SortExpression="Imagen" />
                <asp:CheckBoxField DataField="Disponibilidad" HeaderText="Disponibilidad" SortExpression="Disponibilidad" />
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Promociones" runat="server" SelectMethod="Promociones" TypeName="DAOProducto"></asp:ObjectDataSource>
    </div>
   
</asp:Content>



