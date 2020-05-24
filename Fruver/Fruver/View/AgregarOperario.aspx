<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/AgregarOperario.aspx.cs" Inherits="View_AgregarOperario" %>

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
                                <span class="section-heading-lower text-center mb-4">Agregar Operario</span>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre</label>                                    
                                    <asp:TextBox ID="TB_Nombre" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_IngresaOperario" AutoComplete="off" ValidateRequestMode="Disabled"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Nombre" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Nombre"></asp:RequiredFieldValidator>
                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator4" runat="server" ControlToValidate="TB_Nombre" CssClass="auto-style1" ErrorMessage="Caracteres no validos" ValidateRequestMode="Disabled" ValidationExpression="^[a-zA-ZñÑ\s-A-Za-zäÄëËïÏöÖüÜáéíóúáéíóúÁÉÍÓÚÂÊÎÔÛâêîôûàèìòùÀÈÌÒÙ.,-]+$" style="color: #FF0000; font-size: small"></asp:RegularExpressionValidator>
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Nombre Usuario</label>
                                    <asp:TextBox ID="TB_UserName" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_IngresaOperario" AutoComplete="off" ValidateRequestMode="Disabled"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_UserName" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_UserName"></asp:RequiredFieldValidator>
                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator5" runat="server" ControlToValidate="TB_UserName" CssClass="auto-style1" ErrorMessage="Caracteres no validos" ValidateRequestMode="Disabled" ValidationExpression="^[a-zA-ZñÑ\s-A-Za-zäÄëËïÏöÖüÜáéíóúáéíóúÁÉÍÓÚÂÊÎÔÛâêîôûàèìòùÀÈÌÒÙ.,-]+$" style="color: #FF0000; font-size: small"></asp:RegularExpressionValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Correo</label>
                                    <asp:TextBox ID="TB_Correo" class="form-control float-left" Width="95%" runat="server" TextMode="Email" ValidationGroup="VG_IngresaOperario" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Correo" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Correo"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Codigo</label>
                                    <asp:TextBox ID="TB_Codigo" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_IngresaOperario" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Codigo" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Codigo"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Celular</label>
                                    <asp:TextBox ID="TB_Celular" class="form-control float-left" Width="95%" runat="server" TextMode="Number" min="1111111111" max="9999999999" AutoComplete="off" ValidationGroup="VG_IngresaOperario"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="TFV_Celular" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Celular"></asp:RequiredFieldValidator>
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size:20px;" for="exampleInputPassword1">Direccion</label>
                                    <asp:TextBox ID="TB_Direccion" class="form-control float-left" Width="95%" runat="server"  ValidationGroup="VG_IngresaOperario" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Direccion" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Direccion"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                    <asp:Button ID="B_IngresarOperario"  runat="server" Text="Ingresar" class="btn btn-primary" OnClick="B_IngresarOperario_Click" />
                                </center>

                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

</asp:Content>

