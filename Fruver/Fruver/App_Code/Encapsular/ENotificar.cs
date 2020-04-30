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
[Table("notificaciones", Schema = "producto")]
public class ENotificar
{
    private int id;
    private string descripcion;
    private int usuarioId;
    private int loteId;
    private bool estado;

    [Key]
    [Column("id")]
    public int Id { get => id; set => id = value; }
    [Column("descripcion")]
    public string Descripcion { get => descripcion; set => descripcion = value; }
    [Column("usuario_id")]
    public int UsuarioId { get => usuarioId; set => usuarioId = value; }
    [Column("lote_id")]
    public int LoteId { get => loteId; set => loteId = value; }
    public ELotes Lote { get; set; }
    [Column("estado")]
    public bool Estado { get => estado; set => estado = value; }
    
}