//
// $Id: BoxLib.cpp,v 1.24 2001-07-26 20:08:44 lijewski Exp $
//
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <new>

#include <BoxLib.H>
#include <BLVERSION.H>
#include <FArrayBox.H>
#include <ParallelDescriptor.H>
#include <ParmParse.H>
#include <Profiler.H>
#include <Utility.H>

#define bl_str(s)  # s
#define bl_xstr(s) bl_str(s)
//
// The definition of our version string.
//    
// Takes the form:  boxlib version 2.0 built Jun 25 1996 at 14:52:36
//
const char * const version =

"boxlib version "
bl_xstr(BL_VERSION_MAJOR)
"."
bl_xstr(BL_VERSION_MINOR)
" built "
__DATE__
" at "
__TIME__;

#undef bl_str
#undef bl_xstr

//
// This is used by BoxLib::Error(), BoxLib::Abort(), and BoxLib::Assert()
// to ensure that when writing the message to stderr, that no additional
// heap-based memory is allocated.
//

static
void
write_to_stderr_without_buffering (const char* str)
{
    //
    // Flush all buffers.
    //
    fflush(NULL);

    if (str)
    {
        //
        // Add some `!'s and a newline to the string.
        //
        const char * const end = " !!!\n";
        fwrite(str, strlen(str), 1, stderr);
        fwrite(end, strlen(end), 1, stderr);
    }
}

void
BL_this_is_a_dummy_routine_to_force_version_into_executable ()
{
    write_to_stderr_without_buffering(version);    
}

static
void
write_lib_id(const char* msg)
{
    fflush(0);
    const char* const boxlib = "BoxLib::";
    fwrite(boxlib, strlen(boxlib), 1, stderr);
    if ( msg ) 
    {
	fwrite(msg, strlen(msg), 1, stderr);
	fwrite("::", 2, 1, stderr);
    }
}

void
BoxLib::Error (const char* msg)
{
    write_lib_id("Error");
    write_to_stderr_without_buffering(msg);
    ParallelDescriptor::Abort();
}

void
BoxLib::Abort (const char* msg)
{
    write_lib_id("Abort");
    write_to_stderr_without_buffering(msg);
    ParallelDescriptor::Abort();
}

void
BoxLib::Warning (const char* msg)
{
    if (msg)
    {
        std::cerr << msg << '!' << '\n';
    }
}

void
BoxLib::Assert (const char* EX,
                const char* file,
                int         line)
{
    const int DIMENSION = 1024;

    char buf[DIMENSION+1];

    sprintf(buf,
            "Assertion `%s' failed, file \"%s\", line %d",
            EX,
            file,
            line);
    //
    // Just to be a little safer :-)
    //
    buf[DIMENSION] = 0;

    write_to_stderr_without_buffering(buf);

    ParallelDescriptor::Abort();
}

void
BoxLib::OutOfMemory (const char* file,
                     int         line)
{
    BoxLib::Assert("operator new", file, line);
}

namespace
{
    Profiler* bl_prf;

    void PrintUsage (int, char *argv[])
    {
        std::cerr << "usage:\n";
        std::cerr << argv[0] << " infile [options] \n\tOptions:\n";
        std::cerr << "\t     [<root>.]<var>  = <val_list>\n";
        std::cerr << "\tor  -[<root>.]<var>\n";
        std::cerr << "\t where:\n";
        std::cerr << "\t    <root>     =  class name of variable\n";
        std::cerr << "\t    <var>      =  variable name\n";
        std::cerr << "\t    <val_list> =  list of values\n";

        BoxLib::Error();
    }

}

void
BoxLib::Initialize(int& argc, char**& argv)
{
    static Profiler::Tag bl_prf_tag("BoxLib");

#ifndef WIN32
    //
    // Make sure to catch new failures.
    //
    std::set_new_handler(BoxLib::OutOfMemory);
#endif

    bl_prf = new Profiler(bl_prf_tag, true);
    bl_prf->start();

    ParallelDescriptor::StartParallel(&argc, &argv);
    
    if (argc < 2)
        PrintUsage(argc,argv);

    if (argv[1][0] == '-')
    {
        std::cerr << "input file must be first argument\n";
        PrintUsage(argc, argv);
    }

    ParmParse::Initialize(argc-2,argv+2,argv[1]); 

    Profiler::Initialize(argc, argv);
    //
    // Initialize random seed after we're running in parallel.
    //
    BoxLib::InitRandom(ParallelDescriptor::MyProc() + 1);

    FArrayBox::Initialize();

    std::cout << std::setprecision(10);
}

void
BoxLib::Finalize()
{
    bl_prf->stop();
    FArrayBox::Finalize();
    Profiler::Finalize();
    ParmParse::Finalize();
    ParallelDescriptor::EndParallel();
}
