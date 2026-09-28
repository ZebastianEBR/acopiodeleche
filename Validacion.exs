# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Módulo de validación (funciones puras, sin entrada/salida).

defmodule Validacion do
  @moduledoc """
  Valida entregas en el orden exigido, encadenando las reglas con `with`.
  """

  @dia_min 1
  @dia_max 6
  @max_litros 800
  @grasa_min 0
  @grasa_max 15

  @doc "Días de recepción del centro (1 al 6)."
  def dias, do: @dia_min..@dia_max # solo arma el range(rango) y lo devuelve

  @doc """
  Valida una entrega. Devuelve `{:ok, entrega}` o `{:error, motivo}` con el
  primer motivo encontrado, según el orden de las reglas.
  """
  def validar_entrega(entrega, codigos_productores, ids_tanques) do
    with :ok <- validar_productor(entrega, codigos_productores),
         :ok <- validar_tanque(entrega, ids_tanques),
         :ok <- validar_dia(entrega),
         :ok <- validar_litros(entrega),
         :ok <- validar_grasa(entrega) do
      {:ok, entrega}
    end
  end

  @doc """
  Valida todas las entregas. Devuelve `{validas, rechazadas}`, donde
  `rechazadas` es una lista de `{entrega, motivo}`.
  """
  def clasificar(entregas, productores, tanques) do
    codigos = MapSet.new(productores, & &1.codigo)
    ids = MapSet.new(tanques, & &1.id)

    resultados = Enum.map(entregas, fn e -> {e, validar_entrega(e, codigos, ids)} end)

    validas = for {_entrega, {:ok, valida}} <- resultados, do: valida
    rechazadas = for {entrega, {:error, motivo}} <- resultados, do: {entrega, motivo}

    {validas, rechazadas}
  end

  @doc """
  Convierte el texto `productor;tanque;dia;litros;grasa` en un mapa de entrega.
  Devuelve `{:error, :formato_invalido}` si el formato no es correcto.
  """
  def parsear_entrega(texto) do
    campos = texto |> String.trim() |> String.split(";") |> Enum.map(&String.trim/1)

    with [productor, tanque, dia, litros, grasa] <- campos,
         {dia_entero, ""} <- Integer.parse(dia),
         {litros_num, ""} <- Float.parse(litros),
         {grasa_num, ""} <- Float.parse(grasa) do
      {:ok, %{productor: productor, tanque: tanque, dia: dia_entero, litros: litros_num, grasa: grasa_num}}
    else
      _ -> {:error, :formato_invalido}
    end
  end

  # --- Reglas individuales (en el orden exigido) ---

  defp validar_productor(entrega, codigos) do
    if MapSet.member?(codigos, Map.get(entrega, :productor)),
      do: :ok,
      else: {:error, :productor_desconocido}
  end

  defp validar_tanque(entrega, ids) do
    if MapSet.member?(ids, Map.get(entrega, :tanque)),
      do: :ok,
      else: {:error, :tanque_desconocido}
  end

  defp validar_dia(%{dia: dia}) when is_integer(dia) and dia >= @dia_min and dia <= @dia_max,
    do: :ok

  defp validar_dia(_), do: {:error, :dia_invalido}

  defp validar_litros(%{litros: litros})
       when is_number(litros) and litros > 0 and litros <= @max_litros,
       do: :ok

  defp validar_litros(_), do: {:error, :litros_fuera_de_rango}

  defp validar_grasa(%{grasa: grasa})
       when is_number(grasa) and grasa >= @grasa_min and grasa <= @grasa_max,
       do: :ok

  defp validar_grasa(_), do: {:error, :porcentaje_invalido}
end
