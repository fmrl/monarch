(*--build-config
   options:--admit_fsi Seq;
   other-files:seq.fsi seqext.fsi
--*)

// $legal:614:
//
// Copyright 2015 Michael Lowell Roberts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ,$

module Tesseract.Specs.SeqExt
   open Seq

   val __map__loop:
      // mapping function
      ('a -> Tot 'b)
      // input sequence
      -> s: seq 'a
      // accumulator; in this case, the output sequence.
      -> c: seq 'b{length c <= length s}
      -> Tot (seq 'b)
         (decreases (length s - length c))
   let rec __map__loop f s c =
      let i = length c in
      if i < length s then
         let a = index s i in
         let c' = append c (create 1 (f a)) in
         __map__loop f s c'
      else
         c

   val __lemma_map__loop__length:
      f: ('a -> Tot 'b)
      -> s: seq 'a
      -> c: seq 'b{length c <= length s}
      -> Lemma
         (requires (True))
         (ensures (length (__map__loop f s c) = length s))
         (decreases (length s - length c))
   let rec __lemma_map__loop__length f s c =
      let i = length c in
      if i < length s then
         let a = index s i in
         let c' = append c (create 1 (f a)) in
         __lemma_map__loop__length f s c'
      else
         ()

   val __lemma_map__loop__map:
      f: ('a -> Tot 'b)
      -> s: seq 'a
      -> c: seq 'b{length c <= length s}
      -> Lemma
         (requires ((forall i. 0 <= i && i < length c ==> index c i = f (index s i))))
         (ensures
            (forall i.
               0 <= i
               && i < length (__map__loop f s c)
               ==>
                  (i < length s
                  && index (__map__loop f s c) i = f (index s i))))
         (decreases (length s - length c))
   let rec __lemma_map__loop__map f s c =
      let i = length c in
      if i < length s then
         let a = index s i in
         let c' = append c (create 1 (f a)) in
         __lemma_map__loop__map f s c'
      else
         ()

   let map f s =
      __map__loop f s createEmpty
   let lemma_map__length f s =
      __lemma_map__loop__length f s createEmpty
   let lemma_map__map f s i =
      __lemma_map__loop__map f s createEmpty

   val __mem__loop:
      s: seq 'a
      -> 'a
      -> i: nat{i <= length s}
      -> c: nat{c <= length s}
      -> Tot (c': nat{c' <= length s})
         (decreases (length s - i))
   let rec __mem__loop s a i c =
      if i < length s then
         let c' =
            if c = length s && (a = index s i) then
               i
            else
               c in
         __mem__loop s a (i + 1) c'
      else
         c

   val __lemma_mem__index__loop:
      s: seq 'a
      -> i: nat{i < length s}
      -> j: nat{j <= length s}
      -> c: nat{c <= length s}
      -> Lemma
         (requires (j > i ==> c < length s))
         (ensures ((__mem__loop s (index s i) j c) < length s))
         (decreases (length s - j))
   let rec __lemma_mem__index__loop s i j c =
      if j < length s then
         let c' =
            if c = length s && (index s j = index s i) then
               j
            else
               c in
         __lemma_mem__index__loop s i (j + 1) c'
      else
         ()

   let mem s a =
      __mem__loop s a 0 (length s) < length s
   let lemma_mem__mem s a =
      ()
   let lemma_mem__index s i =
      __lemma_mem__index__loop s i 0 (length s)

   val lemma_mem__append:
      s0: seq 'a
      -> s1: seq 'a
      -> a: 'a
      -> Lemma
         (requires (True))
         (ensures ((mem s0 a \/ mem s1 a) <==> mem (append s0 s1) a))
         [SMTPat (mem (append s0 s1) a)]
   let lemma_mem__append s0 s1 a =
      admit ()

   val __filter__loop:
      // predicate; if false, then the element is discarded from the sequence.
      ('a -> Tot bool)
      // input sequence
      -> s: seq 'a{length s > 0}
      // index of element being reduced
      -> i: nat{i < length s}
      // accumulator; in this case, the output sequence.
      -> c: seq 'a
      -> Tot (seq 'a)
         (decreases (length s - i))
   let rec __filter__loop p s i c =
      let z = length s - 1 in
      let a = index s i in
      let c' =
         if p a then
            append c (create 1 a)
         else
            c in
      if i = z then
         c'
      else
         __filter__loop p s (i + 1) c'

   let filter p s =
      if length s = 0 then
         createEmpty
      else
         __filter__loop p s 0 createEmpty

   val __lemma_filter__loop__length:
      p: ('a -> Tot bool) ->
      s: seq 'a{length s > 0} ->
      i: nat{i < length s} ->
      c: seq 'a ->
      Lemma
         (requires (length c <= i))
         (ensures (length (__filter__loop p s i c) <= length s))
         (decreases (length s - i))
   let rec __lemma_filter__loop__length p s i c =
      let z = length s - 1 in
      let a = index s i in
      let c' =
         if p a then
            append c (create 1 a)
         else
            c in
      if i = z then
         ()
      else
         __lemma_filter__loop__length p s (i + 1) c'

   let lemma_filter__length p s =
      if length s = 0 then
         ()
      else
         __lemma_filter__loop__length p s 0 createEmpty

   val __lemma_filter__loop__admission:
      p: ('a -> Tot bool)
      -> s: seq 'a{length s > 0}
      -> i: nat{i < length s}
      -> c: seq 'a
      -> k: nat
      -> Lemma
         (requires (forall j. 0 <= j && j < length c ==> p (index c j)))
         (ensures
            (k < length (__filter__loop p s i c)
            ==> p (index (__filter__loop p s i c) k)))
         (decreases (length s - i))
   let rec __lemma_filter__loop__admission p s i c k =
      let z = length s - 1 in
      let a = index s i in
      let c' =
         if p a then
            append c (create 1 a)
         else
            c in
      if i = z then
         ()
      else
         __lemma_filter__loop__admission p s (i + 1) c' k

   let lemma_filter__admission p s k =
      if length s = 0 then
         ()
      else
         __lemma_filter__loop__admission p s 0 createEmpty k

   val __lemma_filter__loop__mem:
      p: ('a -> Tot bool)
      -> s: seq 'a{length s > 0}
      -> i: nat{i < length s}
      -> c: seq 'a
      -> Lemma
         (requires
            (forall j.
               (0 <= j && j < length c) ==> (mem s (index c j))))
         (ensures
            (forall j.
               (0 <= j && j < length (__filter__loop p s i c)) ==> (mem s (index (__filter__loop p s i c) j))))
         (decreases (length s - i))
   let rec __lemma_filter__loop__mem p s i c =
      let z = length s - 1 in
      let a = index s i in
      //lemma_mem__mem s a;
      let c' =
         if p a then
            append c (create 1 a)
         else
            c in
      if i = z then
         ()
      else
         admit ()//__lemma_filter__loop__mem p s (i + 1) c'

   (*val lemma_filter__mem:
      p: ('a -> Tot bool) ->
      s: seq 'a ->
      Lemma
         (requires (True))
         (ensures
            (forall i.
               0 <= i && i < length (filter p s)
               ==> mem s (index (filter p s) i)))
   let lemma_filter__mem p s =
      if length s = 0 then
         ()
      else
         __lemma_filter__loop__mem p s 0 createEmpty *)

   let insert s i a =
      let l = slice s 0 i in
      let c = create 1 a in
      let r = slice s i (length s) in
      append (append l c) r

   let lemma_insert__length s i a = ()
   let lemma_insert__contents s i a = ()

   let remove s i a =
      let l = slice s 0 i in
      let r = slice s (i + 1) (length s) in
      append l r

   let lemma_remove__length s i a = ()
   let lemma_remove__contents s i a = ()
