using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de EReceta
/// </summary>
[Serializable]
[Table("recetas", Schema = "producto")]
public class EReceta
{
    private int id;
    private string descripcion;
    private string nombre;
    private string imagenUrl;
    private string productoId;
    private List<EProducto> listaProductos;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("descripcion")]
    public string Descripcion { get => descripcion; set => descripcion = value; }
    [Column("producto_id")]
    public string ProductoId { get => productoId; set => productoId = value; }
    [Column("nombre")]
    public string Nombre { get => nombre; set => nombre = value; }
    [Column("imagen")]
    public string ImagenUrl { get => imagenUrl; set => imagenUrl = value; }
    [NotMapped]
    public List<EProducto> ListaProductos { get => listaProductos; set => listaProductos = value; }
}