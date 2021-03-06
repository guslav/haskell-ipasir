module SAT.PseudoBoolean.C where
   {-    ( cencoder
    , c_encodeNewGeq
    , c_encodeNewLeq
    , c_getClauses
    , c_addConditional
    , c_clearConditional
    , free_C_Clauses
    , c_clearDB
    , peek
    , Comp(..)
    , CEncoder
    , CVector(toList)
    )
    -} 

import Data.Int (Int64)
import Data.List.Split (splitOn)

import Foreign.Ptr (Ptr, castPtr, nullPtr)
import Foreign.ForeignPtr (ForeignPtr, FinalizerPtr, newForeignPtr, withForeignPtr)
import Foreign.Storable (Storable(..))
import Foreign.C.Types (CSize(..), CInt(..), CLong(..), CBool(..))
import Foreign.Marshal.Array (mallocArray, pokeArray, peekArray)

import SAT.PseudoBoolean.WeightedLit (WeightedLit)
import SAT.PseudoBoolean.Config (Config (..), coerceEnum, justApproximate, approximateMaxValue)

import Debug.Trace

data Comp
    = CLeq
    | CGeq
    | CBoth
    deriving (Show, Eq, Enum, Ord)

cencoder :: Config -> Int -> IO (ForeignPtr CEncoder)
cencoder config firstFreeLit = do
    rawEncoder <- toEncoder config $ coerceEnum firstFreeLit
    newForeignPtr free_C_Encoder rawEncoder

cconstraint :: Ptr CEncoder -> [WeightedLit] -> Comp -> Int -> Int -> IO (Ptr CConstraint)
cconstraint encoder lits comp lowerBound upperBound = do
    ptr <- mallocArray (length lits) :: IO (Ptr WeightedLit)
    pokeArray (castPtr ptr) lits
    let size       = coerceEnum $ length lits
        ccomp      = coerceEnum comp
        clower     = coerceEnum lowerBound
        cupper     = coerceEnum upperBound
    new_c_Constraint encoder ptr size ccomp clower cupper
    

toEncoder :: Config -> CInt -> IO (Ptr CEncoder)
toEncoder = new_C_Encoder <$> (coerceEnum <$> pb_encoder)
                          <*> (coerceEnum <$> amk_encoder)
                          <*> (coerceEnum <$> amo_encoder)
                          <*> (coerceEnum <$> bimander_m_is)
                          <*> (coerceEnum <$> bimander_m)
                          <*> (coerceEnum <$> k_product_minimum_lit_count_for_splitting)
                          <*> (coerceEnum <$> k_product_k)
                          <*> (coerceEnum <$> commander_encoding_k)
                          <*> (coerceEnum <$> max_clauses_per_constant)
                          <*> (coerceEnum <$> use_formula_cache)
                          <*> (coerceEnum <$> print_used_encodings)
                          <*> (coerceEnum <$> checkForDuplicateLiterals)
                          <*> (coerceEnum <$> use_gac_binary_merge)
                          <*> (coerceEnum <$> binary_merge_no_support_for_single_bits)
                          <*> (coerceEnum <$> use_recursive_bdd_test)
                          <*> (coerceEnum <$> use_real_robdds)
                          <*> (coerceEnum <$> use_watch_dog_encoding_in_binary_merger)
                          <*> (coerceEnum <$> justApproximate)
                          <*> (coerceEnum <$> approximateMaxValue)

cgetClauses :: Ptr CEncoder -> IO [[Int]]
cgetClauses encoder = do
    clausesPtr <- newForeignPtr free_C_Clauses =<< c_getClauses encoder
    rawClauses <- withForeignPtr clausesPtr peek
    return $ splitOn [0] $ map fromEnum $ toList rawClauses

newtype CVector a = CVector { toList :: [a] }
instance Show a => Show (CVector a) where
    show (CVector l) = show l

instance Storable a => Storable (CVector a) where
    sizeOf _ = sizeOf (undefined :: Ptr a) + sizeOf (undefined :: CSize)
    alignment = sizeOf
    peek ptr = do
        len <- peek (castPtr ptr)
        arrayPtr <- peekByteOff ptr $ sizeOf (undefined :: CSize)
        if  arrayPtr == nullPtr
            then return $ CVector []
            else CVector <$> peekArray len arrayPtr
    poke ptr (CVector elems) = do
        arrPtr <- mallocArray $ length elems
        pokeArray arrPtr elems
        poke (castPtr ptr) arrPtr

-- | An abstract type for the encoder object.
data CEncoder = CEncoder

-- | An abstract type for the Constraint object.
data CConstraint = CConstrant

foreign import ccall unsafe "pblib_c.h new_C_Encoder" new_C_Encoder
    :: CInt  -- ^ pb_encoder
    -> CInt  -- ^ amk_encoder
    -> CInt  -- ^ amo_encoder
    -> CInt  -- ^ bimander_m_is
    -> CInt  -- ^ bimander_m
    -> CInt  -- ^ k_product_minimum_lit_count_for_splitting
    -> CInt  -- ^ k_product_k
    -> CInt  -- ^ commander_encoding_k
    -> CLong -- ^ MAX_CLAUSES_PER_CONSTRAINT
    -> CBool -- ^ use_formula_cache
    -> CBool -- ^ print_used_encodings
    -> CBool -- ^ check_for_dup_literals
    -> CBool -- ^ use_gac_binary_merge
    -> CBool -- ^ binary_merge_no_support_for_single_bits
    -> CBool -- ^ use_recursive_bdd_test
    -> CBool -- ^ use_real_robdds
    -> CBool -- ^ use_watch_dog_encoding_in_binary_merger
    -> CBool -- ^ just_approximate
    -> CLong -- ^ approximate_max_value
    -> CInt  -- ^ first_free_variable
    -> IO (Ptr CEncoder)

foreign import ccall unsafe "pblib_c.h new_c_Constraint" new_c_Constraint
    :: Ptr CEncoder    -- ^ Encoder which have to add the contraint
    -> Ptr WeightedLit -- ^ Literals
    -> CSize           -- ^ numLiterals 
    -> CInt            -- ^ comparator
    -> CLong           -- ^ lowerBound (will be ignored iff Comparator is CLeq)
    -> CLong           -- ^ upperBound (will be ignored iff Comparator is CGeq)
    -> IO (Ptr CConstraint)

foreign import ccall unsafe "pblib_c.h &free_C_Encoder" 
    free_C_Encoder :: FinalizerPtr CEncoder

foreign import ccall unsafe "pblib_c.h c_encodeNewGeq" 
    c_encodeNewGeq :: Ptr CEncoder -> Ptr CConstraint -> CLong -> IO ()
foreign import ccall unsafe "pblib_c.h c_encodeNewLeq" 
    c_encodeNewLeq :: Ptr CEncoder -> Ptr CConstraint -> CLong -> IO ()

foreign import ccall unsafe "pblib_c.h c_clearDB" 
    c_clearDB :: Ptr CEncoder -> IO ()

foreign import ccall unsafe "pblib_c.h c_addConditional" 
    c_addConditional   :: Ptr CConstraint -> CInt -> IO ()
foreign import ccall unsafe "pblib_c.h c_clearConditional" 
    c_clearConditional :: Ptr CConstraint -> IO ()

foreign import ccall unsafe "pblib_c.h c_getClauses" 
    c_getClauses :: Ptr CEncoder -> IO (Ptr (CVector CInt))
foreign import ccall unsafe "pblib_c.h &free_C_Clauses" 
    free_C_Clauses :: FinalizerPtr (CVector CInt)
