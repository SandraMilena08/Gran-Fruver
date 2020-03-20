<%@ Page Title="" Language="C#" MasterPageFile="~/View/Master.master" AutoEventWireup="true" CodeFile="~/Controller/GenerarToken.aspx.cs" Inherits="View_GenerarToken" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server"> 
</asp:Content> 
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server"> 
    <section class="page-section about-heading position-relative d-block w-50" style="margin:80px auto;"> 
        <div class="container"> 
            <div class="about-heading-content"> 
                <div class="row"> 
                    <div class="col-xl-9 col-lg-10 mx-auto"> 
                        <div class="bg-faded rounded p-5"> 
                            <h2 class="section-heading mb-4"> 
                                <span class="section-heading-lower text-center mb-4" style="font-size:35px">Recuperar Contraseña</span> 
                                <div class="input-group flex-nowrap"> 
                                    <asp:TextBox ID="TB_RecuperarNombreUsuario" class="form-control" style="font-size:12px" placeholder="Nombre Usuario" aria-label="Username" aria-describedby="addon-wrapping" runat="server"  ValidationGroup="VG_GenerarToken" MaxLength="20"></asp:TextBox> 
                                    <asp:RequiredFieldValidator ID="RV_RecuperarNombreUsuario" runat="server" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" ErrorMessage="*" ControlToValidate="TB_RecuperarNombreUsuario" ></asp:RequiredFieldValidator> 
                                </div> 
                                <center> 
                                    <asp:Button ID="B_GenerarToken" runat="server" Text="Recuperar" class="btn btn-primary"/> 
                                </center> 
                            </h2> 
                        </div> 
                    </div> 
                </div> 
            </div> 
        </div> 
    </section> 
</asp:Content> 
 

