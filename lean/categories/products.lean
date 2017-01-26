-- Copyright (c) 2017 Scott Morrison. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Authors: Stephen Morgan, Scott Morrison
import .category
import .functor
import .natural_transformation

-- set_option pp.universes true

open tqft.categories
open tqft.categories.functor

namespace tqft.categories.products

@[reducible] definition ProductCategory (C : Category) (D : Category) :
  Category :=
  {
    Obj      := C^.Obj × D^.Obj,
    Hom      := (λ X Y : C^.Obj × D^.Obj, C^.Hom (X^.fst) (Y^.fst) × D^.Hom (X^.snd) (Y^.snd)),
    identity := λ X, (C^.identity (X^.fst), D^.identity (X^.snd)),
    compose  := λ _ _ _ f g, (C^.compose (f^.fst) (g^.fst), D^.compose (f^.snd) (g^.snd)),

    left_identity  := begin
                        intros,
                        rewrite [ C^.left_identity, D^.left_identity ],
                        induction f,
                        simp
                      end,
    right_identity := begin
                        intros,
                        rewrite [ C^.right_identity, D^.right_identity],
                        induction f,
                        simp
                      end,
    associativity  := begin
                        intros,
                        rewrite [ C^.associativity, D^.associativity ]
                      end
  }

namespace ProductCategory
  notation C `×` D := ProductCategory C D
end ProductCategory

definition ProductFunctor { A B C D : Category } ( F : Functor A B ) ( G : Functor C D ) : Functor (A × C) (B × D) :=
{
  onObjects := λ X, (F X^.fst, G X^.snd),
  onMorphisms := λ _ _ f, (F^.onMorphisms f^.fst, G^.onMorphisms f^.snd),
  identities := begin
                  intros X,
                  simp
                end,
  functoriality := begin
                     intros X Y Z f g,
                     simp
                   end
}

namespace ProductFunctor
  notation F `×` G := ProductFunctor F G
end ProductFunctor

@[reducible] definition SwitchProductCategory ( C D : Category ) : Functor (C × D) (D × C) :=
{
  onObjects     := λ X, (X^.snd, X^.fst),
  onMorphisms   := λ _ _ f, (f^.snd, f^.fst),
  identities    := begin -- seems a shame that blast can't do intros itself
                     intros, blast
                   end,
  functoriality := begin
                     intros, blast
                   end
}

lemma switch_twice_is_the_identity ( C D : Category ) : FunctorComposition ( SwitchProductCategory C D ) ( SwitchProductCategory D C ) = IdentityFunctor (C × D) :=
begin
  apply Functors_pointwise_equal,
  exact sorry,
  exact sorry
end

definition { u v } ProductCategoryAssociator ( C D E : Category.{ u v } ) : Functor ((C × D) × E) (C × (D × E)) :=
{
  onObjects     := λ X, (X^.fst^.fst, (X^.fst^.snd, X^.snd)),
  onMorphisms   := λ _ _ f, (f^.fst^.fst, (f^.fst^.snd, f^.snd)),
  identities    := begin
                     intros, blast 
                   end,
  functoriality := begin
                     intros, blast
                   end
}

end tqft.categories.products

