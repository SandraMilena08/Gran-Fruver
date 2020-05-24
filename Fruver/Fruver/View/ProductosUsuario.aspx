<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/ProductosUsuario.aspx.cs" Inherits="View_ProductosUsuario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
     <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
     <div id="gv_cntr"> 
        <asp:GridView ID="GV_Productos" class="grid_view four_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Producto"> 
            <Columns> 
                <asp:TemplateField HeaderText="Nombre" SortExpression="Nombre"> 
                    <EditItemTemplate> 
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("Nombre") %>'></asp:TextBox> 
                    </EditItemTemplate> 
                    <ItemTemplate> 
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label> 
                    </ItemTemplate> 
                </asp:TemplateField> 
                <asp:TemplateField HeaderText="Imagen" SortExpression="Imagen"> 
                    <EditItemTemplate> 
                        <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("Imagen") %>'></asp:TextBox> 
                    </EditItemTemplate> 
                    <ItemTemplate> 
                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Imagen") %>' ValidationGroup="GV_Catalogo" /> 
                    </ItemTemplate> 
                </asp:TemplateField> 
                <asp:TemplateField HeaderText="Cantidad" SortExpression="Cantidad"> 
                    <EditItemTemplate> 
                        <asp:TextBox ID="TextBox3" runat="server" Text='<%# Bind("Cantidad") %>'></asp:TextBox> 
                    </EditItemTemplate> 
                    <ItemTemplate> 
                        <asp:Label ID="Label3" runat="server" Text='<%# Bind("Cantidad") %>'></asp:Label> 
                    </ItemTemplate> 
                </asp:TemplateField> 
                <asp:TemplateField HeaderText="Precio" SortExpression="Precio"> 
                    <EditItemTemplate> 
                        <asp:TextBox ID="TextBox4" runat="server" Text='<%# Bind("Precio") %>'></asp:TextBox> 
                    </EditItemTemplate> 
                    <ItemTemplate> 
                        <asp:Label ID="Label4" runat="server" Text='<%# Bind("Precio") %>'></asp:Label> 
                    </ItemTemplate> 
                </asp:TemplateField> 
            </Columns> 
        </asp:GridView> 
        <asp:ObjectDataSource ID="ODS_Producto" runat="server" DataObjectTypeName="EProducto" SelectMethod="obtenerProductoCatalogo" TypeName="DAOProducto"></asp:ObjectDataSource> 
 
    </div> 
</asp:Content>

