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

The original implementation of random number generation in the Infinity Engine relies on a specific variant of a linear congruential generator, as shown above. However, versions of the game 
running on platforms other than Windows, such as Linux, utilize different approaches by making system-level calls to the rand() function. As a result, they may not encounter the same issues 
inherent in the original implementation.

One notable consequence of this difference is that platforms with superior pseudo-random number generators may exhibit a higher likelihood of consecutive high rolls, such as consistently 
rolling the maximum value (e.g., rolling all 6's during an ability roll).

This distinction becomes particularly evident when observing ability autorollers. With the original algorithm, the occurrence of ability roll totals surpassing 104 seems highly improbable, if 
not impossible. However, when running an autoroller for an extended period on a Linux system with a different algorithm, roll totals of 105 and 106 do occur.

The provided table presents the probabilities of obtaining specific roll totals, along with their corresponding normalized and rounded relative probabilities. These relative probabilities serve 
to highlight the relative disparity between the likelihood of rolling one specific total compared to another. For example, if you roll 104, you can anticipate rolling 103 approximately 4.399 times 
on average. Of particular note is that the likelihood of rolling 105 should be only about 5.25 times less likely than 104.


| **Roll Total** | **Probability of Occurrence** | **Normalized to 103** | **Normalized to 104** | **Normalized to 105** | **Normalized to 106** | **Normalized to 107** | **Normalized to 108** |
|---------------:|------------------------------:|----------------------:|----------------------:|----------------------:|----------------------:|----------------------:|----------------------:|
|            103 |               1 in 3856609580 |                1 in 1 |                       |                       |                       |                       |                       |
|            104 |              1 in 16969082150 |            1 in 4.399 |                1 in 1 |                       |                       |                       |                       |
|            105 |              1 in 89087681288 |           1 in 23.099 |            1 in 5.250 |                1 in 1 |                       |                       |                       |
|            106 |             1 in 593917875254 |          1 in 153.999 |           1 in 35.000 |            1 in 6.666 |                1 in 1 |                       |                       |
|            107 |            1 in 5642219814912 |         1 in 1462.999 |          1 in 332.500 |           1 in 63.333 |            1 in 9.499 |                1 in 1 |                       |
|            108 |          1 in 101559956668416 |        1 in 26333.999 |         1 in 5985.000 |         1 in 1140.000 |          1 in 170.999 |               1 in 18 |                1 in 1 |

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
