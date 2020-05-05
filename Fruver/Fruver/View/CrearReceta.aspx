<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/CrearReceta.aspx.cs" Inherits="View_CrearReceta" %>

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
                                <span class="section-heading-lower text-center mb-4">Crear Receta</span>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Nombre Receta</label>
                                    <asp:TextBox ID="TB_NombreReceta" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearReceta" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_NombreReceta" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="30px" runat="server" ErrorMessage="*" ControlToValidate="TB_NombreReceta"></asp:RequiredFieldValidator>
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Descripcion Receta</label>
                                    <asp:TextBox ID="TB_Descripcion" class="form-control float-left" Width="95%" runat="server" ValidationGroup="VG_CrearReceta" AutoComplete="off"></asp:TextBox>
                                    <asp:RequiredFieldValidator ID="RFV_Descripcion" class="d-inline-block p-0 px-1 alert alert-danger" Width="5%" Heigth="30px" runat="server" ErrorMessage="*" ControlToValidate="TB_Descripcion"></asp:RequiredFieldValidator>
                                </div>
                                <div class="form-group">
                                    <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Imagen Receta</label>
                                    <asp:FileUpload ID="FU_RecetaImagen" class="w-75 p-3" runat="server" style="font-size: 20px;" />
                                </div>
                                <label class="d-block w-100" style="font-size: 20px;" for="exampleInputEmail1">Productos</label>
                                <br />
                                <asp:CheckBoxList ID="CBL_Productos" class="input-group mb-3" runat="server" DataSourceID="ODS_ProductoReceta" DataTextField="Nombre" style="font-size: 50%" DataValueField="Id"></asp:CheckBoxList>
                                <asp:ObjectDataSource ID="ODS_ProductoReceta" runat="server" SelectMethod="obtenerProductosRecetas" TypeName="DAOProducto"></asp:ObjectDataSource>
                                <center>
                                    <asp:Button ID="B_CrearReceta"  runat="server" Text="Crear Receta" class="btn btn-primary" OnClick="B_CrearReceta_Click" />
                                </center>
                            </h2>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</asp:Content>

