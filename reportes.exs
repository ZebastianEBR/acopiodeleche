# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
#
# Módulo de reportes (funciones puras): cada reporte devuelve una lista de
# líneas de texto. Quien imprime es el programa principal.

defmodule Reportes do
  @moduledoc """
  Construye el texto de los reportes R1 a R8 y del comprobante del productor.
  """

  @motivos [
    :productor_desconocido,
    :tanque_desconocido,
    :dia_invalido,
    :litros_fuera_de_rango,
    :porcentaje_invalido
  ]

  # ---------- Formato ----------

  @doc "Pesos con separador de miles: 1234567 -> \"$1.234.567\"."
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

  def litros(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 1) <> " L"
  def porcentaje(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 2) <> " %"

  defp encabezado(titulo), do: ["", String.duplicate("=", 70), titulo, String.duplicate("=", 70)]

  defp izq(texto, ancho), do: texto |> to_string() |> String.pad_trailing(ancho)
  defp der(texto, ancho), do: texto |> to_string() |> String.pad_leading(ancho)

  # ---------- R1 ----------

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

  def r7({total, promedio}) do
    encabezado("R7. TOTAL PAGADO Y COSTO PROMEDIO POR LITRO") ++
      [
        "  Total pagado por el centro:  " <> moneda(total),
        "  Costo promedio por litro:    " <> moneda(promedio) <> " (" <> :erlang.float_to_binary(promedio * 1.0, decimals: 2) <> ")"
      ]
  end

  # ---------- R8 ----------

  def r8(productores) do
    filas =
      case productores do
        [] -> ["  Ningún productor entregó en todos los tanques."]
        _ -> for p <- productores, do: "  " <> p.codigo <> " " <> p.nombre
      end

    encabezado("R8. PRODUCTORES QUE ENTREGARON EN TODOS LOS TANQUES") ++ filas
  end

  # ---------- Comprobante ----------

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
