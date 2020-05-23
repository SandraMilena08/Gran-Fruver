using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de ECarritoCompras
/// </summary>
[Serializable]
[Table("carro_compras", Schema = "venta")]
public class ECarritoCompras
{
    private int id;
    private int detalleLoteId;
    private int usuarioId;
    private int cantidad;
    private int tipoVentaId;
    private ELotes detalleLote;
    private bool estadoId;
    private DateTime fecha;
    private string tipoVenta;
    private double precio;
    private string nombreLote;
    private string nombreusuario;
    private string direccion;
    private long celular;
    private double total;
    private double totalCompra;
    private double aux;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("detalle_lote_id")]
    public int DetalleLoteId { get => detalleLoteId; set => detalleLoteId = value; }
    public ELotes DetalleLote { get => detalleLote; set => detalleLote = value; }
    [Column("usuario_id")]
    public int UsuarioId { get => usuarioId; set => usuarioId = value; }
    [Column("tipo_venta_id")]
    public int TipoVentaId { get => tipoVentaId; set => tipoVentaId = value; }
    [Column("estado_id")]
    public bool EstadoId { get => estadoId; set => estadoId = value; }
    [Column("fecha")]
    public DateTime Fecha { get => fecha; set => fecha = value; }
    [Column("cantidad")]
    public int Cantidad { get => cantidad; set => cantidad = value; }
    [Column("precio")]
    public double Precio { get => precio; set => precio = value; }
    [NotMapped]
    public string TipoVenta { get => tipoVenta; set => tipoVenta = value; }
    [NotMapped]
    public string NombreLote { get => nombreLote; set => nombreLote = value; }
    [NotMapped]
    public double Total { get => total; set => total = value; }
    [NotMapped]
    public string Nombreusuario { get => nombreusuario; set => nombreusuario = value; }
    [NotMapped]
    public string Direccion { get => direccion; set => direccion = value; }
    [NotMapped]
    public long Celular { get => celular; set => celular = value; }
    [NotMapped]
    public double TotalCompra { get => totalCompra; set => totalCompra = value; }
    [NotMapped]
    public double Aux { get => aux; set => aux = value; }
}