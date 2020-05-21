<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/PromocionesUsuario.aspx.cs" Inherits="View_PromocionesUsuario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <style type="text/css">
        .auto-style2 {
            width: 231px;
        }
        .auto-style3 {
            width: 89px;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <section class="page-section about-heading position-relative d-block w-100" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="section-heading mb-4">
                                <span class="section-heading-lower text-center mb-4">Promociones</span>
                                <asp:DataList ID="DL_Promociones" style="font-size:16px" runat="server" Width="30%" DataSourceID="ODS_Promociones" RepeatDirection="Horizontal" OnItemCommand="DL_Promociones_ItemCommand" RepeatColumns="3">
                                    <ItemTemplate>
                                        <table class="w-100">
                                            <tr>
                                                <td class="text-center" colspan="2">
                                                    <asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("Imagen") %>' Width="20%" />
                                                </td>
                                            </tr>
                                            <tr>
                                                <td class="auto-style2">Precio:</td>
                                                <td class="auto-style3">
                                                    <asp:Label ID="PrecioLabel" runat="server" Text='<%# Eval("Precio") %>' />
                                                </td>
                                            </tr>
                                            <tr>
                                                <td class="auto-style2">Cantidad Disponible:</td>
                                                <td class="auto-style3">
                                                    <asp:Label ID="LB_CantidadPromocion" runat="server" Text='<%# Eval("Cantidad") %>' />
                                                </td>
                                            </tr>
                                            <tr>
                                                <td class="auto-style2">Cantidad:</td>
                                                <td class="auto-style3">
                                                    <asp:TextBox ID="TB_CantidadSolicitada" runat="server" Height="25px" TextMode="Number" Min="1" Max='<%# Eval("Cantidad") %>' Width="49px" ValidationGroup='<%# Eval("Id") %>'></asp:TextBox>
                                                    <asp:RequiredFieldValidator ID="RFV_CantidadPromocion" runat="server" ErrorMessage="*" ControlToValidate="TB_CantidadSolicitada" ValidationGroup='<%# Eval("Id") %>'></asp:RequiredFieldValidator>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td class="auto-style2">&nbsp;</td>
                                                <td class="auto-style3">&nbsp;</td>
                                            </tr>
                                            <tr>
                                                <td class="text-center" colspan="2">
                                                    <asp:ImageButton ID="ImageButton1" runat="server" ImageUrl="~/View/icons/cart-plus.png" Width="25px" ValidationGroup='<%# Eval("Id") %>' CommandArgument='<%# Eval("Lote_id") %>'/>
                                                </td>
                                            </tr>
                                        </table>
<br />
                                    </ItemTemplate>
                                </asp:DataList>
                                <asp:ObjectDataSource ID="ODS_Promociones" runat="server" SelectMethod="obtenerPromocionesDisponibles" TypeName="DAOPromociones"></asp:ObjectDataSource>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

