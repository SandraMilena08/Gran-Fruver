<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/ProductosUsuario.aspx.cs" Inherits="View_ProductosUsuario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
     <section class="page-section about-heading position-relative d-block w-100" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="text-center"></h2>
                            <div id="C_ImagenesProductos" class="carousel slide" data-ride="carousel">
                                <div class="carousel-inner">
                                    <div class="carousel-item active" style="text-align: center">
                                        <asp:Image ID="I_imagen1" ImageUrl="~/Imagenes/Aguacate.png" Width="20%" runat="server" />
                                        <br />
                                        <br />
                                        <asp:Label ID="L_Imagen1" runat="server" Text="Aguacate"></asp:Label>
                                    </div>
                                    <div class="carousel-item">
                                        <asp:Image ID="I_imagen2" ImageUrl="~/Imagenes/Berenjena.png" Width="20%" runat="server" />
                                         <br />
                                        <br />
                                        <asp:Label ID="L_Imagen2" runat="server" Text="Berenjena"></asp:Label>
                                    </div>
                                    <div class="carousel-item">
                                        <asp:Image ID="I_imagen3" ImageUrl="~/Imagenes/Arveja.png" Width="20%" runat="server" />
                                         <br />
                                        <br />
                                        <asp:Label ID="L_Imagen3" runat="server" Text="Arveja"></asp:Label>
                                    </div>
                                </div>
                                <a class="carousel-control-prev" href="#carouselExampleControls" role="button" data-slide="prev">
                                    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                    <span class="sr-only">Previous</span>
                                </a>
                                <a class="carousel-control-next" href="#carouselExampleControls" role="button" data-slide="next">
                                    <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                    <span class="sr-only">Next</span>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
     </section>
</asp:Content>

