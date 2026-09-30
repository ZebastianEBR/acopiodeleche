# Integrantes: [Sebastian Ballesteros Ruiz], [Kevin Echeverry], [Sebastian Alirio]
#
# Programa principal. Ejecutar con:  elixir main.exs

Code.require_file("datos.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("liquidacion.exs", __DIR__)
Code.require_file("analisis.exs", __DIR__)
Code.require_file("reportes.exs", __DIR__)
Code.require_file("interaccion.exs", __DIR__)

defmodule Main do
  @moduledoc """
  Modulo principal: orquesta la carga de datos, la entrega adicional, la
  validacion, los reportes y el comprobante.
  - Autores: Sebastian Ballesteros Ruiz, Kevin Echeverry, Sebastian Alirio
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3
  """

  def ejecutar do
    productores = Datos.productores()
    tanques = Datos.tanques()
    entregas = agregar_entrega_adicional(Datos.entregas())

    {validas, rechazadas} = Validacion.clasificar(entregas, productores, tanques)
    liquidaciones = Liquidacion.liquidar_todos(productores, validas)
    nombres = Map.new(productores, &{&1.codigo, &1.nombre})

    Interaccion.imprimir(Reportes.r1(rechazadas))
    Interaccion.imprimir(Reportes.r2(Analisis.ocupacion_tanques(tanques, validas)))
    Interaccion.imprimir(Reportes.r3(Analisis.litros_por_dia(validas)))
    Interaccion.imprimir(Reportes.r4(liquidaciones))
    Interaccion.imprimir(Reportes.r5(Analisis.lideres_por_dia(validas), nombres))
    Interaccion.imprimir(Reportes.r6(Analisis.calidad(productores, validas)))
    Interaccion.imprimir(Reportes.r7(Analisis.totales_pago(liquidaciones)))
    Interaccion.imprimir(Reportes.r8(Analisis.en_todos_los_tanques(productores, tanques, validas)))

    mostrar_comprobante(liquidaciones)
  end

  # Una sola entrada adicional por ejecución.
  defp agregar_entrega_adicional(entregas) do
    case Interaccion.pedir_entrega_adicional() do
      :omitir ->
        entregas

      {:ok, texto} ->
        case Validacion.parsear_entrega(texto) do
          {:ok, entrega} ->
            IO.puts("Entrega recibida; se validará junto con las demás.")
            entregas ++ [entrega]

          {:error, :formato_invalido} ->
            IO.puts("Formato inválido: la entrega no se incorporó.")
            entregas
        end
    end
  end

  defp mostrar_comprobante(liquidaciones) do
    case Interaccion.pedir_codigo_productor() do
      :omitir ->
        IO.puts("Fin del programa.")

      {:ok, codigo} ->
        case Enum.find(liquidaciones, &(&1.codigo == codigo)) do
          nil -> IO.puts("El código #{codigo} no existe.")
          liquidacion -> Interaccion.imprimir(Reportes.comprobante(liquidacion))
        end
    end
  end
end

Main.ejecutar()
