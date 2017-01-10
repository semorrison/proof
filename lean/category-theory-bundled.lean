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

--open Category

-- maybe it's weird to have Category bundled and Functor parameterized ... but that's the deal for now.

structure Functor (C₁ : Category) (C₂ : Category) :=
  (onObjects   : C₁^.Obj → C₂^.Obj)
  (onMorphisms : Π ⦃A B : C₁^.Obj⦄,
                C₁^.Hom A B → C₂^.Hom (onObjects A) (onObjects B))
  (identities : Π (A : C₁^.Obj),
    onMorphisms (C₁^.identity A) = C₂^.identity (onObjects A))
  (functoriality : Π ⦃A B C : C₁^.Obj⦄ (f : C₁^.Hom A B) (g : C₁^.Hom B C),
    onMorphisms (C₁^.compose f g) = C₂^.compose (onMorphisms f) (onMorphisms g))

attribute [class] Functor

namespace Functor
  -- Lean complains about the use of local variables in
  -- notation. There must be a way around that.
  infix `<$>`:50 := λ {C₁ : Category} {C₂ : Category}
                      (F : Functor C₁ C₂) {A B : C₁^.Obj} (f : C₁^.Hom A B),
                      onMorphisms F f
end Functor

instance Functor_to_onObjects { C₁ C₂ : Category }: has_coe_to_fun (Functor C₁ C₂) := 
{ F   := λ f, C₁^.Obj -> C₂^.Obj, 
  coe := Functor.onObjects } 

--This doesn't work, because there's no way to provide the A and B.
--instance Functor_to_onMorphisms { C₁ C₂ : Category } { A B : C₁^.Obj }: has_coe_to_fun (Functor C₁ C₂) := 
--{ F   := λ f, C₁^.Hom A B -> C₂^.Hom (f A) (f B), 
--  coe := λ f, @Functor.onMorphisms C₁ C₂ f A B } 

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

--open prod

instance ProductCategory (C : Category) (D : Category) :
  Category :=
  {
    Obj := C^.Obj × D^.Obj,
    Hom := (λ a b : C^.Obj × D^.Obj, C^.Hom (a^.fst) (b^.fst) × D^.Hom (a^.snd) (b^.snd)),
    identity := λ a, (C^.identity (a^.fst), D^.identity (a^.snd)),
    compose  := λ a b c f g, (C^.compose (f^.fst) (g^.fst), D^.compose (f^.snd) (g^.snd)),

    left_identity  := begin
                        intros,
                        pose x := C^.left_identity (f^.fst),
                        pose y := D^.left_identity (f^.snd),
                        induction f,
                        blast
                      end,
    right_identity := begin
                        intros,
                        pose x := C^.right_identity (f^.fst),
                        pose y := D^.right_identity (f^.snd),
                        induction f,
                        blast
                      end,
    associativity  := begin
                        intros,
                        pose x := C^.associativity (f^.fst) (g^.fst) (h^.fst),
                        pose y := D^.associativity (f^.snd) (g^.snd) (h^.snd),
                        induction f,
                        blast
                      end
  }

namespace ProductCategory
  notation C `×` D := ProductCategory C D
end ProductCategory

def ℕTensorProduct : Functor (ℕCategory × ℕCategory) ℕCategory :=
  { onObjects     := prod.fst,
    onMorphisms   := λ A B n, n^.fst + n^.snd,
    identities    := by blast,
    functoriality := by blast
  }



structure PreMonoidalCategory
  -- this is only for internal use: it has a tensor product, but no associator at all
  -- it's not interesting mathematically, but may allow us to introduce usable notation for the tensor product
  extends carrier : Category :=
  (tensor : Functor (carrier × carrier) carrier)
  (tensor_unit : Obj)
  (interchange: Π { A B C D E F: Obj }, Π f : Hom A B, Π g : Hom B C, Π h : Hom D E, Π k : Hom E F, 
    @Functor.onMorphisms _ _ tensor (A, D) (C, F) ((compose f g), (compose h k)) = compose (@Functor.onMorphisms _ _ tensor (A, D) (B, E) (f, h)) (@Functor.onMorphisms _ _ tensor (B, E) (C, F) (g, k)))


namespace PreMonoidalCategory
  infix `⊗`:70 := λ {C : PreMonoidalCategory} (A B : Obj C),
                    tensor C (A, B)
  infix `⊗m`:70 := λ {C : PreMonoidalCategory} {W X Y Z : Obj C}
                     (f : Hom C W X) (g : Hom C Y Z),
                     C^.tensor <$> (f, g)
end PreMonoidalCategory


attribute [class] PreMonoidalCategory
attribute [instance] PreMonoidalCategory.to_Category
instance PreMonoidalCategory_coercion : has_coe PreMonoidalCategory Category := 
  ⟨PreMonoidalCategory.to_Category⟩

open PreMonoidalCategory

