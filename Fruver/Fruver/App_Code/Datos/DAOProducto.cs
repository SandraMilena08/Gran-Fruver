﻿using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

/// <summary>
/// Descripción breve de DAOProducto
/// </summary>
public class DAOProducto
{
    public bool insertarProducto(EProducto eProducto)
    {
        try
        {

            using (var db = new Mapeo())
            {
                db.producto.Add(eProducto);
                db.SaveChanges();
                return true;
            }

        }
        catch (Exception ex)
        {

            throw ex;
        }
    }

    public void insertarProductoNuevo(EProducto eNuevo)
    {
        using (var db = new Mapeo())
        {
            db.producto.Add(eNuevo);
            db.SaveChanges();
        }
    }

    public List<EProducto> obtenerProductos()
    {

        using (var db = new Mapeo())
        {
            List < EProducto > productos    =  db.producto.ToList();

            for (int x = 0; x < productos.Count;x++ ) {

                productos[x].Lotes = obtenerloteProducto(productos[x].Id);
                

            }

            return productos;

        }
    }

    public void actualizarProducto(EProducto producto)
    {
        using (var db = new Mapeo())
        {
            EProducto productoDos = db.producto.Where(x => x.Id == producto.Id).First();

            productoDos.Nombre = producto.Nombre;
            productoDos.Imagen = producto.Imagen;
            productoDos.Disponibilidad = producto.Disponibilidad;
            db.producto.Attach(productoDos);

            var entry = db.Entry(productoDos);
            entry.State = EntityState.Modified;
            db.SaveChanges();

        }
    }
    public void eliminarProducto(EProducto eProducto)
    {
        using (var db = new Mapeo())
        {
            db.producto.Attach(eProducto);

            var entry = db.Entry(eProducto);
            entry.State = EntityState.Deleted;
            db.SaveChanges();

        }
    }
    public List<ELotes> obtenerloteProducto(int id)
    {

        using (var db = new Mapeo())
        {
            return db.lotes.Where(x => x.Producto_id == id   ).ToList();

            //return db.notificaciones.Where(x => x.usuario_id == Id logueado).ToList();

        }

        /*
         * 
         *   int idProduct = 10;
            using (var db = new Mapeo())
            {
                return (from lote in db.lotes
                        join p in db.producto on lote.Producto_id equals p.Id
                        where lote.Producto_id == idProducto
                        select new
                        {
                            lote,
                            p
                        }).ToList().Select(m => new ELotes
                        {
                            Id = m.lote.Id,
                            Cantidad = m.lote.Cantidad,
                             Producto_id = m.lote.Producto_id,    
                            Nombre_lote = m.lote.Nombre_lote,
                            Precio = m.lote.Precio   
                        }).ToList();
            }
         * */

    }
}