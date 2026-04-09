defmodule NfaToDfa do
  defstruct states: [], alphabet: [], transitions: %{}, start_state: nil, final_states: []

  def nfa_example do
    %NfaToDfa{
      states: [:inicio, :nodo_a, :nodo_b, :fin],
      alphabet: ["a", "b", "c"],
      start_state: :inicio,
      final_states: [:fin],

      transitions: %{
        {:inicio, "a"} => [:nodo_a],
        {:inicio, "b"} => [:nodo_b],
        {:nodo_a, "c"} => [:fin]
      }
    }
  end

  def determinize() do

  end
  def map(), do: 1+2

end
