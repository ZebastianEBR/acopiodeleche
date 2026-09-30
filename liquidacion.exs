# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Módulo de liquidación (funciones puras).

defmodule Liquidacion do
  @moduledoc """
  Calcula el valor de las entregas, bonificaciones, transporte y neto.
  """

  @tarifa_base 1_800
  @litros_bonificacion 450
  @bonificacion_diaria 25_000
  @costo_transporte 18_000

  @doc "Valor de una entrega válida, en pesos enteros (redondeado al peso)."
  def valor_entrega(%{litros: litros, grasa: grasa}) do
    round(litros * @tarifa_base * factor_grasa(grasa))
  end

  defp factor_grasa(grasa) when grasa >= 3.5, do: 1.06
  defp factor_grasa(grasa) when grasa >= 3.0, do: 1.0
  defp factor_grasa(grasa) when grasa >= 2.5, do: 0.92
  defp factor_grasa(_grasa), do: 0.80

  @doc "Bonificación de un día según el total de litros del productor ese día."
  def bonificacion(litros_dia) when litros_dia >= @litros_bonificacion, do: @bonificacion_diaria
  def bonificacion(_litros_dia), do: 0

  @doc """
  Detalle por día de un productor: lista de mapas con `dia`, `litros`, `valor`
  y `bonificacion`, solo para los días con al menos una entrega válida.
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

  @doc "Liquidación de un productor (con valores en cero si no tiene entregas)."
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

  @doc "Liquida a todos los productores."
  def liquidar_todos(productores, validas) do
    Enum.map(productores, &liquidar(&1, validas))
  end
end
