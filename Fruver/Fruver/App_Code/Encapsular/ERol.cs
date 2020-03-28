using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de ERol
[Serializable]
[Table("rol", Schema = "usuario")]
public class ERol
{
    private int id;
    private string nombre;
    private string session;
    private Nullable<DateTime> lastModify;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("nombre")]
    public string Nombre { get => nombre; set => nombre = value; }
    [Column("session")]
    public string Session { get => session; set => session = value; }
    [Column("last_modify")]
    public Nullable<DateTime> LastModify { get => lastModify; set => lastModify = value; }
}