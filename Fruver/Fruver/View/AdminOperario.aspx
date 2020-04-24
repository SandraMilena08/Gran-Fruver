<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/AdminOperario.aspx.cs" Inherits="View_AdminOperario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">


    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />  

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">

    <!-- Grid View -->
    <div id="gv_cntr">
        <asp:GridView ID="GV_IngresoOperario" runat="server" class="grid_view" AutoGenerateColumns="False" DataKeyNames="Id" DataSourceID="ODS_Ingreso">

            <Columns>
                <asp:TemplateField HeaderText="Nombre" SortExpression="Nombre">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("Nombre") %>' ValidationGroup="GV_Usuario" Width="116px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="UserName" SortExpression="UserName">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("UserName") %>' ValidationGroup="GV_Usuario" Width="109px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label2" runat="server" Text='<%# Bind("UserName") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Correo" SortExpression="Correo">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox3" runat="server" Text='<%# Bind("Correo") %>' ValidationGroup="GV_Usuario" Width="128px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" Text='<%# Bind("Correo") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Password" SortExpression="Password">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox4" runat="server" Text='<%# Bind("Password") %>' ValidationGroup="GV_Usuario" Width="120px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label4" runat="server" Text='<%# Bind("Password") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Celular" SortExpression="Celular">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox5" runat="server" Text='<%# Bind("Celular") %>' ValidationGroup="GV_Usuario"  Width="120px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label5" runat="server" Text='<%# Bind("Celular") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Direccion" SortExpression="Direccion">
                    <EditItemTemplate>
                        <asp:TextBox ID="TextBox6" runat="server" Text='<%# Bind("Direccion") %>' ValidationGroup="GV_Usuario" Width="113px"></asp:TextBox>
                    </EditItemTemplate>
                    <ItemTemplate>
                        <asp:Label ID="Label6" runat="server" Text='<%# Bind("Direccion") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:CommandField ButtonType="Image" CancelImageUrl="~/View/icons/close.png" EditImageUrl="~/View/icons/edit.png" HeaderText="Editar" ShowEditButton="True" UpdateImageUrl="~/View/icons/edit.png" ValidationGroup="GV_Usuario" />
                <asp:CommandField DeleteImageUrl="~/View/icons/close.png" HeaderText="Eliminar" ShowDeleteButton="True" ButtonType="Image" />
            </Columns>
        </asp:GridView>
        <asp:ObjectDataSource ID="ODS_Ingreso" runat="server" DataObjectTypeName="EUsuario" DeleteMethod="eliminarUsuario" InsertMethod="insertarUsuario" SelectMethod="buscarUsuario" TypeName="DAOUsuario" UpdateMethod="actualizarUsuario"></asp:ObjectDataSource>
      </div>
    <a href="AgregarOperario.aspx" class="d-block pt-4 text-light text-center" style="font-size:15px; text-transform:none;">Agregar Operario</a>
</asp:Content>

