open nat

def even : ℕ → Prop
| 0        := true
| (succ n) := ¬ (even n)

lemma even_6 : even 6 :=
begin
  unfold even,
  simp
end

def infinitely_many_even_integers : ∀ n : ℕ, ∃ m ≥ n, even m :=
begin
intro n,
by_cases (even n), -- This doesn't work: we need to show that `even` is decidable.
admit
end

instance parity_decidable : decidable_pred even :=
begin
unfold decidable_pred,
intro n,
induction n,
{
    unfold even,
    exact decidable.true -- I found this by grepping for "decidable" in lean/library/, finding lots in init/logic.lean, and noticing the instance called `decidable.true` there
},
{
  cases ih_1,
  {
    unfold even,
    exact decidable.is_true a_1
  },
  {
    unfold even,
    refine decidable.is_false _,
    cc -- This is a horrible hack, because I ran out of time working out the name of (p → ¬¬p).
  }
}
end

def infinitely_many_even_integers_2 : ∀ n : ℕ, ∃ m ≥ n, even m :=
begin
intro n,
by_cases (even n),
{
  existsi n,
  admit -- how do we obtain proof that n ≥ n?
},
{
  existsi (n+1),
  admit
}
end