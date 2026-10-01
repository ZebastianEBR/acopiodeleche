# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

defmodule Datos do
  @moduledoc """
  Modulo con los datos de prueba del grupo para el centro de acopio.
  - Autor: [Nombre 1], [Nombre 2], [Nombre 3]
  - Fecha: Septiembre 2026
  - Licencia: GNU GPL v3

  Incluye 10 productores (5 con transporte), 4 tanques, entregas en los
  6 dias, al menos 80 entregas validas y al menos 2 entregas invalidas
  por cada motivo de rechazo (para probar Validacion.clasificar/3).

  Casos armados a proposito:
  - P07 tiene un promedio simple de grasa bastante mayor a su promedio
    ponderado por litros (para la explicacion de R6).
  - P09 tiene solo 2 entregas validas, por lo que queda fuera de R6
    (que exige al menos 3).
  - P10 no tiene ninguna entrega valida, y debe aparecer en R4 con
    todos sus valores en cero.
  """

  @doc """
  Lista de los 10 productores del centro, cada uno con su codigo,
  nombre y si usa el servicio de transporte.
  """
  def productores do
    [
      %{codigo: "P01", nombre: "Marta Gómez", transporte: true},
      %{codigo: "P02", nombre: "Luis Cardona", transporte: false},
      %{codigo: "P03", nombre: "Andrea Ospina", transporte: true},
      %{codigo: "P04", nombre: "Carlos Restrepo", transporte: false},
      %{codigo: "P05", nombre: "Diana Salazar", transporte: true},
      %{codigo: "P06", nombre: "Jorge Valencia", transporte: false},
      %{codigo: "P07", nombre: "Rosa Marín", transporte: true},
      %{codigo: "P08", nombre: "Hernán Duque", transporte: false},
      %{codigo: "P09", nombre: "Sandra López", transporte: true},
      %{codigo: "P10", nombre: "Felipe Arias", transporte: false}
    ]
  end

  @doc """
  Lista de los 4 tanques del centro, cada uno con su id, nombre y
  capacidad nominal en litros.
  """
  def tanques do
    [
      %{id: "T1", nombre: "Tanque Norte", capacidad: 6000},
      %{id: "T2", nombre: "Tanque Central", capacidad: 5000},
      %{id: "T3", nombre: "Tanque Sur", capacidad: 4000},
      %{id: "T4", nombre: "Tanque Oriente", capacidad: 4500}
    ]
  end

  @doc """
  Lista de entregas registradas durante la semana, transcritas de las
  planillas. Incluye entregas validas e invalidas; la deteccion de
  errores la hace `Validacion.clasificar/3`, no este modulo.
  """
  def entregas do
    [
      %{productor: "P01", tanque: "T1", dia: 1, litros: 240, grasa: 3.8},
      %{productor: "P01", tanque: "T2", dia: 1, litros: 230, grasa: 3.9},
      %{productor: "P01", tanque: "T1", dia: 1, litros: 180, grasa: 3.6},
      %{productor: "P99", tanque: "T1", dia: 2, litros: 150, grasa: 3.4},
      %{productor: "P01", tanque: "T4", dia: 1, litros: 60, grasa: 3.8},
      %{productor: "P01", tanque: "T1", dia: 1, litros: 300, grasa: 4.1},
      %{productor: "P02", tanque: "T2", dia: 1, litros: 200, grasa: 3.6},
      %{productor: "P02", tanque: "T1", dia: 1, litros: 165.5, grasa: 3.5},
      %{productor: "P00", tanque: "T3", dia: 5, litros: 90, grasa: 3.1},
      %{productor: "P02", tanque: "T1", dia: 1, litros: 300, grasa: 2.5},
      %{productor: "P04", tanque: "T2", dia: 1, litros: 165.5, grasa: 3.6},
      %{productor: "P05", tanque: "T1", dia: 1, litros: 80, grasa: 3.4},
      %{productor: "P05", tanque: "T3", dia: 1, litros: 165.5, grasa: 3.9},
      %{productor: "X01", tanque: "T2", dia: 1, litros: 200, grasa: 3.5},
      %{productor: "P05", tanque: "T1", dia: 1, litros: 300, grasa: 2.5},
      %{productor: "P06", tanque: "T3", dia: 1, litros: 80, grasa: 2.8},
      %{productor: "P07", tanque: "T1", dia: 1, litros: 60, grasa: 4.5},
      %{productor: "P08", tanque: "T3", dia: 1, litros: 95.5, grasa: 2.8},
      %{productor: "P02", tanque: "T9", dia: 3, litros: 120, grasa: 3.3},
      %{productor: "P08", tanque: "T3", dia: 1, litros: 410, grasa: 2.9},
      %{productor: "P08", tanque: "T3", dia: 1, litros: 150, grasa: 2.5},
      %{productor: "P08", tanque: "T4", dia: 1, litros: 165.5, grasa: 2.7},
      %{productor: "P01", tanque: "T4", dia: 2, litros: 410, grasa: 3.1},
      %{productor: "P03", tanque: "TX", dia: 4, litros: 180, grasa: 3.6},
      %{productor: "P01", tanque: "T1", dia: 2, litros: 340, grasa: 3.3},
      %{productor: "P02", tanque: "T1", dia: 2, litros: 80, grasa: 3.5},
      %{productor: "P02", tanque: "T1", dia: 2, litros: 220, grasa: 3.1},
      %{productor: "P02", tanque: "T2", dia: 2, litros: 180, grasa: 3.8},
      %{productor: "P05", tanque: "T0", dia: 6, litros: 75, grasa: 3.0},
      %{productor: "P03", tanque: "T2", dia: 2, litros: 180, grasa: 3.7},
      %{productor: "P03", tanque: "T1", dia: 2, litros: 135, grasa: 3.8},
      %{productor: "P04", tanque: "T2", dia: 2, litros: 260, grasa: 2.8},
      %{productor: "P04", tanque: "T2", dia: 2, litros: 165.5, grasa: 3.2},
      %{productor: "P04", tanque: "T2", dia: 0, litros: 150, grasa: 3.2},
      %{productor: "P05", tanque: "T3", dia: 2, litros: 340, grasa: 3.5},
      %{productor: "P06", tanque: "T2", dia: 2, litros: 340, grasa: 2.9},
      %{productor: "P06", tanque: "T4", dia: 2, litros: 150, grasa: 3.5},
      %{productor: "P06", tanque: "T3", dia: 2, litros: 80, grasa: 2.7},
      %{productor: "P06", tanque: "T1", dia: 7, litros: 130, grasa: 3.4},
      %{productor: "P07", tanque: "T2", dia: 2, litros: 70, grasa: 4.4},
      %{productor: "P08", tanque: "T4", dia: 2, litros: 180, grasa: 2.6},
      %{productor: "P08", tanque: "T4", dia: 2, litros: 200, grasa: 2.0},
      %{productor: "P09", tanque: "T2", dia: 2, litros: 140, grasa: 3.2},
      %{productor: "P01", tanque: "T3", dia: "3", litros: 100, grasa: 3.3},
      %{productor: "P01", tanque: "T3", dia: 3, litros: 120, grasa: 3.7},
      %{productor: "P01", tanque: "T1", dia: 3, litros: 260, grasa: 3.2},
      %{productor: "P03", tanque: "T4", dia: 3, litros: 165.5, grasa: 3.4},
      %{productor: "P03", tanque: "T1", dia: 3, litros: 340, grasa: 3.7},
      %{productor: "P08", tanque: "T4", dia: 2.5, litros: 90, grasa: 2.8},
      %{productor: "P04", tanque: "T2", dia: 3, litros: 200, grasa: 2.9},
      %{productor: "P04", tanque: "T2", dia: 3, litros: 340, grasa: 3.3},
      %{productor: "P05", tanque: "T3", dia: 3, litros: 340, grasa: 3.4},
      %{productor: "P05", tanque: "T4", dia: 3, litros: 110, grasa: 3.3},
      %{productor: "P02", tanque: "T1", dia: 4, litros: 0, grasa: 3.4},
      %{productor: "P06", tanque: "T2", dia: 3, litros: 410, grasa: 3.0},
      %{productor: "P06", tanque: "T4", dia: 3, litros: 410, grasa: 2.9},
      %{productor: "P07", tanque: "T3", dia: 3, litros: 50, grasa: 4.6},
      %{productor: "P08", tanque: "T4", dia: 3, litros: 135, grasa: 2.4},
      %{productor: "P03", tanque: "T2", dia: 5, litros: -40, grasa: 3.5},
      %{productor: "P02", tanque: "T2", dia: 4, litros: 260, grasa: 3.5},
      %{productor: "P04", tanque: "T3", dia: 4, litros: 410, grasa: 2.8},
      %{productor: "P05", tanque: "T1", dia: 4, litros: 340, grasa: 3.3},
      %{productor: "P05", tanque: "T3", dia: 4, litros: 80, grasa: 2.9},
      %{productor: "P06", tanque: "T3", dia: 2, litros: 900, grasa: 3.2},
      %{productor: "P06", tanque: "T4", dia: 4, litros: 150, grasa: 3.4},
      %{productor: "P06", tanque: "T2", dia: 4, litros: 60, grasa: 2.5},
      %{productor: "P07", tanque: "T4", dia: 4, litros: 500, grasa: 2.6},
      %{productor: "P08", tanque: "T3", dia: 4, litros: 110, grasa: 3.1},
      %{productor: "P04", tanque: "T4", dia: 6, litros: 801, grasa: 3.0},
      %{productor: "P01", tanque: "T1", dia: 5, litros: 150, grasa: 3.7},
      %{productor: "P01", tanque: "T4", dia: 5, litros: 110, grasa: 3.3},
      %{productor: "P02", tanque: "T2", dia: 5, litros: 150, grasa: 3.0},
      %{productor: "P02", tanque: "T1", dia: 5, litros: 165.5, grasa: 3.6},
      %{productor: "P01", tanque: "T2", dia: 3, litros: 150, grasa: -0.5},
      %{productor: "P03", tanque: "T2", dia: 5, litros: 420, grasa: 3.8},
      %{productor: "P03", tanque: "T4", dia: 5, litros: 95.5, grasa: 3.4},
      %{productor: "P03", tanque: "T4", dia: 5, litros: 180, grasa: 4.0},
      %{productor: "P03", tanque: "T3", dia: 5, litros: 135, grasa: 3.7},
      %{productor: "P05", tanque: "T1", dia: 4, litros: 120, grasa: 15.5},
      %{productor: "P04", tanque: "T2", dia: 5, litros: 60, grasa: 2.8},
      %{productor: "P04", tanque: "T2", dia: 5, litros: 120, grasa: 3.3},
      %{productor: "P04", tanque: "T2", dia: 5, litros: 150, grasa: 3.0},
      %{productor: "P04", tanque: "T2", dia: 5, litros: 165.5, grasa: 3.1},
      %{productor: "P08", tanque: "T3", dia: 1, litros: 140, grasa: "3.4"},
      %{productor: "P05", tanque: "T4", dia: 5, litros: 420, grasa: 3.5},
      %{productor: "P06", tanque: "T4", dia: 5, litros: 110, grasa: 3.7},
      %{productor: "P06", tanque: "T4", dia: 5, litros: 135, grasa: 3.3},
      %{productor: "P08", tanque: "T3", dia: 5, litros: 95.5, grasa: 2.6},
      %{productor: "P10", tanque: "T2", dia: 2, litros: 100, grasa: 20},
      %{productor: "P09", tanque: "T3", dia: 5, litros: 160.5, grasa: 3.0},
      %{productor: "P01", tanque: "T1", dia: 6, litros: 95.5, grasa: 3.8},
      %{productor: "P02", tanque: "T2", dia: 6, litros: 95.5, grasa: 3.6},
      %{productor: "P02", tanque: "T1", dia: 6, litros: 220, grasa: 3.7},
      %{productor: "P10", tanque: "T1", dia: 3, litros: 850, grasa: 3.1},
      %{productor: "P02", tanque: "T1", dia: 6, litros: 420, grasa: 2.9},
      %{productor: "P03", tanque: "T1", dia: 6, litros: 110, grasa: 3.5},
      %{productor: "P03", tanque: "T3", dia: 6, litros: 220, grasa: 3.4},
      %{productor: "P03", tanque: "T1", dia: 6, litros: 200, grasa: 3.9},
      %{productor: "P04", tanque: "T2", dia: 6, litros: 420, grasa: 2.6},
      %{productor: "P05", tanque: "T3", dia: 6, litros: 420, grasa: 3.3},
      %{productor: "P06", tanque: "T1", dia: 6, litros: 60, grasa: 3.7},
      %{productor: "P07", tanque: "T1", dia: 6, litros: 80, grasa: 4.3},
      %{productor: "P08", tanque: "T4", dia: 6, litros: 220, grasa: 2.9}
    ]
  end
end
