// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "Luau/Repl.h"
#include "Luau/Flags.h"
#include <cstdio>
#include <fstream>

#if defined(__GNUC__)
__attribute__((constructor)) static void diag_ctor() {
    fprintf(stderr, "[diag] process ctor before main\n");
}
#endif

int main(int argc, char** argv)
{
    std::ofstream f("diag_repl.txt", std::ios::app); f << "main entry argc=" << argc << "\n"; f.flush();
    setLuauFlagsDefault();
    f << "flags set\n"; f.flush();

    return replMain(argc, argv);
}
