defmodule NfaToDfaE do
  defstruct states: [], alphabet: [], transitions: %{}, start_state: nil, final_states: []

  def nfa_example_con_epsilon do
    %NfaToDfaE{
      states: [:n0, :n1, :n2, :n3],
      alphabet: ["a", "b"],
      start_state: :n0,
      final_states: [:n3],
      transitions: %{
        # Ejemplo: desde n0 con epsilon vas a n1
        {:n0, :epsilon} => [:n1],
        {:n0, "a"} => [:n0],
        {:n1, "b"} => [:n2],
        {:n2, :epsilon} => [:n3]
      }
    }
  end

  # --- FUNCIÓN E-CLOSURE ---
  def e_closure(%NfaToDfaE{} = nfa, states) when is_list(states) do
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
  def determinize(%NfaToDfaE{} = nfa) do
    estado_inicial_dfa = e_closure(nfa, [nfa.start_state])
    resolver([estado_inicial_dfa], MapSet.new([estado_inicial_dfa]), %{}, nfa)
  end

  defp obtener_destino(conjunto_actual, simbolo, nfa) do
    conjunto_actual
    |> Enum.flat_map(fn estado -> Map.get(nfa.transitions, {estado, simbolo}, []) end)
    |> Enum.uniq()

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