structure LaxMonoidalCategory
  extends carrier : PreMonoidalCategory :=

  (associator : Π (A B C : Obj),
     Hom (tensor (tensor (A, B), C)) (tensor (A, tensor (B, C)))) 
     
-- Why can't we use notation here? It seems with slightly cleverer type checking it should work.
-- If we really can't make this work, remove PreMonoidalCategory, as it's useless.

-- TODO actually, express the associator as a natural transformation!
/- I tried writing the pentagon, but it doesn't type check. :-(
  (pentagon : Π (A B C D : Obj),
     -- we need to compare:
     -- ((AB)C)D ---> (A(BC))D ---> A((BC)D) ---> A(B(CD))
     -- ((AB)C)D ---> (AB)(CD) ---> A(B(CD))
     compose
       (compose 
         (tensor <$> (associator A B C, identity D))
         (associator A (tensor (B, C)) D)
       ) (tensor <$> (identity A, associator B C D)) =
     compose
       (associator (tensor (A, B)) C D)
       (associator A B (tensor (C, D)))

  )
-/
/-
-- TODO(far future)
-- One should prove the first substantial result of this theory: that any two ways to reparenthesize are equal.
-- It requires introducing a representation of a reparathesization, but the proof should then be an easy induction.
-- It's a good example of something that is so easy for humans, that is better eventually be easy for the computer too!
-/

-- Notice that LaxMonoidalCategory.tensor has a horrible signature...
-- It sure would be nice if it read ... Functor (carrier × carrier) carrier
-- print LaxMonoidalCategory

attribute [class] LaxMonoidalCategory
attribute [instance] LaxMonoidalCategory.to_PreMonoidalCategory
instance LaxMonoidalCategory_coercion : has_coe LaxMonoidalCategory PreMonoidalCategory := 
  ⟨LaxMonoidalCategory.to_PreMonoidalCategory⟩


