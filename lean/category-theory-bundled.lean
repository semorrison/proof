import standard

meta def blast : tactic unit :=
using_smt $ return ()

structure Category :=
  (Obj : Type)
  (Hom : Obj -> Obj -> Type)
  (identity : Π A : Obj, Hom A A)
  (compose  : Π ⦃A B C : Obj⦄, Hom A B → Hom B C → Hom A C)

  (left_identity  : Π ⦃A B : Obj⦄ (f : Hom A B), compose (identity _) f = f)
  (right_identity : Π ⦃A B : Obj⦄ (f : Hom A B), compose f (identity _) = f)
  (associativity  : Π ⦃A B C D : Obj⦄ (f : Hom A B) (g : Hom B C) (h : Hom C D),
    compose (compose f g) h = compose f (compose g h))

attribute [class] Category
-- declaring it as a class from the beginning results in an insane
-- signature ... This really seems like it must be a bug, or at least
-- a rough edge.
-- print Category

instance ℕCategory : Category :=
  { 
    Obj := unit,    
    Hom := λ a b, ℕ,
    identity := λ a, 0,
    compose  := λ a b c, add,

    left_identity  := λ a b, zero_add,
      -- Sadly, "by blast" doesn't work here. I think this is because
      -- "by blast" checks if the heads of the expressions match,
      -- which is the case for right_identity and associativity, but
      -- not left_identity.
    right_identity := by blast, --λ a b, add_zero,
    associativity  := by blast  --λ a b c d, add_assoc
  }

open Category

-- maybe it's weird to have Category bundled and Functor parameterized ... but that's the deal for now.

structure Functor (C₁ : Category) (C₂ : Category) :=
  (onObjects   : Obj C₁ → Obj C₂)
  (onMorphisms : Π ⦃A B : Obj C₁⦄,
                Hom C₁ A B → Hom C₂ (onObjects A) (onObjects B))
  (identities : Π (A : Obj C₁),
    onMorphisms (identity C₁ A) = identity C₂ (onObjects A))
  (functoriality : Π ⦃A B C : Obj C₁⦄ (f : Hom C₁ A B) (g : Hom C₁ B C),
    onMorphisms (compose C₁ f g) = compose C₂ (onMorphisms f) (onMorphisms g))

attribute [class] Functor

-- (Scott:) I wish it were possible to define coercions of Functor to either
-- onObjects or onMorphisms, so we could just write F A and F f.
-- (Scott:) I'm not sure what purpose these notations serve: is 'F <$> A' that 
-- much better than 'onObjects F A' that it warrants introducing notation?
namespace Functor
  -- Lean complains about the use of local variables in
  -- notation. There must be a way around that.
  infix `<$>`:50 := λ {C₁ : Category} {C₂ : Category}
                      (F : Functor C₁ C₂) (A : Obj C₁),
                      onObjects F A
  infix `<$>m`:50 := λ {C₁ : Category} {C₂ : Category}
                      (F : Functor C₁ C₂) {A B : Obj C₁} (f : Hom C₁ A B),
                      onMorphisms F f
end Functor

--print Functor

instance DoublingAsFunctor : Functor ℕCategory ℕCategory :=
  { onObjects   := id,
    onMorphisms := (λ A B n, n + n),
      -- Sadly, "by blast" doesn't work below if we replace "n + n"
      -- with "2 * n".  Again, I think this is because the heads don't
      -- match. If you use "n * 2", then identities works by blast,
      -- but functoriality still doesn't.
    identities    := by blast,
    functoriality := by blast
  }

open prod

-- TODO(?) Can these proofs be simplified?
-- Stephen's earlier versions (for Lean 2?) were perhaps better.
instance ProductCategory (C : Category) (D : Category) :
  Category :=
  {
    Obj := Obj C × Obj D,
    Hom := (λ a b : Obj C × Obj D, Hom C (fst a) (fst b) × Hom D (snd a) (snd b)),
    identity := λ a, (identity C (fst a), identity D (snd a)),
    compose  := λ a b c f g, (compose C (fst f) (fst g), compose D (snd f) (snd g)),

    left_identity  := begin
                        intros,
                        pose x := left_identity C (fst f),
                        pose y := left_identity D (snd f),
                        induction f,
                        blast
                      end,
    right_identity := begin
                        intros,
                        pose x := right_identity C (fst f),
                        pose y := right_identity D (snd f),
                        induction f,
                        blast
                      end,
    associativity  := begin
                        intros,
                        pose x := associativity C (fst f) (fst g) (fst h),
                        pose y := associativity D (snd f) (snd g) (snd h),
                        induction f,
                        blast
                      end
  }

namespace ProductCategory
  notation C `×c` D := ProductCategory C D
end ProductCategory

def ℕTensorProduct : Functor (ℕCategory ×c ℕCategory) ℕCategory :=
  { onObjects     := fst,
    onMorphisms   := λ A B n, fst n + snd n,
    identities    := by blast,
    functoriality := by blast
  }

structure LaxMonoidalCategory
  extends carrier : Category :=
  (tensor : Functor (carrier ×c carrier) carrier)
  (tensor_unit : Obj)

  (associator : Π (A B C : Obj),
     Hom (tensor <$> (tensor <$> (A, B), C)) (tensor <$> (A, tensor <$> (B, C))))
-- TODO actually, express the associator as a natural transformation!
/- I tried writing the pentagon, but it doesn't type check. :-(
  (pentagon : Π (A B C D : Obj),
     -- we need to compare:
     -- ((AB)C)D ---> (A(BC))D ---> A((BC)D) ---> A(B(CD))
     -- ((AB)C)D ---> (AB)(CD) ---> A(B(CD))
     compose
       (compose 
         (tensor <$>m (associator A B C, identity D))
         (associator A (tensor <$> (B, C)) D)
       ) (tensor <$>m (identity A, associator B C D)) =
     compose
       (associator (tensor <$> (A, B)) C D)
       (associator A B (tensor <$> (C, D)))

  )
