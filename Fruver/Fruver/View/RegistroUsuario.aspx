<%@ Page Title="" Language="C#" MasterPageFile="~/View/Master.master" AutoEventWireup="true" CodeFile="~/Controller/RegistroUsuario.aspx.cs" Inherits="View_RegistroUsuario" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="Server">

    <section class="page-section about-heading position-relative d-block" style="margin: 120px auto; width: 40%;">

        <div class="container">
            <div class="about-heading-content">
                <div class="row">
                    <div style="display: block; width: 100%; height: auto;">
                        <div class="bg-faded rounded p-5" style="width: 100%;">
                            <div class="card w-100">
                                <div class="bg-faded rounded p-5" style=" display: block; width: 100%;">
                                    <h2 class="section-heading mb-4 text-primary text-center">Registro Usuario</h2>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre </label>
                                        <asp:TextBox ID="TB_Nombre" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario" AutoComplete="off" MaxLength="20"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RFV_Nombre" class="d-inline-block p-0 px-1 alert alert-danger my-0" Width="5%" Heigth="100%" runat="server" ErrorMessage="*" ControlToValidate="TB_Nombre"></asp:RequiredFieldValidator>
                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator3" runat="server" ErrorMessage="Solo se permiten letras, un nombre con minimo de letras 3" ControlToValidate="TB_Nombre" ValidationExpression="[a-zA-Z ]{3,35}"  ValidationGroup="Registro" Font-Underline="True" ForeColor="black"></asp:RegularExpressionValidator>
                                    </div>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre de Usuario</label>
                                        <asp:TextBox ID="TB_Username" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario" MaxLength="30" AutoComplete="off"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RFV_Username" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="100%" runat="server" ErrorMessage="*" ControlToValidate="TB_Username"></asp:RequiredFieldValidator>
                                    </div>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Correo</label>
                                        <asp:TextBox ID="TB_Correo" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario" TextMode="Email" MaxLength="30" AutoComplete="off"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RequiredFieldValidator1" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="100%" runat="server" ErrorMessage="*" ControlToValidate="TB_Correo"></asp:RequiredFieldValidator>
                                    </div>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputPassword1">Password</label>
                                        <asp:TextBox ID="TB_Password" class="form-control float-left" Width="95%" runat="server" TextMode="Password" ValidationGroup="VG_RegistroUsuario" MaxLength="20" AutoComplete="off"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RFV_Password" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Password"></asp:RequiredFieldValidator>
                                        
                                    </div>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputPassword1">Celular</label>
                                        <asp:TextBox ID="TB_Celular" class="form-control float-left" Width="95%" runat="server" TextMode="Number" min="1111111111" max="9999999999" ValidationGroup="VG_RegistroUsuario" AutoComplete="off"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RequiredFieldValidator2" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Celular"></asp:RequiredFieldValidator>
                                    </div>
                                    <div class="form-group">
                                        <label class="d-block w-100" style="font-size: 20px;" for="exampleInputPassword1">Direccion</label>
                                        <asp:TextBox ID="TB_Direccion" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_RegistroUsuario" MaxLength="30" AutoComplete="off"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="RequiredFieldValidator3" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Direccion"></asp:RequiredFieldValidator>
                                    </div>
                                     <center>
                                    <asp:Button ID="B_IniciarSesion" runat="server" Text="Registrarme" class="btn btn-danger" OnClick="B_IniciarSesion_Click" />
                                    </center>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

