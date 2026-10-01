# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Liquidacion do
  @moduledoc """
  Modulo con las funciones de liquidacion de productores.
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3

  Calcula el valor de cada entrega segun su porcentaje de grasa, la
  bonificacion por volumen diario, el descuento de transporte y el neto a
  pagar a cada productor.
  """

  @tarifa_base 1_800
  @litros_bonificacion 450
  @bonificacion_diaria 25_000
  @costo_transporte 18_000

  @doc """
  Calcula el valor en pesos de una entrega valida, segun sus litros y su
  ajuste por porcentaje de grasa.

  ## Parametro
  - entrega: mapa con al menos :litros y :grasa

  ## Ejemplo
      iex> Liquidacion.valor_entrega(%{litros: 100, grasa: 3.6})
      190800
  """
  def valor_entrega(%{litros: litros, grasa: grasa}) do
    round(litros * @tarifa_base * factor_grasa(grasa))
  end

  # Ajuste del valor segun el porcentaje de grasa de la muestra.
  defp factor_grasa(grasa) when grasa >= 3.5, do: 1.06
  defp factor_grasa(grasa) when grasa >= 3.0, do: 1.0
  defp factor_grasa(grasa) when grasa >= 2.5, do: 0.92
  defp factor_grasa(_grasa), do: 0.80

  @doc """
  Calcula la bonificacion de un dia, segun el total de litros entregados
  ese dia por un mismo productor.

  ## Parametro
  - litros_dia: suma de litros validos de un productor en un dia

  ## Ejemplo
      iex> Liquidacion.bonificacion(500)
      25000
      iex> Liquidacion.bonificacion(200)
      0
  """
  def bonificacion(litros_dia) when litros_dia >= @litros_bonificacion, do: @bonificacion_diaria
  def bonificacion(_litros_dia), do: 0

  @doc """
  Arma el detalle dia por dia de un productor, con litros, valor de las
  entregas y bonificacion, solo para los dias en que tuvo entregas validas.

  ## Parametros
  - codigo: codigo del productor
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Liquidacion.detalle_dias("P01", validas)
      [%{dia: 1, litros: 470, valor: 837900, bonificacion: 25000}]
  """
  def detalle_dias(codigo, validas) do
    validas
    |> Enum.filter(&(&1.productor == codigo))
    |> Enum.group_by(& &1.dia)
    |> Enum.sort_by(fn {dia, _entregas} -> dia end)
    |> Enum.map(fn {dia, entregas} ->
      litros = entregas |> Enum.map(& &1.litros) |> Enum.sum()
      valor = entregas |> Enum.map(&valor_entrega/1) |> Enum.sum()
      %{dia: dia, litros: litros, valor: valor, bonificacion: bonificacion(litros)}
    end)
  end

  @doc """
  Calcula la liquidacion completa de un productor. Si no tiene entregas
  validas, todos sus valores quedan en cero.

  ## Parametros
  - productor: mapa con :codigo, :nombre, :transporte
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Liquidacion.liquidar(%{codigo: "P01", nombre: "Marta", transporte: true}, validas)
      %{codigo: "P01", nombre: "Marta", dias: [...], litros: 470, valor: 837900,
        bonificaciones: 25000, transporte: 18000, neto: 844900}
  """
  def liquidar(productor, validas) do
    dias = detalle_dias(productor.codigo, validas)

    litros = dias |> Enum.map(& &1.litros) |> Enum.sum()
    valor = dias |> Enum.map(& &1.valor) |> Enum.sum()
    bonificaciones = dias |> Enum.map(& &1.bonificacion) |> Enum.sum()
    transporte = if productor.transporte, do: @costo_transporte * length(dias), else: 0

    %{
      codigo: productor.codigo,
      nombre: productor.nombre,
      dias: dias,
      litros: litros,
      valor: valor,
      bonificaciones: bonificaciones,
      transporte: transporte,
      neto: valor + bonificaciones - transporte
    }
  end

  @doc """
  Liquida a todos los productores de la lista.

  ## Parametros
  - productores: lista completa de productores
  - validas: lista de todas las entregas validas del centro

  ## Ejemplo
      iex> Liquidacion.liquidar_todos(Datos.productores(), validas)
      [%{codigo: "P01", ...}, %{codigo: "P02", ...}, ...]
  """
  def liquidar_todos(productores, validas) do
    Enum.map(productores, &liquidar(&1, validas))
  end
end
