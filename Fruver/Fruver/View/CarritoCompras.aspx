<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/CarritoCompras.aspx.cs" Inherits="View_CarritoCompras" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:GridView ID="GV_CarritoCompras" class="grid_view four_columns_grid_view" runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Carrito_Compras" DataKeyNames="Id">
            <Columns>
                <asp:BoundField DataField="Cantidad" HeaderText="Cantidad" SortExpression="Cantidad" />
                <asp:BoundField DataField="Fecha" HeaderText="Fecha" SortExpression="Fecha" />
                <asp:TemplateField HeaderText="Producto" SortExpression="DetalleLote">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("DetalleLote") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("DetalleLote.Producto.Imagen") %>' />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="TipoVenta" HeaderText="Venta" SortExpression="TipoVenta" />
                <asp:BoundField DataField="Precio" HeaderText="Precio" SortExpression="Precio" />
                <asp:CommandField ButtonType="Image" DeleteImageUrl="~/View/icons/close.png" ShowDeleteButton="True" />
            </Columns>
        </asp:GridView>
        <asp:ObjectDataSource ID="ODS_Carrito_Compras" runat="server" SelectMethod="LeerPedidosCliente" TypeName="DAOCarritoCompras" DataObjectTypeName="ECarritoCompras" DeleteMethod="eliminarCarrito">
            <SelectParameters>
                <asp:SessionParameter Name="usuarioId" SessionField="id" Type="Int32" />
            </SelectParameters>
        </asp:ObjectDataSource>
    </div>
    <center>
      <asp:Button ID="B_CarritoCompras"  runat="server" Text="Comprar" class="btn btn-primary" OnClick="B_CarritoCompras_Click" />
    </center>
</asp:Content>

