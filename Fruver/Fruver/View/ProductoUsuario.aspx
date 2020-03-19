<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterUsuario.master" AutoEventWireup="true" CodeFile="~/Controller/ProductoUsuario.aspx.cs" Inherits="View_ProductoUsuario" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <asp:gridview runat="server" ID="GV_Productos" DataSourceID="ODS_Producto"></asp:gridview>
    <asp:ObjectDataSource ID="ODS_Producto" runat="server"></asp:ObjectDataSource>
</asp:Content>

