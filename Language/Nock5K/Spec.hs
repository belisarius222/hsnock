module Language.Nock5K.Spec where

-- * Structures
{-| #spec-l3#
  A noun is an atom or a cell.  An atom is any natural number.
  A cell is an ordered pair of nouns.
-}
data Noun = Atom !Integer | !Noun :- !Noun deriving (Eq)

-- | Monad representing either a computed result or an error message.
type Nock = Either String

-- * Reductions
nock, wut, lus, tis, fas, tar :: Noun -> Nock Noun

{-| #spec-l8#

@
  nock(a)           *a
@-}
nock = tar

{- spec-l9
  [a b c]           [a [b c]]
-}
infixr 1 :-

{-| #spec-l11#

@
  ?[a b]            0
  ?a                1
@-}
wut (a :- b)  = return $ Atom 0
wut a         = return $ Atom 1

{-| #spec-l13#

@
  +[a b]            +[a b]
  +a                1 + a
@-}
lus (a :- b)  = Left "+[a b]"
lus (Atom a)  = return $ Atom (1 + a)

{-| #spec-l15#

@
  =[a a]            0
  =[a b]            1
  =a                =a
@-}
tis (a :- a') | a == a'  = return $ Atom 0
tis (a :- b)             = return $ Atom 1
tis a                    = Left "=a"

{-| #spec-l19#

@
  \/[1 a]            a
  \/[2 a b]          a
  \/[3 a b]          b
  \/[(a + a) b]      \/[2 \/[a b]]
  \/[(a + a + 1) b]  \/[3 \/[a b]]
  \/a                \/a
@-}
fas (Atom 1 :- a)          = return a
fas (Atom 2 :- a :- b)     = return a
fas (Atom 3 :- a :- b)     = return b
fas (Atom a :- b) | a > 3  = do  x <- fas $ Atom (a `div` 2) :- b
                                 fas $ Atom (2 + (a `mod` 2)) :- x
fas a                      = Left "/a"

{-| #spec-l26#

@
  \*[a [b c] d]      [\*[a b c] \*[a d]]

\  \*[a 0 b]          \/[b a]
  \*[a 1 b]          b
  \*[a 2 b c]        \*[\*[a b] \*[a c]]
  \*[a 3 b]          ?\*[a b]
  \*[a 4 b]          +\*[a b]
  \*[a 5 b]          =\*[a b]

\  \*[a 6 b c d]      \*[a 2 [0 1] 2 [1 c d] [1 0] 2 [1 2 3] [1 0] 4 4 b]
  \*[a 7 b c]        \*[a 2 b 1 c]
  \*[a 8 b c]        \*[a 7 [[7 [0 1] b] 0 1] c]
  \*[a 9 b c]        \*[a 7 c 2 [0 1] 0 b]
  \*[a 10 [b c] d]   \*[a 8 c 7 [0 3] d]
  \*[a 10 b c]       \*[a c]

\  \*a                \*a
@-}
tar (a :- (b :- c) :- d)             = do x <- tar (a :- b :- c)
                                          y <- tar (a :- d)
                                          return $ x :- y

tar (a :- Atom 0 :- b)               = fas $ b :- a
tar (a :- Atom 1 :- b)               = return b
tar (a :- Atom 2 :- b :- c)          = do  x <- tar (a :- b)
                                           y <- tar (a :- c)
                                           tar $ x :- y
tar (a :- Atom 3 :- b)               = tar (a :- b) >>= wut
tar (a :- Atom 4 :- b)               = tar (a :- b) >>= lus
tar (a :- Atom 5 :- b)               = tar (a :- b) >>= tis

tar (a :- Atom 6 :- b :- c :- d)     = do suba <- tar (a :- c) 
                                          subb <- tar (a :- d)
                                          cond  <- tar (a :- Atom 4 :- Atom 4 :- b)
                                          tar $ (suba :- subb) :- Atom 0 :- cond

tar (a :- Atom 7 :- b :- c)          = do sub <- tar (a :- b)
                                          tar $ sub :- c

tar (a :- Atom 8 :- b :- c)          = do pin <- tar (a :- b)
                                          tar $ (pin :- a) :- c

tar (a :- Atom 9 :- b :- c)          = do core <- tar (a :- c)
                                          tar $ core :- Atom 0 :- b

tar (a :- Atom 10 :- (b :- c) :- d)  = tar (a :- Atom 8 :- c :- Atom 7 :-
                                            (Atom 0 :- Atom 3) :- d)
tar (a :- Atom 10 :- b :- c)         = tar (a :- c)

tar a                                = Left "*a"
