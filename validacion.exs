# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Validacion do
  @moduledoc """
  Modulo con las funciones de validacion de entregas del centro de acopio.
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3

  Contiene las reglas de validacion en el orden exigido por el enunciado
  (productor, tanque, dia, litros, grasa), encadenadas con `with`, y la
  funcion para interpretar el texto de una entrega adicional ingresada por
  el usuario.
  """

  @dia_min 1
  @dia_max 6
  @max_litros 800
  @grasa_min 0
  @grasa_max 15

  @doc """
  Devuelve el rango de dias de recepcion del centro (1 al 6).

  ## Ejemplo
      iex> Validacion.dias()
      1..6
  """
  def dias, do: @dia_min..@dia_max

  @doc """
  Valida una entrega contra las 5 reglas de negocio, en el orden exigido.
  Si incumple varias reglas, se reporta unicamente la primera encontrada.

  ## Parametros
  - entrega: mapa con :productor, :tanque, :dia, :litros, :grasa
  - codigos_productores: MapSet con los codigos de productores validos
  - ids_tanques: MapSet con los ids de tanques validos

  ## Devuelve
  `{:ok, entrega}` si pasa las 5 reglas, o `{:error, motivo}` con el
  primer motivo de rechazo encontrado.

  ## Ejemplo
      iex> entrega = %{productor: "P01", tanque: "T1", dia: 1, litros: 200, grasa: 3.5}
      iex> Validacion.validar_entrega(entrega, MapSet.new(["P01"]), MapSet.new(["T1"]))
      {:ok, %{productor: "P01", tanque: "T1", dia: 1, litros: 200, grasa: 3.5}}
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
  Valida una lista completa de entregas y las separa en validas y rechazadas.

  ## Parametros
  - entregas: lista de mapas de entrega a validar
  - productores: lista de productores reales del centro
  - tanques: lista de tanques reales del centro

  ## Devuelve
  Una tupla `{validas, rechazadas}`, donde `validas` es la lista de entregas
  aceptadas y `rechazadas` es una lista de pares `{entrega, motivo}`.

  ## Ejemplo
      iex> Validacion.clasificar(entregas, Datos.productores(), Datos.tanques())
      {[%{...}, %{...}], [{%{...}, :dia_invalido}]}
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
  Interpreta el texto `productor;tanque;dia;litros;grasa` de la entrega
  adicional ingresada por el usuario.

  ## Parametro
  - texto: linea ingresada por el usuario, con los 5 campos separados por `;`

  ## Devuelve
  `{:ok, entrega}` si el texto tiene el formato correcto (5 campos, dia
  entero, litros y grasa numericos), o `{:error, :formato_invalido}` en
  cualquier otro caso.

  ## Ejemplo
      iex> Validacion.parsear_entrega("P03;T2;4;320.5;3.6")
      {:ok, %{productor: "P03", tanque: "T2", dia: 4, litros: 320.5, grasa: 3.6}}

      iex> Validacion.parsear_entrega("P03;T2;cuatro;320.5;3.6")
      {:error, :formato_invalido}
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

  # Regla 1: el codigo del productor debe existir entre los productores reales.
  defp validar_productor(entrega, codigos) do
    if MapSet.member?(codigos, Map.get(entrega, :productor)),
      do: :ok,
      else: {:error, :productor_desconocido}
  end

  # Regla 2: el id del tanque debe existir entre los tanques reales.
  defp validar_tanque(entrega, ids) do
    if MapSet.member?(ids, Map.get(entrega, :tanque)),
      do: :ok,
      else: {:error, :tanque_desconocido}
  end

  # Regla 3: el dia debe ser un entero entre 1 y 6.
  defp validar_dia(%{dia: dia}) when is_integer(dia) and dia >= @dia_min and dia <= @dia_max,
    do: :ok

  defp validar_dia(_), do: {:error, :dia_invalido}

  # Regla 4: los litros deben ser un numero mayor que 0 y maximo 800.
  defp validar_litros(%{litros: litros})
       when is_number(litros) and litros > 0 and litros <= @max_litros,
       do: :ok

  defp validar_litros(_), do: {:error, :litros_fuera_de_rango}

  # Regla 5: el porcentaje de grasa debe ser un numero entre 0 y 15.
  defp validar_grasa(%{grasa: grasa})
       when is_number(grasa) and grasa >= @grasa_min and grasa <= @grasa_max,
       do: :ok

  defp validar_grasa(_), do: {:error, :porcentaje_invalido}
end
