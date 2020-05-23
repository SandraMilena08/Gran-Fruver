<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/FacturaCompra.aspx.cs" Inherits="View_FacturaCompra" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link rel="stylesheet" href="css/gridViewModificado.css" type="text/css" />
    <link rel="stylesheet" href="fonts/fonts.css" type="text/css" />
    <style type="text/css">
        .auto-style2 {
            font-size: medium;
        }
        .auto-style3 {
            font-size: small;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">

    <br />
    <section class="page-section about-heading position-relative d-block w-50" style="margin:80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-16 col-lg-17 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="text-center">
                                &nbsp;FACTURA DE COMPRA<center>
                                <div class="text-center">
                                    <br />
                                     </center>
                                <center>
                                    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" CssClass="auto-style2" DataSourceID="ODS_Factura" Width="543px">
                                        <Columns>
                                            <asp:BoundField DataField="Nombre" HeaderText="Nombre" SortExpression="Nombre" />
                                            <asp:BoundField DataField="Correo" HeaderText="Correo" SortExpression="Correo" />
                                            <asp:BoundField DataField="Celular" HeaderText="Celular" SortExpression="Celular" />
                                            <asp:BoundField DataField="Direccion" HeaderText="Direccion" SortExpression="Direccion" />
                                        </Columns>
                                    </asp:GridView>
                                    <asp:ObjectDataSource ID="ODS_Factura" runat="server" SelectMethod="obtenerComprador" TypeName="DAOCarritoCompras">
                                        <SelectParameters>
                                            <asp:SessionParameter Name="idUsuario" SessionField="id" Type="Int32" />
                                        </SelectParameters>
                                    </asp:ObjectDataSource>
                                    <br />
                                     <center>
                                    <div class="text-center">
                                <asp:GridView ID="GV_CarritoCompras" class="grid_view four_columns_grid_view" runat="server" AutoGenerateColumns="False" DataSourceID="ODS_FacturaCompra" CssClass="auto-style2" Width="540px">
                                 <Columns>
                                     <asp:BoundField DataField="NombreLote" HeaderText="Producto" SortExpression="NombreLote" />
                                     <asp:BoundField DataField="Cantidad" HeaderText="Cantidad" SortExpression="Cantidad" />
                                     <asp:BoundField DataField="Precio" HeaderText="Precio" SortExpression="Precio" />
                                     <asp:BoundField DataField="TipoVenta" HeaderText="Venta" SortExpression="TipoVenta" />
                                     <asp:BoundField DataField="Total" HeaderText="Total" SortExpression="Total" />
                                </Columns>
                            </asp:GridView>
                                  <center>
                                      <span class="auto-style3">
                                      <br />
                                      <asp:Label ID="L_Total" runat="server"></asp:Label>
                                      <br />
                                     !GRACIAS POR SU COMPRA, LO ESPERAMOS PRONTO!</span> </h2>
                                </center>
                                    </div>
                                   </center>
                                    <asp:ObjectDataSource ID="ODS_FacturaCompra" runat="server" SelectMethod="obtenerFactura" TypeName="DAOCarritoCompras">
                                        <SelectParameters>
                                            <asp:SessionParameter Name="UsuarioId" SessionField="id" Type="Int32" />
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



