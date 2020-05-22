<%@ Page Title="" Language="C#" MasterPageFile="~/View/MasterOperario.master" AutoEventWireup="true" CodeFile="~/Controller/ReporteLote.aspx.cs" Inherits="View_ReporteLote" %>

<%@ Register assembly="CrystalDecisions.Web, Version=13.0.3500.0, Culture=neutral, PublicKeyToken=692fbea5521e1304" namespace="CrystalDecisions.Web" tagprefix="CR" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <style type="text/css">
        .auto-style1 {
            height: 26px;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <table class="w-100">
        <tr>
            <td>&nbsp;</td>
        </tr>
        <tr>
            <td class="auto-style1">
                <CR:CrystalReportViewer ID="CRV_ReporteLote" runat="server" AutoDataBind="True" GroupTreeImagesFolderUrl="" Height="1202px" ReportSourceID="CRS_ReporteLote" ToolbarImagesFolderUrl="" ToolPanelWidth="200px" Width="1104px" />
                <CR:CrystalReportSource ID="CRS_ReporteLote" runat="server">
                    <Report FileName="C:\Users\Erika Moreno\Desktop\Gran_Fruver\Gran-Fruver\Fruver\Fruver\Reportes\ReporteLote.rpt">
                    </Report>
                </CR:CrystalReportSource>
            </td>
        </tr>
        <tr>
            <td>&nbsp;</td>
        </tr>
    </table>
</asp:Content>

