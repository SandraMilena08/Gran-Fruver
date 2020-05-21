<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/RecetasUsuario.aspx.cs" Inherits="View_RecetasUsuario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <section class="page-section about-heading position-relative d-block w-100" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="text-center"></h2>
                            <div id="gv_cntr">
                                <asp:GridView ID="GV_RecetasUsuario" class="grid_view three_columns_grid_view" runat="server" AutoGenerateColumns="False" DataSourceID="ODS_Recetas">
                                    <Columns>
                                        <asp:BoundField DataField="Nombre" HeaderText="Nombre" SortExpression="Nombre" />
                                        <asp:BoundField DataField="Descripcion" HeaderText="Descripcion" SortExpression="Descripcion" />
                                        <asp:BoundField DataField="ImagenUrl" HeaderText="Imagen" SortExpression="ImagenUrl" />
                                    </Columns>
                                </asp:GridView>
                                <asp:ObjectDataSource ID="ODS_Recetas" runat="server" SelectMethod="ObtenerRecetasProducto" TypeName="DAOReceta">
                                    <SelectParameters>
                                        <asp:QueryStringParameter Name="idProducto" QueryStringField="id" Type="Int32" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

