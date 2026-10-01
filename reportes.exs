# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Reportes do
  @moduledoc """
  Modulo que arma el texto de los reportes R1 a R8 y del comprobante.
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3

  Cada funcion de reporte devuelve una lista de lineas de texto; quien
  imprime esas lineas es `Interaccion.imprimir/1`. Asi, este modulo se
  mantiene puro (sin entrada/salida) y facil de probar.
  """

  @motivos [
    :productor_desconocido,
    :tanque_desconocido,
    :dia_invalido,
    :litros_fuera_de_rango,
    :porcentaje_invalido
  ]

  # ---------- Formato ----------

  @doc """
  Formatea un valor numerico como pesos colombianos, con separador de
  miles y el simbolo `$` adelante.

  ## Parametro
  - valor: numero a formatear

  ## Ejemplo
      iex> Reportes.moneda(1234567)
      "$1.234.567"
      iex> Reportes.moneda(-5000)
      "-$5.000"
  """
  def moneda(valor) do
    entero = round(valor)
    signo = if entero < 0, do: "-", else: ""

    miles =
      entero
      |> abs()
      |> Integer.to_string()
      |> String.reverse()
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.join/1)
      |> Enum.join(".")
      |> String.reverse()

    signo <> "$" <> miles
  end

  @doc """
  Formatea un valor numerico como litros, con 1 decimal.

  ## Ejemplo
      iex> Reportes.litros(470)
      "470.0 L"
  """
  def litros(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 1) <> " L"

  @doc """
  Formatea un valor numerico como porcentaje, con 2 decimales.

  ## Ejemplo
      iex> Reportes.porcentaje(80.5)
      "80.50 %"
  """
  def porcentaje(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 2) <> " %"

  # Arma el encabezado decorativo que comparten todos los reportes.
  defp encabezado(titulo), do: ["", String.duplicate("=", 70), titulo, String.duplicate("=", 70)]

  # Alinea texto a la izquierda, rellenando con espacios a la derecha.
  defp izq(texto, ancho), do: texto |> to_string() |> String.pad_trailing(ancho)

  # Alinea texto a la derecha, rellenando con espacios a la izquierda.
  defp der(texto, ancho), do: texto |> to_string() |> String.pad_leading(ancho)

  # ---------- R1 ----------

  @doc """
  Arma el reporte R1: entregas rechazadas con su motivo, y la cantidad
  de rechazos por cada motivo.

  ## Parametro
  - rechazadas: lista de pares `{entrega, motivo}`, devuelta por
    `Validacion.clasificar/3`

  ## Ejemplo
      iex> Reportes.r1(rechazadas) |> List.first()
      ""
  """
  def r1(rechazadas) do
    detalle =
      case rechazadas do
        [] ->
          ["  (no hay entregas rechazadas)"]

        _ ->
          for {e, motivo} <- rechazadas do
            "  " <> inspect(Map.get(e, :productor)) <> " | " <> inspect(Map.get(e, :tanque)) <>
              " | día " <> inspect(Map.get(e, :dia)) <> " | litros " <> inspect(Map.get(e, :litros)) <>
              " | grasa " <> inspect(Map.get(e, :grasa)) <> "  ->  " <> inspect(motivo)
          end
      end

    conteo =
      for motivo <- @motivos do
        "  " <> izq(inspect(motivo), 24) <> der(Enum.count(rechazadas, fn {_e, m} -> m == motivo end), 3)
      end

    encabezado("R1. ENTREGAS RECHAZADAS") ++
      detalle ++ ["", "  Cantidad de rechazos por motivo:"] ++ conteo ++
      ["  " <> izq("TOTAL", 24) <> der(length(rechazadas), 3)]
  end

  # ---------- R2 ----------

  @doc """
  Arma el reporte R2: litros y ocupacion de cada tanque, ordenados de
  mayor a menor porcentaje de ocupacion.

  ## Parametro
  - ocupacion: lista devuelta por `Analisis.ocupacion_tanques/2`
  """
  def r2(ocupacion) do
    ordenada = Analisis.ranking(ocupacion, por: :ocupacion, orden: :desc)

    filas =
      for t <- ordenada do
        "  " <> izq(t.id <> " " <> t.nombre, 22) <> der(litros(t.litros), 12) <>
          der("de " <> Integer.to_string(t.capacidad), 10) <> der(porcentaje(t.ocupacion), 10)
      end

    encabezado("R2. LITROS Y OCUPACIÓN POR TANQUE (mayor a menor ocupación)") ++ filas
  end

  # ---------- R3 ----------

  @doc """
  Arma el reporte R3: litros recibidos por dia y si se alcanzo la meta.

  ## Parametro
  - litros_dia: mapa devuelto por `Analisis.litros_por_dia/1`
  """
  def r3(litros_dia) do
    meta = Analisis.meta_diaria()
    dias = litros_dia |> Map.keys() |> Enum.sort()

    filas =
      for dia <- dias do
        l = Map.fetch!(litros_dia, dia)
        "  Día " <> Integer.to_string(dia) <> ": " <> der(litros(l), 12) <>
          "   meta " <> if(l >= meta, do: "ALCANZADA", else: "no alcanzada")
      end

    todos = Enum.all?(dias, fn d -> Map.fetch!(litros_dia, d) >= meta end)
    alguno = Enum.any?(dias, fn d -> Map.fetch!(litros_dia, d) >= meta end)

    encabezado("R3. LITROS RECIBIDOS POR DÍA (meta: #{meta} L)") ++ filas ++
      [
        "",
        "  ¿Meta cumplida todos los días?    " <> si_no(todos),
        "  ¿Meta cumplida al menos un día?   " <> si_no(alguno)
      ]
  end

  defp si_no(true), do: "Sí"
  defp si_no(false), do: "No"

  # ---------- R4 ----------

  @doc """
  Arma el reporte R4: liquidacion de todos los productores, numerada y
  ordenada por pago neto de mayor a menor.

  ## Parametro
  - liquidaciones: lista devuelta por `Liquidacion.liquidar_todos/2`
  """
  def r4(liquidaciones) do
    ordenadas = Analisis.ranking(liquidaciones, por: :neto, orden: :desc)

    cabecera =
      "  " <> der("#", 3) <> "  " <> izq("Productor", 22) <> der("Litros", 11) <> der("Entregas", 13) <>
        der("Bonif.", 11) <> der("Transp.", 10) <> der("Neto", 13)

    filas =
      for {l, i} <- Enum.with_index(ordenadas, 1) do
        "  " <> der(i, 3) <> "  " <> izq(l.codigo <> " " <> l.nombre, 22) <> der(litros(l.litros), 11) <>
          der(moneda(l.valor), 13) <> der(moneda(l.bonificaciones), 11) <>
          der(moneda(l.transporte), 10) <> der(moneda(l.neto), 13)
      end

    encabezado("R4. LIQUIDACIÓN DE PRODUCTORES (por pago neto)") ++ [cabecera | filas]
  end

  # ---------- R5 ----------

  @doc """
  Arma el reporte R5: productor con mas litros entregados cada dia (con
  empates), e indica quien ocupo el primer lugar en mas dias.

  ## Parametros
  - lideres: lista devuelta por `Analisis.lideres_por_dia/1`
  - nombres: mapa `codigo => nombre` de los productores
  """
  def r5(lideres, nombres) do
    filas =
      for {dia, codigos, l} <- lideres do
        quienes =
          case codigos do
            [] -> "(sin entregas)"
            _ -> codigos |> Enum.map(&nombre_de(&1, nombres)) |> Enum.join(", ")
          end

        "  Día " <> Integer.to_string(dia) <> ": " <> quienes <> " (" <> litros(l) <> ")"
      end

    {veces, primeros} = Analisis.mas_veces_primero(lideres)

    final =
      case primeros do
        [] -> "  Nadie ocupó el primer lugar."
        _ ->
          "  Más días en primer lugar: " <> (primeros |> Enum.map(&nombre_de(&1, nombres)) |> Enum.join(", ")) <>
            " (" <> Integer.to_string(veces) <> " días)"
      end

    encabezado("R5. PRODUCTOR CON MÁS LITROS CADA DÍA") ++ filas ++ ["", final]
  end

  defp nombre_de(codigo, nombres), do: codigo <> " " <> Map.get(nombres, codigo, "")

  # ---------- R6 ----------

  @doc """
  Arma el reporte R6: productor con mejor calidad (porcentaje de grasa
  ponderado por litros), entre quienes tengan al menos 3 entregas validas.

  ## Parametro
  - calidad: lista devuelta por `Analisis.calidad/2`
  """
  def r6(calidad) do
    case Analisis.ranking(calidad, por: :ponderado, orden: :desc) do
      [] ->
        encabezado("R6. MEJOR CALIDAD (mínimo 3 entregas válidas)") ++
          ["  Ningún productor tiene 3 o más entregas válidas."]

      [mejor | _] = ordenados ->
        filas =
          for c <- ordenados do
            "  " <> izq(c.codigo <> " " <> c.nombre, 22) <> der(c.entregas, 4) <> " entregas" <>
              "  ponderado " <> der(porcentaje(c.ponderado), 9) <> "  promedio simple " <> der(porcentaje(c.simple), 9)
          end

        encabezado("R6. MEJOR CALIDAD (mínimo 3 entregas válidas)") ++ filas ++
          ["", "  Mejor calidad: " <> mejor.codigo <> " " <> mejor.nombre <>
             " (ponderado " <> porcentaje(mejor.ponderado) <> ")"]
    end
  end

  # ---------- R7 ----------

  @doc """
  Arma el reporte R7: total pagado por el centro y costo promedio por litro.

  ## Parametro
  - totales: tupla `{total, promedio}` devuelta por `Analisis.totales_pago/1`
  """
  def r7({total, promedio}) do
    encabezado("R7. TOTAL PAGADO Y COSTO PROMEDIO POR LITRO") ++
      [
        "  Total pagado por el centro:  " <> moneda(total),
        "  Costo promedio por litro:    " <> moneda(promedio) <> " (" <> :erlang.float_to_binary(promedio * 1.0, decimals: 2) <> ")"
      ]
  end

  # ---------- R8 ----------

  @doc """
  Arma el reporte R8: productores que entregaron en todos los tanques.

  ## Parametro
  - productores: lista devuelta por `Analisis.en_todos_los_tanques/3`
  """
  def r8(productores) do
    filas =
      case productores do
        [] -> ["  Ningún productor entregó en todos los tanques."]
        _ -> for p <- productores, do: "  " <> p.codigo <> " " <> p.nombre
      end

    encabezado("R8. PRODUCTORES QUE ENTREGARON EN TODOS LOS TANQUES") ++ filas
  end

  # ---------- Comprobante ----------

  @doc """
  Arma el comprobante de un productor: detalle diario, totales y neto a pagar.

  ## Parametro
  - liquidacion: mapa devuelto por `Liquidacion.liquidar/2`
  """
  def comprobante(liquidacion) do
    filas =
      case liquidacion.dias do
        [] ->
          ["  (sin entregas válidas en la semana)"]

        dias ->
          for d <- dias do
            "  Día " <> Integer.to_string(d.dia) <> ": " <> der(litros(d.litros), 11) <>
              "  entregas " <> der(moneda(d.valor), 12) <> "  bonificación " <> der(moneda(d.bonificacion), 9)
          end
      end

    encabezado("COMPROBANTE: " <> liquidacion.nombre <> " (" <> liquidacion.codigo <> ")") ++
      filas ++
      [
        "",
        "  Litros entregados:       " <> litros(liquidacion.litros),
        "  Total de entregas:       " <> moneda(liquidacion.valor),
        "  Total de bonificaciones: " <> moneda(liquidacion.bonificaciones),
        "  Descuento por transporte:" <> der(moneda(liquidacion.transporte), 10),
        "  NETO A PAGAR:            " <> moneda(liquidacion.neto)
      ]
  end
end
