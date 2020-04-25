<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/InventarioProducto.aspx.cs" Inherits="View_InventarioProducto" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view six_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Producto" DataKeyNames="id" OnRowCommand="GV_InventarioProducto_RowCommand" >
            <Columns>
                <asp:BoundField DataField="Nombre" HeaderText="Nombre" SortExpression="Nombre" />
                <asp:TemplateField HeaderText="Imagen" SortExpression="Imagen">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("Imagen") %>' ValidationGroup="GV_Usuario"></asp:TextBox>
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
                <asp:CommandField ButtonType="Image" CancelImageUrl="~/View/icons/close.png" EditImageUrl="~/View/icons/edit.png" HeaderText="Editar" ShowEditButton="True" UpdateImageUrl="~/View/icons/edit.png" ValidationGroup="GV_Usuario"/>
                <asp:CommandField DeleteImageUrl="~/View/icons/close.png" HeaderText="Eliminar" ShowDeleteButton="True" ButtonType="Image" />
                <asp:ButtonField ButtonType="Image" CommandName="Ver_Detalle" Text="Ver detalles" ImageUrl="~/View/icons/read-more.png" />
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Producto" runat="server" DataObjectTypeName="EProducto"  DeleteMethod="eliminarProducto" InsertMethod="insertarProductoNuevo" SelectMethod="obtenerProductos" TypeName="DAOProducto" UpdateMethod="actualizarProducto"></asp:ObjectDataSource>
    </div>
    <a href="CrearProducto.aspx" class="d-block pt-4 text-light text-center" style="font-size:15px; text-transform:none;">Crear Producto</a>
</asp:Content>

