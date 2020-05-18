using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de EProducto
/// </summary>
[Serializable]
[Table("promociones", Schema = "venta")]
public class EPromociones
{
    private int id;
    private DateTime FechaVencimiento;
    private int lote_id;
    private int tipoVentaId;
    private bool estado;
    private double precio;
    private int cantidad;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("fecha_vencimiento")]
    public DateTime FechaVencimiento1 { get => FechaVencimiento; set => FechaVencimiento = value; }
    [Column("lote_id")]
    public int Lote_id { get => lote_id; set => lote_id = value; }
    [Column("tipo_venta_id")]
    public int TipoVentaId { get => tipoVentaId; set => tipoVentaId = value; }
    [Column("estado")]
    public bool Estado { get => estado; set => estado = value; }
    [Column("precio")]
    public double Precio { get => precio; set => precio = value; }
    [Column("cantidad")]
    public int Cantidad { get => cantidad; set => cantidad = value; }
}