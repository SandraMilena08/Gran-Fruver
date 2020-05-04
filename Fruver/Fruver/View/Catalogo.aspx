<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/Catalogo.aspx.cs" Inherits="View_Catalogo" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view three_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Producto" DataKeyNames="id">
            <Columns>
                <asp:TemplateField HeaderText="Nombre" SortExpression="Nombre">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("Nombre") %>'></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator2" runat="server" ControlToValidate="TextBox2" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Imagen" SortExpression="Imagen">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("Imagen") %>' ValidationGroup="GV_Usuario" ></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server" ControlToValidate="TextBox1" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Imagen") %>' ValidationGroup="GV_Usuario"/>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Disponibilidad" SortExpression="Disponibilidad">
                    <ItemTemplate>
                        <asp:CheckBox ID="CB_Disponibilidad" runat="server" Checked='<%# Bind("Disponibilidad") %>' ValidationGroup="GV_Usuario" Enabled="false" />
                    </ItemTemplate>
                </asp:TemplateField>
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Producto" runat="server" DataObjectTypeName="EProducto"  DeleteMethod="eliminarProducto" InsertMethod="insertarProductoNuevo" SelectMethod="obtenerProductos" TypeName="DAOProducto" UpdateMethod="actualizarProducto"></asp:ObjectDataSource>
    </div>
   
</asp:Content>