def ℕLaxMonoidalCategory : LaxMonoidalCategory :=
  { ℕCategory with
    tensor     := ℕTensorProduct,
    tensor_unit       := (),
    associator := λ A B C, Category.identity ℕCategory (),
    interchange := sorry
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
  extends carrier : PreMonoidalCategory :=
  -- TODO better name? unfortunately it doesn't yet make sense to say 'inverse_associator'.
  (backwards_associator : Π (A B C : Obj),
     Hom (tensor (A, tensor (B, C)))  (tensor (tensor (A, B), C)))

attribute [class] OplaxMonoidalCategory
attribute [instance] OplaxMonoidalCategory.to_PreMonoidalCategory
instance OplaxMonoidalCategory_coercion : has_coe OplaxMonoidalCategory PreMonoidalCategory := 
  ⟨OplaxMonoidalCategory.to_PreMonoidalCategory⟩

structure MonoidalCategory
  extends LaxMonoidalCategory, OplaxMonoidalCategory :=
  (associators_inverses_1: Π (A B C : Obj), compose (associator A B C) (backwards_associator A B C) = identity (tensor (tensor (A, B), C)))
  (associators_inverses_2: Π (A B C : Obj), compose (backwards_associator A B C) (associator A B C) = identity (tensor (A, tensor (B, C))))

attribute [class] MonoidalCategory
attribute [instance] MonoidalCategory.to_LaxMonoidalCategory
instance MonoidalCategory_coercion_to_LaxMonoidalCategory : has_coe MonoidalCategory LaxMonoidalCategory := ⟨MonoidalCategory.to_LaxMonoidalCategory⟩
--instance MonoidalCategory_coercion_to_OplaxMonoidalCategory : has_coe MonoidalCategory OplaxMonoidalCategory := ⟨MonoidalCategory.to_OplaxMonoidalCategory⟩

namespace MonoidalCategory
  infix `⊗`:70 := λ {C : MonoidalCategory} (A B : Obj C),
                    tensor C (A, B)
  infix `⊗`:70 := λ {C : MonoidalCategory} {W X Y Z : Obj C}
                     (f : Hom C W X) (g : Hom C Y Z),
                     C^.tensor <$> (f, g)
end MonoidalCategory

-- and another test
definition identity_functor (C : MonoidalCategory) : Functor C C :=
{
  onObjects := λ a, a,
  onMorphisms := λ a b f, f,
  identities := by blast,
  functoriality := by blast
}

open Functor

lemma test (C: MonoidalCategory) : MonoidalCategory.identity C = Category.identity C :=
  begin
   blast
  end

definition tensor_on_left (C: MonoidalCategory) (X: C^.Obj) : Functor C C := 
  {
    onObjects := λ A, X ⊗ A,
    onMorphisms := --λ A B f, (C^.identity X) ⊗ f,
                   --λ A B f, C^.tensor <$> (C^.identity X, f),
                   --λ A B f, onMorphisms (C^.tensor) (C^.identity X f),
                   λ A B f, @onMorphisms _ _ (C^.tensor) (X, A) (X, B) (C^.identity X, f),
    identities := begin
                    intros,
                    pose H := identities (C^.tensor) (X, A),
                    assert ids : Category.identity C = MonoidalCategory.identity C, blast,
                    rewrite ids,
                    exact H -- blast doesn't work here?!
                  end,
    functoriality := begin
                       intros, -- this will require the interchange axiom for MonoidalCategory, but I don't know how to do it.
                       blast
                     end
  }

definition tensor_on_right (C: MonoidalCategory) (X: C^.Obj) : Functor C C :=
  {
    onObjects := λ A, A ⊗ X,
    onMorphisms := sorry,
    identities := sorry,
    functoriality := sorry
  }

structure NaturalTransformation { C D : Category } ( F G : Functor C D ) :=
  (components: Π A : C^.Obj, D^.Hom (F A) (G A))
  (naturality: Π { A B : C^.Obj }, Π f : C^.Hom A B, D^.compose (F <$> f) (components B) = D^.compose (components A) (G <$> f))

instance NaturalTransformation_to_components { C D : Category } { F G : Functor C D } : has_coe_to_fun (NaturalTransformation F G) := 
{ F   := λ f, Π A : C^.Obj, D^.Hom (F A) (G A), 
  coe := NaturalTransformation.components } 

-- We'll want to be able to prove that two natural transformations are equal if they are componentwise equal.
lemma NaturalTransformations_componentwise_equal
  { C D : Category } 
  { F G : Functor C D } 
  ( α β : NaturalTransformation F G )
  ( w: Π X : C^.Obj, α X = β X ) : α = β :=
  begin
    induction α,
    induction β,
    -- Argh, how to complete this proof?
    blast
  end

definition IdentityNaturalTransformation { C D : Category } (F : Functor C D) : NaturalTransformation F F :=
  {
    components := λ A, D^.identity (F A),
    naturality := begin
                    intros,
                    pose x := F^.identities A,
                    pose y := F^.identities B,
                    pose w := D^.left_identity (F <$> f),
                    pose z := D^.right_identity (F <$> f),
                    blast
                    -- TODO Stephen, can you work out how to complete this proof?
                  end
  }

definition vertical_composition_of_NaturalTransformations { C D : Category } { F G H : Functor C D } ( α : NaturalTransformation F G ) ( β : NaturalTransformation G H ) : NaturalTransformation F H :=
  {
    components := λ A, D^.compose (α A) (β A),
    naturality := sorry
  }

structure Isomorphism ( C: Category ) ( A B : C^.Obj ) :=
  (morphism : C^.Hom A B)
  (inverse : C^.Hom B A)
  (witness_1 : C^.compose morphism inverse = C^.identity A)
  (witness_2 : C^.compose inverse morphism = C^.identity B)

-- For now, this kills Lean, cf https://github.com/leanprover/lean/issues/1290
instance Isomorphism_coercion_to_morphism { C : Category } { A B : C^.Obj } : has_coe (Isomorphism C A B) (C^.Hom A B) :=
  { coe := Isomorphism.morphism }

-- To define a natural isomorphism, we'll define the functor category, and ask for an isomorphism there.
-- It's then a lemma that each component is an isomorphism, and vice versa.

instance FunctorCategory ( C D : Category ) : Category :=
{
  Obj := Functor C D,
  Hom := λ F G, NaturalTransformation F G,

  identity := λ F, IdentityNaturalTransformation F,
  compose := @vertical_composition_of_NaturalTransformations C D,

  left_identity := sorry -- these facts all rely on NaturalTransformations_componentwise_equal above.
  right_identity := sorry,
  associativity := sorry
}

definition NaturalIsomorphism { C D : Category } ( F G : Functor C D ) := Isomorphism (FunctorCategory C D) F G

-- TODO definition tensor_on_right
-- TODO define natural transformations between functors
-- TODO define a natural isomorphism
-- TODO define a braided monoidal category
structure BraidedMonoidalCategory
  extends MonoidalCategory :=
  (braiding: Π A : Obj, NaturalIsomorphism (tensor_on_left A) (tensor_on_right A))
-- on second thoughts, defining the braiding as a natural isomorphism perhaps makes little sennse;
-- easier to just say what it is componentwise, and leave it as a lemma that these components form natural transformations?
-- hmm...!?


-- TODO define a symmetric monoidal category

structure EnrichedCategory :=
  (V: MonoidalCategory) 
  (Obj : Type )
  (Hom : Obj -> Obj -> V^.Obj)
  (compose :  Π ⦃A B C : Obj⦄, V^.Hom ((Hom A B) ⊗ (Hom B C)) (Hom A C))
  -- TODO and so on

-- How do you define a structure which extends another, but has no new fields?

-- TODO How would we define an additive category, now? We don't want to say:
--   Hom : Obj -> Obj -> AdditiveGroup
-- instead we want to express something like:
--   Hom : Obj -> Obj -> [something coercible to AdditiveGroup]
