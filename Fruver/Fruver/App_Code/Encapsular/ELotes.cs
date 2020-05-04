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
[Table("detalle_lote", Schema = "producto")]
public class ELotes
{
    private int id;
    private int cantidad;
    private int precio;
    private int producto_id;
    private string nombre_lote;
    private DateTime fecha_ingreso;
    private DateTime fecha_vencimiento;
    private string fecha_ingreso_mostrar;
    private string fecha_vencimiento_mostrar;
    private string nombreProducto;


    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("cantidad")]
    public int Cantidad { get => cantidad; set => cantidad = value; }
    [Column("precio")]
    public int Precio { get => precio; set => precio = value; }
    [Column("producto_id")]
    public int Producto_id { get => producto_id; set => producto_id = value; }
    [Column("nombre_lote")]
    public string Nombre_lote { get => nombre_lote; set => nombre_lote = value; }
    [Column("fecha_ingreso")]
    public DateTime Fecha_ingreso { get => fecha_ingreso; set => fecha_ingreso = value; }
    [Column("fecha_vencimiento")]
    public DateTime Fecha_vencimiento { get => fecha_vencimiento; set => fecha_vencimiento = value; }
    [NotMapped]
    public string Fecha_ingreso_mostrar { get => fecha_ingreso_mostrar; set => fecha_ingreso_mostrar = value; }
    [NotMapped]
    public string Fecha_vencimiento_mostrar { get => fecha_vencimiento_mostrar; set => fecha_vencimiento_mostrar = value; }
    [NotMapped]
    public string NombreProducto { get => nombreProducto; set => nombreProducto = value; }

    
    
}