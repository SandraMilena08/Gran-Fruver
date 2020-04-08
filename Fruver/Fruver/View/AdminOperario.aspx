<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/AdminOperario.aspx.cs" Inherits="View_AdminOperario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <style type="text/css">
        .auto-style1 {
            font-family: "Segoe UI";
            font-size: 12px;
            color: #000000;
            background-color: #633716;
            width: 340px;
        }
        .auto-style2 {
            width: 315px;
            background-color: #633716;
        }
        .auto-style3 {
            width: 340px;
            background-color: #633716;
        }
        .auto-style5 {
            width: 59px;
            background-color: #633716;
        }
        .auto-style6 {
            width: 107px;
            text-align: center;
            background-color: #633716;
        }
        .auto-style11 {
            background-color: #FF9933
        }
        .auto-style15 {
            width: 129px;
            background-color: #633716;
        }
        .auto-style17 {
            background-color: #633716;
        }
        .auto-style20 {
        width: 107px;
        background-color: #633716;
    }
        .auto-style21 {
            font-size: small;
        }
        .auto-style22 {
            margin-bottom: 1rem;
            height: 26px;
            width: 286px;
        }
        .auto-style23 {
            margin-bottom: 1rem;
            height: 33px;
            width: 288px;
        }
        .auto-style24 {
            font-size: small;
            margin-left: 50;
        }
        .auto-style25 {
            margin-bottom: 1rem;
            width: 288px;
        }
        .auto-style26 {
            margin-bottom: 1rem;
            width: 286px;
            height: 25px;
            margin-top: 10px;
        }
        .auto-style27 {
            font-size: small;
            margin-left: 0;
        }
        .auto-style28 {
            font-size: small;
            width: 49px;
        }
        .auto-style29 {
            margin-bottom: 1rem;
            width: 297px;
            height: 38px;
        }
        .auto-style30 {
            width: 107px;
            text-align: left;
            background-color: #633716;
        }
        .auto-style31 {
            margin-bottom: 1rem;
            width: 287px;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <table class="w-100">
        <tr>
            <td class="auto-style2">&nbsp;</td>
            <td class="auto-style3">&nbsp;</td>
            <td class="auto-style5">&nbsp;</td>
            <td class="auto-style20">&nbsp;</td>
            <td class="auto-style15">&nbsp;</td>
            <td class="auto-style17">&nbsp;</td>
        </tr>
        <tr>
            <td class="auto-style2">&nbsp;</td>
            <td class="auto-style1" >
                <asp:GridView ID="GV_IngresoOperario" runat="server" AutoGenerateColumns="False" DataKeyNames="id" BackColor="#DEBA84" BorderColor="#DEBA84" BorderStyle="None" BorderWidth="1px" CellPadding="3" CssClass="auto-style17" CellSpacing="2">
                    <Columns>
                        <asp:TemplateField HeaderText="Nombre" SortExpression="Nombre">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox1" runat="server" Text='<%# Bind("Nombre") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_Nombre" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label1" runat="server" Text='<%# Bind("Nombre") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="UserName" SortExpression="UserName">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox2" runat="server" Text='<%# Bind("UserName") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_UserName" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label2" runat="server" Text='<%# Bind("UserName") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Correo" SortExpression="Correo">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox3" runat="server" Text='<%# Bind("Correo") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_Correo" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label3" runat="server" Text='<%# Bind("Correo") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Codigo" SortExpression="Password">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox4" runat="server" Text='<%# Bind("Password") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_Password" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label4" runat="server" Text='<%# Bind("Password") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Celular" SortExpression="Celular">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox5" runat="server" Text='<%# Bind("Celular") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_Celular" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label5" runat="server" Text='<%# Bind("Celular") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Direccion" SortExpression="Direccion">
                            <EditItemTemplate>
                                <asp:TextBox ID="TextBox6" runat="server" Text='<%# Bind("Direccion") %>'></asp:TextBox>
                            </EditItemTemplate>
                            <FooterTemplate>
                                <asp:TextBox ID="TB_Direccion" runat="server"></asp:TextBox>
                            </FooterTemplate>
                            <ItemTemplate>
                                <asp:Label ID="Label6" runat="server" Text='<%# Bind("Direccion") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                    <FooterStyle BackColor="#F7DFB5" ForeColor="#8C4510" />
                    <HeaderStyle BackColor="#A55129" Font-Bold="True" ForeColor="#FFFFCC" />
                    <PagerStyle ForeColor="#8C4510" HorizontalAlign="Center" />
                    <RowStyle BackColor="#FFF7E7" ForeColor="#8C4510" />
                    <SelectedRowStyle BackColor="#738A9C" Font-Bold="True" ForeColor="White" />
                    <SortedAscendingCellStyle BackColor="#FFF1D4" />
                    <SortedAscendingHeaderStyle BackColor="#B95C30" />
                    <SortedDescendingCellStyle BackColor="#F1E5CE" />
                    <SortedDescendingHeaderStyle BackColor="#93451F" />
                </asp:GridView>
            </td>
            <td class="auto-style5">&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;</td>
            <td class="auto-style6"><span class="text-white" aria-autocomplete="none" aria-disabled="True"><br class="auto-style11" />
                <center>
                                <div class="auto-style22">
                                    <label class="auto-style21" for="exampleInputEmail1">Nombre&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </label>                                    
                                    <asp:TextBox ID="TB_Nombre" class="form-control float-left" Width="41%" runat="server" ValidationGroup="VG_IngresaOperario" CssClass="auto-style24"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Nombre" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Nombre" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                              <div class="auto-style23">
                                    <label class="auto-style21" for="exampleInputEmail1">Nombre de Usuario</label>                                    
                                    <asp:TextBox ID="TB_Username" class="form-control float-left" Width="35%" runat="server" ValidationGroup="VG_IngresaOperario" CssClass="auto-style21"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Username" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Username" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                               <center>
                              <div class="auto-style25">
                                    <label class="auto-style21" for="exampleInputEmail1">&nbsp; Correo</label>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;                                    
                                    <asp:TextBox ID="TB_Correo" class="form-control float-left" Width="48%" runat="server" ValidationGroup="VG_IngresaOperario" TextMode="Email" CssClass="auto-style21"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator1" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Correo" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                <div class="auto-style26">
                                    &nbsp;<span class="text-white" aria-autocomplete="none" aria-disabled="True"><label class="auto-style28" for="exampleInputPassword1">Codigo</label></span><asp:TextBox ID="TB_Codigo" class="form-control float-left" Width="61%" runat="server" ValidationGroup="VG_IngresaOperario" CssClass="auto-style27"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Codigo" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="23px" runat="server" ErrorMessage="*" ControlToValidate="TB_Codigo" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                <div class="auto-style31">
                                    <label class="auto-style21" for="exampleInputPassword1">Celular</label>
                                    <asp:TextBox ID="TB_Celular" class="form-control float-left" Width="63%" runat="server" TextMode="Number" ValidationGroup="VG_IngresaOperario" CssClass="auto-style21"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator2" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="18px" runat="server" ErrorMessage="*" ControlToValidate="TB_Celular" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                <div class="auto-style29">
                                    <label class="auto-style21" for="exampleInputPassword1">Direccion</label>
                                    <asp:TextBox ID="TB_Direccion" class="form-control float-left" Width="43%" runat="server" ValidationGroup="VG_IngresaOperario" CssClass="auto-style21"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RequiredFieldValidator3" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Height="24px" runat="server" ErrorMessage="*" ControlToValidate="TB_Direccion" CssClass="auto-style21"></asp:RequiredFieldValidator>
                                </div>
                                                    
            <td class="auto-style15">
                <br />
                <br />
                <br />
                <br />
                <br />
            </td>
            <td class="auto-style17">&nbsp;</td>
        </tr>
        <tr>
            <td class="auto-style2">&nbsp;</td>
            <td class="auto-style1" >
                &nbsp;</td>
            <td class="auto-style5">&nbsp;</td>
            <td class="auto-style30">
                <span class="text-white" aria-autocomplete="none" aria-disabled="True">
                    <asp:Button ID="B_IngresarOperario" runat="server" Text="Ingresar" class="btn btn-danger"  BorderColor="#FF3300" OnClick="B_IngresarOperario_Click"/>   
            </td>
            
            <td class="auto-style15">
                &nbsp;</td>
            <td class="auto-style17">&nbsp;</td>
        </tr>
        <tr>
            <td class="auto-style17">
                <asp:ObjectDataSource ID="ODS_Ingreso" runat="server" DataObjectTypeName="EUsuario" InsertMethod="insertarUsuario" SelectMethod="buscarUsuario" TypeName="DAOUsuario" UpdateMethod="actualizarUsuario"></asp:ObjectDataSource>
            </td>
        </tr>
    </table>
</asp:Content>

