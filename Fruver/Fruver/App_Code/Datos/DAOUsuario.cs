using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Web;

/// <summary>
/// Descripción breve de DAOUsuario
/// </summary>
public class DAOUsuario
{
    public EUsuario login(EUsuario usuario)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.UserName.Equals(usuario.UserName) && x.Password.Equals(usuario.Password)).FirstOrDefault(); // Espera
        }

    }

    public List<ERol> obtenerRol()
    {
        using (var db = new Mapeo())
        {
            return db.rol.ToList();
        }
    }

    public EUsuario obtenerUsuario(string correo)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.Correo.Equals(correo)).FirstOrDefault();
        }

    }

    public EUsuario obtenerToken(string token)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.Token.Equals(token) && x.EstadoId == 2).FirstOrDefault();
        }

    }

    public void actualizarUsuario(EUsuario usuario)
    {
        using (var db = new Mapeo())
        {
            EUsuario usuarioDos = db.usuario.Where(x => x.Id == usuario.Id).First();
            usuarioDos.Nombre = usuario.Nombre;
            usuarioDos.UserName = usuario.UserName;
            usuarioDos.Correo = usuario.Correo;
            usuarioDos.Password = usuario.Password;
            usuarioDos.Celular = usuario.Celular;
            usuarioDos.Direccion = usuario.Direccion;
            usuarioDos.Token = usuario.Token;
            usuarioDos.EstadoId = usuario.EstadoId;
            usuarioDos.VencimientoToken = usuario.VencimientoToken;
            usuarioDos.Session = usuario.Session;
            usuarioDos.LastModify = DateTime.Now;
            db.usuario.Attach(usuarioDos);

            var entry = db.Entry(usuarioDos);
            entry.State = EntityState.Modified;
            db.SaveChanges();

        }
    }
    public void insertarAutentication(EAutenticacion autenticacion)
    {
        using (var db = new Mapeo())
        {
            db.autenticacion.Add(autenticacion);
            db.SaveChanges();
        }
    }

    public void actualizarUsuario(EAutenticacion autenticacion)
    {
        using (var db = new Mapeo())
        {

            EAutenticacion aut = db.autenticacion.Where(x => x.Session == autenticacion.Session && x.UserId == autenticacion.UserId).First();
            aut.FechaFin = DateTime.Now;

            db.autenticacion.Attach(aut);

            var entry = db.Entry(aut);
            entry.State = EntityState.Modified;
            db.SaveChanges();
        }
    }
}