﻿using System;
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
    private int cantidad;
    private double precio;
    private string nombre;
    private string imagen;
    private string Estado;
    private int total;
    private Nullable<bool> disponibilidad;
    private List<ELotes> lotes;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("nombre")]
    public string Nombre { get => nombre; set => nombre = value; }
    [Column("imagen")]
    public string Imagen { get => imagen; set => imagen = value; }
    [Column("disponibilidad")]
    public Nullable<bool> Disponibilidad { get => disponibilidad; set => disponibilidad = value; }
    [NotMapped]
    public List<ELotes> Lotes { get => lotes; set => lotes = value; }
    [NotMapped]
    public int Cantidad { get => cantidad; set => cantidad = value; }
    [NotMapped]
    public double Precio { get => precio; set => precio = value; }
    [NotMapped]
    public string Estado1 { get => Estado; set => Estado = value; }
    [NotMapped]
    public int Total { get => total; set => total = value; }
}