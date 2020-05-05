using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de Mapeo
/// </summary>
public class Mapeo : DbContext
{
    static Mapeo()
    {
        Database.SetInitializer<Mapeo>(null);
    }

    private readonly string schema;

    public Mapeo()
        : base("name=Gran_Fruver")
    {
    }

    public DbSet<EUsuario> usuario { get; set; }
    public DbSet<ERol> rol { get; set; }
    public DbSet<EAutenticacion> autenticacion { get; set; }
    public DbSet<EProducto> producto { get; set; }
    public DbSet<ELotes> lotes { get; set; }
    public DbSet<EPromociones> promociones { get; set; }
    public DbSet<EReceta> receta { get; set; }
    public DbSet<ECarritoCompras> carrito { get; set; }
    
    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(this.schema);
        base.OnModelCreating(modelBuilder);
    }
}