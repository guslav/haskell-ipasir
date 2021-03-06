#ifndef PBLIB_C_H
#define PBLIB_C_H

#include <cstdint>
#include <vector>
#include "incpbconstraint.h"
#include "weightedlit.h"
#include "auxvarmanager.h"
#include "pb2cnf.h"

#ifdef __cplusplus
extern "C" {
#endif

struct C_Encoder {
    std::vector<IncPBConstraint*>* constraint;
    VectorClauseDatabase* clauseDb;
    AuxVarManager* auxManager;
    PB2CNF* encoder;
};

/*
struct C_Clause {
    size_t size;
    int32_t* literals;
};
*/

struct C_Cnf {
    size_t size;
    int32_t* dimacs;
};

PBLib::WeightedLit* new_WeightedLit(int32_t lit, int64_t weight);

C_Encoder* new_C_Encoder(
    PB_ENCODER::PB2CNF_PB_Encoder pb_encoder,
    AMK_ENCODER::PB2CNF_AMK_Encoder amk_encoder,
    AMO_ENCODER::PB2CNF_AMO_Encoder amo_encoder,
    BIMANDER_M_IS::BIMANDER_M_IS bimander_m_is,
    int bimander_m,
    int k_product_minimum_lit_count_for_splitting,
    int k_product_k,
    int commander_encoding_k,
    int64_t MAX_CLAUSES_PER_CONSTRAINT,
    bool use_formula_cache,
    bool print_used_encodings,
    bool check_for_dup_literals,
    bool use_gac_binary_merge,
    bool binary_merge_no_support_for_single_bits,
    bool use_recursive_bdd_test,
    bool use_real_robdds,
    bool use_watch_dog_encoding_in_binary_merger,
    bool just_approximate,
    int64_t approximate_max_value,
    int32_t first_free_variable
    );

void free_C_Encoder(C_Encoder* ptr);
void free_C_Clauses(C_Cnf* cnf);

const IncPBConstraint* new_c_Constraint( C_Encoder* e, PBLib::WeightedLit** literals, 
                                         size_t numLiterals, PBLib::Comparator comp, 
                                         int64_t lowerBound, int64_t upperBound);

void c_encodeNewGeq(C_Encoder* e, IncPBConstraint* constraint, int64_t newGeq);
void c_encodeNewLeq(C_Encoder* e, IncPBConstraint* constraint, int64_t newLeq);

const C_Cnf* c_getClauses(C_Encoder* db);

void c_clearDB(C_Encoder* e);

void c_addConditional(IncPBConstraint* e, int32_t cond);
void c_clearConditional(IncPBConstraint* e);

#ifdef __cplusplus
}
#endif

#endif