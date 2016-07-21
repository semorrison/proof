Require Import CpdtTactics.
Set Implicit Arguments.

Structure Semigroup := {
  element: Type;
  multiplication: element -> element -> element;
  associativity(x y z: element): multiplication (multiplication x y) z = multiplication x (multiplication y z);  
}.

Structure SemigroupMorphism(source target: Semigroup) := {
  map :> element source -> element target;
  intertwinesMultiplication(x y: element source): map (multiplication source x y) = multiplication target (map x) (map y);
}.

Program Definition SemigroupIdentity(G: Semigroup): SemigroupMorphism G G := {|
  map := fun x => x;
|}.

Program Definition SemigroupMorphismComposition { X Y Z: Semigroup } ( f: SemigroupMorphism X Y ) ( g: SemigroupMorphism Y Z ): SemigroupMorphism X Z := {|
  map := fun x => g(f x)
|}.
Next Obligation.
  pose (intertwinesMultiplication f).
  pose (intertwinesMultiplication g).
  crush.
Defined.




Structure Monoid := {
  underlyingSemigroup :> Semigroup;
  identity: element underlyingSemigroup;
  leftIdentity(x: element underlyingSemigroup): x = multiplication underlyingSemigroup identity x;
  rightIdentity(x: element underlyingSemigroup): x = multiplication underlyingSemigroup x identity;
}.

Structure MonoidMorphism(source target: Monoid) := {
  underlyingSemigroupMorphism :> SemigroupMorphism source target;
  takesIdentityToIdentity: underlyingSemigroupMorphism (identity source) = (identity target);
}.

Structure Group := {
  underlyingMonoid :> Monoid;
  inverse: element underlyingMonoid -> element underlyingMonoid;
  leftInverseIdentity(x: element underlyingMonoid): multiplication underlyingMonoid (inverse x) x = identity underlyingMonoid;
  rightInverseIdentity(x: element underlyingMonoid): multiplication underlyingMonoid x (inverse x) = identity underlyingMonoid;
}.

Structure GroupMorphism(source target: Group) := {
  underlyingMonoidMorphism :> MonoidMorphism source target;
}.

Require Import ZArith.
Open Scope Z_scope.

Require Import CpdtTactics.
Obligation Tactic := crush.

Program Definition IntegersAsSemigroup: Semigroup := {|
  element := Z;
  multiplication := fun a b => a + b;
  associativity := _;
|}.

Program Definition IntegersAsMonoid: Monoid := {|
  underlyingSemigroup := IntegersAsSemigroup;
  identity := 0;
  leftIdentity := _;
  rightIdentity := _;
|}.

Program Definition IntegersAsGroup: Group := {|
  underlyingMonoid := IntegersAsMonoid;
  inverse := fun x => -x;
  leftInverseIdentity := _;
  rightInverseIdentity := _;
|}.
