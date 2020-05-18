<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/PromocionesOperario.aspx.cs" Inherits="View_PromocionesOperario" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view six_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Promociones">
            <Columns>
                <asp:BoundField DataField="Id" HeaderText="Id" SortExpression="Id" />
                <asp:BoundField DataField="FechaVencimiento1" HeaderText="FechaVencimiento1" SortExpression="FechaVencimiento1" />
                <asp:BoundField DataField="Lote_id" HeaderText="Lote_id" SortExpression="Lote_id" />
                <asp:BoundField DataField="TipoVentaId" HeaderText="TipoVentaId" SortExpression="TipoVentaId" />
                <asp:CheckBoxField DataField="Estado" HeaderText="Estado" SortExpression="Estado" />
                <asp:BoundField DataField="Precio" HeaderText="Precio" SortExpression="Precio" />
                <asp:BoundField DataField="Cantidad" HeaderText="Cantidad" SortExpression="Cantidad" />
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Promociones" runat="server" SelectMethod="obtenerPromociones" TypeName="DAOProducto"></asp:ObjectDataSource>
    </div>
   
</asp:Content>




