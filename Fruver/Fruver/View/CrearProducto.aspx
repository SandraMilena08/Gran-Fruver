<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/CrearProducto.aspx.cs" Inherits="View_CrearProducto" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <section class="page-section about-heading position-relative d-block w-50" style="margin: 80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="section-heading mb-4">
                                <span class="section-heading-lower text-center mb-4">Crear Producto</span>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre Producto</label>
                                    <asp:TextBox ID="TB_Nombre" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearProducto" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Nombre" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Nombre"></asp:RequiredFieldValidator>
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputPassword1">Imagen Producto</label>
                                    <asp:FileUpload ID="FU_ImagenProducto" class="w-75 p-3" runat="server" style="font-size: 20px;" />
                                </div>
                                <center>
                                    <asp:Button ID="B_CrearProducto"  runat="server" Text="Crear Producto" class="btn btn-primary" OnClick="B_CrearProducto_Click" />
                                </center>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

