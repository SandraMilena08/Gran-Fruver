<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/Reporte.aspx.cs" Inherits="View_Reporte" %>

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
                <CR:CrystalReportViewer ID="CRV_Reporte" runat="server" AutoDataBind="True" GroupTreeImagesFolderUrl="" Height="1202px" ReportSourceID="CRS_Reporte" ToolbarImagesFolderUrl="" ToolPanelWidth="200px" Width="1104px" />
                <CR:CrystalReportSource ID="CRS_Reporte" runat="server">
                    <Report FileName="C:\Users\Erika Moreno\Desktop\Gran_Fruver\Gran-Fruver\Fruver\Fruver\Reportes\Reporte.rpt">
                    </Report>
                </CR:CrystalReportSource>
            </td>
        </tr>
        <tr>
            <td>&nbsp;</td>
        </tr>
    </table>
</asp:Content>

