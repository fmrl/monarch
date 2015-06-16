// $legal:322:
// 
// This work is licensed under the Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International
// License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-nc-sa/4.0/
// or send a letter to:
// 
// Creative Commons
// PO Box 1866
// Mountain View, CA 94042
// USA
// 
// ,$

//@requires "seq.fst"
//@requires "set.fst"

module Tesseract.Specs.Tesseract

   type step_g (region_t: Type) (state_t: Type) (step_kind_t: Type)
      = region_t 
         -> state_t
         -> step_kind_t 
         -> Tot (state_t * (Seq.seq_g (region_t * step_kind_t)))

   type effect_g (region_t: Type) (state_t: Type) (step_kind_t: Type) 
      =
      | Spawn: 
         region: region_t 
         -> state0: state_t
         -> step: step_g region_t state_t step_kind_t
         -> effect_g region_t state_t step_kind_t
      | Step: 
         region: region_t 
         -> step_kind: step_kind_t 
         -> effect_g region_t state_t step_kind_t

   type _tesseract_g 
      (region_t: Type) 
      (state_t: Type) 
      (step_kind_t: Type) 
      = Seq.seq_g (effect_g region_t state_t step_kind_t)

   val _domain: 
      #region_t: Type 
      -> #state_t: Type 
      -> #step_kind_t: Type 
      -> _tesseract_g region_t state_t step_kind_t
      -> Tot (option (Set.set_g region_t))
   let _domain
      (region_t: Type)
      (state_t: Type)
      (step_kind_t: Type)
      _tess
      = let on_fold 
         = (fun accum ffct
            -> match accum with
                  | None ->
                     // an unsafe tesseract continues to be unsafe.
                     None
                  | Some set ->
                     // examine the next effect in the sequence.
                     (match ffct with
                        | Spawn region _ _ ->
                           // if we're looking at a spawn effect associated with a region, that region must not have already set.
                           if Set.is_mem set region then
                              None
                           // otherwise, note that we have encountered it.
                           else
                              Some (Set.add set region)
                        | Step region _ ->
                           // a step effect associated with a given region must be in our set of set regions.
                           if Set.is_mem set region then
                              accum
                           else
                              None))
         in (Seq.foldl on_fold (Some Set.empty) _tess)

   val _is_tesseract_safe: 
      #region_t: Type 
      -> #state_t: Type 
      -> #step_kind_t: Type 
      -> _tesseract_g region_t state_t step_kind_t 
      -> Tot bool
   let _is_tesseract_safe 
      (region_t: Type)
      (state_t: Type)
      (step_kind_t: Type)
      (_tess: _tesseract_g region_t state_t step_kind_t)
      = is_Some (_domain _tess)

   type tesseract_g 
      (region_t: Type) 
      (state_t: Type) 
      (step_kind_t: Type) 
      = _tess: 
         _tesseract_g 
            region_t 
            state_t 
            step_kind_t{_is_tesseract_safe _tess}

   val init:
      #region_t: Type 
      -> #state_t: Type 
      -> #step_kind_t: Type 
      -> Tot (tesseract_g region_t state_t step_kind_t)
   let init 
      (region_t: Type) 
      (state_t: Type) 
      (step_kind_t: Type) 
      = Seq.empty

   val domain: 
      #region_t: Type 
      -> #state_t: Type 
      -> #step_kind_t: Type 
      -> tesseract_g region_t state_t step_kind_t
      -> Tot (Set.set_g region_t)
   let domain
      (region_t: Type)
      (state_t: Type)
      (step_kind_t: Type)
      tess
      = match _domain tess with
         | Some d ->
            d

   val is_mem:
      #region_t: Type
      -> #state_t: Type
      -> #step_kind_t: Type
      -> tesseract_g region_t state_t step_kind_t
      -> region_t
      -> Tot bool
   let is_mem 
      (region_t: Type) 
      (step_kind_t: Type) 
      tess 
      region
      = Set.is_mem (domain tess) region

   val lookup:
      #region_t: Type
      -> #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g region_t state_t step_kind_t
      -> region: region_t{is_mem tess region}
      -> Tot (Seq.seq_g (effect_g region_t state_t step_kind_t))
   let lookup
      (region_t: Type) 
      (state_t: Type) 
      (step_kind_t: Type) 
      tess 
      region
      = Seq.filter
            (fun event ->
               match event with
                  | Spawn r _ _ ->
                     r = region
                  | Step r _ ->
                     r = region)
            tess

   val spawn:
      #region_t: Type
      -> #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g region_t state_t step_kind_t
      -> region: region_t{not (is_mem tess region)}
      -> state_t
      -> step_g region_t state_t step_kind_t
      -> Tot (tesseract_g region_t state_t step_kind_t)
   let spawn
      (region_t: Type) 
      (state_t: Type) 
      (step_kind_t: Type) 
      tess 
      region
      state0
      step
      = Seq.append tess (Spawn region state0 step)

// $vim-fst:32: vim:set sts=3 sw=3 et ft=fstar:,$
