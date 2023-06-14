# Infinity Engine - Better Random Library
A better random for Infinity Engine Games

This repository provides a solution for injecting a "better random" library into the Infinity Engine game executables using a batch file and a custom DLL.
The DLL hooks the `rand()` function and replaces it with a custom implementation that generates more robust random numbers. 

The custom DLL utilizes the C++ standard library's random number generation facilities. It includes the following components:

- `std::random_device rd`: This is a non-deterministic random number generator that provides a source of true randomness from the operating system or hardware.
- `std::uniform_int_distribution<> dist(0, RAND_MAX)`: This distribution object defines a range between 0 and `RAND_MAX` (the maximum value returned by `rand()`), 
  ensuring that the generated numbers are uniformly distributed within this range.
- `std::mt19937 gen(rd())`: This line seeds the Mersenne Twister pseudo-random number generator (`mt19937`) with random values obtained from `std::random_device rd`. 
  The Mersenne Twister is a widely-used pseudo-random number generator that produces high-quality random numbers with a long period.

By utilizing these components, the custom implementation of the `rand()` function improves the randomness and unpredictability of the random numbers generated during gameplay.

## Original Infinity Engine Random Implementation
```C++
__int64 __fastcall rand()
{
  __acrt_ptd *v0;
  unsigned int v1;

  v0 = _acrt_getptd();
  v1 = 214013 * v0->_rand_state + 2531011;
  v0->_rand_state = v1;
  return HIWORD(v1) & 0x7FFF;
}
```

The original implementation of random for the Infinity Engine uses the specific variant of a [linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator) shown above.

In EE game versions, other platforms outside of Windows (E.g. Linux) don't utilize this implementation, but instead perform library calls to a system level rand() function; thus, they don't necessarily
suffer from the same defects.

## Prerequisites

- Windows operating system
- An infinity engine game
  - Baldur's Gate (BGMain2.exe)
  - Baldur's Gate II (BGmain.exe)
  - Icewind Dale (IDMain.exe)
  - Planescape Torment (Torment.exe)
  - Baldur's Gate EE (Baldur.exe)
  - Baldur's Gate II EE (Baldur.exe)
  - Icewind Dale EE (Icewind.exe)
  - Planescape Torment EE (Torment.exe)

## Usage

1. Copy the files to the directory where the Infinity Engine game executable is located.

2. Double-click on the `BetterRandom.bat` file to run it.

3. The batch script will display a menu with the following options:

   - `1. Add BetterRandom library to {EXE Name}`
   - `2. Remove BetterRandom library from {EXE Name]`

4. Choose an action by entering the corresponding number and press Enter.

## Implementation Details

The custom DLL included in this repository utilizes the Detours library for DLL injection and function hooking. Detours is a powerful library developed by 
Microsoft Research that allows for the interception and redirection of function calls within a target executable.

The Better Random library hooks the `rand()` function in the Baldur's Gate game executable using Detours. It intercepts calls to `rand()` and replaces them with 
a custom implementation that generates random numbers using a more robust algorithm. This enhances the randomness and unpredictability of in-game events that rely 
on the random number generator.

The batch file `BetterRandom.bat` included in this repository simplifies the process of adding or removing the `BetterRandom` library from the Baldur's Gate game executable. 
It utilizes the Detours library's `setdll.exe` tool to perform the DLL injection and removal.

When you run the `BetterRandom.bat` script and choose the option to add the better random library, it uses `setdll.exe` to add `BetterRandom_x64.dll` or `BetterRandom_x86.dll` 
into the game executable's imports table. This allows the DLL to redirect calls to `rand()` to the custom implementation during gameplay.

Similarly, when you choose the option to remove the better random library, the `BetterRandom.bat` script utilizes `setdll.exe` to remove the `BetterRandom_x64.dll` or 
`BetterRandom_x86.dll` from the game executable's imports table, restoring the original `rand()` function.
