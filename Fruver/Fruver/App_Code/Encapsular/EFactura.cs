using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de EFactura
/// </summary>
[Serializable]
[Table("factura", Schema = "venta")]
public class EFactura
{
    private int id;
    private double precioTotal;
    private DateTime fechaCompra;
    private int usuarioId;
    private int tipoVentaId;
    private string carroComprasId;    

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("precio_total")]
    public double PrecioTotal { get => precioTotal; set => precioTotal = value; }
    [Column("fecha_compra")]
    public DateTime FechaCompra { get => fechaCompra; set => fechaCompra = value; }
    [Column("usuario_id")]
    public int UsuarioId { get => usuarioId; set => usuarioId = value; }
    [Column("tipo_venta_id")]
    public int TipoVentaId { get => tipoVentaId; set => tipoVentaId = value; }
    [Column("carro_compras_id")]
    public string CarroComprasId { get => carroComprasId; set => carroComprasId = value; }    
}