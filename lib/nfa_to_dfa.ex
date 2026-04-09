defmodule NfaToDfa do
  defstruct states: [], alphabet: [], transitions: %{}, start_state: nil, final_states: []

  def nfa_example do
    %NfaToDfa{
      states: [:inicio, :nodo_a, :nodo_b, :fin],
      alphabet: ["a", "b", "c"],
      start_state: :inicio,
      final_states: [:fin],
      transitions: %{
        {:inicio, "a"} => [:nodo_a, :nodo_b],
        {:inicio, "b"} => [:nodo_b],
        {:nodo_a, "c"} => [:fin]
      }
    }
  end

  def determinize(%NfaToDfa{} = nfa) do
    do_determinize(nfa.start_state,nfa,[[nfa.start_state]],[])
  end

  defp do_determinize([], nfa, dfa_acumulado, [siguiente_estado|estados_pendientes]) do
    #pl primera letra
    do_determinize(siguiente_estado,nfa,dfa_acumulado,estados_pendientes)
  end

  defp do_determinize([current_state|rest], nfa, dfa_acumulado, estados_pendientes, estado_acumulado) do

    add(current_state,nfa,nfa.alphabet,dfa_acumulado,estados_pendientes, estado_acumulado)
    new_estate = construir_estado(current_state, [])
  end

  defp add(curr, nfa, alabeto, dfa_acumulado, estados_pendientes) do
  case alabeto do
    [] ->
      1
    [pl|rest] ->
     unless nfa.transitions[{curr, pl}]  do
      add(curr, nfa, rest, dfa_acumulado, estados_pendientes)
    else
      destinos = nfa.transitions[{curr, pl}]

    end
  end
  end


  def construir_estado(estados_pendientes,dfa_acumulado) do
  case estados_pendientes do
    [] ->
      # Ya no hay nada que añadir, devolvemos el resultado final
      dfa_acumulado

    [actual | resto] ->
      # 1. Calculamos la transformación para el estado 'actual'
      nuevo_dfa = añadir_transiciones_al_dfa(actual, dfa_acumulado)

      # 2. Identificamos nuevos estados descubiertos que no hemos visitado
      nuevos_pendientes = resto ++ descubrir_nuevos_estados(actual)

      # 3. RECURSIÓN: Pasamos el nuevo estado "hacia adelante"
      construir_estado(nuevos_pendientes, nuevo_dfa)
  end
end

end
