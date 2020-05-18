<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/PromocionesOperario.aspx.cs" Inherits="View_PromocionesOperario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_Promociones" class="grid_view six_columns_grid_view " runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Promociones" OnRowDeleting="GV_InventarioProducto_RowDeleting" DataKeyNames="id">
            <Columns>
                <asp:TemplateField HeaderText="NombreLote" SortExpression="NombreLote">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("NombreLote") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("NombreLote") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Imagen" SortExpression="Imagen">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("Imagen") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                       <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Imagen") %>' ValidationGroup="GV_Promocion"/>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Precio" SortExpression="Precio">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox3" runat="server" Text='<%# Bind("Precio") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" Text='<%# Bind("Precio") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Cantidad" SortExpression="Cantidad">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox4" runat="server" Text='<%# Bind("Cantidad") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label4" runat="server" Text='<%# Bind("Cantidad") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Disponibilidad" SortExpression="Disponibilidad">
                    <EditItemTemplate>
                        <asp:CheckBox ID="CheckBox1" runat="server" Checked='<%# Bind("Disponibilidad") %>' />
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:CheckBox ID="CB_Disponibilidad" runat="server" Checked='<%# Bind("Disponibilidad") %>' Enabled="false" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Vencimiento" SortExpression="FechaVencimiento1">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox5" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>'></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label5" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                 <asp:CommandField DeleteImageUrl="~/View/icons/close.png" HeaderText="Eliminar" ShowDeleteButton="True" ButtonType="Image" />
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Promociones" runat="server" DataObjectTypeName="EPromociones" DeleteMethod="eliminarPromocion" SelectMethod="obtenerPromociones" TypeName="DAOPromociones"></asp:ObjectDataSource>
    </div>
</asp:Content>

