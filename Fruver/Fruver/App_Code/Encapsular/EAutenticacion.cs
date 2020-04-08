using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de EAutenticacion
[Serializable]
[Table("autenticacion", Schema = "seguridad")]
public class EAutenticacion
{
    private int id;
    private int userId;
    private string ip;
    private string mac;
    private DateTime fechaInicio;
    private Nullable<DateTime> fechaFin;
    private string session ;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("user_id")]
    public int UserId { get => userId; set => userId = value; }
    [Column("ip")]
    public string Ip { get => ip; set => ip = value; }
    [Column("mac")]
    public string Mac { get => mac; set => mac = value; }
    [Column("fecha_inicio")]
    public DateTime FechaInicio { get => fechaInicio; set => fechaInicio = value; }
    [Column("fecha_fin")]
    public DateTime? FechaFin { get => fechaFin; set => fechaFin = value; }
    [Column("session")]
    public string Session { get => session; set => session = value; }
}