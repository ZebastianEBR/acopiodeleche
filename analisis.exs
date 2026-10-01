# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Analisis do
  @moduledoc """
  Modulo con los calculos necesarios para los reportes R2 a R8 y para la
  combinacion de mapas de la Parte C (investigacion).
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3
  """

  @meta_diaria 2_000
  @min_entregas_calidad 3

  @doc """
  Devuelve la meta diaria de litros del centro de acopio.

  ## Ejemplo
      iex> Analisis.meta_diaria()
      2000
  """
  def meta_diaria, do: @meta_diaria

  @doc """
  Ordena una lista de mapas segun una keyword list de opciones.

  ## Parametros
  - items: lista de mapas a ordenar
  - opciones: keyword list con
    - `:por`    - campo por el cual ordenar (obligatorio)
    - `:orden`  - `:desc` (por defecto) o `:asc`
    - `:limite` - cantidad maxima de elementos a devolver (por defecto `:todos`)

  ## Ejemplo
      iex> Analisis.ranking(liquidaciones, por: :neto, orden: :desc, limite: 3)
      [%{codigo: "P04", neto: 950000}, %{codigo: "P02", neto: 800000}, %{codigo: "P01", neto: 500000}]
  """
  def ranking(items, opciones) do
    campo = Keyword.fetch!(opciones, :por)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, :todos)

    ordenados = Enum.sort_by(items, &Map.fetch!(&1, campo), orden)

    if limite == :todos, do: ordenados, else: Enum.take(ordenados, limite)
  end

  @doc """
  Calcula los litros y el porcentaje de ocupacion de cada tanque.

  ## Parametros
  - tanques: lista completa de tanques
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Analisis.ocupacion_tanques(Datos.tanques(), validas)
      [%{id: "T1", nombre: "Tanque Norte", capacidad: 6000, litros: 4800, ocupacion: 80.0}, ...]
  """
  def ocupacion_tanques(tanques, validas) do
    por_tanque = Enum.group_by(validas, & &1.tanque)

    for tanque <- tanques do
      litros = por_tanque |> Map.get(tanque.id, []) |> sumar_litros()
      %{id: tanque.id, nombre: tanque.nombre, capacidad: tanque.capacidad,
        litros: litros, ocupacion: litros / tanque.capacidad * 100}
    end
  end

  @doc """
  Calcula el total de litros recibidos en cada uno de los 6 dias. Un dia
  sin entregas aparece con 0 litros.

  ## Parametro
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Analisis.litros_por_dia(validas)
      %{1 => 3347.5, 2 => 3470.5, 3 => 0, 4 => 1910.0, 5 => 2822.5, 6 => 2561.0}
  """
  def litros_por_dia(validas) do
    por_dia = Enum.group_by(validas, & &1.dia)

    for dia <- Validacion.dias(), into: %{} do
      {dia, por_dia |> Map.get(dia, []) |> sumar_litros()}
    end
  end

  @doc """
  Combina los litros diarios propios con los de un centro vecino usando
  `Map.merge/3`, sumando los valores de las claves (dias) que aparezcan
  en ambos mapas.

  ## Parametros
  - litros_propios: mapa `dia => litros` del propio centro
  - litros_vecino: mapa `dia => litros` del centro vecino

  ## Ejemplo
      iex> propios = %{1 => 1000, 2 => 2000}
      iex> vecino = %{1 => 500, 3 => 800}
      iex> Analisis.combinar_litros(propios, vecino)
      %{1 => 1500, 2 => 2000, 3 => 800}
  """
  def combinar_litros(litros_propios, litros_vecino) do
    Map.merge(litros_propios, litros_vecino, fn _dia, propios, vecino -> propios + vecino end)
  end

  @doc """
  Calcula, para cada dia, el o los productores con mayor cantidad de
  litros entregados (incluye empates).

  ## Parametro
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Analisis.lideres_por_dia(validas)
      [{1, ["P01"], 470.0}, {2, ["P02", "P05"], 300.0}, ...]
  """
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

  @doc """
  A partir del resultado de `lideres_por_dia/1`, indica que productor(es)
  ocuparon el primer lugar en mas dias.

  ## Parametro
  - lideres: lista devuelta por `lideres_por_dia/1`

  ## Ejemplo
      iex> Analisis.mas_veces_primero(lideres)
      {3, ["P01"]}
  """
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
  Calcula la calidad de los productores con al menos 3 entregas validas,
  segun el porcentaje de grasa ponderado por litros y el promedio simple.

  ## Parametros
  - productores: lista completa de productores
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Analisis.calidad(Datos.productores(), validas)
      [%{codigo: "P07", nombre: "Rosa Marin", entregas: 5, litros: 760, ponderado: 3.08, simple: 4.08}]
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

  @doc """
  Calcula el total pagado por el centro y el costo promedio pagado por litro.

  ## Parametro
  - liquidaciones: lista devuelta por `Liquidacion.liquidar_todos/2`

  ## Ejemplo
      iex> Analisis.totales_pago(liquidaciones)
      {12345678, 1932.5}
  """
  def totales_pago(liquidaciones) do
    total = liquidaciones |> Enum.map(& &1.neto) |> Enum.sum()
    litros = liquidaciones |> Enum.map(& &1.litros) |> Enum.sum()
    promedio = if litros > 0, do: total / litros, else: 0.0
    {total, promedio}
  end

  @doc """
  Calcula los productores que tuvieron al menos una entrega valida en
  todos los tanques del centro.

  ## Parametros
  - productores: lista completa de productores
  - tanques: lista completa de tanques
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Analisis.en_todos_los_tanques(Datos.productores(), Datos.tanques(), validas)
      [%{codigo: "P01", nombre: "Marta Gomez", transporte: true}]
  """
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

  # Suma el campo :litros de una lista de entregas.
  defp sumar_litros(entregas), do: entregas |> Enum.map(& &1.litros) |> Enum.sum()

  # Evita falsos desempates por errores de punto flotante al comparar sumas.
  defp redondear(numero), do: Float.round(numero * 1.0, 4)
end
