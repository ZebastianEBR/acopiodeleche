# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Interaccion do
  @moduledoc """
  Modulo de entrada y salida por consola (funciones impuras).
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3

  Se mantiene separado del resto del programa para que los modulos de
  calculo (Validacion, Liquidacion, Analisis, Reportes) queden puros,
  sin leer ni imprimir nada por su cuenta.
  """

  @doc """
  Imprime una lista de lineas de texto, una por linea.

  ## Parametro
  - lineas: lista de strings a imprimir

  ## Ejemplo
      iex> Interaccion.imprimir(["Hola", "Mundo"])
      Hola
      Mundo
  """
  def imprimir(lineas), do: Enum.each(lineas, &IO.puts/1)

  @doc """
  Solicita al usuario la entrega adicional, en formato
  `productor;tanque;dia;litros;grasa`.

  ## Devuelve
  `:omitir` si el usuario presiona Enter sin escribir nada, o
  `{:ok, texto}` con lo que haya escrito.

  ## Ejemplo
      iex> Interaccion.pedir_entrega_adicional()
      Ingrese una entrega adicional
      (productor;tanque;dia;litros;grasa)
      o Enter para omitir:
  """
  def pedir_entrega_adicional do
    IO.puts("Ingrese una entrega adicional")
    IO.puts("(productor;tanque;dia;litros;grasa)")
    IO.puts("o Enter para omitir:")
    leer_linea()
  end

  @doc """
  Solicita al usuario el codigo de un productor, para mostrar su comprobante.

  ## Devuelve
  `:omitir` si el usuario presiona Enter, o `{:ok, codigo}` en mayusculas.

  ## Ejemplo
      iex> Interaccion.pedir_codigo_productor()
      Ingrese el código del productor para su comprobante (Enter para salir):
  """
  def pedir_codigo_productor do
    IO.puts("")
    IO.puts("Ingrese el código del productor para su comprobante (Enter para salir):")

    case leer_linea() do
      :omitir -> :omitir
      {:ok, texto} -> {:ok, String.upcase(texto)}
    end
  end

  # Lee una linea de la consola y le quita espacios; si esta vacia,
  # devuelve :omitir en vez de un texto vacio.
  defp leer_linea do
    case IO.gets("> ") do
      texto when is_binary(texto) ->
        case String.trim(texto) do
          "" -> :omitir
          limpio -> {:ok, limpio}
        end

      _ ->
        :omitir
    end
  end
end
