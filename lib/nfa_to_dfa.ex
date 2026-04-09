defmodule NfaToDfa do
  def nfa_example do
  transiciones = [
    {:inicio, "a", :nodo_a},
    {:inicio, "b", :nodo_b},
    {:nodo_a, "c", :fin}
  ]
  end

  def map(), do: 1+2

end
