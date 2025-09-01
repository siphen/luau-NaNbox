// NaN-boxed value representation for Luau VM
#pragma once

#include <stdint.h>
#include <string.h>
#include <assert.h>

// Build-time platform checks: require little-endian
// Most platforms are little-endian; add explicit check for known big-endian platforms
#if defined(__BYTE_ORDER__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#error "NaN-box requires little-endian platform"
#elif defined(__BIG_ENDIAN__) || defined(__ARMEB__) || defined(__THUMBEB__) || defined(__AARCH64EB__) || defined(_MIPSEB) || defined(__MIPSEB) || defined(__MIPSEB__)
#error "NaN-box requires little-endian platform"
#endif

// Pointer width requirements
#if defined(LUAU_NANBOX_32)
static_assert(sizeof(void*) == 4, "LUAU_NANBOX_32 requires 32-bit pointers");
#else
static_assert(sizeof(void*) == 8, "NaN-box requires 64-bit pointers (define LUAU_NANBOX_32 for 32-bit)");
#endif
static_assert(sizeof(double) == 8, "NaN-box requires 64-bit double");

namespace Luau { namespace VM {
    using u64 = uint64_t;

    // Bit layout: numbers are any IEEE-754 double EXCEPT tagged quiet-NaNs with nonzero 4-bit tag in bits 50..47.
    static constexpr u64 EXP_MASK      = 0x7ff0000000000000ull;
    static constexpr u64 FRAC_MASK     = 0x000fffffffffffffull;
    static constexpr u64 SIGN_MASK     = 0x8000000000000000ull;
    static constexpr u64 QNAN_BIT      = 0x0008000000000000ull; // quiet NaN bit (MSB of fraction)
    static constexpr u64 QNAN_MASK     = EXP_MASK | QNAN_BIT;   // 0x7ff8_0000_0000_0000
    // Tag is stored in bits 50..47 (four bits) separate from the quiet-NaN bit (bit 51).
    // Tag==0 denotes a canonical numeric NaN; nonzero tag indicates a boxed value.
    static constexpr u64 TAG_SHIFT     = 47;
    static constexpr u64 TAG_MASK      = 0x0007800000000000ull; // bits 50..47
    static constexpr u64 PAYLOAD_MASK  = 0x00007fffffffffffull; // 47-bit payload (LSBs)

    // Compile-time layout sanity (orthogonality)
    static_assert((QNAN_MASK & TAG_MASK) == 0, "NaNbox: tag overlaps qNaN bit");
    static_assert((TAG_MASK & PAYLOAD_MASK) == 0, "NaNbox: tag overlaps payload");
    static_assert((QNAN_MASK & PAYLOAD_MASK) == 0, "NaNbox: qNaN overlaps payload");

    // Distinct tags for all Luau runtime types stored as boxed values
    enum NB_Tag : u64 {
        NB_TNIL      = 0x1ull,
        NB_TFALSE    = 0x2ull,
        NB_TTRUE     = 0x3ull,
        NB_TLIGHTUD  = 0x4ull,
        NB_TVECTOR   = 0x5ull,
        NB_TSTRING   = 0x6ull,
        NB_TTABLE    = 0x7ull,
        NB_TFUNCTION = 0x8ull,
        NB_TUSERDATA = 0x9ull,
        NB_TTHREAD   = 0xaull,
        NB_TBUFFER   = 0xbull,
        NB_TUPVAL    = 0xcull,
        NB_TPROTO    = 0xDull,
    };

    inline u64 nb_tagbits(NB_Tag t) { return ((u64(t) << TAG_SHIFT) & TAG_MASK); }

    // Helpers to classify number vs boxed
    inline bool nb_is_boxed(u64 r) {
        if ((r & EXP_MASK) != EXP_MASK || !(r & QNAN_BIT)) return false;
        u64 tag = (r & TAG_MASK) >> TAG_SHIFT;
        return tag != 0; // nonzero tag => boxed
    }
    inline bool nb_isnumber(u64 r) {
        return !nb_is_boxed(r);
    }

    // Canonicalize numeric doubles: -0 -> +0; NaN -> canonical quiet NaN (still a number, tag==0)
    inline double nb_canon_double(double d) {
        u64 r; memcpy(&r, &d, sizeof(r));
        // -0 -> +0
        if ((r & ~SIGN_MASK) == 0 && (r & SIGN_MASK)) {
            r = 0;
            double out; memcpy(&out, &r, sizeof(out)); return out;
        }
        // numeric NaN -> canonical quiet NaN (tagbits=0)
        if ((r & EXP_MASK) == EXP_MASK && (r & FRAC_MASK) != 0) {
            u64 cn = QNAN_MASK; double out; memcpy(&out, &cn, sizeof(out)); return out;
        }
        return d;
    }

    inline u64 nb_from_number_canon(double d) {
        double cd = nb_canon_double(d);
        u64 r; memcpy(&r, &cd, sizeof(r));
        return r;
    }
    inline double nb_to_number(u64 v) {
        // Caller ensures it's a number
        double d; memcpy(&d, &v, sizeof(d)); return d;
    }

