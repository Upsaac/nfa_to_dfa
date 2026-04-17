defmodule NfaToDfaEPrune do
  defstruct states: [], alphabet: [], transitions: %{}, start_state: nil, final_states: []

  def nfa_example_con_epsilon do
    %NfaToDfaEPrune{
      states: [:n0, :n1, :n2, :n3, :n4],
      alphabet: ["a", "b"],
      start_state: :n0,
      final_states: [:n3],
      transitions: %{
        # Ejemplo: desde n0 con epsilon vas a n1
        {:n0, :epsilon} => [:n1],
        {:n0, "a"} => [:n0],
        {:n0, "b"}=>[:n4],
        {:n1, "b"} => [:n2],
        {:n2, :epsilon} => [:n3]
      }
    }
  end

  def nfa_example_con_epsilon_2 do
    %NfaToDfaEPrune{
      states: [:n0, :n1, :n2, :n3, :n4, :n5, :n6, :n7, :n8, :n9, :n10],
      alphabet: ["a", "b"],
      start_state: :n0,
      final_states: [:n10],
      transitions: %{

        {:n0, :epsilon} => [:n1, :n7],
        {:n1, :epsilon} => [:n2,:n3],
        {:n2, "a"} => [:n4],
        {:n3, "b"} => [:n5],
        {:n4, :epsilon} => [:n6],
        {:n5, :epsilon} => [:n6],
        {:n6, :epsilon} => [:n1,:n7],
        {:n7, "a"} => [:n8],
        {:n8, "b"} => [:n9],
        {:n9, "b"} => [:n10]
      }
    }
  end
  # Codigo que implementación de prune
  def e_determinize(%NfaToDfaEPrune{} = nfa) do
    nfa
    |> prune()       # Aplicamos prune antes determinize para quitar estados muertos y caminos sin salida
    |> determinize()
  end

  def prune(%NfaToDfaEPrune{} = nfa)  do
    #qué estados realmente pueden llegar al final
    estados_vivos = buscar_vivos(nfa.final_states, MapSet.new(nfa.final_states), nfa)

    #prune la lista de estados del NFA
    estados_limpios = Enum.filter(nfa.states, fn s -> MapSet.member?(estados_vivos, s) end)

    # prune las transiciones
    transiciones_limpias =
      nfa.transitions
      |> Enum.map(fn {{origen, simbolo}, destinos} ->
        # eliminamos de las listas de destino aquellos que no llevan a ningun lado
        destinos_vivos = Enum.filter(destinos, fn d -> MapSet.member?(estados_vivos, d) end)
        {{origen, simbolo}, destinos_vivos}
      end)
      # filtramos transiciones enteras si el origen está vacio o si se quedó sin destinos
      |> Enum.filter(fn {{origen, _simbolo}, destinos} ->
        MapSet.member?(estados_vivos, origen) and destinos != []
      end)
      |> Enum.into(%{})

    # Retornamos la estructura actualizada
    %NfaToDfaEPrune{nfa | states: estados_limpios, transitions: transiciones_limpias}

  end

  defp buscar_vivos([], visitados, _nfa), do: visitados
  defp buscar_vivos([actual | resto], visitados, nfa) do
    # Identificamos qué estados tienen al estado 'actual' en su lista de destinos
    predecesores =
    nfa.transitions
      |> Enum.filter(fn {_origen_y_simbolo, destinos} -> actual in destinos end)
      |> Enum.map(fn {{origen, _simbolo}, _destinos} -> origen end)
      |> Enum.reject(fn origen -> MapSet.member?(visitados, origen) end)
      |> Enum.uniq()

    nuevos_visitados = MapSet.union(visitados, MapSet.new(predecesores))
    buscar_vivos(predecesores ++ resto, nuevos_visitados, nfa)
  end



  # --- FUNCIÓN E-CLOSURE ---
  def e_closure(%NfaToDfaEPrune{} = nfa, states) when is_list(states) do
    do_e_closure(states, MapSet.new(states), nfa)
  end

  defp do_e_closure([], reachables, _nfa) do
    reachables |> MapSet.to_list() |> Enum.sort()
  end

  defp do_e_closure([current | rest], reachables, nfa) do
    epsilons = Map.get(nfa.transitions, {current, :epsilon}, [])
    nuevos = Enum.filter(epsilons, fn s -> !MapSet.member?(reachables, s) end)
    nuevo_reachables = MapSet.union(reachables, MapSet.new(nuevos))
    do_e_closure(rest ++ nuevos, nuevo_reachables, nfa)
  end

  # --- DETERMINIZE ACTUALIZADO ---
  def determinize(%NfaToDfaEPrune{} = nfa) do
    estado_inicial_dfa = e_closure(nfa, [nfa.start_state])
    resolver([estado_inicial_dfa], MapSet.new([estado_inicial_dfa]), %{}, nfa)
  end

  defp obtener_destino(conjunto_actual, simbolo, nfa) do
    conjunto_actual
    |> Enum.flat_map(fn estado -> Map.get(nfa.transitions, {estado, simbolo}, []) end)
    |> Enum.uniq()
    |> (&e_closure(nfa, &1)).()
  end

  defp resolver([], _visitados, transiciones_dfa, _nfa), do: transiciones_dfa

  defp resolver([actual | resto], visitados, transiciones_dfa, nfa) do
    {nuevas_trans_estado, nuevos_estados} =
      Enum.reduce(nfa.alphabet, {%{}, []}, fn simbolo, {acc_t, acc_e} ->
        destino = obtener_destino(actual, simbolo, nfa)

        case destino do
          [] -> {acc_t, acc_e}
          _  ->
            {Map.put(acc_t, {actual, simbolo}, destino), [destino | acc_e]}
        end
      end)

    solo_nuevos = nuevos_estados
                  |> Enum.reject(fn e -> MapSet.member?(visitados, e) end)
                  |> Enum.uniq()

    resolver(resto ++ solo_nuevos,
             MapSet.union(visitados, MapSet.new(solo_nuevos)),
             Map.merge(transiciones_dfa, nuevas_trans_estado),
             nfa)
  end
end
