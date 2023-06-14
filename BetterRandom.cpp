#include <Windows.h>
#include <detours.h>
#include <random>
#include <psapi.h>
#include <winnt.h>
#include <dbghelp.h>

// Original function pointer
typedef int(WINAPI *OriginalRandFunc)();

// Pointer to the original rand() function
OriginalRandFunc pOriginalRand = NULL;

std::random_device rd;                             // Non-deterministic random number generator
std::uniform_int_distribution<> dist(0, RAND_MAX); // Distribute results between 0 and RAND_MAX
std::mt19937 gen(rd());                            // Seed Mersenne Twister generator

// Typedef for the original function
typedef int (*OriginalFunc)(int);

// Pointer to the original function
OriginalFunc pOriginalFunction = nullptr;

// Hooked function for rand()
__declspec(dllexport) int WINAPI HookedRand()
{
    // Call the custom implementation instead of the original function
    return dist(gen);
}

/**
 * Match a pattern against data.
 * @param data     The data to match against.
 * @param pattern  The pattern to match.
 * @param length   The length of the pattern.
 * @return         True if the pattern matches the data, false otherwise.
 */
bool MatchPattern(const unsigned char *data, const unsigned char *pattern, int length)
{
    for (int i = 0; i < length; ++i)
    {
        // Skip certain characters in the pattern
        if (pattern[i] == '.')
            continue;

        // If the characters don't match, return false
        if (data[i] != pattern[i])
            return false;
    }

    return true;
}

/**
 * Find the offset of a function within a module using a pattern.
 * @param hModule  Handle to the module to search within.
 * @param pattern  The pattern to search for.
 * @param length   The length of the pattern.
 * @return         The offset of the function if found, or 0x0 if not found.
 */
LPBYTE FindFunctionOffset(HMODULE hModule, const unsigned char *pattern, int length)
{
    // Get the base address of the module
    auto moduleBase = reinterpret_cast<DWORD_PTR>(hModule);

    // Get the module's PE header
    auto ntHeader = ImageNtHeader(hModule);
    if (!ntHeader)
        return 0x0; // Invalid PE header

    // Get the image section header
    auto sectionHeader = IMAGE_FIRST_SECTION(ntHeader);
    if (!sectionHeader)
        return 0x0; // Invalid section header

    // Search within the module's code section
    IMAGE_SECTION_HEADER *codeSectionHeader = nullptr;
    for (int i = 0; i < ntHeader->FileHeader.NumberOfSections; ++i)
    {
        if (sectionHeader->Characteristics & IMAGE_SCN_MEM_EXECUTE)
        {
            codeSectionHeader = sectionHeader;
            break;
        }
        sectionHeader++;
    }

    if (!codeSectionHeader)
        return 0x0; // Code section not found

    // Search for the pattern within the code section
    auto codeSectionMemory = reinterpret_cast<const unsigned char *>(moduleBase + codeSectionHeader->VirtualAddress);
    auto endAddress = codeSectionMemory + codeSectionHeader->Misc.VirtualSize - 2;

    for (; codeSectionMemory < endAddress; codeSectionMemory++)
    {
        if (MatchPattern(codeSectionMemory, pattern, length))
            return (LPBYTE)codeSectionMemory;
    }

    // Pattern not found
    return 0x0;
}

/**
 * Initialize the hook by finding the target function and attaching the custom implementation.
 */
void InitHook()
{
    // Get the address of the target function
    auto hModule = GetModuleHandle(nullptr);

    LPBYTE pFunctionAddress = 0x0;

    // Find the offset of the target function using specific patterns

    // Pattern for Baldur's Gate EE, Baldur's Gate 2 EE, Icewind Dale EE
    unsigned char pattern1[] = "\x48\x83..\xE8.......\xFD\x43\x03\x00";
    if (pFunctionAddress == 0x0)
        pFunctionAddress = FindFunctionOffset(hModule, pattern1, sizeof(pattern1) - 1);

    // Pattern for Planescape EE
    unsigned char pattern2[] = "\xE8.......\xFD\x43\x03\x00";
    if (pFunctionAddress == 0x0)
        pFunctionAddress = FindFunctionOffset(hModule, pattern2, sizeof(pattern2) - 1);

    // Pattern for Baldur's Gate, Baldur's Gate 2, Icewind Dale, Planescape Torment
    unsigned char pattern3[] = "\xE8....\x8B....\xFD\x43\x03\x00";
    if (pFunctionAddress == 0x0)
        pFunctionAddress = FindFunctionOffset(hModule, pattern3, sizeof(pattern3) - 1);

    if (pFunctionAddress == 0x0)
    {
        MessageBoxA(NULL, "original rand() method not found!", "betterrand.dll Error", MB_OK);
        throw("Error: original rand() method not found!");
    }

    // Obtain system information
    SYSTEM_INFO systemInfo;
    GetSystemInfo(&systemInfo);

    // Retrieve the base address of the application
    auto baseAddress = systemInfo.lpMinimumApplicationAddress;

    // Calculate the scan size by subtracting the minimum application address from the maximum application address
    auto scanSize = reinterpret_cast<SIZE_T>(systemInfo.lpMaximumApplicationAddress) - reinterpret_cast<SIZE_T>(systemInfo.lpMinimumApplicationAddress);

    // Get module info
    MODULEINFO modinfo = {NULL};
    GetModuleInformation(GetCurrentProcess(), hModule, &modinfo, sizeof(modinfo));

    // Create a trampoline for the original function
    auto pOriginalFunction = reinterpret_cast<OriginalRandFunc>(pFunctionAddress);

    // Detour the function with the custom implementation
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());
    DetourAttach(&(PVOID &)pOriginalFunction, HookedRand);
    DetourTransactionCommit();
}

/**
 * Remove the hook by detaching the custom implementation from the target function.
 */
void RemoveHook()
{
    // Detach the hook
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());
    DetourDetach(&(PVOID &)pOriginalRand, HookedRand);
    DetourTransactionCommit();
}

/**
 * Entry point of the DLL.
 * @param hinst     The handle to the DLL module.
 * @param dwReason  The reason for calling the DLL entry point.
 * @param reserved  Reserved parameter.
 * @return          True if the DLL was initialized successfully, false otherwise.
 */
BOOL WINAPI DllMain(HINSTANCE hinst, DWORD dwReason, LPVOID reserved)
{
    if (DetourIsHelperProcess())
    {
        return TRUE;
    }

    if (dwReason == DLL_PROCESS_ATTACH)
    {
        // Initialize the hook when the DLL is loaded
        InitHook();
    }
    else if (dwReason == DLL_PROCESS_DETACH)
    {
        // Remove the hook when the DLL is unloaded
        RemoveHook();
    }

    return TRUE;
}
