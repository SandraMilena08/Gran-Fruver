<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/LoteProducto.aspx.cs" Inherits="View_LoteProducto" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />    

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <div id="gv_cntr">
        <asp:gridview id="GV_InventarioProducto" class="grid_view three_columns_grid_view" runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Lotes" DataKeyNames="id" OnRowDeleting="GV_InventarioProducto_RowDeleting" OnRowUpdating="GV_InventarioProducto_RowUpdating">
            <Columns>
                <asp:TemplateField HeaderText="Nombre lote" SortExpression="Nombre Lote">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Nombre" runat="server" Text='<%# Bind("Nombre_lote") %>' ValidationGroup="GV_CrearLote" Width="102px" ValidateRequestMode="Disabled"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RFV_Nombre_lote" runat="server" ControlToValidate="TB_Nombre" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                        <asp:RegularExpressionValidator ID="RegularExpressionValidator4" runat="server" ControlToValidate="TB_Nombre" CssClass="auto-style1" ErrorMessage="Caracteres no validos" style="color: #FF0000; font-size: small" ValidateRequestMode="Disabled" ValidationExpression="^[a-zA-ZñÑ\s-A-Za-zäÄëËïÏöÖüÜáéíóúáéíóúÁÉÍÓÚÂÊÎÔÛâêîôûàèìòùÀÈÌÒÙ.,-]+$"></asp:RegularExpressionValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre_lote") %>' ValidationGroup="GV_CrearLote"></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Cantidad(g)" SortExpression="Cantidad">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Cantidad" runat="server" Text='<%# Bind("Cantidad") %>' ValidationGroup="GV_CrearLote" TextMode="Number" Width="100px" Min="1" Max="9999999"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RFV_Cantidad" runat="server" ControlToValidate="TB_Cantidad" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label2" runat="server" Text='<%# Bind("Cantidad") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Precio" SortExpression="Precio">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_Precio" runat="server" Text='<%# Bind("Precio") %>' ValidationGroup="GV_CrearLote" TextMode="Number" Min="100" Max="9999999" Width="110px"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server" ControlToValidate="TB_Precio" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" Text='<%# Bind("Precio") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Ingreso" SortExpression="Fecha_ingreso">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_fecha_ingreso" runat="server"  Text='<%# Bind("fecha_ingreso_mostrar") %>'  ValidationGroup="GV_CrearLote" TextMode="Date" Width="106px" ReadOnly="true"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator3" runat="server" ControlToValidate="TB_fecha_ingreso" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label5" runat="server" Text='<%# Bind("fecha_ingreso_mostrar") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Vencimiento" SortExpression="Fecha_vencimiento">
                    <EditItemTemplate>
                        <asp:TextBox ID="TB_fecha_vencimiento" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>'  ValidationGroup="GV_CrearLote" TextMode="Date" Width="114px"  ReadOnly="true" ></asp:TextBox>
                        <asp:RequiredFieldValidator ID="RequiredFieldValidator4" runat="server" ControlToValidate="TB_fecha_vencimiento" ErrorMessage="*" ForeColor="Red"></asp:RequiredFieldValidator>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label6" runat="server" Text='<%# Bind("fecha_vencimiento_mostrar") %>' ></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                 <asp:CommandField ButtonType="Image" CancelImageUrl="~/View/icons/close.png" EditImageUrl="~/View/icons/edit.png" HeaderText="Editar" ShowEditButton="True" UpdateImageUrl="~/View/icons/edit.png" ValidationGroup="GV_CrearLote" />
                <asp:CommandField DeleteImageUrl="~/View/icons/close.png" HeaderText="Eliminar" ShowDeleteButton="True" ButtonType="Image" />
                </Columns>
         </asp:gridview>
        <asp:ObjectDataSource ID="ODS_Lotes" runat="server" DataObjectTypeName="ELotes" DeleteMethod="eliminarLotes" InsertMethod="insertarLote" SelectMethod="obtenerLote" TypeName="DAOLotes" UpdateMethod="actualizarLotes"></asp:ObjectDataSource>
    </div>
    <a href="CrearLotesOperario.aspx" class="d-block pt-4 text-light text-center" style="font-size:15px; text-transform:none;">Crear Lote</a>
    <center>
         <asp:Button ID="B_ReporteLote"  runat="server" Text="Reporte Lote" class="btn btn-primary" OnClick="B_ReporteLote_Click" />
     </center>
</asp:Content>


