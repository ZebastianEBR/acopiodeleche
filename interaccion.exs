# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Módulo de interacción con el usuario (funciones impuras: leen e imprimen).

defmodule Interaccion do
  @moduledoc """
  Entrada y salida por consola.
  """

  @doc "Imprime una lista de líneas."
  def imprimir(lineas), do: Enum.each(lineas, &IO.puts/1)

  @doc """
  Solicita la entrega adicional. Devuelve `:omitir` si se presiona Enter
  (o no hay entrada) y `{:ok, texto}` en caso contrario.
  """
  def pedir_entrega_adicional do
    IO.puts("Ingrese una entrega adicional")
    IO.puts("(productor;tanque;dia;litros;grasa)")
    IO.puts("o Enter para omitir:")
    leer_linea()
  end

  @doc "Solicita el código del productor para el comprobante."
  def pedir_codigo_productor do
    IO.puts("")
    IO.puts("Ingrese el código del productor para su comprobante (Enter para salir):")

    case leer_linea() do
      :omitir -> :omitir
      {:ok, texto} -> {:ok, String.upcase(texto)}
    end
  end

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