-/
/-
-- TODO(far future)
-- One should prove the first substantial result of this theory: that any two ways to reparenthesize are equal.
-- It requires introducing a representation of a reparathesization, but the proof should then be an easy induction.
-- It's a good example of something that is so easy for humans, that is better eventually be easy for the computer too!
-/

-- Notice that LaxMonoidalCategory.tensor has a horrible signature...
-- It sure would be nice if it read ... Functor (carrier ×c carrier) carrier
-- print LaxMonoidalCategory

attribute [class] LaxMonoidalCategory
attribute [instance] LaxMonoidalCategory.to_Category
instance LaxMonoidalCategory_coercion : has_coe LaxMonoidalCategory Category := 
  ⟨LaxMonoidalCategory.to_Category⟩

namespace LaxMonoidalCategory
  infix `⊗`:70 := λ {C : LaxMonoidalCategory} (A B : Obj C),
                    tensor C <$> (A, B)
  infix `⊗m`:70 := λ {C : LaxMonoidalCategory} {W X Y Z : Obj C} -- could we just write ⊗ here, overloading the notation?
                     (f : Hom C W X) (g : Hom C Y Z),
                     tensor C <$>m (f, g)
end LaxMonoidalCategory

open LaxMonoidalCategory

def ℕLaxMonoidalCategory : LaxMonoidalCategory :=
  { ℕCategory with
    tensor     := ℕTensorProduct,
    tensor_unit       := (),
    associator := λ A B C, Category.identity ℕCategory ()
  }

/-
instance DoublingAsFunctor' : Functor ℕLaxMonoidalCategory ℕLaxMonoidalCategory :=
  { onObjects   := id,
    onMorphisms := λ A B n, n + n, -- no idea what is going wrong here
    identities    := by blast,
    functoriality := by blast
  }
-/

structure OplaxMonoidalCategory
  extends carrier : Category :=
  (tensor : Functor (carrier ×c carrier) carrier)
  (tensor_unit : Obj)

  -- TODO better name? unfortunately it doesn't yet make sense to say 'inverse_associator'.
  (backwards_associator : Π (A B C : Obj),
     Hom (tensor <$> (A, tensor <$> (B, C)))  (tensor <$> (tensor <$> (A, B), C)))

attribute [class] OplaxMonoidalCategory
attribute [instance] OplaxMonoidalCategory.to_Category
instance OplaxMonoidalCategory_coercion : has_coe OplaxMonoidalCategory Category := 
  ⟨OplaxMonoidalCategory.to_Category⟩

structure MonoidalCategory
  extends LaxMonoidalCategory, OplaxMonoidalCategory :=
  (associators_inverses_1: Π (A B C : Obj), compose (associator A B C) (backwards_associator A B C) = identity (tensor <$> (tensor <$> (A, B), C)))
  (associators_inverses_2: Π (A B C : Obj), compose (backwards_associator A B C) (associator A B C) = identity (tensor <$> (A, tensor <$> (B, C))))

attribute [class] MonoidalCategory
attribute [instance] MonoidalCategory.to_LaxMonoidalCategory
instance MonoidalCategory_coercion_to_LaxMonoidalCategory : has_coe MonoidalCategory LaxMonoidalCategory := ⟨MonoidalCategory.to_LaxMonoidalCategory⟩
--instance MonoidalCategory_coercion_to_OplaxMonoidalCategory : has_coe MonoidalCategory OplaxMonoidalCategory := ⟨MonoidalCategory.to_OplaxMonoidalCategory⟩

-- just testing the coercion is working now
definition foo (C : MonoidalCategory) : Category := C

-- and another test
definition identity_functor (C : MonoidalCategory) : Functor C C :=
{
  onObjects := λ a, a,
  onMorphisms := λ a b f, f,
  identities := by blast,
  functoriality := by blast
}

open Functor

/- okay, this seems to be a serious difficulty -/
definition tensor_on_left (C: MonoidalCategory) (X: Category.Obj C) : Functor C C := 
  {
    onObjects := λ a, onObjects (tensor C) (X, a),
    onMorphisms := λ a b f, onMorphisms (tensor C) (MonoidalCategory.identity C X, f),
    identities := --begin
                  --  intros,
                  --  pose H := identities (@tensor Obj Hom C) (X, A),
                  --  -- sadly, that's not enough
                  --  sorry
                  --end,
                  by sorry,
    functoriality := by sorry
  }

-- TODO definition tensor_on_right
-- TODO define natural transformations between functors
-- TODO define a natural isomorphism
-- TODO define a braided monoidal category
structure BraidedMonoidalCategory
  extends MonoidalCategory :=
  (braiding: Π A : Obj, NaturalIsomorphism (tensor_on_left this A) (tensor_on_right this A))

-- TODO define a symmetric monoidal category

structure EnrichedCategory :=
  (V: MonoidalCategory) 
  (Obj : Type )
  (Hom : Obj -> Obj -> MonoidalCategory.Obj V)
  (compose :  Π ⦃A B C : Obj⦄, MonoidalCategory.Hom V ((tensor V) <$> ((Hom A B), (Hom B C))) (Hom A C))
  -- TODO and so on

-- How do you define a structure which extends another, but has no new fields?

-- TODO How would we define an additive category, now? We don't want to say:
--   Hom : Obj -> Obj -> AdditiveGroup
-- instead we want to express something like:
--   Hom : Obj -> Obj -> [something coercible to AdditiveGroup]