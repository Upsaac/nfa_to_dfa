defmodule NfaToDfa do
  defstruct states: [], alphabet: [], transitions: %{}, start_state: nil, final_states: []

  def nfa_example do
    %NfaToDfa{
      states: [:n0, :n1, :n2, :n3],
      alphabet: ["a", "b"],
      start_state: :n0,
      final_states: [:n3],
      transitions: %{
        {:n0, "a"} => [:n0, :n1],
        {:n0, "b"} => [:n0],
        {:n1, "b"} => [:n2],
        {:n2, "b"} => [:n3],
      }
    }
  end

  def determinize(%NfaToDfa{} = nfa) do
  estado_inicial_dfa = [nfa.start_state] |> Enum.sort()

  resolver([estado_inicial_dfa], MapSet.new([estado_inicial_dfa]), %{}, nfa)
end

defp obtener_destino(conjunto_actual, simbolo, nfa) do
  conjunto_actual
  |> Enum.flat_map(fn estado -> Map.get(nfa.transitions, {estado, simbolo}, []) end)
  |> Enum.uniq()
  |> Enum.sort()
end


defp resolver([], _visitados, transiciones_dfa, _nfa), do: transiciones_dfa

defp resolver([actual | resto], visitados, transiciones_dfa, nfa) do
  # Para el estado 'actual', probamos cada letra del alfabeto
  {nuevas_transiciones_de_este_estado, nuevos_estados_descubiertos} =
    Enum.reduce(nfa.alphabet, {%{}, []}, fn simbolo, {acc_trans, acc_nuevos} ->
      destino = obtener_destino(actual, simbolo, nfa)

      case destino do
        [] -> {acc_trans, acc_nuevos} # No hay a donde ir
        _  ->
          # Guardamos la transición: {[:inicio], "a"} => [:nodo_a, :nodo_b]
          nueva_t = Map.put(acc_trans, {actual, simbolo}, destino)
          {Map.merge(acc_trans, nueva_t), [destino | acc_nuevos]}
      end
    end)

  # Filtramos los estados que ya vimos para no repetir computo
  solo_nuevos = nuevos_estados_descubiertos
                |> Enum.filter(fn e -> !MapSet.member?(visitados, e) end)

  resolver(resto ++ solo_nuevos, MapSet.union(visitados, MapSet.new(solo_nuevos)),
           Map.merge(transiciones_dfa, nuevas_transiciones_de_este_estado), nfa)
end


end
