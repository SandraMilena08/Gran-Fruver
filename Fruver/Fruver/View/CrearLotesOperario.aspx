<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/CrearLotesOperario.aspx.cs" Inherits="View_CrearLotesOperario" %>


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
                                <span class="section-heading-lower text-center mb-4">Crear lote</span>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre Lote</label>
                                    <asp:TextBox ID="TB_NombreLote" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearLote" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_NombreLote" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_NombreLote"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Cantidad</label>
                                    <asp:TextBox ID="TB_Cantidad" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearLote" AutoComplete="off" TextMode="Number"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Cantidad" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Cantidad"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Precio</label>
                                    <asp:TextBox ID="TB_Precio" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearLote" AutoComplete="off" TextMode="Number"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Precio" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_Precio"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Producto</label>
                                    <asp:RequiredFieldValidator ID="RFV_Producto" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="DDL_Producto"></asp:RequiredFieldValidator>
                                     <br />
                                     <asp:DropDownList ID="DDL_Producto" runat="server" DataSourceID="ODS_Producto" DataTextField="Nombre" DataValueField="Id" >
                                     </asp:DropDownList>
                                     <asp:ObjectDataSource ID="ODS_Producto" runat="server" SelectMethod="obtenerProductos" TypeName="DAOProducto"></asp:ObjectDataSource>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Fecha de Ingreso</label>
                                    <asp:TextBox ID="TB_FechaIngreso" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearLote" AutoComplete="off" TextMode="Date" ></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_FechaIngreso" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_FechaIngreso"></asp:RequiredFieldValidator>
                                </div>
                                 <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Fecha de Vencimineto</label>
                                    <asp:TextBox ID="TB_FechaVencimiento" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearLote" AutoComplete="off" TextMode="Date"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_FechaVencimiento" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="38px" runat="server" ErrorMessage="*" ControlToValidate="TB_FechaVencimiento"></asp:RequiredFieldValidator>
                                </div>
                                <center>
                                    <asp:Button ID="B_CrearLote"  runat="server" Text="Crear Lote" class="btn btn-primary" OnClick="B_CrearLote_Click"  />
                                </center>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

