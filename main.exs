# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Programa principal. Ejecutar con:  elixir main.exs
# (los archivos .exs deben estar en la misma carpeta)

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
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3
  """

  @doc """
  Punto de entrada del programa. Carga los datos, pide la entrega
  adicional, valida todo, imprime los reportes R1 a R8 y finalmente
  muestra el comprobante del productor que se indique.
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

  # Pide la entrega adicional y, si el formato es correcto, la agrega a
  # la lista de entregas para que se valide junto con las demas. El
  # programa atiende una sola entrada adicional por ejecucion.
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

  # Pide el codigo del productor y muestra su comprobante, o avisa si
  # el codigo no existe, sin que el programa falle.
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
