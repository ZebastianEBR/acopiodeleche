# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Módulo de análisis: cálculos de los reportes (funciones puras).

defmodule Analisis do
  @moduledoc """
  Cálculos para los reportes R2 a R8 y la combinación de mapas.
  """

  @meta_diaria 2_000
  @min_entregas_calidad 3

  def meta_diaria, do: @meta_diaria

  @doc """
  Ordena una lista de mapas según una keyword list de opciones:

    * `:por`    - campo por el cual ordenar (obligatorio)
    * `:orden`  - `:desc` (por defecto) o `:asc`
    * `:limite` - cantidad máxima de elementos (por defecto `:todos`)
  """
  def ranking(items, opciones) do
    campo = Keyword.fetch!(opciones, :por)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, :todos)

    ordenados = Enum.sort_by(items, &Map.fetch!(&1, campo), orden)

    if limite == :todos, do: ordenados, else: Enum.take(ordenados, limite)
  end

  @doc "R2: litros y porcentaje de ocupación por tanque."
  def ocupacion_tanques(tanques, validas) do
    por_tanque = Enum.group_by(validas, & &1.tanque)

    for tanque <- tanques do
      litros = por_tanque |> Map.get(tanque.id, []) |> sumar_litros()
      %{id: tanque.id, nombre: tanque.nombre, capacidad: tanque.capacidad,
        litros: litros, ocupacion: litros / tanque.capacidad * 100}
    end
  end

  @doc "R3: mapa `dia => litros` para los 6 días."
  def litros_por_dia(validas) do
    por_dia = Enum.group_by(validas, & &1.dia)

    for dia <- Validacion.dias(), into: %{} do
      {dia, por_dia |> Map.get(dia, []) |> sumar_litros()}
    end
  end

  @doc "Combina los litros diarios de dos centros con `Map.merge/3`, sumando claves comunes."
  def combinar_litros(litros_propios, litros_vecino) do
    Map.merge(litros_propios, litros_vecino, fn _dia, propios, vecino -> propios + vecino end)
  end

  @doc "R5: por cada día, `{dia, [codigos_lideres], litros}`. Incluye empates."
  def lideres_por_dia(validas) do
    for dia <- Validacion.dias() do
      totales =
        validas
        |> Enum.filter(&(&1.dia == dia))
        |> Enum.group_by(& &1.productor)
        |> Enum.map(fn {codigo, es} -> {codigo, es |> sumar_litros() |> redondear()} end)

      case totales do
        [] ->
          {dia, [], 0}

        _ ->
          maximo = totales |> Enum.map(fn {_c, l} -> l end) |> Enum.max()
          lideres = for {codigo, l} <- totales, l == maximo, do: codigo
          {dia, Enum.sort(lideres), maximo}
      end
    end
  end

  @doc "R5 (final): códigos que fueron líderes en más días (puede haber empate)."
  def mas_veces_primero(lideres) do
    conteo = lideres |> Enum.flat_map(fn {_dia, codigos, _l} -> codigos end) |> Enum.frequencies()

    if map_size(conteo) == 0 do
      {0, []}
    else
      maximo = conteo |> Map.values() |> Enum.max()
      {maximo, conteo |> Enum.filter(fn {_c, n} -> n == maximo end) |> Enum.map(&elem(&1, 0)) |> Enum.sort()}
    end
  end

  @doc """
  R6: calidad de los productores con al menos 3 entregas válidas. Devuelve mapas
  con `ponderado` (grasa × litros / litros) y `simple` (promedio de porcentajes).
  """
  def calidad(productores, validas) do
    por_productor = Enum.group_by(validas, & &1.productor)

    for productor <- productores,
        entregas = Map.get(por_productor, productor.codigo, []),
        length(entregas) >= @min_entregas_calidad do
      litros = sumar_litros(entregas)
      ponderado = entregas |> Enum.map(&(&1.grasa * &1.litros)) |> Enum.sum() |> Kernel./(litros)
      simple = entregas |> Enum.map(& &1.grasa) |> Enum.sum() |> Kernel./(length(entregas))

      %{codigo: productor.codigo, nombre: productor.nombre, entregas: length(entregas),
        litros: litros, ponderado: ponderado, simple: simple}
    end
  end

  @doc "R7: `{total_pagado, costo_promedio_por_litro}`."
  def totales_pago(liquidaciones) do
    total = liquidaciones |> Enum.map(& &1.neto) |> Enum.sum()
    litros = liquidaciones |> Enum.map(& &1.litros) |> Enum.sum()
    promedio = if litros > 0, do: total / litros, else: 0.0
    {total, promedio}
  end

  @doc "R8: productores con al menos una entrega válida en todos los tanques."
  def en_todos_los_tanques(productores, tanques, validas) do
    todos = MapSet.new(tanques, & &1.id)
    usados = validas |> Enum.group_by(& &1.productor, & &1.tanque)

    for productor <- productores,
        propios = usados |> Map.get(productor.codigo, []) |> MapSet.new(),
        MapSet.subset?(todos, propios) do
      productor
    end
  end

  # --- Auxiliares ---

  defp sumar_litros(entregas), do: entregas |> Enum.map(& &1.litros) |> Enum.sum()

  # Evita falsos desempates por errores de punto flotante al comparar sumas.
  defp redondear(numero), do: Float.round(numero * 1.0, 4)
end
