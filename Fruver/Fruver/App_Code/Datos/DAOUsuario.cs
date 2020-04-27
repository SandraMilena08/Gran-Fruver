using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Web;
using System.Web.UI;

/// <summary>
/// Descripción breve de DAOUsuario
/// </summary>
public class DAOUsuario
{
    public ClientScriptManager ClientScript { get; private set; }

    public EUsuario login(EUsuario usuario)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.UserName.Equals(usuario.UserName) && x.Password.Equals(usuario.Password)).FirstOrDefault(); 
        }

    }

    public List<ERol> obtenerRol()
    {
        using (var db = new Mapeo())
        {
            return db.rol.ToList();
        }
    }

    public EUsuario buscarCorreoUsuario(string correo, string nombreUsuario)
    {
        using (var db = new Mapeo())
        {
            return db.usuario.Where(x => x.Correo.Equals(correo) || x.UserName.Equals(nombreUsuario)).FirstOrDefault();
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
        ClientScriptManager am = this.ClientScript;

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

            EUsuario eUsuario = new DAOUsuario().buscarCorreoUsuario(usuario.Correo, usuario.UserName);
            
            if(eUsuario == null)
            {
                var entry = db.Entry(usuarioDos);
                entry.State = EntityState.Modified;
                db.SaveChanges();
            }
            else
            {
                am.RegisterClientScriptBlock(this.GetType(), "mensaje", "<script type='text/javascript'>alert('ERROR: El correo o el nombre de usuario ya existe');window.location=\"AdminOperario.aspx\"</script>");
            }

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
    public void insertarUsuario(EUsuario eUsuario)
    {
        using (var db = new Mapeo())
        {
            db.usuario.Add(eUsuario);
            db.SaveChanges();
        }
    }

    public List<EUsuario> obtenerUsuario()
    {
        using (var db = new Mapeo())
        {
            return (from uu in db.usuario

                    select new
                    {
                        uu
                    }).ToList().Select(m => new EUsuario
                    {

                        Id = m.uu.Id,
                        Nombre = m.uu.Nombre,
                        UserName = m.uu.UserName,
                        Celular = m.uu.Celular,
                        Correo = m.uu.Correo,
                        Direccion = m.uu.Direccion,
                        Password = m.uu.Password,
                        EstadoId = m.uu.EstadoId,
                        NombreRol = m.uu.NombreRol,
                        Session = m.uu.Session,
                        RolId = m.uu.RolId,
                       LastModify = m.uu.LastModify,
  
                    }).ToList();
        }

    }

    public List<EUsuario> buscarUsuario()
    {
         
        using (var db = new Mapeo())
        {
            List<EUsuario> eUsuario = db.usuario.Where(x => x.RolId == 2).ToList();
            return eUsuario;
        }
    }

    public void eliminarUsuario(EUsuario usuario)
    {
        using (var db = new Mapeo())
        {
            db.usuario.Attach(usuario);

            var entry = db.Entry(usuario);
            entry.State = EntityState.Deleted;
            db.SaveChanges();

        }
    }
}