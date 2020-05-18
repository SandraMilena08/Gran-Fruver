<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/ProductoDetalle.aspx.cs" Inherits="View_ProductoDetalle" %>

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
                            <h2 class="text-center">
                                <asp:Label ID="L_Nombre" style="font-size: 15px;" runat="server" Text=""></asp:Label>
                                <asp:Image ID="I_Imagen" runat="server" Height="15%" Width="15%" />
                                 <br />
                                 <br />
                                <div class="text-center">
                                <asp:GridView ID="GV_Lotes" style="font-size: 15px;" runat="server" class="grid_view six_columns_grid_view" AutoGenerateColumns="False" DataSourceID="ODS_Lotes" CellPadding="4" ForeColor="#333333" GridLines="None" HorizontalAlign="Center">
                                    <AlternatingRowStyle BackColor="White" />
                                    <Columns>
                                        <asp:BoundField DataField="Cantidad" HeaderText="Cantidad" SortExpression="Cantidad" />
                                        <asp:BoundField DataField="Precio" HeaderText="Precio" SortExpression="Precio" />
                                        <asp:BoundField DataField="Producto_id" HeaderText="Producto" SortExpression="Producto_id" />
                                        <asp:BoundField DataField="Nombre_lote" HeaderText="Nombre lote" SortExpression="Nombre_lote" />
                                        <asp:BoundField DataField="Fecha_ingreso" HeaderText="Fecha ingreso" SortExpression="Fecha_ingreso" DataFormatString="{0:d}" />
                                        <asp:BoundField DataField="Fecha_vencimiento" HeaderText="Fecha vencimiento" SortExpression="Fecha_vencimiento" DataFormatString="{0:d}" />
                                    </Columns>
                                    <EditRowStyle BackColor="#7C6F57" />
                                    <FooterStyle BackColor="#1C5E55" Font-Bold="True" ForeColor="White" />
                                    <HeaderStyle BackColor="#cc3300" Font-Bold="True" ForeColor="White" />
                                    <PagerStyle BackColor="#666666" ForeColor="White" HorizontalAlign="Center" />
                                    <RowStyle BackColor="#E3EAEB" />
                                    <SelectedRowStyle BackColor="#C5BBAF" Font-Bold="True" ForeColor="#333333" />
                                    <SortedAscendingCellStyle BackColor="#F8FAFA" />
                                    <SortedAscendingHeaderStyle BackColor="#246B61" />
                                    <SortedDescendingCellStyle BackColor="#D4DFE1" />
                                    <SortedDescendingHeaderStyle BackColor="#15524A" />
                                </asp:GridView>
                                    <br />
                                    <asp:Button ID="B_VolverInventario" class="btn btn-primary" runat="server" Text="Volver" OnClick="B_VolverInventario_Click" />
                                    <br />
                                </div>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <asp:ObjectDataSource ID="ODS_Lotes" runat="server" SelectMethod="obtenerloteProducto" TypeName="DAOProducto">
        <SelectParameters>
            <asp:QueryStringParameter Name="id" QueryStringField="id" Type="Int32" />
        </SelectParameters>
    </asp:ObjectDataSource>
</asp:Content>

