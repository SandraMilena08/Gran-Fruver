<%@ Page Title="" Language="C#" MasterPageFile="~/View/Master.master" AutoEventWireup="true" CodeFile="~/Controller/RegistroUsuario.aspx.cs" Inherits="View_RegistroUsuario" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <style type="text/css">
        .auto-style1 {
            left: 0px;
            top: 0px;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">

    <br />
    <br />
    <br />
    <center>
    <section class="page-section about-heading position-relative d-block w-50"  style="margin:80px auto ;">
        
       <br />    <div class="container">
              <div class="about-heading-content">
                <div class="row">
                    <div class="auto-style1">
                        <div class="bg-faded rounded p-5">
                               <h2 class="section-heading mb-4">
               
                                    <div class="card col-xs-4 col-sm-4 col-md-4 col-lg-4 col-xl-4" style="max-width:359px;"> 
                                           <br /> <div class="bg-faded rounded p-5">
                                          <br />      <h2 class="section-heading mb-4">
                                <span<p class=".text-primary"></p>Registro Usuario</span>
                                 <br />
                                 <br />
                               <center>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre </label>                                    
                                    <asp:TextBox ID="TB_Nombre" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Nombre" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Nombre"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                              <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre de Usuario</label>                                    
                                    <asp:TextBox ID="TB_Username" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Username" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Username"></asp:RequiredFieldValidator>
                                </div>
                               <center>
                              <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Correo</label>                                    
                                    <asp:TextBox ID="TB_Correo" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario" TextMode="Email"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator1" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Correo"></asp:RequiredFieldValidator>
                                </div>
                            <center>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Password</label>
                                    <asp:TextBox ID="TB_Password" class="form-control float-left" Width="95%" runat="server" TextMode="Password" ValidationGroup="VG_RegistroUsuario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Password" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Password"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Celular</label>
                                    <asp:TextBox ID="TB_Celular" class="form-control float-left" Width="95%" runat="server" TextMode="Number" min="1111111111" max="9999999999" ValidationGroup="VG_RegistroUsuario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator2" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Celular"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Direccion</label>
                                    <asp:TextBox ID="TB_Direccion" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator3" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Direccion"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                    <asp:Button ID="B_IniciarSesion" runat="server" Text="Registrarme" class="btn btn-danger" OnClick="B_IniciarSesion_Click"/>
                               </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

