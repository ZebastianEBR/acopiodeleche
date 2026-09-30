# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Parte C (investigación). Ejecutar con:  elixir investigacion.exs

Code.require_file("datos.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("liquidacion.exs", __DIR__)
Code.require_file("analisis.exs", __DIR__)
Code.require_file("reportes.exs", __DIR__)

defmodule Investigacion do
  def ejecutar do
    productores = Datos.productores()
    tanques = Datos.tanques()
    {validas, _rechazadas} = Validacion.clasificar(Datos.entregas(), productores, tanques)
    liquidaciones = Liquidacion.liquidar_todos(productores, validas)

    keyword_lists(liquidaciones)
    merge(validas)
    mediciones(productores, tanques)
  end

  defp keyword_lists(liquidaciones) do
    IO.puts("== ranking/2 con keyword lists ==")

    top3 = Analisis.ranking(liquidaciones, por: :neto, orden: :desc, limite: 3)
    IO.puts("Top 3 por neto:    " <> inspect(Enum.map(top3, &{&1.codigo, &1.neto})))

    menos = Analisis.ranking(liquidaciones, por: :litros, orden: :asc, limite: 2)
    IO.puts("2 con menos litros: " <> inspect(Enum.map(menos, &{&1.codigo, &1.litros})))
  end

  defp merge(validas) do
    IO.puts("\n== Map.merge/3 vs Map.merge/2 ==")

    centro_vecino = %{1 => 1850.5, 2 => 2100, 3 => 1640, 5 => 2350, 7 => 800}
    propios = Analisis.litros_por_dia(validas)

    IO.puts("Propios:          " <> inspect(propios))
    IO.puts("Vecino:           " <> inspect(centro_vecino))
    IO.puts("merge/3 (suma):   " <> inspect(Analisis.combinar_litros(propios, centro_vecino)))
    IO.puts("merge/2 (pisa):   " <> inspect(Map.merge(propios, centro_vecino)))
  end

  # Compara buscar códigos en una lista (Enum.member?) contra un MapSet.
  defp mediciones(productores, tanques) do
    IO.puts("\n== Mediciones con :timer.tc/1 ==")

    entregas = Datos.entregas()
    codigos_lista = Enum.map(productores, & &1.codigo)
    ids_lista = Enum.map(tanques, & &1.id)
    codigos_set = MapSet.new(codigos_lista)
    ids_set = MapSet.new(ids_lista)
    repeticiones = 2_000

    {t_lista, _} =
      :timer.tc(fn ->
        for _ <- 1..repeticiones, e <- entregas do
          Enum.member?(codigos_lista, e.productor) and Enum.member?(ids_lista, e.tanque)
        end
      end)

    {t_set, _} =
      :timer.tc(fn ->
        for _ <- 1..repeticiones, e <- entregas do
          MapSet.member?(codigos_set, e.productor) and MapSet.member?(ids_set, e.tanque)
        end
      end)

    IO.puts("Lista  (Enum.member?):   #{t_lista} µs")
    IO.puts("MapSet (MapSet.member?): #{t_set} µs")

    {t_val, _} = :timer.tc(fn -> Validacion.clasificar(entregas, productores, tanques) end)
    IO.puts("Validación completa (una vez): #{t_val} µs")
  end
end

Investigacion.ejecutar()
