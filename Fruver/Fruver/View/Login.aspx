﻿<%@ Page Title="Gran Fruver | Iniciar Sesion" Language="C#" MasterPageFile="~/View/Master.master" AutoEventWireup="true" CodeFile="~/Controller/Login.aspx.cs" Inherits="View_Login" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <style type="text/css">
        .auto-style1 {
            font-size: small;
            color: #FF3300;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">

    <br />
    <br />
    <br />
    <section class="page-section about-heading position-relative d-block w-50" style="margin:80px auto;">
        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div class="col-xl-9 col-lg-10 mx-auto">
                        <div class="bg-faded rounded p-5">
                            <h2 class="section-heading mb-4">
                                <span class="section-heading-lower text-center mb-4">LOGIN</span>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre Usuario</label>                                    
                                    <asp:TextBox ID="TB_UserName" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_Login"  AutoComplete="off" ValidateRequestMode="Disabled"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_UserName" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_UserName"></asp:RequiredFieldValidator>
                                   
                                    <asp:RegularExpressionValidator ID="RegularExpressionValidator1" runat="server" ControlToValidate="TB_UserName" CssClass="auto-style1" ErrorMessage="Caracteres no validos" ValidateRequestMode="Disabled" ValidationExpression="^[a-zA-ZñÑ\s-A-Za-zäÄëËïÏöÖüÜáéíóúáéíóúÁÉÍÓÚÂÊÎÔÛâêîôûàèìòùÀÈÌÒÙ.,-]+$"></asp:RegularExpressionValidator>
                                   
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Password</label>
                                    <asp:TextBox ID="TB_Password" class="form-control float-left" Width="95%" runat="server" TextMode="Password" ValidationGroup="VG_Login"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Password" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Password"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                    <asp:Button ID="B_IniciarSesion"  runat="server" Text="Iniciar Sesion" class="btn btn-primary" OnClick="B_IniciarSesion_Click" />
                                </center>
                                <a href="GenerarToken.aspx" class="d-block pt-4 text-secondary text-center" style="font-size:15px; text-transform:none;">Recuperar Contraseña</a>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

