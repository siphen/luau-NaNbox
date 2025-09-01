#include "doctest.h"

#include <cmath>
#include <cstdint>
#include <limits>
#if __has_include("VM/src/lobject.h")
#  include "VM/src/lobject.h"
#elif __has_include("../VM/src/lobject.h")
#  include "../VM/src/lobject.h"
#elif __has_include("../../VM/src/lobject.h")
#  include "../../VM/src/lobject.h"
#else
#  include "lobject.h"
#endif

#ifdef LUAU_NANBOX
static bool isNegZero(double d) {
    return d == 0.0 && std::signbit(d);
}

TEST_SUITE_BEGIN("NaNboxBasic");

TEST_CASE("nanbox_value_tests") {
    TValue tv;

    // -0 canonicalizes to +0
    setnvalue(&tv, -0.0);
    {
        double d = nvalue(&tv);
        CHECK(!isNegZero(d));
        CHECK(d == 0.0);
        (void)d;
    }

    // NaN canonicalization: still a number and is NaN
    {
        double nan = std::numeric_limits<double>::quiet_NaN();
        setnvalue(&tv, nan);
        double d = nvalue(&tv);
        CHECK(std::isnan(d));
    }

    // Infinities preserved as numbers
    {
        double inf = std::numeric_limits<double>::infinity();
        setnvalue(&tv, inf);
        CHECK(std::isinf(nvalue(&tv)));
    }

    // Booleans
    setbvalue(&tv, 0);
    CHECK(ttisboolean(&tv));
    CHECK(!bvalue(&tv));
    setbvalue(&tv, 1);
    CHECK(ttisboolean(&tv));
    CHECK(bvalue(&tv));

    // Nil
    setnilvalue(&tv);
    CHECK(ttisnil(&tv));

    // Lightuserdata payload masking
    {
        void* p = (void*)0x1234abcd5678ull;
        setpvalue(&tv, p, 0);
        CHECK(ttislightuserdata(&tv));
        CHECK(pvalue(&tv) == p);
    }
}

TEST_SUITE_END();

#endif
