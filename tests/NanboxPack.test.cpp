// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

#include "doctest.h"

#include <cstdint>

#include "../VM/src/nanbox.h"

using namespace Luau::VM;

static inline void* p48(uint64_t v)
{
    return reinterpret_cast<void*>(static_cast<uintptr_t>(v & 0x0000ffffffffffffull));
}

TEST_SUITE_BEGIN("NaNboxPackUnpack");

TEST_CASE("nil_and_booleans")
{
    uint64_t n = nb_from_nil();
    CHECK(nb_is_nil(n));
    CHECK(nb_is_falsey(n));

    uint64_t f = nb_from_bool(false);
    CHECK(nb_is_bool(f));
    CHECK(nb_is_falsey(f));

    uint64_t t = nb_from_bool(true);
    CHECK(nb_is_bool(t));
    CHECK_FALSE(nb_is_falsey(t));
}

TEST_CASE("lightuserdata_roundtrip")
{
    void* p = p48(0x123456789abull);
    uint64_t v = nb_from_lightud(p);
    CHECK(nb_is_lightud(v));
    CHECK(nb_to_lightud(v) == p);
}

TEST_CASE("gc_types_roundtrip")
{
    void* s = p48(0x1000ull);
    void* h = p48(0x2000ull);
    void* fn= p48(0x3000ull);
    void* ud= p48(0x4000ull);
    void* th= p48(0x5000ull);
    void* bf= p48(0x6000ull);
    void* uv= p48(0x7000ull);
    void* pr= p48(0x8000ull);
    void* vv= p48(0x9000ull);

    uint64_t vs = nb_from_string(s);   CHECK(nb_is_string(vs));   CHECK(nb_to_string(vs)   == s);
    uint64_t vh = nb_from_table(h);    CHECK(nb_is_table(vh));    CHECK(nb_to_table(vh)    == h);
    uint64_t vf = nb_from_function(fn);CHECK(nb_is_function(vf)); CHECK(nb_to_function(vf) == fn);
    uint64_t vu = nb_from_userdata(ud);CHECK(nb_is_userdata(vu)); CHECK(nb_to_userdata(vu) == ud);
    uint64_t vt = nb_from_thread(th);  CHECK(nb_is_thread(vt));   CHECK(nb_to_thread(vt)   == th);
    uint64_t vb = nb_from_buffer(bf);  CHECK(nb_is_buffer(vb));   CHECK(nb_to_buffer(vb)   == bf);
    uint64_t vv0= nb_from_upval(uv);   CHECK(nb_is_upval(vv0));   CHECK(nb_to_upval(vv0)   == uv);
    uint64_t vp = nb_from_proto(pr);   CHECK(nb_is_proto(vp));    CHECK(nb_to_proto(vp)    == pr);
    uint64_t vx = nb_from_vector_ptr(vv); CHECK(nb_is_vector(vx)); CHECK(nb_to_vector_ptr(vx) == vv);
}

TEST_SUITE_END();