    // Boxed constructors
    inline u64 nb_from_nil() { return QNAN_MASK | nb_tagbits(NB_TNIL); }
    inline u64 nb_from_bool(bool b) { return QNAN_MASK | nb_tagbits(b ? NB_TTRUE : NB_TFALSE); }

    inline u64 nb_from_lightud(void* p) {
        u64 v = (u64)(uintptr_t)p;
        assert((v & ~PAYLOAD_MASK) == 0 && "lightuserdata pointer exceeds 48-bit payload");
        return QNAN_MASK | nb_tagbits(NB_TLIGHTUD) | (v & PAYLOAD_MASK);
    }

    // GC object categories: store raw pointer in payload; distinct tags per GC subtype
    struct GCObject; // fwd decl only

    inline u64 nb_from_string(const void* p)   { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TSTRING)   | v; }
    inline u64 nb_from_table(const void* p)    { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TTABLE)    | v; }
    inline u64 nb_from_function(const void* p) { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TFUNCTION) | v; }
    inline u64 nb_from_userdata(const void* p) { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TUSERDATA) | v; }
    inline u64 nb_from_thread(const void* p)   { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TTHREAD)   | v; }
    inline u64 nb_from_buffer(const void* p)   { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TBUFFER)   | v; }
    inline u64 nb_from_upval(const void* p)    { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TUPVAL)    | v; }
    inline u64 nb_from_proto(const void* p)    { u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TPROTO)    | v; }
    inline u64 nb_from_vector_ptr(const void* p){u64 v=(u64)(uintptr_t)p; assert((v & ~PAYLOAD_MASK)==0); return QNAN_MASK | nb_tagbits(NB_TVECTOR)   | v; }

    // Accessors
    inline NB_Tag nb_tag(u64 v) {
        u64 t = (v & TAG_MASK) >> TAG_SHIFT; // 0..15
#if defined(_DEBUG) || !defined(NDEBUG)
        if ((v & EXP_MASK) == EXP_MASK && (v & QNAN_BIT)) {
            // If caller treats as boxed, tag must be non-zero
            // (nb_is_boxed should be used to check that; this is a defensive check.)
        }
#endif
        return NB_Tag(t);
    }
    inline u64 nb_payload(u64 v) { return (v & PAYLOAD_MASK); }

    // Type predicates
    inline bool nb_is_nil(u64 v)      { return nb_is_boxed(v) && nb_tag(v) == NB_TNIL; }
    inline bool nb_is_bool(u64 v)     { return nb_is_boxed(v) && (nb_tag(v) == NB_TTRUE || nb_tag(v) == NB_TFALSE); }
    inline bool nb_is_true(u64 v)     { return nb_is_boxed(v) && nb_tag(v) == NB_TTRUE; }
    inline bool nb_is_false(u64 v)    { return nb_is_boxed(v) && nb_tag(v) == NB_TFALSE; }
    inline bool nb_is_lightud(u64 v)  { return nb_is_boxed(v) && nb_tag(v) == NB_TLIGHTUD; }
    inline bool nb_is_string(u64 v)   { return nb_is_boxed(v) && nb_tag(v) == NB_TSTRING; }
    inline bool nb_is_table(u64 v)    { return nb_is_boxed(v) && nb_tag(v) == NB_TTABLE; }
    inline bool nb_is_function(u64 v) { return nb_is_boxed(v) && nb_tag(v) == NB_TFUNCTION; }
    inline bool nb_is_userdata(u64 v) { return nb_is_boxed(v) && nb_tag(v) == NB_TUSERDATA; }
    inline bool nb_is_thread(u64 v)   { return nb_is_boxed(v) && nb_tag(v) == NB_TTHREAD; }
    inline bool nb_is_buffer(u64 v)   { return nb_is_boxed(v) && nb_tag(v) == NB_TBUFFER; }
    inline bool nb_is_upval(u64 v)    { return nb_is_boxed(v) && nb_tag(v) == NB_TUPVAL; }
    inline bool nb_is_proto(u64 v)    { return nb_is_boxed(v) && nb_tag(v) == NB_TPROTO; }
    inline bool nb_is_vector(u64 v)   { return nb_is_boxed(v) && nb_tag(v) == NB_TVECTOR; }
    inline bool nb_is_falsey(u64 v)   { return nb_is_nil(v) || nb_is_false(v); }

    // Decoders
    inline void* nb_to_lightud(u64 v)   { assert(nb_is_lightud(v)); return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_string(u64 v)    { assert(nb_is_string(v));  return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_table(u64 v)     { assert(nb_is_table(v));   return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_function(u64 v)  { assert(nb_is_function(v));return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_userdata(u64 v)  { assert(nb_is_userdata(v));return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_thread(u64 v)    { assert(nb_is_thread(v));  return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_buffer(u64 v)    { assert(nb_is_buffer(v));  return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_upval(u64 v)     { assert(nb_is_upval(v));   return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_proto(u64 v)     { assert(nb_is_proto(v));   return (void*)(uintptr_t)nb_payload(v); }
    inline void* nb_to_vector_ptr(u64 v){ assert(nb_is_vector(v));  return (void*)(uintptr_t)nb_payload(v); }

}} // namespace Luau::VM
