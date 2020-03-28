using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Net.NetworkInformation;
using System.Web;

/// <summary>
/// Descripción breve de EUsuario
/// </summary>
[Serializable]
[Table("usuario", Schema = "usuario")]
public class EUsuario
{

    private int id;
    private string nombre;
    private string userName;
    private string correo;
    private string password;
    private int celular;
    private string direccion;
    private Nullable<int> rolId;
    private string nombreRol;
    private string session;
    private Nullable<DateTime> lastModify;
    private int estadoId;
    private string token;
    private Nullable<DateTime> vencimientoToken;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("nombre")]
    public string Nombre { get => nombre; set => nombre = value; }
    [Column("user_name")]
    public string UserName { get => userName; set => userName = value; }
    [Column("correo")]
    public string Correo { get => correo; set => correo = value; }
    [Column("password")]
    public string Password { get => password; set => password = value; }
    [Column("celular")]
    public int Celular { get => celular; set => celular = value; }
    [Column("direccion")]
    public string Direccion { get => direccion; set => direccion = value; }
    [Column("rol_id")]
    public Nullable<int> RolId { get => rolId; set => rolId = value; }
    [Column("session")]
    public string Session { get => session; set => session = value; }
    [Column("last_modify")]
    public Nullable<DateTime> LastModify { get => lastModify; set => lastModify = value; }
    [Column("estado_id")]
    public int EstadoId { get => estadoId; set => estadoId = value; }
    [Column("token")]
    public string Token { get => token; set => token = value; }
    [Column("vencimiento_token")]
    public Nullable<DateTime> VencimientoToken { get => vencimientoToken; set => vencimientoToken = value; }
    [NotMapped]
    public string NombreRol { get => nombreRol; set => nombreRol = value; } // Perdon
}