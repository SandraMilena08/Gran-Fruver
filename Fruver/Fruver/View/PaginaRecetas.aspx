<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/PaginaRecetas.aspx.cs" Inherits="Controller_PaginaRecetas" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <section class="page-section about-heading position-relative d-block w-100" style="margin: 80px auto;">
        <div id="gv_cntr">
            <asp:GridView runat="server" ID="GV_Recetas" style="font-size:15px" class="grid_view four_columns_grid_view" AutoGenerateColumns="False" DataSourceID="ODS_Receta" OnRowCommand="GV_Recetas_RowCommand" DataKeyNames="Id" OnRowUpdating="GV_Recetas_RowUpdating">
                <Columns>
                    <asp:TemplateField HeaderText="Nombre" SortExpression="Nombre">
                        <EditItemTemplate>
                            <asp:TextBox ID="TB_EditarNombre" runat="server" Text='<%# Bind("Nombre") %>'></asp:TextBox>
                        </EditItemTemplate>
                        <ItemTemplate>
                            <asp:Label ID="LB_NombreReceta" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Descripcion" SortExpression="Descripcion">
                        <EditItemTemplate>
                            <asp:TextBox ID="TB_EditarDescripcion" runat="server" Text='<%# Bind("Descripcion") %>'></asp:TextBox>
                        </EditItemTemplate>
                        <ItemTemplate>
                            <asp:Label ID="Label2" runat="server" Text='<%# Bind("Descripcion") %>'></asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="ImagenUrl" SortExpression="ImagenUrl">
                        <EditItemTemplate>
                            <asp:FileUpload ID="FU_EditarImagen" runat="server" />
                        </EditItemTemplate>
                        <ItemTemplate>
                            <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ImagenUrl") %>' Width="40%" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="ProductoId" SortExpression="ProductoId">
                        <EditItemTemplate>
                            <asp:CheckBoxList ID="CBL_EditarReceta" runat="server" DataSourceID="ODS_Recetas" DataTextField="Nombre" DataValueField="Id">
                            </asp:CheckBoxList>
                            <asp:ObjectDataSource ID="ODS_Recetas" runat="server" SelectMethod="obtenerProductosRecetas" TypeName="DAOProducto"></asp:ObjectDataSource>
                        </EditItemTemplate>
                        <ItemTemplate>
                            <asp:GridView ID="GV_Productos" class="grid_view two_columns_grid_view no_header" runat="server" DataSource='<%# Bind("ListaProductos") %>' AutoGenerateColumns="False">
                                <Columns>
                                    <asp:TemplateField ShowHeader="False">
                                        <ItemTemplate>
                                            <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField ShowHeader="False">
                                        <ItemTemplate>
                                            <asp:Image ID="Image2" runat="server" ImageUrl='<%# Bind("Imagen") %>' Width="20%" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:CommandField ButtonType="Image" CancelImageUrl="~/View/icons/close.png" EditImageUrl="~/View/icons/edit.png" ShowEditButton="True" UpdateImageUrl="~/View/icons/edit.png" />
                    <asp:CommandField ButtonType="Image" DeleteImageUrl="~/View/icons/close.png" ShowDeleteButton="True" />
                </Columns>
            </asp:GridView>
            <asp:ObjectDataSource ID="ODS_Receta" runat="server" DataObjectTypeName="EReceta" DeleteMethod="eliminarReceta" SelectMethod="obtenerReceta" TypeName="DAOReceta" UpdateMethod="actualizarReceta">
                <DeleteParameters>
                    <asp:Parameter Name="id" Type="Int32" />
                </DeleteParameters>
            </asp:ObjectDataSource>
        </div>

    </section>
    <a href="CrearReceta.aspx" class="d-block pt-4 text-light text-center" style="font-size: 15px; text-transform: none;">Crear Receta</a>
</asp:Content>

