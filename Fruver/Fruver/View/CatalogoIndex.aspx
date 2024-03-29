﻿<%@ Page Title="" Language="C#" MasterPageFile="~/View/Master.master" AutoEventWireup="true" CodeFile="~/Controller/CatalogoIndex.aspx.cs" Inherits="View_CatalogoIndex" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view two_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Producto">

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
                         <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Imagen") %>' ValidationGroup="GV_Catalogo"/>
                    </ItemTemplate>
                </asp:TemplateField>
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Producto" runat="server" DataObjectTypeName="EProducto"  DeleteMethod="eliminarProducto" InsertMethod="insertarProductoNuevo" SelectMethod="obtenerProductoCatalogo" TypeName="DAOProducto" UpdateMethod="actualizarProducto"></asp:ObjectDataSource>
    </div>
   
</asp:Content>







