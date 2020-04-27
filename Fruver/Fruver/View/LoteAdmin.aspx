<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/LoteAdmin.aspx.cs" Inherits="View_LoteAdmin" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view three_columns_grid_view" runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Lotes" DataKeyNames="id">
            <Columns>
                <asp:TemplateField HeaderText="Nombre_lote" SortExpression="Nombre_lote">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Nombre" runat="server" Text='<%# Bind("Nombre_lote") %>' ValidationGroup="GV_CrearLote" ></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RFV_Nombre_lote" runat="server" ControlToValidate="TB_Nombre" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre_lote") %>' ValidationGroup="GV_CrearLote"></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Cantidad" SortExpression="Cantidad">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Cantidad" runat="server" Text='<%# Bind("Cantidad") %>' ValidationGroup="GV_CrearLote" TextMode="Number"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RFV_Cantidad" runat="server" ControlToValidate="TB_Cantidad" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label2" runat="server" Text='<%# Bind("Cantidad") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Precio" SortExpression="Precio">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Precio" runat="server" Text='<%# Bind("Precio") %>' ValidationGroup="GV_CrearLote" TextMode="Number" ></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server" ControlToValidate="TB_Precio" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" Text='<%# Bind("Precio") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Producto" SortExpression="Producto_id">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Producto" runat="server" Text='<%# Bind("Producto_id") %>' ValidationGroup="GV_CrearLote"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator2" runat="server" ControlToValidate="TB_Producto" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label4" runat="server" Text='<%# Bind("Producto_id") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Fecha_ingreso" SortExpression="Fecha_ingreso">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_fecha_ingreso" runat="server"  Text='<%# Bind("fecha_ingreso_mostrar") %>'  ValidationGroup="GV_CrearLote" TextMode="Date"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator3" runat="server" ControlToValidate="TB_fecha_ingreso" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label5" runat="server" Text='<%# Bind("fecha_ingreso_mostrar") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Fecha_vencimiento" SortExpression="Fecha_vencimiento">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_fecha_vencimiento" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>'  ValidationGroup="GV_CrearLote" TextMode="Date" ></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator4" runat="server" ControlToValidate="TB_fecha_vencimiento" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label6" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>' ></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Lotes" runat="server" DataObjectTypeName="ELotes" DeleteMethod="eliminarLotes" InsertMethod="eliminarLotes" SelectMethod="obtenerLote" TypeName="DAOLotes" UpdateMethod="actualizarLotes"></asp:ObjectDataSource>
    </div>
</asp:Content>


