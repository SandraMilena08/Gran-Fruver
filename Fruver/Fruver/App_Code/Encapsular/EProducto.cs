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
[Table("producto", Schema = "producto")]
public class EProducto
{
    private int id;
    private string nombre;
    private string imagen;
    private Nullable<bool> disponibilidad;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("nombre")]
    public string Nombre { get => nombre; set => nombre = value; }
    [Column("imagen")]
    public string Imagen { get => imagen; set => imagen = value; }
    [Column("disponibilidad")]
    public Nullable<bool> Disponibilidad { get => disponibilidad; set => disponibilidad = value; }
}