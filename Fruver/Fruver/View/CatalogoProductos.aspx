<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/CatalogoProductos.cs" Inherits="View_CatalogoProductos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <style type="text/css">
        .auto-style2 {
            height: 20px;
        }
        .auto-style3 {
            text-align: left;
            height: 20px;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">
    <section class="page-section about-heading position-relative d-block w-100" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="section-heading mb-4">
                                <span class="section-heading-lower text-center mb-4">Catalogo Productos</span>
                                <div class="text-center">
                                    <asp:DataList ID="DL_Catalogo" Style="font-size: 17px" runat="server" DataSourceID="ODS_CatalagoProductos" RepeatDirection="Horizontal" OnItemCommand="DL_Catalogo_ItemCommand" RepeatColumns="3">
                                        <ItemTemplate>
                                            &nbsp;<asp:Label ID="NombreProductoLabel" runat="server" Text='<%# Eval("NombreProducto") %>' />
                                            <br />
                                            <table class="w-100">
                                                <tr>
                                                    <td class="text-center" colspan="2">
                                                        <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Producto.Imagen") %>' Width="20%" />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Nombre:</td>
                                                    <td class="text-left">
                                                        <asp:Label ID="ProductoLabel" runat="server" Text='<%# Eval("Producto.Nombre") %>' />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Precio:</td>
                                                    <td class="text-left">
                                                        <asp:Label ID="PrecioLabel" runat="server" Text='<%# Eval("Precio") %>' />
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">Cantidad disponible:</td>
                                                    <td class="text-left">
                                                        <asp:Label ID="L_CantidadDisponible" runat="server" Text='<%# Eval("Cantidad") %>'></asp:Label>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style2">Cantidad:</td>
                                                    <td class="auto-style3">
                                                        <asp:TextBox ID="TB_CantidadCarrito" runat="server" TextMode="Number" Min="1" Max='<%# Eval("Cantidad") %>' Width="44px" Height="21px" ValidationGroup='<%# Eval("Id") %>' ></asp:TextBox>
                                                        <asp:RequiredFieldValidator ID="RFV_Cantidad" runat="server" ErrorMessage="*" ControlToValidate="TB_CantidadCarrito" ValidationGroup='<%# Eval("Id") %>'></asp:RequiredFieldValidator>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="auto-style4">
                                                        <asp:Button ID="B_Receta" class="btn btn-primary" runat="server" Text="Receta" ValidationGroup="VG_Receta" CommandName="Receta" CommandArgument='<%# Eval("Producto.Id") %>' />
                                                    </td>
                                                    <td class="text-left">
                                                        <asp:ImageButton ID="I_Carrito" runat="server" ImageUrl="~/View/icons/cart-plus.png" Width="30%" ValidationGroup='<%# Eval("Id") %>' CommandName="Carrito" CommandArgument='<%# Eval("Id") %>' />
                                                    </td>
                                                </tr>
                                            </table>
                                            <br />
                                        </ItemTemplate>
                                    </asp:DataList>
                                </div>
                                <asp:ObjectDataSource ID="ODS_CatalagoProductos" runat="server" SelectMethod="LeerLotesCatalogo" TypeName="DAOLotes"></asp:ObjectDataSource>

                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

