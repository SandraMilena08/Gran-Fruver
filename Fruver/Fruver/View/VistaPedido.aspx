<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/VistaPedido.aspx.cs" Inherits="View_VistaPedido" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" /> 
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_VistaPedido" class="grid_view six_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_VistaPedidos" DataKeyNames="Id">
            <Columns>
                <asp:TemplateField HeaderText="Producto" SortExpression="DetalleLoteId">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("DetalleLoteId") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("DetalleLote.Producto.Imagen") %>' Width="30%" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="UsuarioId" SortExpression="UsuarioId">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("UsuarioId") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label2" runat="server" Text='<%# Bind("UsuarioId") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="Fecha" HeaderText="Fecha" SortExpression="Fecha" />
                <asp:BoundField DataField="Cantidad" HeaderText="Cantidad" SortExpression="Cantidad" />
                <asp:BoundField DataField="Precio" HeaderText="Precio" SortExpression="Precio" />
                <asp:CommandField ButtonType="Image" DeleteImageUrl="~/View/icons/check.png" ShowDeleteButton="True" />
            </Columns>
        </asp:gridview>
        <asp:ObjectDataSource ID="ODS_VistaPedidos" runat="server" SelectMethod="obtenerCarrito" TypeName="DAOCarritoCompras" DataObjectTypeName="ECarritoCompras" DeleteMethod="eliminarCarrito">
        </asp:ObjectDataSource>
    </div>
</asp:Content>

