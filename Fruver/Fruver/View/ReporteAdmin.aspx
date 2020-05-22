<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterAdmin.master" AutoEventWireup="true" CodeFile="~/Controller/ReporteAdmin.aspx.cs" Inherits="View_ReporteAdmin" %>

<%@ Register assembly="CrystalDecisions.Web, Version=13.0.3500.0, Culture=neutral, PublicKeyToken=692fbea5521e1304" namespace="CrystalDecisions.Web" tagprefix="CR" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <table class="w-100">
        <tr>
            <td>&nbsp;</td>
        </tr>
        <tr>
            <td>
                <CR:CrystalReportViewer ID="CRV_ReporteAdmin" runat="server" AutoDataBind="True" GroupTreeImagesFolderUrl="" Height="1202px" ReportSourceID="CRS_ReporteAdmin" ToolbarImagesFolderUrl="" ToolPanelWidth="200px" Width="1104px" />
                <CR:CrystalReportSource ID="CRS_ReporteAdmin" runat="server">
                    <Report FileName="C:\Users\Erika Moreno\Desktop\Gran_Fruver\Gran-Fruver\Fruver\Fruver\Reportes\ReporteAdmin.rpt">
                    </Report>
                </CR:CrystalReportSource>
            </td>
        </tr>
        <tr>
            <td>&nbsp;</td>
        </tr>
    </table>
</asp:Content>

