<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/CatalagoProductos.aspx.cs" Inherits="View_CatalagoProductos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <section class="page-section about-heading position-relative d-block w-50" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="section-heading mb-4">
                                <span class="section-heading-lower text-center mb-4">Catalogo Productos</span>
                                <div class="text-center">
                                    <asp:DataList ID="DataList1" Style="font-size: 17px" runat="server" DataSourceID="ODS_CatalagoProductos">
                                        <ItemTemplate>
                                            &nbsp;<asp:Label ID="NombreProductoLabel" runat="server" Text='<%# Eval("NombreProducto") %>' />
                                            <br />
                                            <table class="w-100">
                                                <tr>
                                                    <td class="text-center" colspan="2">
                                                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Producto.Imagen") %>' Width="15%" />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Nombre:</td>
                                                    <td>
                                                        <asp:Label ID="ProductoLabel" runat="server" Text='<%# Eval("Producto.Nombre") %>' />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Precio:</td>
                                                    <td>
                                                        <asp:Label ID="PrecioLabel" runat="server" Text='<%# Eval("Precio") %>' />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Cantidad:</td>
                                                    <td>
                                                        <asp:Label ID="CantidadLabel" runat="server" Text='<%# Eval("Cantidad") %>' />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">
                                                        <asp:Button ID="B_Receta" class="btn btn-primary" runat="server" Text="Receta" />
                                                    </td>
                                                    <td class="text-left">
                                                        <asp:ImageButton ID="I_Carrito" runat="server" ImageUrl="~/View/icons/cart-plus.png" Width="25%" />
                                                    </td>
                                                </tr>
                                            </table>
                                            <br />
                                        </ItemTemplate>
                                    </asp:DataList>
                                </div>
                                <asp:ObjectDataSource ID="ODS_CatalagoProductos" runat="server" SelectMethod="obtenerLote" TypeName="DAOLotes"></asp:ObjectDataSource>

                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

